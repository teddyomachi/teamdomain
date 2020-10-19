# coding: utf-8
require 'const/vfs_const'
require 'const/stat_const'
require 'const/acl_const'
require 'const/ssl_const'
require 'const/spin_types'
require 'openssl'
require 'base64'
require 'uri'
require 'tasks/login_proc'
require 'tasks/security'
require 'tasks/session_management'
require 'tasks/spin_location_manager'
require 'utilities/database_utilities'
require 'utilities/system'
require 'pg'
require 'pp'
require 'time'

require 'byebug'

module RequestBroker
  include Vfs
  include Acl
  include Ssl
  include Stat
  include Types

  def self.get_my_address
    udp = UDPSocket.new;
    udp.connect("128.0.0.0", 7);
    addr = Socket.unpack_sockaddr_in(udp.getsockname)[1];
    udp.close;
    return addr;
  end

  def self.xcall(paramshash, current_session='')
    # pp paramshashadow
    # initiualize return values ( hash )
    rethash = {:success => true, :status => INFO_BASE}
    # analyze request and eprivilexec!
    # pp paramshash[:request_type]set
    # put timestamp in the session
    my_session_id = paramshash[:session_id]
    if my_session_id.blank?
      my_session_id = current_session
    end
    my_request = paramshash[:request_type]
    if paramshash[:session_id].present?
      # get session timeout
      server_name = '127.0.0.1:18880'
      sfs = SpinFileServer.find_by(server_port: SYSTEM_DEFAULT_SPIN_SERVER_PORT)
      # sfs = SpinFileServer.find_by(server_name: server_name)
      session_timeout = DEFAULT_SPIN_SESSION_TIMEOUT
      if sfs.present?
        server_name = sfs[:server_name]
        session_timeout = (sfs[:session_timeout] > 0 ? sfs[:session_timeout] : DEFAULT_SPIN_SESSION_TIMEOUT)
      end
      last_accessed = SessionManager.get_last_access my_session_id
      t_current = Time.now.tv_sec
      t_last_accessed = t_current
      if last_accessed.present?
        t_last_accessed = last_accessed.tv_sec
      end
      if my_request != 'logout' and last_accessed.present? and (t_last_accessed + session_timeout) < t_current # => timed out session
        SessionManager.force_logout my_session_id
        rethash[:success] = false
        rethash[:status] = ERROR_SESSION_TIMEOUT
        rethash[:errors] = 'Login session timed out'
        return rethash
      else
        SessionManager.put_timestamp my_session_id
      end
    end
    my_request_params = paramshash.to_s
    SessionManager.set_last_access my_session_id, my_request, my_request_params
    case my_request

    when 'login_auth'
      # login user authgentication
      login_option = LOGIN_DEFAULT_LOGIN
      if paramshash[:default_login]
        case paramshash[:default_login]
        when LOGIN_FRESH_LOGIN, LOGIN_FRESH_LOGIN_AND_CLEAR_SESSIONS
          login_option = paramshash[:default_login]
        else
          login_option = LOGIN_FRESH_LOGIN_AND_CLEAR_SESSIONS
          #login_option = LOGIN_DEFAULT_LOGIN
          #          login_option = LOGIN_FRESH_LOGIN
        end
      end
      #      SystemTools::DbTools.set_domain_root_node
      #      login_user = paramshash[:loginUsername]
      login_uname = paramshash[:loginUsername]
      login_user = ''
      uname_and_options = login_uname.scan(/[^:]+/)
      if uname_and_options.length > 1
        login_user = uname_and_options[0]
        login_option = uname_and_options[1].to_i
      else
        login_user = uname_and_options[0]
      end
      rethash = LoginProc::Exec.auth(login_user, paramshash[:loginPassword])
      if rethash[:success] && rethash[:success] == true
        rethash[:status] = true
        rethash[:login_option] = login_option
      else
        #rethash[:status] = false
        rethash[:status] = ERROR_SYSADMIN_INVALID_PASSWORD
        rethash[:success] = false
      end

    when 'mobile_login'
      # login user authgentication
      login_option = LOGIN_DEFAULT_LOGIN
      if paramshash[:default_login]
        case paramshash[:default_login]
        when LOGIN_FRESH_LOGIN, LOGIN_FRESH_LOGIN_AND_CLEAR_SESSIONS
          login_option = paramshash[:default_login]
        else
          #          login_option = LOGIN_FRESH_LOGIN_AND_CLEAR_SESSIONS
          login_option = LOGIN_DEFAULT_LOGIN
          #          login_option = LOGIN_FRESH_LOGIN
        end
      end
      #      SystemTools::DbTools.set_domain_root_node
      #      login_user = paramshash[:loginUsername]
      login_uname = paramshash[:uid]
      login_user = ''
      uname_and_options = login_uname.scan(/[^:]+/)
      if uname_and_options.length > 1
        login_user = uname_and_options[0]
        login_option = uname_and_options[1].to_i
      else
        login_user = uname_and_options[0]
      end
      rethash = LoginProc::Exec.auth(login_user, paramshash[:upw])
      if rethash[:success] && rethash[:success] == true
        rethash[:status] = true
        rethash[:login_option] = login_option
      else
        rethash[:status] = false
        rethash[:success] = false
      end
    when 'user_activation'
      # user acount activation
      user_record = {}
      user_record[:spin_uid] = paramshash[:user_id]
      user_record[:new_user_login_name] = paramshash[:user_name]
      user_record[:new_user_description] = paramshash[:user_description]
      user_record[:new_user_mail_address] = paramshash[:user_mail]
      user_record[:student_id_number] = paramshash[:user_tel]
      user_record[:student_major] = paramshash[:user_major]
      user_record[:student_laboratory] = paramshash[:user_org]
      rethash = SpinUser.activate_user my_session_id, user_record
      if rethash[:success] == true
        locations = CONT_LOCATIONS_LIST
        #        locations.each {|location|
        #          FolderDatum.fill_folders(my_session_id, location)
        #        }
        locations.each {|loc|
          if loc == locations[0]
            reth = FolderDatum.fill_folders my_session_id, loc
          else
            reth = FolderDatum.copy_folder_data_from_location_to_location my_session_id, locations[0], loc
          end
        }
        rethash[:user_name] = user_record[:new_user_login_name]
      end
    when 'change_user_info'
      # user acount activation
      user_record = {}
      user_record[:spin_uid] = paramshash[:user_id]
      user_record[:new_user_login_name] = paramshash[:user_name]
      user_record[:new_user_description] = paramshash[:user_description]
      user_record[:new_user_mail_address] = paramshash[:user_mail]
      user_record[:student_id_number] = paramshash[:user_tel]
      user_record[:student_major] = paramshash[:user_major]
      user_record[:student_laboratory] = paramshash[:user_org]
      rethash = SpinUser.change_user_info my_session_id, user_record
      if rethash[:success] == true
        rethash[:user_name] = user_record[:new_user_login_name]
      end
    when 'change_pw'
      change_password_params = {:uid => paramshash[:operator_id].to_i,
                                :current_password => paramshash[:operator_pw], :new_password => paramshash[:operator_new_pw]}
      rethash = SpinUser.change_password my_session_id, change_password_params
    when 'change_options'
      #auto_save
      #	"auto_noncog"
      #
      #disp_ext
      #	"hide"
      #
      #disp_tree
      #	"hide"
      #
      #operator_id
      #	"1000"
      #
      #request_type
      #	"change_options"
      #
      #rule_created_date
      #	"local_date"
      #
      #session_id
      #	"8cf5b11f04482a0ac7cb3b74b1347bac2b2d5af1"
      change_option_params = {:uid => paramshash[:operator_id].to_i, :auto_save => paramshash[:auto_save],
                              :disp_ext => paramshash[:disp_ext], :disp_tree => paramshash[:disp_tree], :rule_created_date => paramshash[:rule_created_date]
      }
      rethash = SpinUserAttribute.change_options my_session_id, change_option_params
    when 'change_domain'
      # change domain request
      pha = {:hash_key => paramshash[:hash_key],
             :target_folder => paramshash[:target_folder] # => {'folder_a', 'folder_b'} means folder in A or B is selected.
      }
      user_agent = $http_user_agent
      spin_domain_key = ''
      begin
        if /HTTP_Request2.+/ =~ user_agent # => PHP API
          spin_domain_key = paramshash[:hash_key]
        else # => from UI
          #        spin_domain_key = paramshash[:hash_key]
          dd0 = DomainDatum.find_by(hash_key: paramshash[:hash_key])
          #        file_data_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
          if dd0.present?
            spin_domain_key = dd0[:spin_domain_hash_key]
          else
            spin_domain_key = paramshash[:hash_key]
          end
        end
      rescue
        rethash[:success] = false
        rethash[:status] = ERROR_UPLOAD_FILE
        rethash[:errors] = 'Failed to get domain data in change_domain.'
        return rethash
      end
      rh = DomainDatum.select_domain my_session_id, spin_domain_key, paramshash[:target_folder]
      # DatabaseUtility::SessionUtility.set_current_domain my_session_id, spin_domain_key, paramshash[:target_folder]
      if rh.present? and rh[:success]
        rethash[:success] = true
        rethash[:domain_root_node] = rh[:domain_root_node]
      else
        rethash[:success] = false
      end
      locations = Array.new
      if /folder_a/ =~ paramshash[:target_folder]
        locations.push(CONT_LOCATIONS_LIST_A)
      else
        locations.push(CONT_LOCATIONS_LIST_A)
      end
      # reth = FolderDatum.fill_folders(my_session_id, paramshash[:target_folder], spin_domain_key, nil, PROCESS_FOR_UNIVERSAL_REQUEST, false)
      target_folder = DomainDatum.get_selected_folder(my_session_id, spin_domain_key, LOCATION_A)
      # target_folder = SessionManager.get_selected_folder(my_session_id, LOCATION_A)
      if target_folder.present?
        FolderDatum.select_folder(my_session_id, target_folder, LOCATION_A, spin_domain_key)
        FileDatum.fill_file_list(my_session_id, LOCATION_A, target_folder, true)
      end

      if rethash[:success]
      else
        rethash[:success] = false
        rethash[:status] = false
        rethash[:errors] = "ドメイン変更に失敗しました"
      end
    when 'change_domain_m', 'selected_domain'
      # change domain request
      pha = {:hash_key => paramshash[:hash_key],
             :target_folder => paramshash[:target_folder] # => {'folder_a', 'folder_b'} means folder in A or B is selected.
      }
      #      pha = { :hash_key => "#{paramshash[:hash_key]}",
      #        :target_folder => "#{paramshash[:target_folder]}"  # => {'folder_a', 'folder_b'} means folder in A or B is selected.
      #      }
      # root_path = DatabaseUtility::VirtualFileSystemUtility.find_spin_domain_root paramshash[:hash_key]
      # current_path = DatabaseUtility::SessionUtility.set_current_directory paramshash[:session_id], root_path
      my_domain = paramshash[:domain]
      spin_domain_key = ''
      spin_domain_root_key = ''
      #        spin_domain_key = paramshash[:hash_key]
      dd0 = DomainDatum.find_by_hash_key my_domain[:hash_key]
      #        file_data_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
      if dd0.present?
        spin_domain_root_key = dd0[:folder_hash_key]
        spin_domain_key = dd0[:spin_domain_hash_key]
      else
        spin_domain_key = my_domain[:hash_key]
      end
      #      retb = DatabaseUtility::SessionUtility.set_session_info my_session_id,my_request,spin_domain_key,paramshash[:target_folder]
      # if DatabaseUtility::SessionUtility.set_current_domain my_session_id,paramshash[:hash_key],paramshash[:target_folder]
      rh = DomainDatum.select_domain my_session_id, spin_domain_key, LOCATION_A
      #      rh = DomainDatum.select_domain my_session_id,dd0[:spin_domain_hash_key],paramshash[:target_folder]
      if rh[:success]
        rethash[:success] = true
        rethash[:domain_root_node] = rh[:domain_root_node]
        rethash[:message] = 'ドメインを正しく選択しました。'
      else
        rethash[:success] = false
        rethash[:message] = "ドメイン変更に失敗しました"
      end
      #      FolderDatum.reset_partial_root(my_session_id, LOCATION_A, spin_domain_key)
      FolderDatum.fill_folders(my_session_id, LOCATION_A, spin_domain_key, nil, PROCESS_FOR_UNIVERSAL_REQUEST, false)
      target_folder = DomainDatum.get_selected_folder(my_session_id, spin_domain_key, LOCATION_A)
      # target_folder = SessionManager.get_selected_folder(my_session_id, LOCATION_A)
      if target_folder.present?
        FolderDatum.select_folder(my_session_id, target_folder, LOCATION_A, spin_domain_key)
        FileDatum.fill_file_list(my_session_id, LOCATION_A, target_folder, true)
      end
      if rethash[:success]
        rethash[:message] = 'コンテンツを正しく選択しました。'
      else
        rethash[:success] = false
        rethash[:status] = false
        rethash[:message] = "ドメイン変更に失敗しました"
      end
    when 'change_folder'
      # set folder privilege
      user_agent = $http_user_agent
      folder_hashkey = nil
      folder_rec = nil
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        folder_hashkey = paramshash[:hash_key]
      else # => from UI
        #        folder_rec = FolderDatum.find_by_hash_key paramshash[:hash_key]
        folder_rec = FolderDatum.find_by_spin_node_hashkey paramshash[:spin_node_hashkey]
        if folder_rec.blank?
          folder_hashkey = paramshash[:spin_node_hashkey]
        else
          folder_hashkey = folder_rec[:spin_node_hashkey]
        end
      end
      # change folder request
      #set      DatabaseUtility::SessionUtility.set_session_info my_session_id,my_request,paramshash[:hash_key],paramshash[:cont_location]
      #      fd0 = FolderDatum.find_by_hash_key paramshash[:hash_key]
      if folder_hashkey.present?
        #        folder_hashkey = folder_rec[:spin_node_hashkey]
        #        DatabaseUtility::SessionUtility.set_session_info my_session_id,my_request,folder_hashkey,paramshash[:cont_location]
        # if DatabaseUtility::SessionUtility.set_current_folder my_session_id,paramshash[:hash_key],paramshash[:cont_location]
        if FolderDatum.select_folder my_session_id, folder_hashkey, paramshash[:cont_location], paramshash[:domain_hash_key]
          FileDatum.fill_file_list(my_session_id, paramshash[:cont_location], folder_hashkey)
          FolderDatum.reset_partial_root(my_session_id, paramshash[:cont_location])
          FolderDatum.set_partial_root(my_session_id, paramshash[:cont_location], folder_hashkey)
          rethash[:success] = true
          rethash[:status] = INFO_CHANGE_FOLDER_SUCCESS
        else
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_CHANGE_FOLDER
        end
      else
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_CHANGE_FOLDER
      end
    when 'change_file'
      # set folder privilege
      user_agent = $http_user_agent
      file_hashkey = ''
      file_rec = nil
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        file_hashkey = paramshash[:hash_key]
      else # => from UI
        file_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
      end

      if file_rec.present?
        file_hashkey = file_rec[:folder_hash_key]
        if FileDatum.set_selected(my_session_id, file_hashkey, paramshash[:cont_location])
          rethash[:success] = true
          rethash[:status] = INFO_CHANGE_FILE_SUCCESS
          rethash[:result] = file_hashkey
        else
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_CHANGE_FILE
          rethash[:errors] = 'Failed to change file'
        end
      end
    when 'back_to_parent_m'
      # set folder privilege
      user_agent = $http_user_agent
      folder_hashkey = ''
      file_rec = nil
      file_rec = FileDatum.find_by_hash_key paramshash[:parent_hash_key]
      msg = ">> back_to_parent_m : parent_hash_key = " + paramshash[:parent_hash_key] + "\n"
      #      logger.debug msg
      pp msg
      # change folder request
      #set      DatabaseUtility::SessionUtility.set_session_info my_session_id,my_request,paramshash[:hash_key],paramshash[:cont_location]
      #      fd0 = FolderDatum.find_by_hash_key paramshash[:hash_key]
      if file_rec.present?
        #        folder_hashkey = file_rec[:folder_hash_key]
        folder_hashkey = file_rec[:spin_node_hashkey]
        #        folder_hashkey = SpinLocationManager.get_parent_key(current_folder_hashkey, NODE_DIRECTORY)
        parent_folder_hashkey = SpinLocationManager.get_parent_key(folder_hashkey, NODE_DIRECTORY)
        domain_hashkey = SessionManager.get_selected_domain(my_session_id, LOCATION_A)
        #        DatabaseUtility::SessionUtility.set_session_info my_session_id,my_request,folder_hashkey,paramshash[:cont_location]
        # if DatabaseUtility::SessionUtility.set_current_folder my_session_id,paramshash[:hash_key],paramshash[:cont_location]
        FolderDatum.select_folder(my_session_id, parent_folder_hashkey, LOCATION_A, domain_hashkey)
        reth = FileDatum.fill_file_list(my_session_id, LOCATION_A, parent_folder_hashkey, true)
        if reth[:success]
          #          FileDatum.fill_file_list(my_session_id, LOCATION_A, folder_hashkey)
          rethash[:success] = true
          rethash[:message] = 'コンテンツを正しく選択しました。'
        else
          rethash[:success] = false
          rethash[:message] = 'コンテンツ選択を失敗しました。'
        end
      else
        rethash[:success] = false
        rethash[:message] = 'コンテンツ選択を失敗しました。'
      end
    when 'open_folder_m', 'selected_folder'
      # set folder privilege
      user_agent = $http_user_agent
      folder_hashkey = ''
      folder_rec = nil
      folder_rec = FileDatum.find_by_hash_key paramshash[:folder][:hash_key]
      # change folder request
      #set      DatabaseUtility::SessionUtility.set_session_info my_session_id,my_request,paramshash[:hash_key],paramshash[:cont_location]
      #      fd0 = FolderDatum.find_by_hash_key paramshash[:hash_key]
      if folder_rec.present?
        folder_hashkey = folder_rec[:spin_node_hashkey]
        domain_hashkey = SessionManager.get_selected_domain(my_session_id, LOCATION_A)
        #        folder_hashkey = SpinLocationManager.get_parent_key(current_folder_hashkey, NODE_DIRECTORY)
        #        DatabaseUtility::SessionUtility.set_session_info my_session_id,my_request,folder_hashkey,paramshash[:cont_location]
        # if DatabaseUtility::SessionUtility.set_current_folder my_session_id,paramshash[:hash_key],paramshash[:cont_location]
        ret_load_folder_recs = FolderDatum.load_folder_recs(my_session_id, folder_hashkey, folder_rec[:parent_hash_key], domain_hashkey, LOCATION_A, DEPTH_TO_TRAVERSE, SessionManager.get_last_session(my_session_id))
        FolderDatum.select_folder(my_session_id, folder_hashkey, LOCATION_A, domain_hashkey)
        reth = FileDatum.fill_file_list(my_session_id, LOCATION_A, folder_hashkey, true)
        if reth[:success]
          rethash[:success] = true
          rethash[:message] = 'コンテンツを正しく選択しました。'
        else
          rethash[:success] = false
          rethash[:message] = 'コンテンツ選択を失敗しました。'
        end
      else
        logger.debug ">> open_folder_m failed : no folder record is found"
        rethash[:success] = false
        rethash[:message] = 'コンテンツ選択を失敗しました。'
      end
    when 'update_file_list'
      # set folder privilege
      user_agent = $http_user_agent
      folder_hash_key = ''
      file_rec = nil

      if paramshash[:event_type] == nil
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No event type is specified'
        return rethash
      end

      event_type = paramshash[:event_type]

      case event_type
      when 'dd_file_a2b'
        hash_key = paramshash[:hash_key]
        target_folder_hash_key = paramshash[:target_folder_hash_key]
        slocation = 'folder_a'
        target_cont_location = 'folder_b'
        # get folder data
        target_fd = FolderDatum.find_by_hash_key target_folder_hash_key
        if target_fd.present?
          folder_spin_node_hashkey = target_fd[:spin_node_hashkey]
          FileDatum.fill_file_list(my_session_id, target_cont_location, folder_spin_node_hashkey)
        end
      when 'dd_file_b2a'
        hash_key = paramshash[:hash_key]
        target_folder_hash_key = paramshash[:target_folder_hash_key]
        slocation = 'folder_b'
        target_cont_location = 'folder_a'
        # get folder data
        target_fd = FolderDatum.find_by_hash_key target_folder_hash_key
        if target_fd.present?
          folder_spin_node_hashkey = target_fd[:spin_node_hashkey]
          FileDatum.fill_file_list(my_session_id, target_cont_location, folder_spin_node_hashkey)
        end
      when 'property_upload_file' # => after upload, update file list
        domain_hash_key = ''
        folder_spin_node_hashkey = ''
        hash_key = paramshash[:hash_key]
        cont_location = paramshash[:cont_location]
        frec = FileDatum.find_by_session_id_and_cont_location_and_hash_key my_session_id, cont_location, hash_key
        if frec.blank? # => see folder_data
          frec = FolderDatum.find_by_session_id_and_cont_location_and_hash_key my_session_id, cont_location, hash_key
          if frec.present? and frec[:domain_hash_key].present?
            domain_hash_key = frec[:domain_hash_key]
          else
            domain_hash_key = SessionManager.get_selected_domain(my_session_id, cont_location)
          end
          folder_spin_node_hashkey = frec[:spin_node_hashkey]
        else # => see file_data
          # get folder rec
          folder_rec = FolderDatum.find_by_spin_node_hashkey frec[:folder_hash_key] # => folder_hash_key : spin_node_hashkey of the
          if folder_rec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'property_upload_file failed'
            return rethash
          end
          domain_hash_key = folder_rec[:domain_hash_key]
          folder_spin_node_hashkey = frec[:folder_hash_key]
        end
        #        if FolderDatum.select_folder(my_session_id,folder_spin_node_hashkey,paramshash[:cont_location],domain_hash_key)
        FileDatum.fill_file_list(my_session_id, cont_location, folder_spin_node_hashkey)
        rethash[:success] = true
        rethash[:status] = INFO_UPDATE_FILE_LIST_SUCCESS
        rethash[:result] = paramshash[:hash_key]
        #        else
        #          rethash[:success] = false
        #          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        #          rethash[:errors] = 'failed to set current folder'
        #        end
      when 'property_change_file_property'
        domain_hash_key = ''
        folder_spin_node_hashkey = ''
        hash_key = paramshash[:hash_key]
        cont_location = paramshash[:cont_location]
        frec = FolderDatum.find_by_session_id_and_cont_location_and_hash_key my_session_id, cont_location, hash_key
        if frec.blank?
          firec = FileDatum.find_by_session_id_and_cont_location_and_hash_key my_session_id, cont_location, hash_key
          if firec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'property_change_file_property failed'
            return rethash
          end
          domain_hash_key = SessionManager.get_selected_domain(my_session_id, cont_location)
          #          folder_rec = FolderDatum.find_by_hash_key firec[:folder_hash_key]
          folder_spin_node_hashkey = firec[:folder_hash_key]
          #          folder_spin_node_hashkey = folder_rec[:spin_node_hashkey]
        else
          domain_hash_key = frec[:domain_hash_key]
          folder_spin_node_hashkey = frec[:spin_node_hashkey]
        end
        if FolderDatum.select_folder(my_session_id, folder_spin_node_hashkey, paramshash[:cont_location], domain_hash_key)
          FileDatum.fill_file_list(my_session_id, cont_location, folder_spin_node_hashkey)
          rethash[:success] = true
          rethash[:status] = INFO_UPDATE_FILE_LIST_SUCCESS
          rethash[:result] = paramshash[:hash_key]
        else
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'failed to set current folder'
        end
      when 'property_move_file'
        domain_hash_key = ''
        folder_spin_node_hashkey = ''
        hash_key = paramshash[:hash_key]
        cont_location = paramshash[:cont_location]
        frec = FileDatum.find_by_session_id_and_cont_location_and_hash_key my_session_id, cont_location, hash_key
        if frec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'failed to get filelist record'
        else
          folder_hash_key = frec[:folder_hash_key]
          domain_hash_key = frec[:domain_hash_key]
          folder_spin_node_hashkey = frec[:folder_hash_key]
        end
        FolderDatum.select_folder(my_session_id, folder_spin_node_hashkey, cont_location, domain_hash_key)
        FileDatum.fill_file_list(my_session_id, cont_location, folder_spin_node_hashkey)
        case cont_location
        when LOCATION_A
          selected_folder = SessionManager.get_selected_folder(my_session_id, LOCATION_B)
          FileDatum.fill_file_list(my_session_id, LOCATION_B, selected_folder)
        when LOCATION_B
          selected_folder = SessionManager.get_selected_folder(my_session_id, LOCATION_A)
          FileDatum.fill_file_list(my_session_id, LOCATION_A, selected_folder)
        else
          selected_folder = SessionManager.get_selected_folder(my_session_id, LOCATION_B)
          FileDatum.fill_file_list(my_session_id, LOCATION_B, selected_folder)
        end
        rethash[:success] = true
        rethash[:status] = INFO_UPDATE_FILE_LIST_SUCCESS
        rethash[:result] = paramshash[:hash_key]
      else
        rethash[:success] = true
        rethash[:status] = INFO_UPDATE_FILE_LIST_SUCCESS
        rethash[:result] = paramshash[:hash_key]
        #        rethash[:success] = false
        #        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        #        rethash[:errors] = 'Invalid event type is specified'
        return rethash
      end
    when 'update_folder_list'
      # set folder privilege
      user_agent = $http_user_agent
      folder_key = ''
      folder_hashkey = ''
      domain_hashkey = ''
      my_cont_location = ''
      retb = true
      is_after_retrieve_from_recycler = false

      # Is it called from TRASH?
      if paramshash[:hash_key] == CALLED_FROM_TRASH_HASH_KEY
        is_after_retrieve_from_recycler = true
        my_cont_location = SessionManager.get_current_location(my_session_id)
        folder_hashkey = SessionManager.get_selected_folder(my_session_id, my_cont_location)
        domain_hashkey = SessionManager.get_selected_domain(my_session_id, my_cont_location)
      end

      folder_rec = nil
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        folder_hashkey = paramshash[:hash_key]
      else # => from UI
        if (paramshash[:original_place]=='listGridPanelA'||paramshash[:original_place]=='thumbnailViewAB')
          folder_rec = FileDatum.find_by(hash_key: paramshash[:hash_key])
        else
          folder_rec = FolderDatum.find_by(hash_key: paramshash[:hash_key])
        end
        if folder_rec.blank? and paramshash[:event_type] != 'selected_domain' and paramshash[:event_type] != 'priviledge_folder_member_exclude'
          # put login folder to folder_list
          myrethash = Hash.new
          myrethash = FolderDatum.fill_folders(my_session_id,"folder_a")
          if myrethash['success'] == true
            return myrethash
          end
          #
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No folder record is found at update_folder_list'
          return rethash
        end
      end
      # change folder request
      #set      DatabaseUtility::SessionUtility.set_session_info my_session_id,my_request,paramshash[:hash_key],paramshash[:cont_location]
      #      fd0 = FolderDatum.find_by_hash_key paramshash[:hash_key]

      if paramshash[:event_type] == nil
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No event type is specified'
        return rethash
      end

      event_type = paramshash[:event_type]

      case event_type
      when 'priviledge_folder_member_exclude'
        my_cont_location = 'folder_a'
        domain_s = SessionManager.get_selected_domain(my_session_id, my_cont_location)
        DomainDatum.set_domain_dirty(my_session_id, my_cont_location, domain_s)
        # FolderDatum.reset_partial_root(my_session_id, my_cont_location, domain_s)
        # FolderDatum.clear_folder_tree(my_session_id, my_cont_location, domain_s)
        reth = FolderDatum.fill_folders(my_session_id, my_cont_location, domain_s)
        # copy_locations = CONT_LOCATIONS_LIST - [my_cont_location]
        # reth = {}
        # copy_locations.each {|copy_location|
        #   reth = FolderDatum.copy_folder_data_from_location_to_location(my_session_id, my_cont_location, copy_location, domain_hashkey)
        # }
      when 'property_move_folder'
        my_cont_location = paramshash[:cont_location]
        domain_hashkey = SessionManager.get_selected_domain(my_session_id, my_cont_location)
        DomainDatum.set_domain_dirty(my_session_id, my_cont_location, domain_hashkey)
        FolderDatum.reset_partial_root(my_session_id, my_cont_location, domain_hashkey)
        FolderDatum.fill_folders(my_session_id, my_cont_location)
        copy_locations = CONT_LOCATIONS_LIST - [my_cont_location]
        reth = {}
        copy_locations.each {|copy_location|
          reth = FolderDatum.copy_folder_data_from_location_to_location(my_session_id, my_cont_location, copy_location, domain_hashkey)
        }
        retb = reth[:success]
      when 'property_copy_folder'
        my_cont_location = paramshash[:cont_location]
        domain_hashkey = SessionManager.get_selected_domain(my_session_id, my_cont_location)
        DomainDatum.set_domain_dirty(my_session_id, my_cont_location, domain_hashkey)
        FolderDatum.reset_partial_root(my_session_id, my_cont_location, domain_hashkey)
        FolderDatum.fill_folders(my_session_id, my_cont_location)
        copy_locations = CONT_LOCATIONS_LIST - [my_cont_location]
        reth = {}
        copy_locations.each {|copy_location|
          reth = FolderDatum.copy_folder_data_from_location_to_location(my_session_id, my_cont_location, copy_location, domain_hashkey)
        }
        retb = reth[:success]
      when 'property_create_subfolder'
        if folder_rec.present?
          folder_hashkey = folder_rec[:spin_node_hashkey]
          domain_hashkey = folder_rec[:domain_hash_key]
          FolderDatum.load_folder_recs(my_session_id, folder_hashkey, domain_hashkey, folder_rec[:parent_hash_key], paramshash[:cont_location], DEPTH_TO_TRAVERSE, SessionManager.get_last_session(my_session_id))
          #          copy_locations = CONT_LOCATIONS_LIST - [ paramshash[:cont_location] ]
          #          copy_locations.each {|copy_location|
          #            FolderDatum.copy_folder_data_from_location_to_location(my_session_id, paramshash[:cont_location], copy_location, domain_hashkey)
          #          }
          FolderDatum.has_updated(my_session_id, folder_hashkey, NEW_CHILD)
          #          SpinNode.has_updated(my_session_id, folder_hashkey)
          locations = CONT_LOCATIONS_LIST
          locations -= [paramshash[:cont_location]]
          locations.each {|loc|
            reth = FolderDatum.copy_folder_data_from_location_to_location my_session_id, paramshash[:cont_location], loc, paramshash[:domain_hash_key]
          }
          rethash[:success] = true
          rethash[:status] = INFO_UPDATE_FOLDER_LIST_SUCCESS
          rethash[:result] = paramshash[:hash_key]
        else
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FOLDER_LIST
          rethash[:errors] = 'failed to set current folder : update folder list'
        end
        #ペースト機能追加↓
      when 'property_paste_file'
        target_cont_location = 'folder_a'
        domain_hashkey = SessionManager.get_selected_domain(my_session_id, target_cont_location)
        DomainDatum.set_domain_dirty(my_session_id, target_cont_location, domain_hashkey)
        FolderDatum.reset_partial_root(my_session_id, target_cont_location, domain_hashkey)
        FolderDatum.fill_folders(my_session_id, target_cont_location)
        copy_locations = CONT_LOCATIONS_LIST - [target_cont_location]
        reth = {}
        copy_locations.each {|copy_location|
          reth = FolderDatum.copy_folder_data_from_location_to_location(my_session_id, target_cont_location, copy_location, domain_hashkey)
        }
        retb = reth[:success]
        #ペースト機能追加↑
      when 'selected_domain'
        selected_folder = DomainDatum.get_selected_folder(my_session_id, paramshash[:hash_key], 'folder_a')
        if selected_folder.present?
          FolderDatum.select_folder(my_session_id, selected_folder, target_cont_location, domain_hashkey)
          rethash[:success] = true
          rethash[:status] = INFO_UPDATE_FOLDER_LIST_SUCCESS
          rethash[:result] = selected_folder
        else
          selected_folder = SpinUser.get_login_directory my_session_id
          DomainDatum.set_selected_folder my_session_id, paramshash[:hash_key], selected_folder, 'folder_a'
          FolderDatum.load_folder_recs my_session_id, selected_folder, paramshash[:hash_key]
          rethash[:success] = true
          rethash[:status] = INFO_UPDATE_FOLDER_LIST_SUCCESS
          rethash[:result] = selected_folder
        end
      else # => another events

        if is_after_retrieve_from_recycler
          copy_locations = CONT_LOCATIONS_LIST - [my_cont_location]
          reth = {}
          copy_locations.each {|copy_location|
            reth = FolderDatum.copy_folder_data_from_location_to_location(my_session_id, my_cont_location, copy_location, domain_hashkey)
          }
        elsif folder_rec.present?
          folder_hashkey = folder_rec[:spin_node_hashkey]
          domain_hashkey = folder_rec[:domain_hash_key]
          #        if folder_rec[:moved] == true
          #          folder_rec.destroy
          #        end
          #        DomainDatum.set_domain_dirty(my_session_id, paramshash[:cont_location], domain_hashkey)
          #        FolderDatum.fill_folders(my_session_id, paramshash[:cont_location], folder_rec[:domain_hash_key], folder_hashkey)
          #        FolderDatum.remove_folder_rec(my_session_id, paramshash[:cont_location], folder_hashkey)
          FolderDatum.load_folder_recs(my_session_id, folder_hashkey, domain_hashkey, folder_rec[:parent_hash_key], paramshash[:cont_location], DEPTH_TO_TRAVERSE, SessionManager.get_last_session(my_session_id))
          #          copy_locations = CONT_LOCATIONS_LIST - [ paramshash[:cont_location] ]
          #          copy_locations.each {|copy_location|
          #            FolderDatum.copy_folder_data_from_location_to_location(my_session_id, paramshash[:cont_location], copy_location, domain_hashkey)
          #          }
          #        retb = FolderDatum.select_folder my_session_id, folder_hashkey, paramshash[:cont_location], domain_hashkey
          retb = true
          if retb
            rethash[:success] = true
            rethash[:status] = INFO_UPDATE_FOLDER_LIST_SUCCESS
            rethash[:result] = paramshash[:hash_key]
          else
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FOLDER_LIST
            rethash[:errors] = 'failed to set current folder : update folder list'
          end
        else # => no folder rec means it is after move or delete operation
          retb = true
          # retry over file list
          file_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
          if file_rec.present?
            my_cont_location = SessionManager.get_current_location(my_session_id)
            folder_rec = FolderDatum.find_by_hash_key file_rec[:folder_hash_key]
            if folder_rec.present?
              folder_hashkey = folder_rec[:spin_node_hashkey]
              domain_hashkey = folder_rec[:domain_hash_key]
              #        if folder_rec[:moved] == true
              #          folder_rec.destroy
              #        end
              #          DomainDatum.set_domain_dirty(my_session_id, paramshash[:cont_location], domain_hashkey)
              #          FolderDatum.fill_folders(my_session_id, paramshash[:cont_location], domain_hashkey)
              #          DomainDatum.set_domain_dirty(my_session_id, paramshash[:cont_location], domain_hashkey)
              #          FolderDatum.fill_folders(my_session_id, paramshash[:cont_location], domain_hashkey)
              copy_locations = CONT_LOCATIONS_LIST - [my_cont_location]
              reth = {}
              copy_locations.each {|copy_location|
                reth = FolderDatum.copy_folder_data_from_location_to_location(my_session_id, my_cont_location, copy_location, domain_hashkey)
              }
              #            retb = reth[:success]
              #          retb = FolderDatum.select_folder my_session_id, folder_rec[:spin_node_hashkey], paramshash[:cont_location], domain_hashkey
              #        else # => it is not found yet after retry
              #          # It should be after throw files from recycler
              #          my_cont_location = SessionManager.get_current_location(my_session_id)
              #          folder_hashkey = SessionManager.get_selected_folder(my_session_id, my_cont_location)
              #          domain_hashkey = SessionManager.get_selected_domain(my_session_id, my_cont_location)
              #          DomainDatum.set_domain_dirty(my_session_id, my_cont_location, domain_hashkey)
              #          FolderDatum.fill_folders(my_session_id, my_cont_location)
              #          copy_locations = CONT_LOCATIONS_LIST - [ my_cont_location ]
              #          reth = {}
              #          copy_locations.each {|copy_location|
              #            reth = FolderDatum.copy_folder_data_from_location_to_location(my_session_id, my_cont_location, copy_location, domain_hashkey)
              #          }
              ##          retb = FolderDatum.select_folder my_session_id, folder_hashkey, my_cont_location, domain_hashkey
              #          retb = reth[:success]
            end
          else # => no display data rec that means folder is moved by properety-pane-move method
            my_cont_location = paramshash[:cont_location]
            domain_hashkey = SessionManager.get_selected_domain(my_session_id, my_cont_location)
            DomainDatum.set_domain_dirty(my_session_id, my_cont_location, domain_hashkey)
            FolderDatum.fill_folders(my_session_id, my_cont_location)
            copy_locations = CONT_LOCATIONS_LIST - [my_cont_location]
            reth = {}
            copy_locations.each {|copy_location|
              reth = FolderDatum.copy_folder_data_from_location_to_location(my_session_id, my_cont_location, copy_location, domain_hashkey)
            }
            retb = reth[:success]
          end
        end
        if retb
          rethash[:success] = true
          rethash[:status] = INFO_UPDATE_FOLDER_LIST_SUCCESS
          rethash[:result] = paramshash[:hash_key]
        else
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FOLDER_LIST
          rethash[:errors] = 'failed to set current folder'
        end
      end
    when 'open_file'
      # download and open file
      # "cont_location"=>"folder_a", "hash_key"=>"598377551fc375d16b6171dd8fe7700b4fcccc2c", "file_name"=>"P3310283.jpg", "wayToOpen"=>"read_only", "openVersion1"=>"latest", "ver_number1"=>nil, "forAllFiles"=>false
      if FileManager.is_busy
        # => not writable
        rethash[:success] = false
        rethash[:status] = ERROR_SYSTEM_FILE_MANAGER_BUSY
        return rethash
      end
      open_file_key = String.new
      open_file_name = String.new
      open_sid = String.new
      #      open_contlocation = String.new

      open_file_name = (paramshash[:file_name] == nil ? "download_file" : paramshash[:file_name])
      #      paramshash.keys.each {|k| printf "%s = %s\n",k,paramshash[k]}
      open_sid = my_session_id
      #      open_contlocation = paramshash[:cont_location]
      # set latest flag to false
      download_file_key = ''
      file_data = FileDatum.find_by_hash_key paramshash[:hash_key]
      if file_data.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No file record is found'
        return rethash
      end
      user_agent = $http_user_agent
      if user_agent == "BoomboxAPI" # => PHP API
        download_file_key = paramshash[:hash_key]
      else # => from UI
        file_data = FileDatum.find_by_hash_key paramshash[:hash_key]
        unless file_data.blank?
          download_file_key = file_data[:spin_node_hashkey]
        else
          download_file_key = paramshash[:hash_key]
        end
        #download_file_key = file_data[:spin_node_hashkey]
      end
      if paramshash[:openVersion1] == "latest"
        # open_file_key = DatabaseUtility::VirtualFileSystemUtility.get_latest_version file_data[:spin_node_hashkey]
        open_file_key = DatabaseUtility::VirtualFileSystemUtility.get_latest_version download_file_key
      elsif paramshash[:openVersion1] == "prior"
        # open_file_key = DatabaseUtility::VirtualFileSystemUtility.get_prior_version file_data[:spin_node_hashkey]
        open_file_key = DatabaseUtility::VirtualFileSystemUtility.get_prior_version download_file_key
      end
      # => yes there is!
      if SpinAccessControl.is_readable(open_sid, open_file_key, ANY_TYPE) == false
        FileManager.rails_logger("RequestBroker::open_file::open_file_key = " + open_file_key)
        # => not readable
        rethash[:success] = false
        rethash[:status] = ERROR_NOT_READABLE
        return rethash
      end
      rsa_key_pem = SpinNode.get_root_rsa_key
      pdata = ''
      fmargs = ''
      retry_encrypt = ENCRYPTION_RETRY_COUNT
      catch(:encrypt_again_1) {
        begin
          pdata = my_session_id + open_file_key + open_file_name
          # make encrypted data
          file_manager_params = Security.public_key_encrypt2 rsa_key_pem, pdata
          # and encode into base64
          # fmargs = file_manager_params
          enc_len = file_manager_params[:data].length
          if enc_len < (KEY_SIZE / 8)
            if retry_encrypt > 0
              retry_encrypt -= 1
              sleep(AR_RETRY_WAIT_MSEC)
              throw :encrypt_again_1
            end
          end
          fmargs = Security.urlsafe_encode_base64(file_manager_params[:length].to_s + file_manager_params[:data])
          if ENV['RAILS_ENV'] != 'production'
            my_host = $http_host.split(/:|\//)[-2]
            # => get URL server
            my_url_host = SpinFileServer.find_by_server_port(SYSTEM_DEFAULT_SPIN_SERVER_PORT)
            if my_url_host.present?
              my_host = my_url_host[:spin_url_server_name]
            end
            #          if my_host.length == 2
            rethash[:redirect_uri] = my_host + "/secret_files/downloader/download_proc?fmargs=" + fmargs
          else
            rethash[:redirect_uri] = '/secret_files/downloader/download_proc?fmargs=' + fmargs
          end
          #          my_host = $http_host.split(/:|\//)[-2]
          #          if my_host.length == 2
          #            rethash[:redirect_uri] = "http://#{my_host[0]}:18881/filemanager/downloader/download_proc?fmargs=" + fmargs
          #          else
          #            rethash[:redirect_uri] = '/secret_files/downloader/download_proc?fmargs=' + fmargs
          #          end
          rethash[:is_download] = true
          rethash[:success] = true
        rescue OpenSSL::PKey::RSAError
          if retry_encrypt > 0
            retry_encrypt -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :encrypt_again_1
          end
          rethash[:success] = false
          rethash[:status] = ERROR_DOWNLOAD_FILE
          rethash[:errors] = 'Failed to generate encrypted URL by OpenSSL::PKey::RSA'
        rescue
          if retry_encrypt > 0
            retry_encrypt -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :encrypt_again_1
          end
          rethash[:success] = false
          rethash[:status] = ERROR_DOWNLOAD_FILE
          rethash[:errors] = 'Failed to generate encrypted urlsafe URL'
        end
      }
    when 'get_uri_m'
      # download and open file
      # "cont_location"=>"folder_a", "hash_key"=>"598377551fc375d16b6171dd8fe7700b4fcccc2c", "file_name"=>"P3310283.jpg", "wayToOpen"=>"read_only", "openVersion1"=>"latest", "ver_number1"=>nil, "forAllFiles"=>false
      if FileManager.is_busy
        # => not writable
        rethash[:success] = false
        rethash[:status] = ERROR_SYSTEM_FILE_MANAGER_BUSY
        return rethash
      end
      open_file_key = String.new
      open_file_name = String.new
      open_sid = String.new
      #      open_contlocation = String.new

      open_file_name = (paramshash[:targetFile][:file_name] == nil ? "download_file" : paramshash[:targetFile][:file_name])
      #      paramshash.keys.each {|k| printf "%s = %s\n",k,paramshash[k]}
      open_sid = my_session_id
      #      open_contlocation = LOCATION_A
      # set latest flag to false
      download_file_key = ''
      user_agent = $http_user_agent
      file_data = FileDatum.find_by_hash_key paramshash[:targetFile][:hash_key]
      if file_data.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No file record is found'
        return rethash
      end
      download_file_key = file_data[:spin_node_hashkey]
      open_file_key = DatabaseUtility::VirtualFileSystemUtility.get_latest_version file_data[:spin_node_hashkey]
      # => yes there is!
      if SpinAccessControl.is_readable(open_sid, open_file_key, ANY_TYPE) == false
        # => not readable
        rethash[:success] = false
        rethash[:status] = ERROR_NOT_READABLEs
        return rethash
      end
      rsa_key_pem = SpinNode.get_root_rsa_key
      pdata = ''
      fmargs = ''
      retry_encrypt = ENCRYPTION_RETRY_COUNT
      catch(:encrypt_again_2) {
        begin
          pdata = my_session_id + open_file_key + open_file_name
          # make encrypted data
          file_manager_params = Security.public_key_encrypt2 rsa_key_pem, pdata
          # and encode into base64
          # fmargs = file_manager_params
          enc_len = file_manager_params[:data].length
          if enc_len < (KEY_SIZE / 8)
            if retry_encrypt > 0
              retry_encrypt -= 1
              sleep(AR_RETRY_WAIT_MSEC)
              throw :encrypt_again_2
            end
          end
          fmargs = Security.urlsafe_encode_base64(file_manager_params[:length].to_s + file_manager_params[:data])
          if ENV['RAILS_ENV'] != 'production'
            my_host = $http_host.split(/:|\//)[-2]
            # => get URL server
            my_url_host = SpinFileServer.find_by_server_port(SYSTEM_DEFAULT_SPIN_SERVER_PORT)
            if my_url_host.present?
              my_host = my_url_host[:spin_url_server_name]
            end
            #          if my_host.length == 2
            rethash[:redirect_uri] = my_host + "/secret_files/uploader/upload_proc?fmargs=" + fmargs
          else
            rethash[:redirect_uri] = '/secret_files/uploader/upload_proc?fmargs=' + fmargs
          end
          #          my_host = $http_host.split(/:|\//)[-2]
          #          if my_host.length == 2
          #            rethash[:redirect_uri] = "http://#{my_host[0]}:18881/filemanager/downloader/download_proc?fmargs=" + fmargs
          #          else
          #            rethash[:redirect_uri] = '/secret_files/downloader/download_proc?fmargs=' + fmargs
          #          end
          rethash[:is_download] = true
          rethash[:success] = true
        rescue OpenSSL::PKey::RSAError
          if retry_encrypt > 0
            retry_encrypt -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :encrypt_again_2
          end
          rethash[:success] = false
          rethash[:status] = ERROR_UPLOAD_FILE
          rethash[:errors] = 'Failed to generate encrypted URL by OpenSSL::PKey::RSA'
        rescue
          if retry_encrypt > 0
            retry_encrypt -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :encrypt_again_2
          end
          rethash[:success] = false
          rethash[:status] = ERROR_UPLOAD_FILE
          rethash[:errors] = 'Failed to generate encrypted urlsafe URL'
        end
      }
      #      pdata = my_session_id + open_file_key + open_file_name
      #      # make encrypted data
      #      file_manager_params = Security.public_key_encrypt2 rsa_key_pem,  pdata
      #      # and encode into base64
      #      # fmargs = file_manager_params
      #      fmargs = Security.urlsafe_encode_base64(file_manager_params[:length].to_s + file_manager_params[:data])
      #      # then URI escape
      #      # uri_fmargs = Security.escape_base64 fmargs
      #      # rethash[:redirect_uri] = 'http://192.168.2.119:18080/secret_files/uploader/upload_proc?fmargs=' + fmargs
      #      my_host = $http_host.split(/:/)
      #      if my_host.length == 2
      #        rethash[:redirect_uri] = "http://#{my_host[0]}:18881/filemanager/downloader/download_proc?fmargs=" + fmargs
      #      else
      #        rethash[:redirect_uri] = '/secret_files/downloader/download_proc?fmargs=' + fmargs
      #      end
      #      rethash[:is_download] = true
      #      #      rethash[:redirect_uri] = '/secret_files/downloader/download_proc?fmargs=' + fmargs
      #      rethash[:success] = true
    when 'lock_open'
      # download and open file
      # "cont_location"=>"folder_a", "hash_key"=>"598377551fc375d16b6171dd8fe7700b4fcccc2c", "file_name"=>"P3310283.jpg", "wayToOpen"=>"read_only", "openVersion1"=>"latest", "ver_number1"=>nil, "forAllFiles"=>false
      open_file_name = paramshash[:file_name]
      #      paramshash.keys.each {|k| printf "%s = %s\n",k,paramshash[k]}
      open_sid = my_session_id
      #      open_contlocation = paramshash[:cont_location]
      #      open_file_fey = paramshash[:hash_key]
      # set latest flag to false
      file_data = FileDatum.find_by_hash_key paramshash[:hash_key]
      if file_data.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No file record is found at lock_open'
        return rethash
      end
      if paramshash[:openVersion1] == "latest"
        open_file_key = DatabaseUtility::VirtualFileSystemUtility.get_latest_version file_data[:spin_node_hashkey]
      elsif paramshash[:openVersion1] == "prior"
        open_file_key = DatabaseUtility::VirtualFileSystemUtility.get_prior_version file_data[:spin_node_hashkey]
      end
      # => yes there is!
      if SpinAccessControl.is_readable(open_sid, open_file_key, ANY_TYPE) == false
        # => not readable
        rethash[:success] = false
        rethash[:status] = ERROR_NOT_READABLE
        return rethash
      end
      rsa_key_pem = SpinNode.get_root_rsa_key
      pdata = ''
      fmargs = ''
      retry_encrypt = ENCRYPTION_RETRY_COUNT
      catch(:encrypt_again_3) {
        begin
          pdata = my_session_id + open_file_key + open_file_name
          # make encrypted data
          file_manager_params = Security.public_key_encrypt2 rsa_key_pem, pdata
          # and encode into base64
          # fmargs = file_manager_params
          enc_len = file_manager_params[:data].length
          if enc_len < (KEY_SIZE / 8)
            if retry_encrypt > 0
              retry_encrypt -= 1
              sleep(AR_RETRY_WAIT_MSEC)
              throw :encrypt_again_3
            end
          end
          fmargs = Security.urlsafe_encode_base64(file_manager_params[:length].to_s + file_manager_params[:data])
          if ENV['RAILS_ENV'] != 'production'
            my_host = $http_host.split(/:|\//)[-2]
            # => get URL server
            my_url_host = SpinFileServer.find_by_server_port(SYSTEM_DEFAULT_SPIN_SERVER_PORT)
            if my_url_host.present?
              my_host = my_url_host[:spin_url_server_name]
            end
            #          if my_host.length == 2
            rethash[:redirect_uri] = my_host + "/secret_files/uploader/upload_proc?fmargs=" + fmargs
          else
            rethash[:redirect_uri] = '/secret_files/uploader/upload_proc?fmargs=' + fmargs
          end
          #          my_host = $http_host.split(/:|\//)[-2]
          #          if my_host.length == 2
          #            rethash[:redirect_uri] = "http://#{my_host[0]}:18881/filemanager/downloader/download_proc?fmargs=" + fmargs
          #          else
          #            rethash[:redirect_uri] = '/secret_files/downloader/download_proc?fmargs=' + fmargs
          #          end
          rethash[:is_download] = true
          rethash[:success] = true
        rescue OpenSSL::PKey::RSAError
          if retry_encrypt > 0
            retry_encrypt -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :encrypt_again_3
          end
          rethash[:success] = false
          rethash[:status] = ERROR_UPLOAD_FILE
          rethash[:errors] = 'Failed to generate encrypted URL by OpenSSL::PKey::RSA'
        rescue
          if retry_encrypt > 0
            retry_encrypt -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :encrypt_again_3
          end
          rethash[:success] = false
          rethash[:status] = ERROR_UPLOAD_FILE
          rethash[:errors] = 'Failed to generate encrypted urlsafe URL'
        end
      }
    when 'just_open'
      # download and open file
      # "cont_location"=>"folder_a", "hash_key"=>"598377551fc375d16b6171dd8fe7700b4fcccc2c", "file_name"=>"P3310283.jpg", "wayToOpen"=>"read_only", "openVersion1"=>"latest", "ver_number1"=>nil, "forAllFiles"=>false
      if FileManager.is_busy
        # => not writable
        rethash[:success] = false
        rethash[:status] = ERROR_SYSTEM_FILE_MANAGER_BUSY
        return rethash
      end
      open_file_key = String.new
      open_file_name = String.new
      open_sid = String.new
      #      open_contlocation = String.new

      open_file_name = (paramshash[:file_name] == nil ? "download_file" : paramshash[:file_name])
      #      paramshash.keys.each {|k| printf "%s = %s\n",k,paramshash[k]}
      open_sid = my_session_id
      #      open_contlocation = paramshash[:cont_location]
      # set latest flag to false
      download_file_key = ''
      file_data = FileDatum.find_by_hash_key paramshash[:hash_key]
      if file_data.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No file record is found'
        return rethash
      end
      user_agent = $http_user_agent
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        download_file_key = paramshash[:hash_key]
      else # => from UI
        file_data = FileDatum.find_by_hash_key paramshash[:hash_key]
        if file_data.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No file record is found'
          return rethash
        end
        download_file_key = file_data[:spin_node_hashkey]
      end
      if paramshash[:openVersion1] == "latest"
        open_file_key = DatabaseUtility::VirtualFileSystemUtility.get_latest_version download_file_key
      else
        open_file_key = download_file_key
      end
      # => yes there is!
      if SpinAccessControl.is_readable(open_sid, open_file_key, ANY_TYPE) == false
        # => not readable
        rethash[:success] = false
        rethash[:status] = ERROR_NOT_READABLEs
        return rethash
      end
      rsa_key_pem = SpinNode.get_root_rsa_key
      pdata = ''
      fmargs = ''
      retry_encrypt = ENCRYPTION_RETRY_COUNT
      catch(:encrypt_again_4) {
        begin
          pdata = my_session_id + open_file_key + open_file_name
          # make encrypted data
          file_manager_params = Security.public_key_encrypt2 rsa_key_pem, pdata
          # and encode into base64
          # fmargs = file_manager_params
          enc_len = file_manager_params[:data].length
          if enc_len < (KEY_SIZE / 8)
            if retry_encrypt > 0
              retry_encrypt -= 1
              sleep(AR_RETRY_WAIT_MSEC)
              throw :encrypt_again_4
            end
          end
          fmargs = Security.urlsafe_encode_base64(file_manager_params[:length].to_s + file_manager_params[:data])
          if ENV['RAILS_ENV'] != 'production'
            my_host = $http_host.split(/:|\//)[-2]
            # => get URL server
            my_url_host = SpinFileServer.find_by_server_port(SYSTEM_DEFAULT_SPIN_SERVER_PORT)
            if my_url_host.present?
              my_host = my_url_host[:spin_url_server_name]
            end
            #          if my_host.length == 2
            rethash[:redirect_uri] = my_host + "/secret_files/uploader/upload_proc?fmargs=" + fmargs
          else
            rethash[:redirect_uri] = '/secret_files/uploader/upload_proc?fmargs=' + fmargs
          end
          #          my_host = $http_host.split(/:/)
          #          if my_host.length == 2
          #            rethash[:redirect_uri] = "http://#{my_host[0]}:18881/filemanager/downloader/download_proc?fmargs=" + fmargs
          #          else
          #            rethash[:redirect_uri] = '/secret_files/downloader/download_proc?fmargs=' + fmargs
          #          end
          rethash[:is_download] = true
          rethash[:success] = true
        rescue OpenSSL::PKey::RSAError
          if retry_encrypt > 0
            retry_encrypt -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :encrypt_again_4
          end
          rethash[:success] = false
          rethash[:status] = ERROR_UPLOAD_FILE
          rethash[:errors] = 'Failed to generate encrypted URL by OpenSSL::PKey::RSA'
        rescue
          if retry_encrypt > 0
            retry_encrypt -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :encrypt_again_4
          end
          rethash[:success] = false
          rethash[:status] = ERROR_UPLOAD_FILE
          rethash[:errors] = 'Failed to generate encrypted urlsafe URL'
        end
      }
    when 'ref_open'
      # download and open file
      # "cont_location"=>"folder_a", "hash_key"=>"598377551fc375d16b6171dd8fe7700b4fcccc2c", "file_name"=>"P3310283.jpg", "wayToOpen"=>"read_only", "openVersion1"=>"latest", "ver_number1"=>nil, "forAllFiles"=>false
      if FileManager.is_busy
        # => not writable
        rethash[:success] = false
        rethash[:status] = ERROR_SYSTEM_FILE_MANAGER_BUSY
        return rethash
      end
      open_file_key = String.new
      open_file_name = String.new
      open_sid = String.new
      #      open_contlocation = String.new

      open_file_name = (paramshash[:file_name] == nil ? "download_file" : paramshash[:file_name])
      #      paramshash.keys.each {|k| printf "%s = %s\n",k,paramshash[k]}
      open_sid = my_session_id
      #      open_contlocation = paramshash[:cont_location]
      # set latest flag to false
      download_file_key = ''
      file_data = FileDatum.find_by_hash_key paramshash[:hash_key]
      if file_data.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No file record is found'
        return rethash
      end
      user_agent = $http_user_agent
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        download_file_key = paramshash[:hash_key]
      else # => from UI
        file_data = FileDatum.find_by_hash_key paramshash[:hash_key]
        if file_data.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No file record is found'
          return rethash
        end
        download_file_key = file_data[:spin_node_hashkey]
      end
      if paramshash[:openVersion1] == "latest"
        open_file_key = DatabaseUtility::VirtualFileSystemUtility.get_latest_version download_file_key
      else
        open_file_key = download_file_key
      end
      # => yes there is!
      if SpinAccessControl.is_readable(open_sid, open_file_key, ANY_TYPE) == false
        # => not readable
        rethash[:success] = false
        rethash[:status] = ERROR_NOT_READABLEs
        return rethash
      end
      rsa_key_pem = SpinNode.get_root_rsa_key
      pdata = ''
      fmargs = ''
      retry_encrypt = ENCRYPTION_RETRY_COUNT
      catch(:encrypt_again_5) {
        begin
          pdata = my_session_id + open_file_key + open_file_name
          # make encrypted data
          file_manager_params = Security.public_key_encrypt2 rsa_key_pem, pdata
          # and encode into base64
          # fmargs = file_manager_params
          enc_len = file_manager_params[:data].length
          if enc_len < (KEY_SIZE / 8)
            if retry_encrypt > 0
              retry_encrypt -= 1
              sleep(AR_RETRY_WAIT_MSEC)
              throw :encrypt_again_5
            end
          end
          fmargs = Security.urlsafe_encode_base64(file_manager_params[:length].to_s + file_manager_params[:data])
          if ENV['RAILS_ENV'] != 'production'
            my_host = $http_host.split(/:|\//)[-2]
            # => get URL server
            my_url_host = SpinFileServer.find_by_server_port(SYSTEM_DEFAULT_SPIN_SERVER_PORT)
            if my_url_host.present?
              my_host = my_url_host[:spin_url_server_name]
            end
            #          if my_host.length == 2
            rethash[:redirect_uri] = my_host + "/secret_files/uploader/upload_proc?fmargs=" + fmargs
          else
            rethash[:redirect_uri] = '/secret_files/uploader/upload_proc?fmargs=' + fmargs
          end
          #          my_host = $http_host.split(/:/)
          #          if my_host.length == 2
          #            rethash[:redirect_uri] = "http://#{my_host[0]}:18881/filemanager/downloader/download_proc?fmargs=" + fmargs
          #          else
          #            rethash[:redirect_uri] = '/secret_files/downloader/download_proc?fmargs=' + fmargs
          #          end
          rethash[:is_download] = true
          rethash[:success] = true
        rescue OpenSSL::PKey::RSAError
          if retry_encrypt > 0
            retry_encrypt -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :encrypt_again_5
          end
          rethash[:success] = false
          rethash[:status] = ERROR_UPLOAD_FILE
          rethash[:errors] = 'Failed to generate encrypted URL by OpenSSL::PKey::RSA'
        rescue
          if retry_encrypt > 0
            retry_encrypt -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :encrypt_again_5
          end
          rethash[:success] = false
          rethash[:status] = ERROR_UPLOAD_FILE
          rethash[:errors] = 'Failed to generate encrypted urlsafe URL'
        end
      }
    when 'move_files'
      # delete file from list and put it in the recycler
      # session_id, cont_location, hash_key, file_writable_status:bool, lock:int, file_name
      move_sid = my_session_id
      #      move_target_folder_name = paramshash[:target_folder]
      #      move_target_folder_hashkey = paramshash[:target_hash]
      # get numbered hashes
      list_files = Array.new
      #      files_to_move = Array.new
      hash_params = Hash.new
      paramshash.each {|key, value|
        if /[0-9]+/ =~ key # => number
          list_files.push value
        else # => string
          hash_params[key] = value
        end
      }
      # get file attributes
      target_cont_location = 'folder_b'
      source_cont_location = 'folder_a'
      move_file_hash_keys = Array.new
      list_files.each {|f|
        f_rec = FileDatum.find_by_hash_key f[:hash_key]
        if f_rec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No file record is found'
          return rethash
        end
        source_cont_location = f[:cont_location]
        move_file_hash_keys.append(f_rec[:spin_node_hashkey])
      }
      if source_cont_location == 'folder_a'
        target_cont_location = 'folder_b'
      else
        target_cont_location = 'folder_a'
      end
      move_target_folder_hashkey = SessionManager.get_selected_folder(my_session_id, target_cont_location)
      r = Random.new

      # check trash can
      list_files.each {|lf|
        can_file_nodes = DatabaseUtility::VirtualFileSystemUtility.search_virtual_file my_session_id, lf[:file_name], move_target_folder_hashkey, ANY_VALUE, ANY_VALUE, SEARCH_EXISTING_VFILE
        can_file_nodes.each {|canf|
          if canf[:in_trash_flag] and canf[:is_void] != true
            rethash[:success] = false
            rethash[:status] = ERROR_SAME_FILE_PATH_IN_RECYCLER
            if canf[:node_type] == NODE_FILE
              rethash[:errors] = '同じパス名のファイルがゴミ箱の中にあります'
            else
              rethash[:errors] = '同じパス名のフォルダがゴミ箱の中にあります'
            end
          else
            rethash[:success] = false
            rethash[:status] = ERROR_SAME_FILE_PATH_IN_DIRECTORY
            if canf[:node_type] == NODE_FILE
              rethash[:errors] = '同じパス名のファイルがフォルダの中にあります'
            else
              rethash[:errors] = '同じパス名のフォルダがフォルダの中にあります'
            end
          end
          return rethash
        }
      }

      move_source_folder_hashkey = SpinLocationManager.get_parent_key(move_file_hash_keys[0])

      # Are source folder and target folder the same?
      move_file_hash_keys.each {|mvf|
        if mvf == move_target_folder_hashkey
          rethash[:success] = false
          rethash[:status] = ERROR_TRIED_TO_MOVE_TO_SAME_FOLDER
          rethash[:errors] = '自分自身には移動出来ません'
          return rethash
        end
        if move_source_folder_hashkey == move_target_folder_hashkey
          rethash[:success] = false
          rethash[:status] = ERROR_TRIED_TO_MOVE_TO_SAME_FOLDER
          rethash[:errors] = '同じフォルダには移動出来ません'
          return rethash
        end
        if SpinLocationManager.is_in_sub_tree(mvf, move_target_folder_hashkey)
          rethash[:success] = false
          rethash[:status] = ERROR_TRIED_TO_MOVE_TO_SAME_FOLDER
          rethash[:errors] = '自分のサブフォルダには移動出来ません'
          return rethash
        end
      }

      opr_id = Security.hash_key_s(move_sid + move_target_folder_hashkey + target_cont_location + r.rand.to_s)
      rethash = ClipBoards.put_nodes(opr_id, move_sid, move_file_hash_keys, OPERATION_CUT)
      unless rethash[:success]
        return rethash
      end
      put_node_count = rethash[:rsult]

      # acl check!
      # Does it have ACL to do move operation?
      has_right_to_delete = SpinAccessControl.is_writable(move_sid, move_source_folder_hashkey, NODE_DIRECTORY)
      target_has_right_to_delete = SpinAccessControl.is_writable(move_sid, move_target_folder_hashkey, NODE_DIRECTORY)
      if has_right_to_delete == false or target_has_right_to_delete == false
        rethash[:success] = false
        rethash[:status] = ERROR_MOVE_FILE
        rethash[:errors] = 'Failed to move files :  user has no right to delete the file or a file in target dir.'
      else
        retb = DatabaseUtility::VirtualFileSystemUtility.move_virtual_files_in_clipboard opr_id, move_sid, move_source_folder_hashkey, move_target_folder_hashkey, target_cont_location
        if retb
          FolderDatum.has_updated(move_sid, move_source_folder_hashkey, DISMISS_CHILD, true)
          FolderDatum.has_updated(move_sid, move_target_folder_hashkey, NEW_CHILD, true)
          domain_s = SessionManager.get_selected_domain(my_session_id, source_cont_location)
          domain_t = SessionManager.get_selected_domain(my_session_id, target_cont_location)
          # clear is_partial_root flag
          FolderDatum.reset_partial_root(my_session_id, source_cont_location, domain_t)
          if domain_s != domain_t
            FolderDatum.reset_partial_root(my_session_id, target_cont_location, domain_s)
          end
          #      locations.each {|loc|
          reth = FolderDatum.fill_folders(my_session_id, source_cont_location, domain_t, nil, PROCESS_FOR_UNIVERSAL_REQUEST, false, 1)
          if domain_s != domain_t
            reth = FolderDatum.fill_folders(my_session_id, target_cont_location, domain_s, nil, PROCESS_FOR_UNIVERSAL_REQUEST, false, 1)
          end
          #        SessionManager.set_location_dirty(move_sid, (source_cont_location == 'folder_a' ? 'file_listA' : 'file_listB'), true)
          #        SessionManager.set_location_dirty(move_sid, (target_cont_location == 'folder_a' ? 'file_listA' : 'file_listB'), true)
          rethash[:success] = true
          rethash[:status] = INFO_MOVE_FILE_SUCCESS
        else
          rethash[:success] = false
          rethash[:status] = ERROR_MOVE_FILE
          rethash[:errors] = 'Failed to move files'
        end
      end
    when 'move_folder'
      user_agent = $http_user_agent
      move_file_key = ''
      move_file_name = ''
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        move_file_key = paramshash[:hash_key]
      else # => from UI
        if paramshash[:original_place] == 'folder_tree' # it is in folder tree
          folder_rec = FolderDatum.find_by_session_id_and_hash_key_and_cont_location my_session_id, paramshash[:hash_key], paramshash[:cont_location]
          if folder_rec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'No folder record is found at move_folder'
            return rethash
          end
          move_file_key = folder_rec[:spin_node_hashkey]
          move_file_name = folder_rec[:text]
        else
          folder_rec = FileDatum.find_by_session_id_and_hash_key_and_cont_location my_session_id, paramshash[:hash_key], paramshash[:cont_location]
          if folder_rec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'No folder record is found at move_folder 2'
            return rethash
          end
          move_file_key = folder_rec[:spin_node_hashkey]
          move_file_name = folder_rec[:text]
        end
      end
      # delete file from list and put it in the recycler
      # session_id, cont_location, hash_key, file_writable_status:bool, lock:int, file_name
      #      move_file_name = paramshash[:file_name]
      # paramshash.keys.each {|k| printf "%s = %s\n",k,paramshash[k]}
      move_sid = my_session_id
      #      move_contlocation = paramshash[:cont_location]
      #      move_file_key = paramshash[:hash_key]
      move_folder_writable_status = ((paramshash[:folder_writable_status] == true or paramshash[:folder_writable_status] == 'true') ? true : false)
      target_cont_location = paramshash[:target_cont_location]
      target_folder_writable_status = ((paramshash[:target_folder_writable_status] == true or paramshash[:target_folder_writable_status] == 'true') ? true : false)
      target_folder_rec = FolderDatum.find_by_session_id_and_target_hash_key_and_target_cont_location my_session_id, paramshash[:target_hash_key], target_cont_location
      if target_folder_rec.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No target folder record is found'
        return rethash
      end
      target_hash_key = target_folder_rec[:spin_node_hashkey]
      target_folder_name = paramshash[:text]

      # check trash can
      can_file_nodes = DatabaseUtility::VirtualFileSystemUtility.search_virtual_file my_session_id, move_file_name, target_hash_key, ANY_VALUE, ANY_VALUE, SEARCH_EXISTING_VFILE
      can_file_nodes.each {|canf|
        can_file_nodes.each {|canf|
          if canf[:in_trash_flag]
            rethash[:success] = false
            rethash[:status] = ERROR_SAME_FILE_PATH_IN_RECYCLER
            if canf[:node_type] == NODE_FILE
              rethash[:errors] = '同じパス名のファイルがゴミ箱の中にあります'
            else
              rethash[:errors] = '同じパス名のフォルダがゴミ箱の中にあります'
            end
          else
            rethash[:success] = false
            rethash[:status] = ERROR_SAME_FILE_PATH_IN_DIRECTORY
            if canf[:node_type] == NODE_FILE
              rethash[:errors] = '同じパス名のファイルがフォルダの中にあります'
            else
              rethash[:errors] = '同じパス名のフォルダがフォルダの中にあります'
            end
          end
          return rethash
        }
      }

      if move_folder_writable_status != true or target_folder_writable_status != true # => not movable
        # this should not be deleted
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_MOVE_FOLDER
        rethash[:errors] = "Failed to move folder : folder is not movable"
        return rethash
      end
      has_right_to_delete = SpinAccessControl.is_deletable(move_sid, move_file_key, NODE_DIRECTORY)
      target_has_right_to_delete = SpinAccessControl.is_writable(move_sid, target_hash_key, NODE_DIRECTORY)
      move_file_hash_keys = Array.new
      move_file_hash_keys.push move_file_key
      #      target_folder_rec = FolderDatum.find_by_session_id_and_cont_location_and_selected move_sid, target_cont_location, true
      move_target_folder_hashkey = target_hash_key
      r = Random.new

      move_source_folder_hashkey = SpinLocationManager.get_parent_key(move_file_hash_keys[0])

      # Are source folder and target folder the same?
      if move_file_key == move_target_folder_hashkey
        rethash[:success] = false
        rethash[:status] = ERROR_TRIED_TO_MOVE_TO_SAME_FOLDER
        rethash[:errors] = '自分自身には移動出来ません'
        return rethash
      end
      if move_source_folder_hashkey == move_target_folder_hashkey
        rethash[:success] = false
        rethash[:status] = ERROR_TRIED_TO_MOVE_TO_SAME_FOLDER
        rethash[:errors] = '同じフォルダには移動出来ません'
        return rethash
      end
      if SpinLocationManager.is_in_sub_tree(move_file_key, move_target_folder_hashkey)
        rethash[:success] = false
        rethash[:status] = ERROR_TRIED_TO_MOVE_TO_SAME_FOLDER
        rethash[:errors] = '自分のサブフォルダには移動出来ません'
        return rethash
      end

      opr_id = Security.hash_key_s(move_sid + target_hash_key + target_cont_location + r.rand.to_s)
      rethash = ClipBoards.put_nodes(opr_id, move_sid, move_file_hash_keys, OPERATION_CUT)
      unless rethash[:success]
        return rethash
      end
      put_node_count = rethash[:rsult]

      # acl check!
      # Does it have ACL to do move operation?
      if has_right_to_delete != true or target_has_right_to_delete != true
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_MOVE_FOLDER
        rethash[:errors] = 'failed to move folder at acl check before operation'
      else
        retb = DatabaseUtility::VirtualFileSystemUtility.move_virtual_files_in_clipboard opr_id, move_sid, move_source_folder_hashkey, move_target_folder_hashkey, target_cont_location
        if retb
          FolderDatum.has_updated(move_sid, move_source_folder_hashkey, DISMISS_CHILD, true)
          FolderDatum.has_updated(move_sid, move_target_folder_hashkey, NEW_CHILD, true)
          #        SessionManager.set_location_dirty(move_sid, (source_cont_location == 'folder_a' ? 'file_listA' : 'file_listB'), true)
          #        SessionManager.set_location_dirty(move_sid, (target_cont_location == 'folder_a' ? 'file_listA' : 'file_listB'), true)
          rethash[:success] = true
          rethash[:status] = INFO_MOVE_FOLDER_SUCCESS
        else
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_MOVE_FOLDER
          rethash[:errors] = 'failed to move folder at move_virtual_files_in_clipboard operation'
        end
      end
    when 'copy_folder'
      user_agent = $http_user_agent
      copy_file_key = ''
      copy_file_name = ''
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        copy_file_key = paramshash[:hash_key]
      else # => from UI
        if paramshash[:original_place] == 'folder_tree' # it is in folder tree
          folder_rec = FolderDatum.find_by_session_id_and_hash_key_and_cont_location my_session_id, paramshash[:hash_key], paramshash[:cont_location]
          if folder_rec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'No folder record is found at copy_folder'
            return rethash
          end
          copy_file_key = folder_rec[:spin_node_hashkey]
          copy_file_name = folder_rec[:text]
        else
          folder_rec = FileDatum.find_by_session_id_and_hash_key_and_cont_location my_session_id, paramshash[:hash_key], paramshash[:cont_location]
          if folder_rec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'No folder record is found at copy_folder 2'
            return rethash
          end
          copy_file_key = folder_rec[:spin_node_hashkey]
          copy_file_name = folder_rec[:text]
        end
      end
      # delete file from list and put it in the recycler
      # session_id, cont_location, hash_key, file_writable_status:bool, lock:int, file_name
      #      copy_file_name = paramshash[:file_name]
      # paramshash.keys.each {|k| printf "%s = %s\n",k,paramshash[k]}
      copy_sid = my_session_id
      #      copy_contlocation = paramshash[:cont_location]
      #      copy_file_key = paramshash[:hash_key]

      # Is it readable?
      copy_file_is_readable = SpinAccessControl.is_readable(my_session_id, copy_file_key, NODE_DIRECTORY)
      unless copy_file_is_readable # => not copyable
        # this should not be deleted
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_COPY_FOLDER
        rethash[:errors] = ""
        return rethash
      end

      target_cont_location = paramshash[:target_cont_location]
      target_folder_writable_status = ((paramshash[:target_folder_writable_status] == true or paramshash[:target_folder_writable_status] == 'true') ? true : false)
      target_folder_rec = FolderDatum.find_by_session_id_and_target_hash_key_and_target_cont_location my_session_id, paramshash[:target_hash_key], target_cont_location
      if target_folder_rec.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No folder record is found at copy_folder 3'
        return rethash
      end
      target_hash_key = target_folder_rec[:spin_node_hashkey]
      target_folder_name = paramshash[:text]

      # check trash can
      can_file_nodes = DatabaseUtility::VirtualFileSystemUtility.search_virtual_file my_session_id, copy_file_name, target_hash_key, ANY_VALUE, ANY_VALUE, SEARCH_EXISTING_VFILE
      can_file_nodes.each {|canf|
        can_file_nodes.each {|canf|
          if canf[:in_trash_flag]
            rethash[:success] = false
            rethash[:status] = ERROR_SAME_FILE_PATH_IN_RECYCLER
            if canf[:node_type] == NODE_FILE
              rethash[:errors] = '同じパス名のファイルがゴミ箱の中にあります'
            else
              rethash[:errors] = '同じパス名のフォルダがゴミ箱の中にあります'
            end
          else
            rethash[:success] = false
            rethash[:status] = ERROR_SAME_FILE_PATH_IN_DIRECTORY
            if canf[:node_type] == NODE_FILE
              rethash[:errors] = '同じパス名のファイルがフォルダの中にあります'
            else
              rethash[:errors] = '同じパス名のフォルダがフォルダの中にあります'
            end
          end
          return rethash
        }
      }

      if target_folder_writable_status != true # => not copyable
        # this should not be deleted
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_COPY_FOLDER
        rethash[:errors] = "Failed to copy folder : target folder is not writable"
        return rethash
      end
      target_has_right_to_delete = SpinAccessControl.is_writable(copy_sid, target_hash_key, NODE_DIRECTORY)
      copy_file_hash_keys = Array.new
      copy_file_hash_keys.push copy_file_key
      #      target_folder_rec = FolderDatum.find_by_session_id_and_cont_location_and_selected copy_sid, target_cont_location, true
      copy_target_folder_hashkey = target_hash_key
      r = Random.new

      copy_source_folder_hashkey = SpinLocationManager.get_parent_key(copy_file_hash_keys[0])

      # Are source folder and target folder the same?
      if copy_file_key == copy_target_folder_hashkey
        rethash[:success] = false
        rethash[:status] = ERROR_TRIED_TO_COPY_TO_SAME_FOLDER
        rethash[:errors] = '自分自身にはコピー出来ません'
        return rethash
      end
      if copy_source_folder_hashkey == copy_target_folder_hashkey
        rethash[:success] = false
        rethash[:status] = ERROR_TRIED_TO_COPY_TO_SAME_FOLDER
        rethash[:errors] = '同じフォルダにはコピー出来ません'
        return rethash
      end
      if SpinLocationManager.is_in_sub_tree(copy_file_key, copy_target_folder_hashkey)
        rethash[:success] = false
        rethash[:status] = ERROR_TRIED_TO_COPY_TO_SAME_FOLDER
        rethash[:errors] = '自分のサブフォルダにはコピー出来ません'
        return rethash
      end

      opr_id = Security.hash_key_s(copy_sid + target_hash_key + target_cont_location + r.rand.to_s)
      rethash = ClipBoards.put_nodes(opr_id, copy_sid, copy_file_hash_keys, OPERATION_COPY)
      unless rethash[:success]
        return rethash
      end
      put_node_count = rethash[:rsult]

      # acl check!
      # Does it have ACL to do copy operation?
      if target_has_right_to_delete != true
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_COPY_FOLDER
        rethash[:errors] = '指定されたフォルダにコピーする権限がありません'
      else
        retb = DatabaseUtility::VirtualFileSystemUtility.copy_virtual_files_in_clipboard opr_id, copy_sid, copy_source_folder_hashkey, copy_target_folder_hashkey, target_cont_location
        if retb
          FolderDatum.has_updated(copy_sid, copy_target_folder_hashkey, NEW_CHILD, true)
          #        SessionManager.set_location_dirty(copy_sid, (source_cont_location == 'folder_a' ? 'file_listA' : 'file_listB'), true)
          #        SessionManager.set_location_dirty(copy_sid, (target_cont_location == 'folder_a' ? 'file_listA' : 'file_listB'), true)
          rethash[:success] = true
          rethash[:status] = INFO_COPY_FOLDER_SUCCESS
        else
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_COPY_FOLDER
          rethash[:errors] = 'コピーに失敗しました'
        end
      end
    when 'move_file'
      user_agent = $http_user_agent
      move_file_key = ''
      move_file_name = ''
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        move_file_key = paramshash[:hash_key]
        move_file_name = paramshash[:file_name]
      else # => from UI
        file_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
        if file_rec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No folder record is foundat move_file'
          return rethash
        end
        move_file_key = file_rec[:spin_node_hashkey]
        move_file_name = file_rec[:file_name]
      end
      # delete file from list and put it in the recycler
      # session_id, cont_location, hash_key, file_writable_status:bool, lock:int, file_name
      #      move_file_name = paramshash[:file_name]
      # paramshash.keys.each {|k| printf "%s = %s\n",k,paramshash[k]}
      move_sid = my_session_id
      #      move_contlocation = paramshash[:cont_location]
      #      move_file_key = paramshash[:hash_key]
      move_file_writable_status = ((paramshash[:file_writable_status] == true or paramshash[:file_writable_status] == 'true') ? true : false)
      target_cont_location = paramshash[:target_cont_location]
      target_folder_writable_status = ((paramshash[:target_folder_writable_status] == true or paramshash[:target_folder_writable_status] == 'true') ? true : false)
      target_folder_rec = FolderDatum.find_by_session_id_and_target_hash_key_and_target_cont_location my_session_id, paramshash[:target_hash_key], target_cont_location
      if target_folder_rec.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No folder record is found at move_file 2'
        return rethash
      end
      target_hash_key = target_folder_rec[:spin_node_hashkey]
      #      target_hash_key = paramshash[:target_hash_key]
      #      target_folder_name = paramshash[:text]
      if move_file_writable_status != true or target_folder_writable_status != true # => not movable
        # this should not be deleted
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_MOVE_FILE
        rethash[:errors] = "Failed to move file : file is not movable"
        return rethash
      end
      #      has_right_to_delete = true
      #      target_has_right_to_delete = true
      has_right_to_delete = SpinAccessControl.is_deletable(move_sid, move_file_key, NODE_DIRECTORY)
      target_has_right_to_delete = SpinAccessControl.is_writable(move_sid, target_hash_key, NODE_DIRECTORY)
      move_file_hash_keys = Array.new
      move_file_hash_keys.push move_file_key
      #      target_folder_rec = FolderDatum.find_by_session_id_and_cont_location_and_selected move_sid, target_cont_location, true
      move_target_folder_hashkey = target_hash_key
      r = Random.new
      t = Time.now

      # check trash can
      can_file_nodes = DatabaseUtility::VirtualFileSystemUtility.search_virtual_file my_session_id, move_file_name, move_target_folder_hashkey, ANY_VALUE, ANY_VALUE, SEARCH_EXISTING_VFILE
      can_file_nodes.each {|canf|
        if canf[:in_trash_flag] and canf[:is_void] != true
          rethash[:success] = false
          rethash[:status] = ERROR_SAME_FILE_PATH_IN_RECYCLER
          if canf[:node_type] == NODE_FILE
            rethash[:errors] = '同じパス名のファイルがゴミ箱の中にあります'
          else
            rethash[:errors] = '同じパス名のフォルダがゴミ箱の中にあります'
          end
        else
          rethash[:success] = false
          rethash[:status] = ERROR_SAME_FILE_PATH_IN_DIRECTORY
          if canf[:node_type] == NODE_FILE
            rethash[:errors] = '同じパス名のファイルがフォルダの中にあります'
          else
            rethash[:errors] = '同じパス名のフォルダがフォルダの中にあります'
          end
        end
        return rethash
      }

      move_source_folder_hashkey = SpinLocationManager.get_parent_key(move_file_hash_keys[0])

      # Are source folder and target folder the same?
      if move_file_key == move_target_folder_hashkey
        rethash[:success] = false
        rethash[:status] = ERROR_TRIED_TO_MOVE_TO_SAME_FOLDER
        rethash[:errors] = '自分自身には移動出来ません'
        return rethash
      end
      if move_source_folder_hashkey == move_target_folder_hashkey
        rethash[:success] = false
        rethash[:status] = ERROR_TRIED_TO_MOVE_TO_SAME_FOLDER
        rethash[:errors] = '同じフォルダには移動出来ません'
        return rethash
      end
      if SpinLocationManager.is_in_sub_tree(move_file_key, move_target_folder_hashkey)
        rethash[:success] = false
        rethash[:status] = ERROR_TRIED_TO_MOVE_TO_SAME_FOLDER
        rethash[:errors] = '自分のサブフォルダには移動出来ません'
        return rethash
      end

      opr_id = Security.hash_key_s(move_sid + target_hash_key + t.to_s + r.rand.to_s)

      rethash = ClipBoards.put_nodes(opr_id, move_sid, move_file_hash_keys, OPERATION_CUT)
      unless rethash[:success]
        return rethash
      end
      put_node_count = rethash[:rsult]

      # acl check!
      # Does it have ACL to do move operation?
      if has_right_to_delete != true or target_has_right_to_delete != true
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_MOVE_FILE
      else
        retb = DatabaseUtility::VirtualFileSystemUtility.move_virtual_files_in_clipboard opr_id, move_sid, move_source_folder_hashkey, move_target_folder_hashkey, target_cont_location
        if retb
          FolderDatum.has_updated(move_sid, move_source_folder_hashkey, DISMISS_CHILD, true)
          FolderDatum.has_updated(move_sid, move_target_folder_hashkey, NEW_CHILD, true)
          #        SessionManager.set_location_dirty(move_sid, (source_cont_location == 'folder_a' ? 'file_listA' : 'file_listB'), true)
          #        SessionManager.set_location_dirty(move_sid, (target_cont_location == 'folder_a' ? 'file_listA' : 'file_listB'), true)
          rethash[:success] = true
          rethash[:status] = INFO_MOVE_FILE_SUCCESS
        else
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_MOVE_FILE
        end
      end
    when 'copy_file'
      user_agent = $http_user_agent
      copy_file_key = ''
      copy_file_name = ''
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        copy_file_key = paramshash[:hash_key]
        copy_file_name = paramshash[:file_name]
      else # => from UI
        file_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
        if file_rec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No folder record is found at copy_file'
          return rethash
        end
        copy_file_key = file_rec[:spin_node_hashkey]
        copy_file_name = file_rec[:file_name]
      end
      # delete file from list and put it in the recycler
      # session_id, cont_location, hash_key, file_writable_status:bool, lock:int, file_name
      #      copy_file_name = paramshash[:file_name]
      # paramshash.keys.each {|k| printf "%s = %s\n",k,paramshash[k]}
      copy_sid = my_session_id
      #      copy_contlocation = paramshash[:cont_location]
      #      copy_file_key = paramshash[:hash_key]
      target_cont_location = paramshash[:target_cont_location]
      target_folder_writable_status = ((paramshash[:target_folder_writable_status] == true or paramshash[:target_folder_writable_status] == 'true') ? true : false)
      target_folder_rec = FolderDatum.find_by_session_id_and_target_hash_key_and_target_cont_location my_session_id, paramshash[:target_hash_key], target_cont_location
      if target_folder_rec.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No folder record is found at copy_file 2'
        return rethash
      end
      target_hash_key = target_folder_rec[:spin_node_hashkey]
      #      target_hash_key = paramshash[:target_hash_key]
      #      target_folder_name = paramshash[:text]
      if target_folder_writable_status != true # => not movable
        # this should not be deleted
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_COPY_FILE
        rethash[:errors] = "Failed to move file : file is not movable"
        return rethash
      end
      #      has_right_to_delete = true
      #      target_has_right_to_delete = true
      target_has_right_to_delete = SpinAccessControl.is_writable(copy_sid, target_hash_key, NODE_DIRECTORY)
      copy_file_hash_keys = Array.new
      copy_file_hash_keys.push copy_file_key
      #      target_folder_rec = FolderDatum.find_by_session_id_and_cont_location_and_selected copy_sid, target_cont_location, true
      copy_target_folder_hashkey = target_hash_key
      r = Random.new
      t = Time.now
      copy_source_folder_hashkey = SpinLocationManager.get_parent_key(copy_file_key)

      # Are source folder and target folder the same?
      if copy_file_key == copy_target_folder_hashkey
        rethash[:success] = false
        rethash[:status] = ERROR_TRIED_TO_COPY_TO_SAME_FOLDER
        rethash[:errors] = '自分自身にはコピー出来ません'
        return rethash
      end
      if copy_source_folder_hashkey == copy_target_folder_hashkey
        rethash[:success] = false
        rethash[:status] = ERROR_TRIED_TO_COPY_TO_SAME_FOLDER
        rethash[:errors] = '同じフォルダにはコピー出来ません'
        return rethash
      end
      if SpinLocationManager.is_in_sub_tree(copy_file_key, copy_target_folder_hashkey)
        rethash[:success] = false
        rethash[:status] = ERROR_TRIED_TO_COPY_TO_SAME_FOLDER
        rethash[:errors] = '自分のサブフォルダにはコピー出来ません'
        return rethash
      end

      # check trash can
      can_file_nodes = DatabaseUtility::VirtualFileSystemUtility.search_virtual_file my_session_id, copy_file_name, copy_target_folder_hashkey, ANY_VALUE, ANY_VALUE, SEARCH_EXISTING_VFILE
      can_file_nodes.each {|canf|
        if canf[:in_trash_flag]
          rethash[:success] = false
          rethash[:status] = ERROR_SAME_FILE_PATH_IN_RECYCLER
          if canf[:node_type] == NODE_FILE
            rethash[:errors] = '同じパス名のファイルがゴミ箱の中にあります'
          else
            rethash[:errors] = '同じパス名のフォルダがゴミ箱の中にあります'
          end
        else
          rethash[:success] = false
          rethash[:status] = ERROR_SAME_FILE_PATH_IN_DIRECTORY
          if canf[:node_type] == NODE_FILE
            rethash[:errors] = '同じパス名のファイルがフォルダの中にあります'
          else
            rethash[:errors] = '同じパス名のフォルダがフォルダの中にあります'
          end
        end
        return rethash
      }

      opr_id = Security.hash_key_s(copy_sid + target_hash_key + t.to_s + r.rand.to_s)

      rethash = ClipBoards.put_nodes(opr_id, copy_sid, copy_file_hash_keys, OPERATION_COPY)
      unless rethash[:success]
        return rethash
      end
      put_node_count = rethash[:rsult]

      # acl check!
      # Does it have ACL to do move operation?
      if target_has_right_to_delete != true
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_COPY_FOLDER
        rethash[:errors] = '指定されたフォルダにコピーする権限がありません'
      else
        retb = DatabaseUtility::VirtualFileSystemUtility.copy_virtual_files_in_clipboard opr_id, copy_sid, copy_source_folder_hashkey, copy_target_folder_hashkey, target_cont_location
        if retb
          FolderDatum.has_updated(copy_sid, copy_target_folder_hashkey, NEW_CHILD, true)
          #        SessionManager.set_location_dirty(copy_sid, (source_cont_location == 'folder_a' ? 'file_listA' : 'file_listB'), true)
          #        SessionManager.set_location_dirty(copy_sid, (target_cont_location == 'folder_a' ? 'file_listA' : 'file_listB'), true)
          rethash[:success] = true
          rethash[:status] = INFO_COPY_FOLDER_SUCCESS
        else
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_COPY_FOLDER
          rethash[:errors] = 'コピーに失敗しました'
        end
      end
      #      user_agent = $http_user_agent
      #      copy_file_key = ''
      #      if /HTTP_Request2.+/ =~ user_agent # => PHP API
      #        copy_file_key = paramshash[:hash_key]
      #      else # => from UI
      #        file_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
      #        copy_file_key = file_rec[:spin_node_hashkey]
      #      end
      #      # delete file from list and put it in the recycler
      #      # session_id, cont_location, hash_key, file_writable_status:bool, lock:int, file_name
      #      #      copy_file_name = paramshash[:file_name]
      #      # paramshash.keys.each {|k| printf "%s = %s\n",k,paramshash[k]}
      #      copy_sid = my_session_id
      #      #      copy_contlocation = paramshash[:cont_location]
      #      #      copy_file_key = paramshash[:hash_key]
      ##      copy_file_writable_status = ((paramshash[:file_writable_status] == true or paramshash[:file_writable_status] == 'true') ? true : false)
      #      target_cont_location = paramshash[:target_cont_location]
      #      target_folder_writable_status = ((paramshash[:target_folder_writable_status] == true or paramshash[:target_folder_writable_status] == 'true') ? true : false)
      #      #      target_folder_rec = FileDatum.find_by_session_id_and_hash_key_and_cont_location my_session_id, paramshash[:target_hash_key], target_cont_location
      #      target_folder_rec = FolderDatum.find_by_session_id_and_target_hash_key_and_target_cont_location my_session_id, paramshash[:target_hash_key], target_cont_location
      #      target_hash_key = target_folder_rec[:spin_node_hashkey]
      #      #      target_hash_key = paramshash[:target_hash_key]
      #      #      target_folder_name = paramshash[:text]
      #      if target_folder_writable_status != true # => may not copy to
      #        # this should not be deleted
      #        rethash[:success] = false
      #        rethash[:status] = ERROR_FAILED_TO_COPY_FILE
      #        rethash[:errors] = "Failed to copy file : file is not movable"
      #        return rethash
      #      end
      #      has_right_to_delete = true
      #      target_has_right_to_delete = true
      #      copy_file_hash_keys = Array.new
      #      copy_file_hash_keys.push copy_file_key
      #      #      target_folder_rec = FolderDatum.find_by_session_id_and_cont_location_and_selected copy_sid, target_cont_location, true
      #      copy_target_folder_hashkey = target_hash_key
      #      r = Random.new
      #      opr_id = Security.hash_key_s(copy_sid + target_hash_key + target_cont_location + r.rand.to_s)
      #      put_node_count = ClipBoards.put_nodes(opr_id, copy_sid, copy_file_hash_keys, OPERATION_COPY)
      #      copy_source_folder_hashkey = SpinLocationManager.get_parent_key(copy_file_hash_keys[0])
      #      # acl check!
      #      # Does it have ACL to do copy operation?
      #      if has_right_to_delete != true or target_has_right_to_delete != true
      #        rethash[:success] = false
      #        rethash[:status] = ERROR_FAILED_TO_COPY_FILE
      #      else
      #        retb = DatabaseUtility::VirtualFileSystemUtility.copy_virtual_files_in_clipboard opr_id, copy_sid, copy_source_folder_hashkey, copy_target_folder_hashkey, target_cont_location
      #        if retb
      #          FolderDatum.has_updated(copy_sid, copy_source_folder_hashkey, true)
      #          FolderDatum.has_updated(copy_sid, copy_target_folder_hashkey, true)
      #          #        SessionManager.set_location_dirty(copy_sid, (source_cont_location == 'folder_a' ? 'file_listA' : 'file_listB'), true)
      #          #        SessionManager.set_location_dirty(copy_sid, (target_cont_location == 'folder_a' ? 'file_listA' : 'file_listB'), true)
      #          rethash[:success] = true
      #          rethash[:status] = INFO_COPY_FILE_SUCCESS
      #        else
      #          rethash[:success] = false
      #          rethash[:status] = ERROR_FAILED_TO_COPY_FILE
      #        end
      #      end

    when 'copy_files'
      # delete file from list and put it in the recycler
      # session_id, cont_location, hash_key, file_writable_status:bool, lock:int, file_name
      copy_sid = my_session_id
      #      copy_target_folder_name = paramshash[:target_folder]
      #      copy_target_folder_hashkey = paramshash[:target_hash]
      # get numbered hashes
      list_files = Array.new
      #      files_to_move = Array.new
      hash_params = Hash.new
      paramshash.each {|key, value|
        if /[0-9]+/ =~ key # => number
          list_files.append value
        else # => string
          hash_params[key] = value
        end
      }
      # get file attributes
      target_cont_location = 'folder_b'
      source_cont_location = 'folder_a'
      copy_file_hash_keys = Array.new
      list_files.each {|f|
        f_rec = FileDatum.find_by_hash_key f[:hash_key]
        if f_rec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No file record is found'
          return rethash
        end
        source_cont_location = f[:cont_location]
        copy_file_hash_keys.append(f_rec[:spin_node_hashkey])
      }
      if source_cont_location == 'folder_a'
        target_cont_location = 'folder_b'
      else
        target_cont_location = 'folder_a'
      end
      target_folder_rec = FolderDatum.find_by_session_id_and_cont_location_and_selected copy_sid, target_cont_location, true
      copy_target_folder_hashkey = target_folder_rec[:spin_node_hashkey]
      if target_folder_rec.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No folder record is found at copy_files'
        return rethash
      end
      r = Random.new
      opr_id = Security.hash_key_s(copy_sid + target_folder_rec[:spin_node_hashkey] + target_cont_location + r.rand.to_s)
      rethash = ClipBoards.put_nodes(opr_id, copy_sid, copy_file_hash_keys, OPERATION_COPY)
      unless rethash[:success]
        return rethash
      end
      put_node_count = rethash[:rsult]

      copy_source_folder_hashkey = SpinLocationManager.get_parent_key(copy_file_hash_keys[0])
      # acl check!
      # Does it have ACL to do move operation?
      #      source_acls = SpinAccessControl.has_acl_values copy_sid, copy_source_folder_hashkey, NODE_DIRECTORY
      target_acls = SpinAccessControl.has_acl_values copy_sid, copy_target_folder_hashkey, NODE_DIRECTORY
      has_right_to_delete = false
      target_has_right_to_delete = false
      #      source_acls.values.each {|av|
      #        if av & ACL_NODE_WRITE or av & ACL_NODE_DELETE # => has right to delete
      #          has_right_to_delete = true
      #          break # => break from 'each' iterator
      #        end
      #      }
      target_acls.values.each {|tav|
        if tav & ACL_NODE_WRITE or tav & ACL_NODE_DELETE # => has right to delete
          target_has_right_to_delete = true
          break # => break from 'each' iterator
        end
      }
      if target_has_right_to_delete == false
        rethash[:success] = false
        rethash[:status] = ERROR_COPY_FILE
      else
        retb = DatabaseUtility::VirtualFileSystemUtility.copy_virtual_files_in_clipboard opr_id, copy_sid, copy_source_folder_hashkey, copy_target_folder_hashkey, target_cont_location
        if retb
          FolderDatum.has_updated(copy_sid, copy_source_folder_hashkey, NO_UPDATE_TYPE, true)
          FolderDatum.has_updated(copy_sid, copy_target_folder_hashkey, NEW_CHILD, true)
          #        SessionManager.set_location_dirty(copy_sid, (source_cont_location == vfolder_a' ? 'file_listA' : 'file_listB'), true)
          #        SessionManager.set_location_dirty(copy_sid, (target_cont_location == 'folder_a' ? 'file_listA' : 'file_listB'), true)
          rethash[:success] = true
          rethash[:status] = INFO_COPY_FILE_SUCCESS
        else
          rethash[:success] = false
          rethash[:status] = ERROR_COPY_FILE
        end
      end
    when 'throw_files' #=> empty trash cann
      # remove file from storage
      rethash = {}
      n = paramshash.length # => I need it!
      throw_files = n - 5 # => I hate this kind of logic but client send me fucking json data!
      remove_sid = my_session_id
      parent_key = ''
      #      remove_cont_location = paramshash[:cont_location]
      # extract keys and file names
      remove_file_keys = Array.new
      1.upto(throw_files) {|i|
        #        rmkey = paramshash["#{i-1}"][:hash_key]
        rmf = RecyclerDatum.find_by_hash_key paramshash["#{i-1}"][:hash_key]
        unless rmf.present?
          next
        end
        rmkey = rmf[:spin_node_hashkey]
        if rmkey == nil
          rmkey = paramshash["#{i-1}"][:hash_key]
        end
        remove_file_keys.push(rmkey)
        # remove_file_names << paramshash["#{i-1}"][:file_name]
        #        if i == 1
        #          parent_key = SpinLocationManager.get_parent_key(rmkey)
        #        end
      }
      retc = DatabaseUtility::VirtualFileSystemUtility.throw_virtual_files remove_sid, remove_file_keys
      #      if retb.length == throw_files # => success, 'throw_files' files are remoevd
      if retc >= throw_files # => success, 'throw_files' files are remoevd
        #        remove_source_folder_hashkey = SpinLocationManager.get_parent_key(remove_file_keys[0])
        #        FolderDatum.has_updated(remove_sid, remove_source_folder_hashkey, true)
        #        FolderDatum.has_updated(move_sid, move_target_folder_hashkey, true)
        #        SessionManager.set_location_dirty(remove_sid, (remove_cont_location == 'folder_a' ? 'file_listA' : 'file_listB'), true)
        #        my_cont_location = SessionManager.get_current_location(remove_sid)
        #        domain_key = SessionManager.get_selected_domain(remove_sid, my_cont_location)
        #        unless parent_key.blank?
        #          FolderDatum.select_folder(remove_sid, parent_key, my_cont_location, domain_key)
        #        end
        rethash[:success] = true
        rethash[:status] = INFO_THROW_FILES_SUCCESS
      else
        rethash[:success] = false
        rethash[:status] = ERROR_THROW_FILES
      end
    when 'throw_all_files' #=> empty trash cann
      # remove file from storage
      rethash = {}
      remove_sid = my_session_id
      uid = SessionManager.get_uid remove_sid
      parent_key = ''
      #      remove_cont_location = paramshash[:cont_location]
      # extract keys and file names
      remove_file_keys = Array.new
      throw_files=0
      rmf = RecyclerDatum.where(["spin_uid = ?", uid])
      rmf.each {|r|
        rmkey = r[:spin_node_hashkey]
        if rmkey == nil
          rmkey = r[:hash_key]
        end
        remove_file_keys.push(rmkey)
        throw_files+=1
      }

      retc = DatabaseUtility::VirtualFileSystemUtility.throw_virtual_files remove_sid, remove_file_keys
      #      if retb.length == throw_files # => success, 'throw_files' files are remoevd
      if retc >= throw_files # => success, 'throw_files' files are remoevd
        rethash[:success] = true
        rethash[:status] = INFO_THROW_FILES_SUCCESS
      else
        rethash[:success] = false
        rethash[:status] = ERROR_THROW_FILES
      end
    when 'escape_files' #=> retreive from trash cann
      # remove file from storage
      n = paramshash.length # => I need it!
      retrieve_files = n - 5 # => I hate this kind of logic but client send me fucking json data!
      retrieve_sid = my_session_id
      # extract keys and file names
      retrieve_file_keys = []
      1.upto(retrieve_files) {|i|
        #        retrieve_file_keys << paramshash["#{i-1}"][:hash_key]
        # remove_file_names << paramshash["#{i-1}"][:file_name]
        #        rmkey = paramshash["#{i-1}"][:hash_key]
        rmf = RecyclerDatum.find_by_hash_key paramshash["#{i-1}"][:hash_key]
        if rmf.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No file record is found'
          return rethash
        end
        rmkey = rmf[:spin_node_hashkey]
        retrieve_file_keys.push(rmkey)
      }
      retb = DatabaseUtility::VirtualFileSystemUtility.retrieve_virtual_files retrieve_sid, retrieve_file_keys
      if retb.length >= retrieve_files # => success, 'retrieve_files' files are remoevd
        my_cont_location = SessionManager.get_current_location(my_session_id)
        domain_key = SessionManager.get_selected_domain(my_session_id, my_cont_location)
        FolderDatum.reset_partial_root(my_session_id, my_cont_location, domain_key)
        FolderDatum.fill_folders(my_session_id, my_cont_location, domain_key, nil, PROCESS_FOR_UNIVERSAL_REQUEST, false, 1)
        rethash[:success] = true
        rethash[:status] = INFO_RETREIVE_FILES_SUCCESS
      else
        rethash[:success] = false
        rethash[:status] = ERROR_RETREIVE_FILES
        rethash[:errors] = '元に戻せないファイルがあります'
      end
    when 'change_file_property'
      # set folder privilege
      user_agent = $http_user_agent
      file_hashkey = ''
      #if /HTTP_Request2.+/ =~ user_agent # => PHP API 2015/10/22
      if user_agent == "BoomboxAPI"
        file_hashkey = paramshash[:hash_key]
      else # => from UI
        file_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
        if file_rec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No file record is found'
          return rethash
        end
        file_hashkey = file_rec[:spin_node_hashkey]
      end
      properties = Hash.new
      if paramshash[:file_name].present?
        properties[:file_name] = paramshash[:file_name]
      end
      if paramshash[:description].present?
        properties[:description] = paramshash[:description]
      end
      if paramshash[:keyword].present?
        properties[:keyword] = paramshash[:keyword]
      end
      if paramshash[:title].present?
        properties[:title] = paramshash[:title]
      end
      if paramshash[:subtitle].present?
        properties[:subtitle] = paramshash[:subtitle]
      end
      # get numbered hashes
      #      list_files = Array.new
      #      hash_params = Hash.new
      #      paramshash.each { |key,value|
      #        if /[0-9]+/ =~ key # => number
      #          list_files.append value
      #        else # => string
      #          hash_params[key] = value
      #        end
      #      }
      retb = DatabaseUtility::VirtualFileSystemUtility.change_virtual_file_properties my_session_id, file_hashkey, properties
      if retb == false
        rethash[:success] = false
        rethash[:errors] = "Failed to change file name"
      else
        rethash[:status] = "File name has changed"
      end
    when 'change_file_extension'
      # set folder privilege
      user_agent = $http_user_agent
      file_hashkey = ''
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        file_hashkey = paramshash[:hash_key]
      else # => from UI
        file_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
        if file_rec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No file record is found'
          return rethash
        end
        file_hashkey = file_rec[:spin_node_hashkey]
      end
      properties = Hash.new
      #      properties[:file_name] = paramshash[:file_name]
      #      properties[:description] = paramshash[:description]
      #      properties[:keyword] = paramshash[:keyword]
      #      properties[:title] = paramshash[:title]
      #      properties[:subtitle] = paramshash[:subtitle]
      # get numbered hashes
      list_files = Array.new
      hash_params = Hash.new
      paramshash.each {|key, value|
        if /[0-9]+/ =~ key # => number
          list_files.append value
        else # => string
          properties[key] = value
        end
      }
      retb = DatabaseUtility::VirtualFileSystemUtility.change_virtual_file_extension my_session_id, file_hashkey, properties
      if retb == false
        rethash[:success] = false
        rethash[:status] = "Failed to change file name"
      else
        rethash[:status] = "File name has changed"
      end
    when 'change_file_details'
      # set folder privilege
      user_agent = $http_user_agent
      file_hashkey = ''
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        file_hashkey = paramshash[:hash_key]
      else # => from UI
        file_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
        if file_rec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No file record is found'
          return rethash
        end
        file_hashkey = file_rec[:spin_node_hashkey]
      end
      properties = Hash.new
      properties[:details] = paramshash[:details]
      retb = DatabaseUtility::VirtualFileSystemUtility.change_virtual_file_details my_session_id, file_hashkey, properties
      if retb == false
        rethash[:success] = false
        rethash[:status] = "Failed to change file name"
      else
        rethash[:status] = "File name has changed"

        properties = Hash.new
        properties[:file_name] = paramshash[:file_name]
        properties[:description] = paramshash[:description]
        properties[:keyword] = paramshash[:keyword]
        properties[:title] = paramshash[:title]
        properties[:subtitle] = paramshash[:subtitle]
        retp = DatabaseUtility::VirtualFileSystemUtility.change_virtual_file_properties my_session_id, file_hashkey, properties
        if retp == false
          rethash[:success] = false
          rethash[:status] = "Failed to change file name"
        end
      end
    when 'change_folder_name'
      folder_key = ''
      target_key = ''
      folder_name = ''
      folder_rec = {}
      user_agent = $http_user_agent
      in_list = false
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        folder_key = paramshash[:hash_key]
      else # => from UI
        folder_rec = FolderDatum.find_by_hash_key paramshash[:hash_key]
        if folder_rec.blank?
          folder_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
          if folder_rec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'No folder record is found at change_folder_name'
            return rethash
          end
          folder_name = folder_rec[:file_name]
          in_list = true
        else
          folder_name = folder_rec[:text]
        end
        folder_key = folder_rec[:spin_node_hashkey]
      end
      rethash[:success] = true
      retb = DatabaseUtility::VirtualFileSystemUtility.change_virtual_file_name my_session_id, paramshash[:cont_location], folder_key, paramshash[:text]
      if retb == false
        rethash[:success] = false
        rethash[:status] = "Failed to change folder name"
      else
        #        folder_hashkey = folder_key
        if in_list
          target_key = SpinLocationManager.get_parent_key(folder_key, NODE_DIRECTORY)
        else
          target_key = folder_key
        end
        domain_key = SessionManager.get_selected_domain(my_session_id, paramshash[:cont_location])
        #        DomainDatum.set_domain_dirty(my_session_id, paramshash[:cont_location])
        #        FolderDatum.remove_folder_rec(my_session_id, paramshash[:cont_location], folder_key)
        #        FolderDatum.load_folder_recs(my_session_id, parent_key, domain_key, paramshash[:cont_location])
        FolderDatum.reset_partial_root(my_session_id, paramshash[:cont_location], domain_key)
        FolderDatum.fill_folders(my_session_id, paramshash[:cont_location])
        FolderDatum.select_folder my_session_id, target_key, paramshash[:cont_location]
        #        FolderDatum.reset_partial_root(my_session_id,paramshash[:cont_location], domain_key)
        #        FolderDatum.set_partial_root(my_session_id,paramshash[:cont_location], parent_key, domain_key)
        copy_locations = CONT_LOCATIONS_LIST - [paramshash[:cont_location]]
        copy_locations.each {|copy_location|
          FolderDatum.copy_folder_data_from_location_to_location(my_session_id, paramshash[:cont_location], copy_location)
        }
        rethash[:status] = "File name has changed"
      end
    when 'change_domain_name'
      domain_key = ''
      user_agent = $http_user_agent
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        domain_key = paramshash[:hash_key]
      else # => from UI
        domain_data_rec = DomainDatum.find_by_hash_key paramshash[:hash_key]
        if domain_data_rec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No domain_data_rec record is found'
          return rethash
        end
        domain_key = domain_data_rec[:spin_domain_hash_key]
      end
      rethash[:success] = true
      rethash[:success] = true
      new_domain_name = paramshash[:domain_name]
      retb = DatabaseUtility::VirtualFileSystemUtility.change_virtual_domain_name my_session_id, domain_key, new_domain_name
      if retb == false
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_CHANGE_DOMAIN_NAME
        rethash[:errors] = "Failed to change domain name"
      else
        DomainDatum.has_updated(my_session_id, domain_key)
        rethash[:success] = true
        rethash[:status] = INFO_CHANGE_DOMAIN_NAME_SUCCESS
        rethash[:result] = "Domain name has changed to " + new_domain_name
      end
    when 'change_file_name'
      rethash[:success] = true
      file_attributes = Hash.new
      file_attributes[:file_name] = paramshash[:file_name]
      file_attributes[:cont_location] = paramshash[:cont_location]
      file_attributes[:title] = paramshash[:title]
      file_attributes[:subtitle] = paramshash[:subtitle]
      file_attributes[:keyword] = paramshash[:keyword]
      file_attributes[:description] = paramshash[:description]
      file_attributes[:file_type] = paramshash[:file_type]
      file_attributes[:file_version] = paramshash[:file_version]
      file_attributes[:created_date] = paramshash[:created_date]
      file_attributes[:creator] = paramshash[:creator]
      file_attributes[:modified_date] = paramshash[:modified_date]
      file_attributes[:modifier] = paramshash[:modifier]
      file_attributes[:owner] = paramshash[:owner]
      file_attributes[:ownership] = paramshash[:ownership]
      file_attributes[:file_readable_status] = paramshash[:file_readable_status]
      file_attributes[:file_writable_status] = paramshash[:file_writable_status]
      file_attributes[:url] = paramshash[:url]

      retb = DatabaseUtility::VirtualFileSystemUtility.change_virtual_file_properties my_session_id, paramshash[:hash_key], file_attributes
      if retb == false
        rethash[:success] = false
        rethash[:status] = "Failed to change file name"
      else
        rethash[:status] = "File name has changed"
      end
    when 'unlock_file'
      frec = FileDatum.find_by_hash_key_and_session_id paramshash[:hash_key], my_session_id
      if frec.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No file record is found'
        return rethash
      end
      lock_ret = SpinNode.clear_lock frec[:spin_node_hashkey]
      if !lock_ret
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UNLOCK_FILE
        rethash[:errors] = "Failed to set lock of " + paramshash[:hash_key]
      else
        rethash[:status] = INFO_UNLOCK_FILE_SUCCESS
        rethash[:success] = true
      end
    when 'lock_file'
      lock_file_hash_key = paramshash[:hash_key]
      frec = FileDatum.find_by_session_id_and_hash_key_and_cont_location my_session_id, lock_file_hash_key, 'folder_a'
      if frec.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No file record is found'
        return rethash
      end
      lock_node_hash_key = frec[:spin_node_hashkey]
      spin_node_upd = Hash.new
      spin_node_upd[:upd_lock_status] = FSTAT_LOCKED
      spin_node_upd[:upd_lock_mode] = FSTAT_WRITE_LOCKED
      lock_ret = SpinNode.set_lock2 my_session_id, lock_node_hash_key, spin_node_upd
      if !lock_ret
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_LOCK_FILE
        rethash[:errors] = "Failed to set lock of " + lock_node_hash_key
      else
        rethash[:status] = INFO_LOCK_FILE_SUCCESS
        rethash[:success] = true
      end
    when 'delete_file'
      # delete file from list and put it in the recycler
      # session_id, cont_location, hash_key, file_writable_status:bool, lock:int, file_name
      #      delete_file_name = paramshash[:fileg_name]
      # paramshash.keys.each {|k| printf "%s = %s\n",k,paramshash[k]}
      delete_sid = my_session_id
      #      delete_contlocation = paramshash[:cont_location]
      delete_file_key = paramshash[:hash_key]
      user_agent = $http_user_agent
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        delete_file_key = paramshash[:hash_key]
      else # => from UI
        file_data_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
        if file_data_rec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FILE_IS_NOT_IN_LIST_DATA
          rethash[:errors] = "指定されたファイルが見つかりません"
          return rethash
        else
          delete_file_key = file_data_rec[:spin_node_hashkey]
        end
      end
      if paramshash[:file_writable_status] == false or paramshash[:file_writable_status] == "false" or SpinAccessControl.is_deletable(my_session_id, delete_file_key) != true # not writable or login dir# => not writable
        # this should not be deleted
        rethash[:success] = false
        rethash[:status] = ERROR_NOT_WRITABLE
        rethash[:errors] = "指定されたファイルは移動できません"
        return rethash
      end
      parent_key = SpinLocationManager.get_parent_key(delete_file_key)
      #      # => get versions
      #      delete_file_loc = SpinLocationManager.key_to_location(delete_file_key, ANY_TYPE)
      #      delete_files = SpinNode.where :node_x_coord => delete_file_loc[X],:node_y_coord => delete_file_loc[Y]
      #      #      delete_file_keys = []
      #      delete_files.each {|delf|
      Rails.logger.warn(">> delete_file : call delete_virtual_file")
      rethash = DatabaseUtility::VirtualFileSystemUtility.delete_virtual_file delete_sid, delete_file_key, true, true # => the last argument is trash_it flag
      #        delete_file_keys.push delf[:spin_node_hashkey]
      #      }
      if rethash[:success]
        #        folder_key = SpinLocationManager.get_parent_key(delete_file_key)
        domain_key = SessionManager.get_selected_domain(my_session_id, paramshash[:cont_location])
        FolderDatum.select_folder(my_session_id, parent_key, paramshash[:cont_location], domain_key)
        FolderDatum.has_updated(delete_sid, parent_key, DISMISS_CHILD, true)
        if (DELETE_NOTIFICATION & SpinNotifyControl.has_notification(delete_sid, parent_key, NODE_DIRECTORY)) != 0
          trashed_vps = SpinLocationManager.get_key_vpath(delete_sid, parent_key, NODE_DIRECTORY)
          SpinNotifyControl.notify_delete(delete_sid, trashed_vps)
        end
        #        SessionManager.set_location_dirty(delete_sid, delete_contlocation, true)1111
        #        rethash[:success] = true
        rethash[:status] = INFO_TRASH_FILE_SUCCESS
      else
        #        rethash[:success] = false
        #        rethash[:status] = ERROR_TRASH_FILE
      end
    when 'notify_delete'
      delete_sid = my_session_id
      notify_node_vpath = paramshash[:virtual_path]
      SpinNotifyControl.notify_delete(delete_sid, notify_node_vpath)
      rethash[:success] = true
      rethash[:status] = INFO_BASE
    when 'notify_new'
      domain_key = SessionManager.get_selected_domain(my_session_id, 'folder_a')
      frec = FileDatum.find_by_hash_key_and_session_id paramshash[:hash_key], my_session_id
      if frec.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No file record is found'
        return rethash
      end
      ssid = my_session_id
      notify_node = frec[:spin_node_hashkey]
      notify_url = frec[:url]
      #                    if new_file_list_datum[:file_version] > 1
      SpinNotifyControl.notify_modification(ssid, current_folder_key, notify_node, notufy_url, domain_hash_key)
      rethash[:success] = true
      rethash[:status] = INFO_BASE
    when 'notify_modification'
      domain_key = SessionManager.get_selected_domain(my_session_id, 'folder_a')
      frec = FileDatum.find_by_hash_key_and_session_id paramshash[:hash_key], my_session_id
      if frec.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No file record is found'
        return rethash
      end
      ssid = my_session_id
      notify_node = frec[:spin_node_hashkey]
      notify_url = frec[:url]
      SpinNotifyControl.notify_modification(ssid, current_folder_key, fn[:spin_node_hashkey], new_file_list_datum[:url], domain_hash_key)
      rethash[:success] = true
      rethash[:status] = INFO_BASE
    when 'delete_folder'
      # delete file from list and put it in the recycler
      # session_id, cont_location, hash_key, file_writable_status:bool, lock:int, file_name
      #      delete_file_name = paramshash[:file_name]
      # paramshash.keys.each {|k| printf "%s = %s\n",k,paramshash[k]}
      delete_sid = my_session_id
      #      delete_contlocation = paramshash[:cont_location]
      delete_file_key = paramshash[:hash_key]
      folder_data_rec = {}
      rethash[:deleted_node_type] = NODE_DIRECTORY
      user_agent = $http_user_agent
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        delete_file_key = paramshash[:hash_key]
      else # => from UI
        target_folder_key = nil
        current_folder_key = SpinSession.select(:spin_current_directory).find_by_spin_session_id(my_session_id)
        if current_folder_key.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No current_folder_key record is found'
          return rethash
        end
        if paramshash[:original_place] == 'folder_tree'
          folder_data_rec = FolderDatum.find_by_hash_key paramshash[:hash_key]
          if folder_data_rec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'No folder_data_rec record is found'
            return rethash
          end
          if folder_data_rec == nil
            folder_data_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
            if folder_data_rec.blank?
              rethash[:success] = false
              rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
              rethash[:errors] = 'No folder_data_rec record is found'
              return rethash
            end
          end
          rethash[:deleted_node_type] = NODE_DIRECTORY
          #          target_folder_key = FolderDatum.get_parent_folder my_session_id current_folder_key
        else # => from file list
          folder_data_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
          if folder_data_rec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'No folder_data_rec record is found'
            return rethash
          end
          rethash[:deleted_node_type] = (folder_data_rec[:file_type] == 'folder' ? NODE_DIRECTORY : NODE_FILE)
          #          target_folder_key = current_folder_key
        end
        target_folder_key = FolderDatum.get_parent_folder my_session_id, current_folder_key

        if folder_data_rec == nil
          rethash[:success] = false
          rethash[:status] = ERROR_INVALID_HASH_KEY
          #          rethash[:errors] = "Failed to delete file : hash key is invalid"
          rethash[:errors] = "指定されたフォルダが見つかりません"
          return rethash
        end
        delete_file_key = folder_data_rec[:spin_node_hashkey]
      end
      if paramshash[:folder_writable_status] == false or paramshash[:folder_writable_status] == "false" or SpinAccessControl.is_deletable(my_session_id, delete_file_key) != true # not writable or login dir
        # this should not be deleted
        rethash[:success] = false
        rethash[:status] = ERROR_NOT_WRITABLE
        rethash[:errors] = "このフォルダは削除できません"
        return rethash
      end
      folder_key = SpinLocationManager.get_parent_key(delete_file_key)
      Rails.logger.warn(">> delete_folder : call delete_virtual_file")
      rethash = DatabaseUtility::VirtualFileSystemUtility.delete_virtual_file delete_sid, delete_file_key, true, true # => the last 2 arguments are trash_it flag and is_thrown
      if rethash[:success]
        rethash[:status] = (INFO_TRASH_FILE_SUCCESS | INFO_RENDERING_DONE)
        domain_key = SessionManager.get_selected_domain(my_session_id, paramshash[:cont_location])
        FolderDatum.reset_partial_root(my_session_id, paramshash[:cont_location], domain_key)
        FolderDatum.fill_folders(my_session_id, paramshash[:cont_location], domain_key)
        FolderDatum.has_updated(my_session_id, target_folder_key, DISMISS_CHILD, true)
        FolderDatum.set_partial_root(my_session_id, paramshash[:cont_location], target_folder_key)
        FolderDatum.select_folder(my_session_id, folder_key, paramshash[:cont_location], domain_key)
        if (DELETE_NOTIFICATION & SpinNotifyControl.has_notification(delete_sid, folder_key, NODE_DIRECTORY)) != 0
          trashed_vps = SpinLocationManager.get_key_vpath(delete_sid, folder_key, NODE_DIRECTORY)
          SpinNotifyControl.notify_delete(delete_sid, trashed_vps, folder_key)
        end
      else
        rethash[:status] = INFO_RENDERING_DONE
      end
    when 'secret_files_delete_node', 'delete_node'
      # delete file from list and put it in the recycler
      # session_id, cont_location, hash_key, file_writable_status:bool, lock:int, file_name
      #      delete_file_name = paramshash[:file_name]
      # paramshash.keys.each {|k| printf "%s = %s\n",k,paramshash[k]}
      delete_sid = my_session_id
      #      delete_contlocation = paramshash[:cont_location]
      delete_file_key = paramshash[:hash_key]
      folder_data_rec = {}
      user_agent = $http_user_agent
      #if /HTTP_Request2.+/ =~ user_agent # => PHP API
      if user_agent == "BoomboxAPI"
        delete_file_key = paramshash[:hash_key]
      else # => from UI
        #if paramshash[:original_place] == 'folder_tree'
        #  folder_data_rec = FolderDatum.find_by_hash_key paramshash[:hash_key]
        #  if folder_data_rec == nil
        #    folder_data_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
        #  end
        #else
        #  folder_data_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
        #end
        #if folder_data_rec == nil
        #  rethash[:success] = false
        #  rethash[:status] = ERROR_INVALID_HASH_KEY
        #  #          rethash[:errors] = "Failed to delete file : hash key is invalid"
        #  rethash[:errors] = "指定されたフォルダが見つかりません"
        #  return rethash
        #end
        #delete_file_key = folder_data_rec[:spin_node_hashkey]
      end
      if paramshash[:folder_writable_status] == false or paramshash[:folder_writable_status] == "false" or SpinAccessControl.is_deletable(my_session_id, delete_file_key) != true # not writable or login dir
        # this should not be deleted
        rethash[:success] = false
        rethash[:status] = ERROR_NOT_WRITABLE
        rethash[:errors] = "このノードは権限がないため削除できません"
        return rethash
      end
      is_domains = SpinDomain.secret_files_is_domain(my_session_id, delete_file_key)
      count = is_domains[:domains].count
      if (count > 0)
        rethash[:success] = false
        rethash[:status] = ERROR_NOT_WRITABLE
        rethash[:errors] = "このノードはドメインがあるため削除できません"
        return rethash
      end
      folder_key = SpinLocationManager.get_parent_key(delete_file_key)
      Rails.logger.warn(">> delete_folder : call delette_virtual_file")
      rethash = DatabaseUtility::VirtualFileSystemUtility.delete_virtual_file delete_sid, delete_file_key, false, false # => the last 2 arguments are trash_it flag and is_thrown
      if rethash[:success]
        rethash[:status] = (INFO_TRASH_FILE_SUCCESS | INFO_RENDERING_DONE)
        domain_key = SessionManager.get_selected_domain(my_session_id, paramshash[:cont_location])
        #以下の３行はBOOMBOXAPIでは不要 2015/11/6
        #FolderDatum.reset_partial_root(my_session_id, paramshash[:cont_location], domain_key)
        #FolderDatum.fill_folders(my_session_id, paramshash[:cont_location], domain_key)
        #FolderDatum.select_folder(my_session_id, folder_key, paramshash[:cont_location], domain_key)
        if (DELETE_NOTIFICATION & SpinNotifyControl.has_notification(delete_sid, folder_key, NODE_DIRECTORY)) != 0
          trashed_vps = SpinLocationManager.get_key_vpath(delete_sid, folder_key, NODE_DIRECTORY)
          SpinNotifyControl.notify_delete(delete_sid, trashed_vps, folder_key)
        end
      else
        rethash[:status] = INFO_RENDERING_DONE
      end

    when 'secret_files_add_domain_list'
      ret = SpinDomain.secret_files_add_domain(my_session_id, paramshash[:hash_key])
      if ret[:success] == true
        rethash[:success] = true
        rethash[:status] = INFO_BOOMBOX_API_ADD_DOMAIN_LIST_SUCCESS
        rethash[:result] = {}
        rethash[:result] = ret
      else
        rethash[:success] = false
        rethash[:errors] = "add_domain_list: " + ret[:errors]
      end

    when 'secret_files_delete_domain_list'
      ret = SpinDomain.secret_files_delete_domain(my_session_id, paramshash[:hash_key])
      if ret.present?
        if ret[:success] == true
          rethash[:success] = true
          rethash[:status] = INFO_BOOMBOX_API_DELETE_DOMAIN_LIST_SUCCESS
          rethash[:count] = ret[:count]
        else
          rethash = ret
          rethash[:success] = false
          rethash[:status] = ERROR_BOOMBOX_API_DELETE_DOMAIN_LIST_FAILED
        end
      else
        rethash[:success] = false
        rethash[:status] = ERROR_BOOMBOX_API_DELETE_DOMAIN_LIST_FAILED
        rethash[:errors] = 'サーバの戻り値がNULLです。エイリアスの削除に失敗しました。'
      end


    when 'get_domain_list'

      #  def self.fill_domain_data_table ssid, my_uid, location, mtime
      # get my group id
      #  if ssid == ADMIN_SESSION_ID
      #    rethash[:uid] = ACL_SUPERUSER_UID
      #    rethash[:gid] = ACL_SUPERUSER_GID
      #    rethash[:gids] = [ ACL_SUPERUSER_UID ]
      #    return rethash
      #  end
      rethash = {}
      #ssrec = SpinSession.readonly.select("spin_uid").find(:first, :conditions=>["spin_session_id = ?", my_session_id])
      ssrec = SpinSession.readonly.find_by_sql(['select spin_uid from spin_sessions where spin_session_id = ?', my_session_id])
      if ssrec.blank?
        rethash[:status] = false;
        rethash[:status] = ERROR_BOOMBOX_API_GET_DOMAIN_LIST_GET_SESSION;
        rethash[:errors] = "セッションからUIDが判別できないです。";
        return rethash;
      end

      my_uid = ssrec[0][:spin_uid]
      #    my_gid = ssrec[:spin_gid]
      # spin_user_obj = SpinUser.readonly.select("spin_gid").find(["spin_uid = ?", my_uid])
      spin_user_obj = SpinUser.readonly.find_by_sql(['select spin_gid from spin_users where spin_uid = ?', my_uid])
      if spin_user_obj == nil
        rethash[:status] = false;
        rethash[:status] = ERROR_BOOMBOX_API_GET_DOMAIN_LIST_GET_DOMAINS;
        rethash[:errors] = "ユーザ情報からグループが判別できないです。";
        return rethash;
      end
      my_gid = spin_user_obj[0][:spin_gid] # => primary gruop id

      #if primary_group_id_only
      #  rethash[:uid] = my_uid
      #  rethash[:gid] = my_gid
      #  return rethash
      #end
      #pgids = SpinGroupMember.get_parent_gids(my_gid)

      my_gids = SpinGroupMember.get_user_groups my_uid
      if my_gid == nil
        rethash[:status] = false;
        rethash[:status] = ERROR_BOOMBOX_API_GET_DOMAIN_LIST_GET_GROUPMEMBER;
        rethash[:errors] = "グループメンバー情報からユーザのグループが判別できないです。";
        return rethash;
      end


      c_domains = SpinDomain.search_accessible_domains my_session_id, my_gids
      unless c_domains.length > 0
        rethash[:status] = false;
        rethash[:status] = ERROR_BOOMBOX_API_GET_DOMAIN_LIST_GET_DOMAINS;
        rethash[:errors] = "このユーザにドメインが有りません";
        return rethash;
      else
        rethash[:success] = true;
        rethash[:status] = INFO_BOOMBOX_API_GET_DOMAIN_LIST_SUCCESS;
        #count = 0
        rethash[:list] = {}
        c_domains.each_with_index {|d_list, index|
          rethash[:list][index] = {}
          rethash[:list][index][:spin_domain_name] = d_list[:spin_domain_name]
          rethash[:list][index][:spin_did] = d_list[:spin_did]
          rethash[:list][index][:spin_domain_disp_name] = d_list[:spin_domain_disp_name]
          rethash[:list][index][:hash_key] = d_list[:hash_key]
          rethash[:list][index][:spin_domain_root] = d_list[:spin_domain_root]
          rethash[:list][index][:domain_root_node_hashkey] = d_list[:domain_root_node_hashkey]
          #count = count + 1
        }

      end
    when 'secret_files_get_file_digest'

      node_hashkey = paramshash[:hash_key]
      location = SpinLocationMapping.get_mapping_data(node_hashkey)
      if location.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_BOOMBOX_API_GET_MAPPING_DATA_SLM_COUNT
        rethash[:errors] = "SPIN_LOCAION_MAPPINGの戻り値が空です。"
        return rethash
      end
      if location == ERROR_BOOMBOX_API_GET_MAPPING_DATA_SLM_COUNT
        rethash[:success] = false
        rethash[:status] = ERROR_BOOMBOX_API_GET_MAPPING_DATA_SLM_COUNT
        rethash[:errors] = "SPIN_LOCAION_MAPPINGに同じハッシュ値が複数ある可能性があります。"
      end
      if File.exist?(location) == false
        rethash[:success] = false
        rethash[:status] = ERROR_BOOMBOX_API_GET_MAPPING_DATA_SLM_COUNT
        rethash[:errors] = location + "が削除されている可能性があります。 "
        return rethash
      end
      startime = Time.now
      sha256 = Digest::SHA256.file(location).to_s
      realtime = Time.now - startime
      filesize = File.size(location)

      rethash[:success] = true
      rethash[:status] = INFO_BOOMBOX_API_GET_MAPPING_DATA_SLM_COUNT
      rethash[:result] = {}
      rethash[:result][:location] = location
      rethash[:result][:size] = filesize
      rethash[:result][:digest] = sha256
      rethash[:result][:digestime] = realtime

    when 'get_recycler_data'
      #recycler_data = {}
      spin_uid = SessionManager.get_uid my_session_id
      offset = DEFAULT_OFFSET
      limit = DEFAULT_PAGE_SIZE
      n_files = []
      n_files = RecyclerDatum.limit(limit).offset(offset).where(["spin_uid = ? AND latest = true AND is_thrown = true", spin_uid])
      total = n_files.count
      rethash = {}
      if total < 0
        rethash[:success] = false
        rethash[:status] = -1
        rethash[:error] = "error....."
        return rethash
      end
      rethash[:success] = true
      rethash[:status] = INFO_BOOMBOX_API_IHAB_LS_SUCCESS
      rethash[:list] = {}
      n = 0;
      files_list = []
      n_files.each {|f|
        files_list.push(f)
      }
      files_list.each {|fl|
        rethash[:list][n] = {}
        rethash[:list][n][:node_name] = fl[:file_name]
        rethash[:list][n][:hash_key] = fl[:spin_node_hashkey]
        rethash[:list][n][:virtual_path] = fl[:virtual_path]
        rethash[:list][n][:node_type] = fl[:file_type]
        n = n + 1
      }

      #return rtn

    when 'secret_files_ls'
      # delete file from list and put it in the recycler
      # session_id, cont_location, hash_key, file_writable_status:bool, lock:int, file_name
      #      delete_file_name = paramshash[:file_name]
      # paramshash.keys.each {|k| printf "%s = %s\n",k,paramshash[k]}
      # sid = my_session_id
      #      delete_contlocation = paramshash[:cont_location]
      ls_node_key = paramshash[:hash_key]
      folder_data_rec = {}
      user_agent = $http_user_agent
      # folder_hashkey = paramshash[:hash_key]
      #if SpinAccessControl.is_readable(my_session_id, ls_node_key) != true # not writable or login dir
      # this should not be deleted
      #  rethash[:success] = false
      #  rethash[:status] = ERROR_NOT_WRITABLE
      #  rethash[:errors] = "このフォルダは表示できません"
      #  return rethash
      #end

      if SpinAccessControl.is_write_only(my_session_id, ls_node_key) == true # not writable or login dir
        rethash[:success] = false
        rethash[:status] = ERROR_NOT_READTABLE
        rethash[:errors] = "There are no reading right."
        return rethash
      end

      #loc = SpinLocationManager.key_to_location(ls_node_key)
      #ns = SpinNode.readonly.where("spin_node_hashkey = ? and in_trash_flag = ? and is_pending = ? and is_void = ?",ls_node_key,false,false,false)
      #ns = SpinNode.readonly.where(:spin_node_hashkey => ls_node_key ,:in_trash_flag => false ,:is_pending => false, :is_void => false)
      ns = SpinNode.readonly.find_by_sql(['select * from spin_nodes where spin_node_hashkey = ? and in_trash_flag = false and is_pending = false and is_void = false', ls_node_key])
      #loc_x = ns[0][:node_x_coord]
      #loc_y = ns[0][:node_y_coord]
      #trash_flag = ns[0][:in_trash_flag]
      #pending_flag = ns[0][:is_pending]
      #void_flag = ns[0][:is_void]
      #node_type = ns[0][:node_type]
      # folder_key = SpinLocationManager.get_parent_key(delete_file_key)
      #Rails.logger.warn(">> secret_files_ls : call secret_files_ls")
      rethash = {}
      node_type = -1
      #rethash = Hash.new { |h,k| h[k] = Hash.new(&h.default_proc) }
      if ns.size == 0
        rethash[:success] = false
        rethash[:status] = ERROR_BOOMBOX_API_IHAB_LS_LIST_NOT_FOUND
        rethash[:errors] = "META information couldnot be acquired from a node hash."
        node_type = 0
      else
        rethash[:success] = true
        rethash[:status] = INFO_BOOMBOX_API_IHAB_LS_SUCCESS
        #domain_key = SessionManager.get_selected_domain(my_session_id, paramshash[:cont_location])
        #node_loc_x = ns[0][:node_x_coord]
        #rethash[:loc_y] = ns[0][:node_y_coord]
        #rethash[:in_trash_flag] = ns[0][:in_trash_flag]
        #rethash[:pending_flag] = ns[0][:is_pending]
        #rethash[:void_flag] = ns[0][:is_void]
        node_type = ns[0][:node_type]
      end
      if node_type == 2
        if SpinAccessControl.is_readable(my_session_id, ls_node_key) == true
          rethash[:list] = {}
          rethash[:list][0] = {}
          rethash[:list][0][:node_name] = ns[0][:node_name]
          rethash[:list][0][:node_type] = ns[0][:node_type]
          rethash[:list][0][:node_size] = ns[0][:node_size]
          rethash[:list][0][:node_description] = ns[0][:node_description]
          rethash[:list][0][:created_by] = ns[0][:created_by]
          #DB上のcreated_atはテーブルに追加された時刻です。アップロード時に参照した作成時刻はctimeになる。
          created_at = ns[0][:ctime]
          rethash[:list][0][:created_at] = created_at.to_i
          rethash[:list][0][:updated_by] = ns[0][:updated_by]
          #DB上のupdated_atはテーブルに追加された時刻です。アップロード時に参照した作成時刻はmtimeになる。
          updated_at = ns[0][:mtime]
          rethash[:list][0][:updated_at] = updated_at.to_i
          rethash[:list][0][:virtual_path] = ns[0][:virtual_path]
          rethash[:list][0][:hashkey] = ns[0][:spin_node_hashkey]
          rethash[:list][0][:readable_status] = true
          if SpinAccessControl.is_writable(my_session_id, rethash[:list][0][:hashkey]) == true
            rethash[:list][0][:writable_status] = true
          else
            rethash[:list][0][:writable_status] = false
          end
          file_type_icons = $file_type_icons
          ftype = ns[0][:node_name].split('.')[-1]
          file_type_icons.each {|key, value|
            next if ftype.blank?
            if /#{ftype}/i =~ key
              rethash[:list][0][:icon_image] = value
              break
            end
          }
        end
      elsif node_type == 1
        rethash[:list] = {}
        node_loc_x_pr = ns[0][:node_x_coord]
        node_loc_y = ns[0][:node_y_coord] + 1
        node_list = SpinNode.readonly.where(["node_x_pr_coord = ? AND node_y_coord = ? AND in_trash_flag = false AND is_pending = false AND is_void = false AND latest = true", node_loc_x_pr, node_loc_y])
        node_list = SpinNode.readonly.find_by_sql(['select * from spin_nodes where node_x_pr_coord = ? and node_y_coord = ? and in_trash_flag = false and is_pending = false and is_void = false and latest = true', node_loc_x_pr, node_loc_y])
        node_list_count = node_list.length
        count = 0
        if node_list_count > 0
          file_type_icons = $file_type_icons
          node_list.each_with_index {|nlk, index|
            node_list_node_type = nlk[:node_type]
            next if node_list_node_type == 8
            node_list_hashkey = nlk[:spin_node_hashkey]
            if SpinAccessControl.is_readable(my_session_id, node_list_hashkey) == true
              rethash[:list][count] = {}
              rethash[:list][count][:node_name] = nlk[:node_name]
              rethash[:list][count][:node_type] = nlk[:node_type]
              rethash[:list][count][:node_size] = nlk[:node_size]
              rethash[:list][count][:node_description] = nlk[:node_description]
              rethash[:list][count][:created_by] = nlk[:created_by]
              #DB上のcreated_atはテーブルに追加された時刻です。アップロード時に参照した作成時刻はctimeになる。
              created_at = nlk[:ctime]
              rethash[:list][count][:created_at] = created_at.to_i
              rethash[:list][count][:updated_by] = nlk[:updated_by]
              #DB上のupdated_atはテーブルに追加された時刻です。アップロード時に参照した作成時刻はmtimeになる。
              updated_at = nlk[:mtime]
              rethash[:list][count][:updated_at] = updated_at.to_i
              rethash[:list][count][:virtual_path] = nlk[:virtual_path]
              rethash[:list][count][:hashkey] = nlk[:spin_node_hashkey]
              rethash[:list][count][:node_version] = nlk[:node_version]
              if SpinAccessControl.is_writable(my_session_id, rethash[:list][count][:hashkey]) == true
                rethash[:list][count][:writable_status] = true
              else
                rethash[:list][count][:writable_status] = false
              end
              rethash[:list][count][:readable_status] = true
              #if SpinAccessControl.is_readable(my_session_id, rethash[:list][count][:hashkey]) == true
              #  rethash[:list][count][:readable_status] = true
              #else
              #  rethash[:list][count][:readable_status] = false
              #end
              rethash[:list][count][:icon_image] = "file_type_icon/unknown.png"
              if nlk[:node_type] == 1
                rethash[:list][count][:icon_image] = "file_type_icon/FolderDocument.png"
              elsif nlk[:node_type] == 2
                ftype = nlk[:node_name].split('.')[-1]
                file_type_icons.each {|key, value|
                  next if ftype.blank?
                  if /#{ftype}/i =~ key
                    rethash[:list][count][:icon_image] = value
                    break
                  end
                }
                #フォルダ、ファイル以外のnode_typeが出てきたら以下のコードを使う。
                #if rethash[:list][count][:icon_image].blank?
                #  rethash[:list][count][:icon_image] = "file_type_icon/unknown.png"
                #end
                #フォルダ、ファイル以外のnode_typeが出てきたら使う。
                #
                #
              end
              count = count + 1
            end
          }
        end
      else
        rethash[:success] = false
        rethash[:status] = ERROR_BOOMBOX_API_IHAB_LS_LIST_NOT_FOUND
        rethash[:errors] = "META information couldnot be acquired from a node hash."
      end

    when 'thread_delete_folder'
      Rails.logger.warn(">>thread_delete_folder : start")
      # delete file from list and put it in the recycler
      # session_id, cont_location, hash_key, file_writable_status:bool, lock:int, file_name
      #      delete_file_name = paramshash[:file_name]
      # paramshash.keys.each {|k| printf "%s = %s\n",k,paramshash[k]}
      delete_sid = my_session_id
      delete_uid = SessionManager.get_uid(delete_sid, true)
      #      delete_contlocation = paramshash[:cont_location]
      delete_file_key = paramshash[:hash_key]
      rethash[:deleted_node_type] = NODE_DIRECTORY
      folder_data_rec = {}
      user_agent = $http_user_agent
      parent_hash_key = ''
      node_name = ''
      #if /HTTP_Request2.+/ =~ user_agent # => PHP API
      if user_agent == "BoomboxAPI"
        delete_file_key = paramshash[:hash_key]
      else # => from UI
        target_folder_key = nil
        current_folder_key = SpinSession.select(:spin_current_directory).find_by_spin_session_id(my_session_id)
        if current_folder_key.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No current_folder_key record is found'
          return rethash
        end
        if paramshash[:original_place] == 'folder_tree'
          folder_data_rec = FolderDatum.find_by_hash_key paramshash[:hash_key]
          if folder_data_rec.blank?
            folder_data_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
            if folder_data_rec.blank?
              rethash[:success] = false
              rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
              rethash[:errors] = 'No folder_data_rec record is found'
              return rethash
            end
          end
          parent_hash_key = (folder_data_rec.present? and folder_data_rec[:parent_hash_key].present?) ? folder_data_rec[:parent_hash_key] : ''
          node_name = folder_data_rec[:folder_name]
          parent_folder_rec = FolderDatum.get_parent_folder my_session_id, folder_data_rec[:spin_node_hashkey]
          #          parent_folder_rec = FolderDatum.get_parent_folder my_session_id, current_folder_key[:spin_current_directory]
          target_folder_key = parent_folder_rec[:spin_node_hashkey]
          rethash[:deleted_node_type] = NODE_DIRECTORY
        else
          folder_data_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
          if folder_data_rec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'No folder_data_rec record is found'
            return rethash
          end
          parent_hash_key = (folder_data_rec.present? and folder_data_rec[:parent_hash_key].present?) ? folder_data_rec[:parent_hash_key] : ''
          node_name = folder_data_rec[:file_name]
          target_folder_key = current_folder_key[:spin_current_directory]
          rethash[:deleted_node_type] = (folder_data_rec[:file_type] == 'folder' ? NODE_DIRECTORY : NODE_FILE)
        end

        if folder_data_rec == nil
          rethash[:success] = false
          rethash[:status] = ERROR_INVALID_HASH_KEY
          #          rethash[:errors] = "Failed to delete file : hash key is invalid"
          rethash[:errors] = "指定されたフォルダが見つかりません"
          return rethash
        end
        delete_file_key = folder_data_rec[:spin_node_hashkey]
      end
      if paramshash[:folder_writable_status] == false or paramshash[:folder_writable_status] == "false" or SpinAccessControl.is_deletable(my_session_id, delete_file_key) != true # not writable or login dir
        # this should not be deleted
        rethash[:success] = false
        rethash[:status] = ERROR_NOT_WRITABLE
        rethash[:errors] = "このフォルダは削除できません"
        return rethash
      end

      # ロック状態排他制御
      file_nodes = []
      if paramshash[:original_place] === 'folder_tree'
        file_nodes = DatabaseUtility::VirtualFileSystemUtility.search_virtual_file_on_tree delete_file_key
      else
        if folder_data_rec[:file_type] === 'folder'
          file_nodes = DatabaseUtility::VirtualFileSystemUtility.search_virtual_file_on_tree delete_file_key
        else
          file_nodes = DatabaseUtility::VirtualFileSystemUtility.search_virtual_file delete_sid, node_name, parent_hash_key, ANY_VALUE, ANY_VALUE, SEARCH_EXISTING_VFILE
        end
      end

      if file_nodes.size() > 0
        file_nodes.each {|file_node|
          if file_node[:latest]
            if FSTAT_WRITE_LOCKED == file_node[:lock_mode] && FSTAT_LOCKED == file_node[:lock_status]
              if delete_uid != file_node[:lock_uid] && -1 != file_node[:lock_uid]
                rethash[:success] = false
                rethash[:status] = ERROR_TRASH_FILE
                rethash[:errors] = '他のユーザーにロックされているため削除できません'
                return rethash
              end
            end
          end
        }
      end

      folder_key = SpinLocationManager.get_parent_key(delete_file_key)
      Rails.logger.warn(">> thread_delete_folder : new thread")
      # Rails.logger.warn(">> thread_delete_folder : call set_pending 1") # ゴミ箱に移動する際のタイミングで初めに持ってき他方がよいときはコメントを外す。
      # pc = SpinNode.set_pending(delete_file_key, true)
      thr_rethash = {}
      begin
        delete_thread = Thread.new(delete_sid, delete_file_key, folder_data_rec[:file_type], thr_rethash) {|del_sid, arg_del_key, f_type, thr_reth|
          Thread.pass
          if f_type != 'folder'
            pc = SpinNode.set_pending(arg_del_key, true)
          else
            pc = SpinNode.set_pending_all(arg_del_key, true)
          end
          # Rails.logger.warn(">> thread_delete_folder : call delete_virtual_file")
          thr_rethash = DatabaseUtility::VirtualFileSystemUtility.delete_virtual_file del_sid, arg_del_key, true, true # => the last 2 arguments are trash_it flag and is_thrown
          if thr_rethash[:success]
            RecyclerDatum.reset_busy(del_sid, arg_del_key)
          end
          thr_rethash[:pending_count] = pc
        }
          #        delete_thread.join
      rescue
        log_msg = 'Unhandled excption!'
        FileManager.logger(delete_sid, log_msg, 'LOCAL', LOG_ERROR)
        rethash[:success] = false
        rethash[:status] = ERROR_NOT_WRITABLE
        rethash[:errors] = "このフォルダは削除できません"
        return rethash
      end # => end of thread

      wait_recycler_proc_count = 10
      while RecyclerDatum.find_by_session_id_and_spin_node_hashkey(delete_sid, delete_file_key).blank? and wait_recycler_proc_count > 0
        sleep 1
        wait_recycler_proc_count -= 1
      end

      rethash[:success] = true
      rethash[:status] = (INFO_TRASH_FILE_SUCCESS | INFO_RENDERING_DONE)
      domain_key = SessionManager.get_selected_domain(my_session_id, paramshash[:cont_location])
      FolderDatum.reset_partial_root(my_session_id, paramshash[:cont_location], domain_key)
      #pc = SpinNode.set_pending(delete_file_key, true)

      FolderDatum.transaction do
        begin
          #        FolderDatum.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
          delquery = "DELETE FROM folder_data WHERE session_id = \'#{delete_sid}\' AND spin_node_hashkey = \'#{delete_file_key}\';"
          FolderDatum.find_by_sql(delquery)
        rescue ActiveRecord::StaleObjectError
          FileManager.logger(delete_sid, "folder record is alread removed")
        end
      end

      # FolderDatum.fill_folders(my_session_id, paramshash[:cont_location], domain_key)
      FolderDatum.has_updated(my_session_id, target_folder_key, DISMISS_CHILD, true)
      FolderDatum.set_partial_root(my_session_id, paramshash[:cont_location], target_folder_key)
      FolderDatum.select_folder(my_session_id, folder_key, paramshash[:cont_location], domain_key)

    when 'set_node_pending'
      pending_sid = my_session_id
      #      pending_contlocation = paramshash[:cont_location]
      pending_file_key = paramshash[:hash_key]
      folder_data_rec = {}
      user_agent = $http_user_agent
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        pending_file_key = paramshash[:hash_key]
      else # => from UI
        if paramshash[:original_place] == 'folder_tree'
          folder_data_rec = FolderDatum.find_by_hash_key paramshash[:hash_key]
          if folder_data_rec.blank?
            folder_data_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
            if folder_data_rec.blank?
              rethash[:success] = false
              rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
              rethash[:errors] = 'No folder_data_rec record is found'
              return rethash
            end
          end
        else
          folder_data_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
          if folder_data_rec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'No folder_data_rec record is found'
            return rethash
          end
        end
        if folder_data_rec == nil
          rethash[:success] = false
          rethash[:status] = ERROR_INVALID_HASH_KEY
          #          rethash[:errors] = "Failed to delete file : hash key is invalid"
          rethash[:errors] = "指定されたフォルダが見つかりません"
          return rethash
        end
        pending_file_key = folder_data_rec[:spin_node_hashkey]
      end
      SpinNode.set_pending(pending_file_key)
      rethash[:success] = true
      rethash[:status] = INFO_BASE

    when 'secret_files_get_domain_privilege'
      # set folder privilege
      user_agent = $http_user_agent
      folder_hashkey = ''
      #if /HTTP_Request2.+/ =~ user_agent # => PHP API
      if user_agent == "BoomboxAPI"
        domain_hashkey = paramshash[:domain_hashkey] #ドメインのハッシュ値
        vpath_hashkey = paramshash[:vpath_hashkey] #ドメインのVPATHのハッシュ値
        #l_offset = paramshash[:start].to_i
        #l_limit = paramshash[:limit].to_i
        l_offset = 0
        l_limit = 0
        #recs=GroupDatum.secret_files_get_folder_node_data ssid, GROUP_LIST_FOLDER, l_offset, l_limit, target_hashkey
        disp_group_list_obj = GroupDatum.secret_files_get_domain_access_list my_session_id, GROUP_LIST_FOLDER, l_offset, l_limit, vpath_hashkey, domain_hashkey
        rethash = disp_group_list_obj
      else
        rethash[:success] = false
        rethash[:errors] = "BoomboxAPIではありません。"
      end

    when 'secret_files_set_folder_privilege'
      # set folder privilege
      user_agent = $http_user_agent
      folder_hashkey = ''
      source_cont_location = 'folder_a'
      #if /HTTP_Request2.+/ =~ user_agent # => PHP API
      if user_agent == "BoomboxAPI"
        folder_hashkey = paramshash[:data][:hash_key]

        privileges = Hash.new
        set_priv_sid = my_session_id
        #members = paramshash[:members]
        temp = paramshash[:members]
        if (temp.is_a?(Hash))
          count = 0
          members = []
          temp.each {|key, value|
            members[count] = {}
            members[count] = value
            count = count + 1
          }
        else
          members = paramshash[:members]
        end
        privileges[:folder_name] = paramshash[:data][:text]
        privileges[:folder_hashkey] = folder_hashkey
        privileges[:cont_location] = paramshash[:data][:cont_location]
        privileges[:target] = paramshash[:data][:target]
        privileges[:range] = paramshash[:data][:range]
        privileges[:owner] = paramshash[:data][:owner_name]
        privileges[:owner_right] = 'full'
        privileges[:other_writable] = false # => boolean
        privileges[:other_readable] = false # => boolean
        #      privileges[:other_writable] = paramshash[:data][:other_writable] # => boolean
        #      privileges[:other_readable] = paramshash[:data][:other_readable] # => boolean
        privileges[:group_writable] = paramshash[:data][:group_writable] # => boolean
        privileges[:group_readable] = paramshash[:data][:group_readable] # => boolean
        # group_editable -> control_right 2014/3/13
        #      privileges[:group_editable] = paramshash[:group_editable] # => boolean
        privileges[:control_right] = paramshash[:data][:control_right] # => boolean
        # get numbered hashes
        list_files = Array.new
        # get file attributes
        acl_recs = SpinAccessControl.secret_files_set_folder_privilege set_priv_sid, privileges, members
        if acl_recs >= 0
          if user_agent != "BoomboxAPI"
            domain_s = SessionManager.get_selected_domain(my_session_id, source_cont_location)
            DomainDatum.set_domain_dirty(my_session_id, paramshash[:data][:cont_location], domain_s)
            FolderDatum.reset_partial_root(my_session_id, paramshash[:data][:cont_location], domain_s)
            reth = FolderDatum.fill_folders(my_session_id, paramshash[:data][:cont_location], domain_s)
          end
          rethash[:success] = true
          rethash[:status] = INFO_SET_FOLDER_PRIVILEGE_SUCCESS
          rethash[:result] = acl_recs
        else
          rethash[:success] = false
          rethash[:errors] = "SpinAccessControlからの戻り値が不正です。"
        end
      else # => from UI
        rethash[:success] = false
        rethash[:errors] = "BoomboxAPIではありません。"
      end

    when 'secret_files_set_domain_privilege'
      # set folder privilege
      user_agent = $http_user_agent
      folder_hashkey = ''
      #if /HTTP_Request2.+/ =~ user_agent # => PHP API
      if user_agent == "BoomboxAPI"
        domain_hashkey = paramshash[:data][:hash_key]
        managed_node_hashkey = paramshash[:data][:managed_node_hashkey]
        privileges = Hash.new
        set_priv_sid = my_session_id
        #members = paramshash[:members]
        temp = paramshash[:members]
        if (temp.is_a?(Hash))
          count = 0
          members = []
          temp.each {|key, value|
            members[count] = {}
            members[count] = value
            count = count + 1
          }
        else
          members = paramshash[:members]
        end
        privileges[:folder_name] = paramshash[:data][:text]
        privileges[:folder_hashkey] = managed_node_hashkey
        privileges[:cont_location] = paramshash[:data][:cont_location]
        privileges[:target] = paramshash[:data][:target]
        privileges[:range] = paramshash[:data][:range]
        privileges[:owner] = paramshash[:data][:owner_name]
        privileges[:owner_right] = 'full'
        privileges[:other_writable] = false # => boolean
        privileges[:other_readable] = false # => boolean
        #      privileges[:other_writable] = paramshash[:data][:other_writable] # => boolean
        #      privileges[:other_readable] = paramshash[:data][:other_readable] # => boolean
        privileges[:group_writable] = paramshash[:data][:group_writable] # => boolean
        privileges[:group_readable] = paramshash[:data][:group_readable] # => boolean
        # group_editable -> control_right 2014/3/13
        #      privileges[:group_editable] = paramshash[:group_editable] # => boolean
        privileges[:control_right] = paramshash[:data][:control_right] # => boolean
        # get numbered hashes
        privileges[:spin_uid_access_right] = ACL_NODE_NO_ACCESS
        privileges[:spin_world_access_right] = ACL_NODE_NO_ACCESS

        list_files = Array.new
        # get file attributes
        gacl = ((privileges[:group_readable] ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (privileges[:group_writable] ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS) | (privileges[:control_right] ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
        rtn = SpinAccessControl.secret_files_add_domain_access_control(my_session_id, managed_node_hashkey, gacl, members, 32768, domain_hashkey)
        acl_recs = SpinAccessControl.secret_files_set_domain_privilege set_priv_sid, privileges, members, domain_hashkey
        if acl_recs >= 0
          rethash[:success] = true
          rethash[:status] = INFO_SET_FOLDER_PRIVILEGE_SUCCESS
          rethash[:result] = acl_recs
        else
          rethash[:success] = false
          rethash[:errors] = "SpinAccessControlからの戻り値が不正です。"
        end
      else # => from UI
        rethash[:success] = false
        rethash[:errors] = "This isn't BoomboxAPI."
      end

    when 'secret_files_dismiss_domain_group' # 元はdissmiss_folder_group

      user_agent = $http_user_agent
      folder_hashkey = ''

      if user_agent == "BoomboxAPI" # => PHP API
        domain_hashkey = paramshash[:data][:hash_key]
        managed_node_hashkey = paramshash[:data][:managed_node_hashkey]

        privileges = Hash.new
        remove_priv_sid = my_session_id
        privileges[:folder_name] = paramshash[:data][:text]
        privileges[:folder_hashkey] = managed_node_hashkey
        privileges[:cont_location] = paramshash[:data][:cont_location]
        privileges[:target] = paramshash[:data][:target]
        privileges[:range] = paramshash[:data][:range]
        privileges[:owner] = paramshash[:data][:owner]
        privileges[:other_writable] = paramshash[:data][:other_writable] # => boolean
        privileges[:other_readable] = paramshash[:data][:other_readable] # => boolean
        privileges[:group_writable] = paramshash[:data][:group_writable] # => boolean
        privileges[:group_readable] = paramshash[:data][:group_readable] # => boolean
        privileges[:group_editable] = paramshash[:data][:group_editable] # => boolean

        remove_groups = paramshash[:members]

        # get file attributes
        acl_recs = SpinAccessControl.remove_folder_privilege remove_priv_sid, privileges, remove_groups, folder_hashkey
        if acl_recs >= 0
          rethash[:success] = true
          rethash[:status] = STAT_DATA_NOT_LOADED_YET
          rethash[:result] = rm_recs
        else
          rethash[:success] = false
          rethash[:errors] = "SpinAccessControlからの戻り値が不正です。"
        end
      else
        #将来的にはエラーを返すようにする
        rethash[:success] = false
        rethash[:errors] = "This isn't Boombox API."
      end


    when 'set_folder_privilege'
      # set folder privilege
      user_agent = $http_user_agent
      folder_hashkey = ''
      source_cont_location = 'folder_a'
      #if /HTTP_Request2.+/ =~ user_agent # => PHP API
      if user_agent == "BoomboxAPI"
        folder_hashkey = paramshash[:data][:hash_key]
      else # => from UI
        folder_rec = FolderDatum.find_by_hash_key paramshash[:data][:hash_key]
        if folder_rec.blank?
          folder_rec = FileDatum.find_by_hash_key paramshash[:data][:hash_key]
          if folder_rec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_SET_FOLDER_PRIVILEGE
            rethash[:errors] = "Failed to set folder privilege."
            return rethash
          end
        end
        folder_hashkey = folder_rec[:spin_node_hashkey]
      end
      privileges = Hash.new
      set_priv_sid = my_session_id
      members = paramshash[:members]
      privileges[:folder_name] = paramshash[:data][:text]
      privileges[:folder_hashkey] = folder_hashkey
      privileges[:cont_location] = paramshash[:data][:cont_location]
      privileges[:target] = paramshash[:data][:target]
      if paramshash[:data][:range].present?
        privileges[:range] = 'folder'
      else
        privileges[:range] = paramshash[:data][:range]
      end
      privileges[:owner] = paramshash[:data][:owner_name]
      privileges[:owner_right] = 'full'
      privileges[:other_writable] = false # => boolean
      privileges[:other_readable] = false # => boolean
      #      privileges[:other_writable] = paramshash[:data][:other_writable] # => boolean
      #      privileges[:other_readable] = paramshash[:data][:other_readable] # => boolean
      privileges[:group_writable] = paramshash[:data][:group_writable] # => boolean
      privileges[:group_readable] = paramshash[:data][:group_readable] # => boolean
      # group_editable -> control_right 2014/3/13
      #      privileges[:group_editable] = paramshash[:group_editable] # => boolean
      privileges[:control_right] = paramshash[:data][:control_right] # => boolean
      # get numbered hashes
      list_files = Array.new
      # get file attributes
      #定義との差異があったため、パラメータの順番を変更 2015/11/16
      acl_recs = SpinAccessControl.set_folder_privilege set_priv_sid, privileges, members, folder_hashkey
      if acl_recs >= 0
        domain_s = SessionManager.get_selected_domain(my_session_id, source_cont_location)
        DomainDatum.set_domain_dirty(my_session_id, paramshash[:data][:cont_location], domain_s)
        # FolderDatum.reset_partial_root(my_session_id, paramshash[:data][:cont_location], domain_s)
        reth = FolderDatum.fill_folders(my_session_id, paramshash[:data][:cont_location], domain_s)
        rethash[:success] = true
        rethash[:status] = INFO_SET_FOLDER_PRIVILEGE_SUCCESS
        rethash[:result] = acl_recs
      else
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_SET_FOLDER_PRIVILEGE
      end

    when 'set_folder_notification'
      user_agent = $http_user_agent
      folder_hashkey = ''
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        folder_hashkey = paramshash[:data][:hash_key]
      else # => from UI
        folder_rec = FolderDatum.find_by_hash_key paramshash[:data][:hash_key]
        if folder_rec.blank?
          folder_rec = FileDatum.find_by_hash_key paramshash[:data][:hash_key]
          if folder_rec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_SET_FOLDER_PRIVILEGE
            rethash[:errors] = "Failed to set folder privilege."
            return rethash
          end
        end
        folder_hashkey = folder_rec[:spin_node_hashkey]
      end
      privileges = Hash.new
      set_priv_sid = my_session_id
      members = paramshash[:members]
      privileges[:file_name] = paramshash[:data][:file_name]
      privileges[:file_hashkey] = file_hashkey
      privileges[:cont_location] = paramshash[:data][:cont_location]
      privileges[:target] = 'folder'
      if paramshash[:data][:range].present?
        privileges[:range] = 'folder'
      else
        privileges[:range] = paramshash[:data][:range]
      end
      #      privileges[:range] = paramshash[:data][:range]
      privileges[:owner] = paramshash[:data][:owner]
      privileges[:notify_upload] = paramshash[:data][:notify_read] # => boolean
      privileges[:notify_modify] = paramshash[:data][:notify_modify] # => boolean
      privileges[:notify_delete] = paramshash[:data][:notify_delete] # => boolean
      # group_editable -> control_right 2014/3/13
      #      privileges[:group_editable] = paramshash[:data][:group_editable] # => boolean
      #      privileges[:control_right] = paramshash[:data][:control_right] # => boolean
      # get numbered hashes
      list_files = Array.new
      hash_params = Hash.new
      paramshash.each {|key, value|
        if /[0-9]+/ =~ key # => number
          list_files.append value
        else # => string
          hash_params[key] = value
        end
      }
      # get file attributes
      acl_recs = SpinNotifyControl.set_folder_notification set_priv_sid, privileges, members, folder_hashkey
      if acl_recs >= 0
        domain_s = SessionManager.get_selected_domain(my_session_id, source_cont_location)
        DomainDatum.set_domain_dirty(my_session_id, paramshash[:data][:cont_location], domain_s)
        FolderDatum.reset_partial_root(my_session_id, paramshash[:data][:cont_location], domain_s)
        reth = FolderDatum.fill_folders(my_session_id, paramshash[:data][:cont_location], domain_s)
        rethash[:success] = true
        rethash[:status] = INFO_SET_FOLDER_PRIVILEGE_SUCCESS
        rethash[:result] = acl_recs
      else
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_SET_FOLDER_PRIVILEGE
      end
    when 'set_file_privilege'
      # set folder privilege
      user_agent = $http_user_agent
      file_hashkey = ''
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        file_hashkey = paramshash[:data][:hash_key]
      else # => from UI
        folder_rec = FileDatum.find_by_hash_key paramshash[:data][:hash_key]
        if folder_data_rec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No folder_data_rec record is found at set_file_privilege'
          return rethash
        end
        file_hashkey = folder_rec[:spin_node_hashkey]
      end
      privileges = Hash.new
      set_priv_sid = my_session_id
      members = paramshash[:members]
      privileges[:file_name] = paramshash[:data][:file_name]
      privileges[:file_hashkey] = file_hashkey
      privileges[:cont_location] = paramshash[:data][:cont_location]
      privileges[:target] = paramshash[:data][:target]
      #      privileges[:range] = paramshash[:data][:range]
      privileges[:owner] = paramshash[:data][:owner]
      privileges[:owner_right] = paramshash[:data][:owner_right]
      privileges[:other_writable] = paramshash[:data][:other_writable] # => boolean
      privileges[:other_readable] = paramshash[:data][:other_readable] # => boolean
      privileges[:group_writable] = paramshash[:data][:group_writable] # => boolean
      privileges[:group_readable] = paramshash[:data][:group_readable] # => boolean
      # group_editable -> control_right 2014/3/13
      #      privileges[:group_editable] = paramshash[:data][:group_editable] # => boolean
      privileges[:control_right] = paramshash[:data][:control_right] # => boolean
      # get numbered hashes
      list_files = Array.new
      hash_params = Hash.new
      paramshash.each {|key, value|
        if /[0-9]+/ =~ key # => number
          list_files.append value
        else # => string
          hash_params[key] = value
        end
      }
      # get file attributes
      acl_recs = SpinAccessControl.set_file_privilege set_priv_sid, privileges, members
      if acl_recs >= 0
        domain_s = SessionManager.get_selected_domain(my_session_id, source_cont_location)
        DomainDatum.set_domain_dirty(my_session_id, paramshash[:data][:cont_location], domain_s)
        FolderDatum.reset_partial_root(my_session_id, paramshash[:data][:cont_location], domain_s)
        reth = FolderDatum.fill_folders(my_session_id, paramshash[:data][:cont_location], domain_s)
        rethash[:success] = true
        rethash[:status] = INFO_SET_FOLDER_PRIVILEGE_SUCCESS
        rethash[:result] = acl_recs
      else
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_SET_FOLDER_PRIVILEGE
      end

    when 'get_group_list'
      my_session_id = paramshash[:session_id]
      if paramshash[:id_type].present?
        id_type = paramshash[:id_type]
      else
        id_type = GROUP_MEMBER_ID_TYPE_GROUP #値は１ ユーザのプライマリでないグループ
        #id_type = GROUP_MEMBER_ID_TYPE_USER_PRIMARY_GROUP #値は２　ユーザのプライマリグループ
      end
      # "session_id"=>"e0c4a5515e746275f5dc94feca20a147cffd192e", "searching_group"=>"x", "target_hash_key"=>""
      #ssrec = SpinSession.readonly.select("spin_uid").find(:first, :conditions=>["spin_session_id = ?", my_session_id])
      ssrec = SpinSession.readonly.find_by_sql(['select spin_uid from spin_sessions where spin_session_id = ?', my_session_id])
      if ssrec.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No session record is found at get_group_list'
        return rethash
      end
      my_uid = ssrec[0][:spin_uid]
      #    my_gid = ssrec[:spin_gid]
      #spin_user_obj = SpinUser.readonly.select("spin_gid").find(["spin_uid = ?", my_uid])
      spin_user_obj = SpinUser.find_by_sql(['select spin_gid from spin_users where spin_uid = ?', my_uid])
      if spin_user_obj.blank?
        rethash[:status] = false;
        rethash[:status] = ERROR_BOOMBOX_API_GET_GROUP_LIST;
        rethash[:errors] = "ユーザ情報からグループが判別できないです。";
        return rethash
      end
      my_gid = spin_user_obj[0][:spin_gid].to_i
      if (my_uid == 0)
        #n_groups = SpinGroup.readonly.find_by_sql(['select *, spin_gid as member_id from spin_groups where id_type = ?'],id_type)
        n_groups = SpinGroup.readonly.find_by_sql(['select *, spin_gid as member_id from spin_groups'])
        if n_groups.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No group record is found at get_group_list'
          return rethash
        end
      else
        #n_groups = SpinGroup.readonly.find_by_sql(['select *, spin_gid as member_id from spin_groups where owner_id = ? and id_type = ?',my_gid,id_type])
        n_groups = SpinGroup.readonly.find_by_sql(['select *, spin_gid as member_id from spin_groups where (owner_id = ? and id_type = 1) or id_type = 2', my_gid])
        if n_groups.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No session record is found at get_group_list'
          return rethash
        end
      end

      rethash[:result] = n_groups
      rethash[:success] = true
      rethash[:status] = INFO_BOOMBOX_API_GET_GROUP_LIST_SUCCESS

    when 'get_member_group_list'
      my_session_id = paramshash[:session_id]
      my_group_id = paramshash[:my_group_id].to_i

      #ssrec = SpinSession.readonly.select("spin_uid").find(:first, :conditions=>["spin_session_id = ?", my_session_id])
      #ssrec = SpinSession.readonly.find_by_sql(['select spin_uid from spin_sessions where spin_session_id = ?',my_session_id])
      #my_uid = ssrec[0][:spin_uid]
      #    my_gid = ssrec[:spin_gid]
      #spin_user_obj = SpinUser.readonly.select("spin_gid").find(["spin_uid = ?", my_uid])
      #spin_user_obj = SpinUser.readonly.find_by_sql(['select spin_gid from spin_users where spin_uid = ?',my_uid])
      #if spin_user_obj == nil
      #  rethash[:status] = false;
      #  rethash[:status] = ERROR_BOOMBOX_API_GET_MEMBER_GROUP_LIST;
      #  rethash[:errors] = "ユーザ情報からグループが判別できないです。";
      #  return rethash;
      #end
      #my_gid = spin_user_obj[0][:spin_gid]

      n_uids = SpinGroupMember.readonly.find_by_sql(['select *, spin_uid as member_id from spin_group_members where spin_gid = ?', my_group_id])
      rethash[:result] = {}
      if n_uids.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No user id record is found at get_group_list'
        return rethash
      end
      #n_uids.each_whih_index{|value, index|
      #  spin_uid = n_uid[:spin_uid].to_i
      #  spin_gid = n_uid[:spin_gid].to_i
      #  rtn = SpinGroup.readonly.find_by_sql(['select * ,spin_gid as member_id from spin_groups where spin_uid = ? and spin_gid = ?', spin_uid, spinuid])
      #  if rtn.present?
      #    rethash[:result][index] = {}
      #    rethash[:result][index] = rtn
      #   end
      #}
      rethash[:result] = n_uids
      rethash[:status] = INFO_BOOMBOX_API_GET_MEMBER_GROUP_LIST_SUCCESS;
      rethash[:success] = true

    when 'add_member_my_group'
      my_session_id = paramshash[:session_id]
      my_group_id = paramshash[:my_group_id].to_i
      member_ids = paramshash[:member_ids]
      # "session_id"=>"e0c4a5515e746275f5dc94feca20a147cffd192e", "searching_group"=>"x", "target_hash_key"=>""
      #ssrec = SpinSession.readonly.select("spin_uid").find(:first, :conditions=>["spin_session_id = ?", my_session_id])
      ssrec = SpinSession.readonly.find_by_sql(['select spin_uid from spin_sessions where spin_session_id = ?', my_session_id])
      if ssrec.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No session record is found at add_member_my_group'
        return rethash
      end
      my_uid = ssrec[0][:spin_uid]
      #    my_gid = ssrec[:spin_gid]
      #spin_user_obj = SpinUser.readonly.select("spin_gid").find(["spin_uid = ?", my_uid])
      #spin_user_obj = SpinUser.find_by_sql(['select spin_gid from spin_users where spin_uid = ?',my_uid])
      #if spin_user_obj == nil
      #  rethash[:status] = false;
      #  rethash[:status] = ERROR_BOOMBOX_API_GET_GROUP_LIST;
      #  rethash[:errors] = "ユーザ情報からグループが判別できないです。";
      #  return rethash
      #end
      #my_gid = spin_user_obj[0][:spin_gid]
      if (my_uid != 0)
        rtn_groups = SpinGroup.readonly.find_by_sql(['select * from spin_groups where owner_id = ? and spin_gid = ?', my_uid, my_group_id])
        if rtn_groups.count != 1
          rethash[:errors] = "追加元のグループ(#{my_group_id})に権限(#{my_uid})がありません。"
          rethash[:success] = false
          rethash[:status] = ERROR_BOOMBOX_API_ADD_MEMBER_MY_GROUP
          return rethash
        end
      end

      member_ids.each {|value|
        member_id = value[:member_id].to_i
        next if my_group_id == member_id
        reth = SpinGroupMember.add_member my_session_id, member_id, my_group_id
        if reth[:success] == false
          rethash[:status] = ERROR_BOOMBOX_API_ADD_MEMBER_MY_GROUP
          return reth
        end
      }
      rethash[:success] = true
      rethash[:result] = member_ids.count
      rethash[:status] = INFO_BOOMBOX_API_ADD_MEMBER_MY_GROUP_SUCCESS

    when 'delete_member_my_group'
      # add members to my group
      my_session_id = paramshash[:session_id]
      my_group_id = paramshash[:my_group_id].to_i
      member_ids = paramshash[:member_ids]
      # get numbered hashes

      removed_members = 0
      member_ids.each {|value|
        member_id = value[:member_id].to_i
        reth = SpinGroupMember.delete_member my_session_id, member_id, my_group_id
        if reth[:success] == false
          rethash[:success] = false
          rethash[:status] = reth[:status]
          rethash[:errors] = reth[:errors]
          return reth
        end
        removed_members += 1
      }

      if reth[:success] == true
        rethash[:success] = true
        rethash[:status] = reth[:status]
        rethash[:result] = removed_members
      else
        rethash[:success] = false
        rethash[:status] = reth[:status]
        rethash[:errors] = reth[:errors]
      end

    when 'search_all_groups'
      # "session_id"=>"e0c4a5515e746275f5dc94feca20a147cffd192e", "searching_group"=>"x", "target_hash_key"=>""
      n_groups = GroupDatum.search_all_groups my_session_id, paramshash[:searching_group]
      rethash[:n_groups] = n_groups
      rethash[:success] = true
    when 'search_group_folder_privilege', 'search_group_file_privilege'
      folder_location = paramshash[:cont_lcation]
      # "session_id"=>"e0c4a5515e746275f5dc94feca20a147cffd192e", "searching_group"=>"x", "target_hash_key"=>""
      n_groups = GroupDatum.search_all_groups my_session_id, paramshash[:searching_group]
      rethash[:success] = true
      #    when 'search_group_file_privilege'
      #      search_group = paramshash[:searching_group] # => query string
      #      folder_location = paramshash[:cont_lcation]
      #      rethash[:success] = true
    when 'dismiss_group_members'
      # add members to my group
      my_session_id = paramshash[:session_id]
      my_group_id = paramshash[:my_group].to_i
      # get numbered hashes
      list_members = Array.new
      hash_params = Hash.new
      paramshash.each {|key, value|
        if /[0-9]+/ =~ key # => number
          list_members.append value
        else # => string
          hash_params[key] = value
        end
      }
      # get file attributes
      reth = SpinGroupMember.remove_group_members_from_group my_session_id, my_group_id, list_members
      if reth[:success] == true
        rethash[:success] = true
        rethash[:status] = reth[:status]
        rethash[:result] = reth[:result]
      else
        rethash[:success] = false
        rethash[:status] = reth[:status]
      end
    when 'delete_my_group'
      # add members to my group
      my_session_id = paramshash[:session_id]
      # get attributes
      my_group_id = paramshash[:my_group].to_i
      reth = SpinGroup.delete_group my_session_id, my_group_id
      #      reth = SpinGroupMember.append_group_members_to_current_selected_group my_session_id, list_groups, hash_params
      if reth[:success] == true
        rethash[:success] = true
        rethash[:status] = reth[:status]
        rethash[:result] = reth[:result]
      else
        rethash[:success] = false
        rethash[:status] = reth[:status]
      end
    when 'change_my_group_name'
      # add members to my group
      my_session_id = paramshash[:session_id]
      # get attributes
      my_group_id = paramshash[:my_group].to_i
      my_new_group_description = paramshash[:group_description]
      my_new_group_name = paramshash[:changed_group_name]
      reth = SpinGroup.modify_group_info my_group_id, my_new_group_name, my_new_group_description
      #      reth = SpinGroupMember.append_group_members_to_current_selected_group my_session_id, list_groups, hash_params
      if reth[:success] == true
        retgid = SpinGroup.select_group my_session_id, my_new_group_name
        if retgid < 0
          rethash[:success] = false
          rethash[:status] = ERROR_SELECTED_GROUP_MISSING
          rethash[:errors] = "no selected group data"
          return rethash
        else
          rethash[:success] = true
          rethash[:status] = INFO_SELECT_GROUP_SUCCESS
          rethash[:result] = retgid
        end
        #        rethash[:success] = true
        #        rethash[:status] = reth[:status]
        #        rethash[:result] = reth[:result]
      else
        rethash[:success] = false
        rethash[:status] = reth[:status]
      end
    when 'append_my_group_members'
      # add members to my group
      my_session_id = paramshash[:session_id]
      gid=paramshash[:gid]
      # get numbered hashes
      list_groups = Array.new
      hash_params = Hash.new
      paramshash.each {|key, value|
        if /[0-9]+/ =~ key # => number
          list_groups.append value
        else # => string
          hash_params[key] = value
        end
      }
      # get file attributes
      if (list_groups.length()>0)
        reth = SpinGroupMember.append_group_members_to_current_selected_group my_session_id, list_groups, hash_params, gid
      else
        rethash[:success] = false
        rethash[:errors] = 'メンバーが選択されていません。'
        return rethash;
      end
      if reth[:success] == true
        rethash[:success] = true
        rethash[:status] = reth[:status]
        rethash[:result] = reth[:result]
      else
        rethash[:success] = false
        rethash[:status] = reth[:status]
      end
    when 'append_my_folder_members', 'append_my_folder_memebers'
      # add members to my folder access list
      # set folder privilege
      privileges = Hash.new
      append_group_sid = my_session_id
      append_folder_location = paramshash[:cont_location]
      #target_hash_key = paramshash[:target_hash_key]
      target_hash_key = ''
      if (paramshash[:target]=='folderPanelA')
        fd = FolderDatum.find_by_hash_key paramshash[:hash_key];
        if fd.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No folder record is found at append_my_folder_members'
          return rethash
        end
        target_hash_key=fd[:spin_node_hashkey];
      else
        fd = FileDatum.find_by_hash_key paramshash[:hash_key];
        if fd.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No folder record is found at append_my_folder_members 2'
          return rethash
        end
        target_hash_key=fd[:spin_node_hashkey];
      end
      # get numbered hashes
      append_groups = Array.new
      hash_params = Hash.new
      paramshash.each {|key, value|
        if /[0-9]+/ =~ key # => number
          append_groups.append value
        else # => string
          hash_params[key] = value
        end
      }
      # get file attributes
      acl_recs = GroupDatum.append_group_to_privilege_list append_group_sid, append_folder_location, append_groups, target_hash_key, GROUP_LIST_FOLDER
      if acl_recs >= 0
        rethash[:success] = true
        rethash[:result] = acl_recs
      else
        rethash[:success] = false
      end
    when 'append_my_file_members'
      # add members to my folder access list
      # set folder privilege
      privileges = Hash.new
      append_group_sid = my_session_id
      append_folder_location = paramshash[:cont_location]
      target_hash_key = paramshash[:target_hash_key]
      # get numbered hashes
      append_groups = Array.new
      hash_params = Hash.new
      paramshash.each {|key, value|
        if /[0-9]+/ =~ key # => number
          append_groups.append value
        else # => string
          hash_params[key] = value
        end
      }
      # get file attributes
      acl_recs = GroupDatum.append_group_to_privilege_list append_group_sid, append_folder_location, append_groups, target_hash_key, GROUP_LIST_FILE
      if acl_recs >= 0
        rethash[:success] = true
        rethash[:result] = acl_recs
      else
        rethash[:success] = false
      end
    when 'dismiss_folder_group'
      # set folder privilege
      # set folder privilege
      user_agent = $http_user_agent
      folder_hashkey = ''
      #if /HTTP_Request2.+/ =~ user_agent # => PHP API
      if user_agent == "BoomboxAPI" # => PHP API
        folder_hashkey = paramshash[:data][:hash_key]
      else # => from UI
        #folder_rec = FolderDatum.find_by_hash_key paramshash[:data][:hash_key]
        #folder_rec = FileDatum.find_by_hash_key paramshash[:data][:hash_key]
        #folder_hashkey = folder_rec[:spin_node_hashkey]
        if (paramshash[:target]=='listGridPanelA')
          folder_rec=FileDatum.find_by_hash_key paramshash[:data][:hash_key];
          if folder_rec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'No folder record is found at dismiss_folder_group'
            return rethash
          end
          folder_hashkey = folder_rec[:spin_node_hashkey]
        else
          folder_rec=FolderDatum.find_by_hash_key paramshash[:data][:hash_key];
          if folder_rec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'No folder record is found at dismiss_folder_group 2'
            return rethash
          end
          folder_hashkey = folder_rec[:spin_node_hashkey]
        end
      end
      privileges = Hash.new
      remove_priv_sid = my_session_id
      privileges[:folder_name] = paramshash[:data][:text]
      privileges[:folder_hashkey] = folder_hashkey
      privileges[:cont_location] = paramshash[:data][:cont_location]
      privileges[:target] = paramshash[:data][:target]
      if paramshash[:data][:range].present?
        privileges[:range] = 'folder'
      else
        privileges[:range] = paramshash[:data][:range]
      end
      privileges[:owner] = paramshash[:data][:owner]
      privileges[:other_writable] = paramshash[:data][:other_writable] # => boolean
      privileges[:other_readable] = paramshash[:data][:other_readable] # => boolean
      privileges[:group_writable] = paramshash[:data][:group_writable] # => boolean
      privileges[:group_readable] = paramshash[:data][:group_readable] # => boolean
      privileges[:group_editable] = paramshash[:data][:group_editable] # => boolean
      # get numbered hashes
      remove_groups = paramshash[:members]
      #      hash_params = Hash.new
      #      paramshash.each { |key,value|
      #        if /[0-9]+/ =~ key # => number
      #          remove_groups.append value
      #        else # => string
      #          hash_params[key] = value
      #        end
      #      }
      # get file attributes
      acl_recs = SpinAccessControl.remove_folder_privilege remove_priv_sid, privileges, remove_groups, folder_hashkey
      if acl_recs >= 0
        rm_recs = GroupDatum.remove_group_from_privilege_list remove_priv_sid, remove_groups, GROUP_LIST_FOLDER
        if rm_recs >= 0
          domain_s = SessionManager.get_selected_domain(my_session_id, paramshash[:data][:cont_location])
          #          DomainDatum.set_domain_dirty(my_session_id, paramshash[:data][:cont_location], domain_s)
          FolderDatum.reset_partial_root(my_session_id, paramshash[:data][:cont_location], domain_s)
          #          FolderDatum.load_folder_recs(my_session_id, folder_hashkey, domain_s, paramshash[:data][:cont_location])
          FolderDatum.fill_folders(my_session_id, paramshash[:data][:cont_location], domain_s)
          FolderDatum.select_folder(my_session_id, folder_hashkey, paramshash[:data][:cont_location], domain_s)
          rethash[:success] = true
          rethash[:status] = STAT_DATA_NOT_LOADED_YET
          rethash[:isDirty] =
              rethash[:result] = rm_recs
        else
          rethash[:success] = false
          rethash[:errors] = "Failed to remove access right records from GroupData"
        end
      else
        rethash[:success] = false
      end
      #      acl_recs = SpinAccessControl.set_folder_privilege set_priv_sid, privileges, members
      #      if acl_recs >= 0
      #        domain_s = SessionManager.get_selected_domain(my_session_id, source_cont_location)
      #        DomainDatum.set_domain_dirty(my_session_id, paramshash[:data][:cont_location], domain_s)
      #        FolderDatum.reset_partial_root(my_session_id, paramshash[:data][:cont_location], domain_s)
      #        reth = FolderDatum.fill_folders(my_session_id, paramshash[:data][:cont_location], domain_s)
      #        rethash[:success] = true
      #        rethash[:status] = INFO_SET_FOLDER_PRIVILEGE_SUCCESS
      #        rethash[:result] = acl_recs
      #      else
      #        rethash[:success] = false
      #      end
    when 'dismiss_file_group'
      # set folder privilege
      # set folder privilege
      user_agent = $http_user_agent
      folder_hashkey = ''
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        folder_hashkey = paramshash[:data][:hash_key]
      else # => from UI
        file_rec = FileDatum.find_by_hash_key paramshash[:data][:hash_key]
        if file_rec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No folder record is found at dismiss_file_group'
          return rethash
        end
        file_hashkey = file_rec[:spin_node_hashkey]
      end
      privileges = Hash.new
      remove_priv_sid = my_session_id
      privileges[:file_name] = paramshash[:data][:fle_name]
      privileges[:file_hashkey] = file_hashkey
      privileges[:cont_location] = paramshash[:data][:cont_location]
      privileges[:target] = paramshash[:data][:target]
      #      privileges[:range] = paramshash[:data][:range]
      privileges[:owner] = paramshash[:data][:owner]
      privileges[:other_writable] = paramshash[:data][:other_writable] # => boolean
      privileges[:other_readable] = paramshash[:data][:other_readable] # => boolean
      privileges[:group_writable] = paramshash[:data][:group_writable] # => boolean
      privileges[:group_readable] = paramshash[:data][:group_readable] # => boolean
      privileges[:group_editable] = paramshash[:data][:group_editable] # => boolean
      # get numbered hashes
      remove_groups = paramshash[:members]
      #      hash_params = Hash.new
      #      paramshash.each { |key,value|
      #        if /[0-9]+/ =~ key # => number
      #          remove_groups.append value
      #        else # => string
      #          hash_params[key] = value
      #        end
      #      }
      # get file attributes
      acl_recs = SpinAccessControl.remove_file_privilege remove_priv_sid, privileges, remove_groups
      if acl_recs >= 0
        rm_recs = GroupDatum.remove_group_from_privilege_list remove_priv_sid, remove_groups, GROUP_LIST_FILE
        if rm_recs >= 0
          rethash[:success] = true
          rethash[:result] = rm_recs
        else
          rethash[:success] = false
          rethash[:errors] = "Failed to remove access right records from GroupData"
        end
      else
        rethash[:success] = false
      end
    when 'xmove_folder'
      user_agent = $http_user_agent
      move_file_key = ''
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        move_file_key = paramshash[:hash_key]
      else # => from UI
        folder_rec = FolderDatum.find_by_hash_key paramshash[:hash_key]
        if folder_rec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No folder record is found at xmove_folder'
          return rethash
        end
        move_file_key = folder_rec[:spin_node_hashkey]
      end
      # delete file from list and put it in the recycler
      # session_id, cont_location, hash_key, file_writable_status:bool, lock:int, file_name
      #      move_file_name = paramshash[:file_name]
      # paramshash.keys.each {|k| printf "%s = %s\n",k,paramshash[k]}
      move_sid = my_session_id
      #      move_contlocation = paramshash[:cont_location]
      #      move_file_key = paramshash[:hash_key]
      if paramshash[:folder_writable_status] == true or paramshash[:folder_writable_status] == 'true'
        move_folder_writable_status = true
      else
        move_folder_writable_status = false
      end
      target_cont_location = paramshash[:target_cont_location]
      if target_cont_location == 'folder_a'
        source_cont_location = 'folder_b'
      else
        source_cont_location = 'folder_a'
      end
      target_folder_writable_status = paramshash[:target_folder_writable_status]
      if paramshash[:target_folder_writable_status] == true or paramshash[:targert_folder_writable_status] == 'true'
        target_folder_writable_status = true
      else
        target_folder_writable_status = false
      end
      target_hash_key = paramshash[:target_hash_key]
      #      target_folder_name = paramshash[:text]
      if move_folder_writable_status != true # => not movable
        # this should not be deleted
        rethash[:success] = false
        rethash[:status] = ERROR_MOVE_FILE
        rethash[:errors] = "Failed to move file : file is not movable"
        return rethash
      end
      retb = DatabaseUtility::VirtualFileSystemUtility.move_virtual_file move_sid, move_file_key, target_hash_key, target_cont_location
      if retb
        move_source_folder_hashkey = SpinLocationManager.get_parent_key(move_file_key)
        FolderDatum.has_updated(move_sid, move_source_folder_hashkey, DISMISS_CHILD, true)
        FolderDatum.has_updated(move_sid, target_hash_key, NEW_CHILD, true)
        #        SessionManager.set_location_dirty(move_sid, (source_cont_location == 'folder_a' ? 'file_listA' : 'file_listB'), true)
        #        SessionManager.set_location_dirty(move_sid, (target_cont_location == 'folder_a' ? 'file_listA' : 'file_listB'), true)
        rethash[:success] = true
        rethash[:status] = INFO_MOVE_FILE_SUCCESS
        DomainDatum.domains_have_updated(my_session_id, SpinNode.get_domains(move_file_key))
      else
        rethash[:success] = false
        rethash[:status] = ERROR_MOVE_FILEl
      end
    when 'create_sub_folder'
      # coord_value is an array : [x,y,prx,v,h]
      FileManager.rails_logger(">> create_sub_folder : started at " + Time.now.to_s)
      error_coord = [-1, -1, -1, -1, nil]
      flag_make_dir_if_not_exeits = true
      hk = ''
      parent_folder = ''
      parent_is_expanded = false
      #if paramshash[:original_place] == 'folder_tree' # it is in folder tree
      if paramshash[:original_place] == 'folderPanelA'
        folder_rec = FolderDatum.find_by_session_id_and_hash_key_and_cont_location_and_text my_session_id, paramshash[:hash_key], paramshash[:cont_location], paramshash[:text]
        if folder_rec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No folder record is found at create_sub_folder'
          return rethash
        end
        hk = folder_rec[:spin_node_hashkey]
        target_hashkey = folder_rec[:spin_node_hashkey]
      else
        folder_rec = FileDatum.find_by_session_id_and_hash_key_and_cont_location_and_file_name my_session_id, paramshash[:hash_key], paramshash[:cont_location], paramshash[:text]
        if folder_rec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No folder record is found at create_sub_folder 2'
          return rethash
        end
        hk = folder_rec[:spin_node_hashkey]
        target_hashkey = folder_rec[:folder_hash_key]
        #        FolderDatum.select_folder(my_session_id, hk, paramshash[:cont_location])
      end
      #      if paramshash[:folder_hash_key]primary_group
      #        hk = paramshash[:folder_hash_key]
      #      elsif paramshash[:hash_key]
      #        hk = paramshash[:hash_key]
      #      else
      #        hk = nil
      #      end
      #      current_dir = DatabaseUtility::SessionUtility.get_current_directory my_session_id
      #      FileManager.rails_logger(">> get_vpath : started at " + Time.now.to_s)

      #      my_vpath = SpinNode.get_vpath(hk)
      my_vpath = SpinNode.get_vpath folder_rec[:spin_node_hashkey]
      #my_vpath = folder_rec[:vpath]
      #      my_vpath=SpinNode.get_virtual_path hk
      if my_vpath == nil or my_vpath.blank?
        rethash[:success] = false
        rethash[:status] = false
        rethash[:errors] = 'アクセス出来ないパスが指定されました'
        return rethash
      end
      new_vpath = my_vpath + '/' + paramshash[:new_folder]
      parent_folder_node = SpinNode.find_by_spin_node_hashkey hk
      if parent_folder_node.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No folder record is found at create_sub_folder 3'
        return rethash
      end
      parent_folder = hk
      #      # get void directory nodes under hk
      #      void_dirs = SpinNode.where(["spin_tree_type = 0 AND node_x_pr_coord = ? AND node_y_coord = ? AND node_type = ? AND is_void = true",pn[:node_x_coord],pn[:node_y_coord] + 1,NODE_DIRECTORY])
      #      void_dirs.each {|vd|
      #        vd.destroy
      #      }

      #      FileManager.rails_logger(">> DatabaseUtility::VirtualFileSystemUtility.search_virtual_file : started at " + Time.now.to_s)
      can_file_nodes = DatabaseUtility::VirtualFileSystemUtility.search_virtual_file my_session_id, paramshash[:new_folder], hk, parent_folder_node[:node_x_coord], parent_folder_node[:node_y_coord], SEARCH_EXISTING_VFILE
      unless can_file_nodes.blank?
        can_file_nodes.each {|canf|
          if canf[:in_trash_flag]
            rethash[:success] = false
            rethash[:status] = ERROR_SAME_FILE_PATH_IN_RECYCLER
            if canf[:node_type] == NODE_FILE
              rethash[:errors] = '同じパス名のファイルがゴミ箱の中にあります'
            else
              rethash[:errors] = '同じパス名のフォルダがゴミ箱の中にあります'
            end
          else
            rethash[:success] = false
            rethash[:status] = ERROR_SAME_FILE_PATH_IN_DIRECTORY
            if canf[:node_type] == NODE_FILE
              rethash[:errors] = '同じパス名のファイルがフォルダの中にあります'
            else
              rethash[:errors] = '同じパス名のフォルダがフォルダの中にあります'
            end
          end
          return rethash
        }
      end

      # Create directory if it isn't there.
      #      FileManager.rails_logger(">> SpinLocationManager.get_location_coordinates : started at " + Time.now.to_s)
      coord_value = SpinLocationManager.get_location_coordinates my_session_id, paramshash[:cont_location], new_vpath, flag_make_dir_if_not_exeits, ACL_NO_VALUE, ACL_NO_VALUE, ACL_NO_VALUE
      if coord_value[X..V] == [-1, -1, -1, -1]
        rethash[:success] = false
        rethash[:status] = false
        rethash[:errors] = coord_value.to_s
      else
        created_folder = coord_value[K]
        #        FileManager.rails_logger(">> FolderDatum.add_folder_rec : started at " + Time.now.to_s)
        FolderDatum.add_folder_rec(my_session_id, coord_value[K], paramshash[:domain_hash_key], paramshash[:cont_location])
        #        FileManager.rails_logger(">>SpinNode.get_parent : started at " + Time.now.to_s)
        #        parent_folder = SpinNode.get_parent(created_folder, NODE_DIRECTORY)
        #        FileManager.rails_logger(">> SpinDomain.get_domain_root_node_key : started at " + Time.now.to_s)
        domain_root_key = domain_root_key = SpinDomain.get_domain_root_node_key(paramshash[:domain_hash_key])
        if parent_folder == domain_root_key
          parent_is_expanded = true
          parent_folder = created_folder
        else
          #        FileManager.rails_logger(">> FolderDatum.is_expanded_folder : started at " + Time.now.to_s)
          parent_is_expanded = FolderDatum.is_expanded_folder(my_session_id, paramshash[:cont_location], parent_folder)
        end
        if parent_is_expanded
          #        FileManager.rails_logger(">> DomainDatum.is_dirty_domain : started at " + Time.now.to_s)
          is_dirty = DomainDatum.is_dirty_domain(my_session_id, paramshash[:cont_location], paramshash[:domain_hash_key])
          if is_dirty
            #        FileManager.rails_logger(">> FolderDatum.reset_partial_root : started at " + Time.now.to_s)
            FolderDatum.reset_partial_root(my_session_id, paramshash[:cont_location], paramshash[:domain_hash_key])
            #        FileManager.rails_logger(">> FolderDatum.fill_folders : started at " + Time.now.to_s)
            FolderDatum.fill_folders(my_session_id, paramshash[:cont_location], paramshash[:domain_hash_key])
            FolderDatum.set_partial_root(my_session_id, paramshash[:cont_location], target_hashkey, paramshash[:domain_hash_key])
            rethash = {:success => true, :status => STAT_DATA_NOT_LOADED_YET, :isDirty => true, :parent_node => parent_folder}
          else
            #        FileManager.rails_logger(">> FolderDatum.load_folder_recs : started at " + Time.now.to_s)
            FolderDatum.load_folder_recs(my_session_id, parent_folder, paramshash[:domain_hash_key], parent_folder, paramshash[:cont_location], DEPTH_TO_TRAVERSE, SessionManager.get_last_session(my_session_id))
            #        FileManager.rails_logger(">> FolderDatum.select_folder : started at " + Time.now.to_s)
            FolderDatum.select_folder(my_session_id, parent_folder, paramshash[:cont_location], paramshash[:domain_hash_key])
            #        FileManager.rails_logger(">> FolderDatum.reset_partial_root : started at " + Time.now.to_s)
            FolderDatum.reset_partial_root(my_session_id, paramshash[:cont_location], paramshash[:domain_hash_key])
            #        FileManager.rails_logger(">> FolderDatum.set_partial_root : started at " + Time.now.to_s)
            FolderDatum.set_partial_root(my_session_id, paramshash[:cont_location], target_hashkey, paramshash[:domain_hash_key])
            rethash = {:success => true, :status => STAT_DATA_NOT_LOADED_YET, :isDirty => false, :parent_node => parent_folder}
          end
        else
          #        FileManager.rails_logger(">> DomainDatum.is_dirty_domain : started at " + Time.now.to_s)
          is_dirty = DomainDatum.is_dirty_domain(my_session_id, paramshash[:cont_location], paramshash[:domain_hash_key])
          if is_dirty
            #        FileManager.rails_logger(">> FolderDatum.reset_partial_root : started at " + Time.now.to_s)
            FolderDatum.reset_partial_root(my_session_id, paramshash[:cont_location], paramshash[:domain_hash_key])
            #        FileManager.rails_logger(">> FolderDatum.fill_folders : started at " + Time.now.to_s)
            FolderDatum.fill_folders(my_session_id, paramshash[:cont_location], paramshash[:domain_hash_key])
            #        FileManager.rails_logger(">> FolderDatum.select_folder : started at " + Time.now.to_s)
            FolderDatum.select_folder(my_session_id, parent_folder, paramshash[:cont_location], paramshash[:domain_hash_key])
            FolderDatum.set_partial_root(my_session_id, paramshash[:cont_location], target_hashkey, paramshash[:domain_hash_key])
            rethash = {:success => true, :status => STAT_DATA_NOT_LOADED_YET, :isDirty => true, :parent_node => parent_folder}
          else
            #        FileManager.rails_logger(">> FolderDatum.load_folder_recs : started at " + Time.now.to_s)
            FolderDatum.load_folder_recs(my_session_id, parent_folder, paramshash[:domain_hash_key], parent_folder, paramshash[:cont_location], DEPTH_TO_TRAVERSE, SessionManager.get_last_session(my_session_id))
            #        FileManager.rails_logger(">> FolderDatum.select_folder : started at " + Time.now.to_s)
            FolderDatum.select_folder(my_session_id, parent_folder, paramshash[:cont_location], paramshash[:domain_hash_key])
            #        FileManager.rails_logger(">> FolderDatum.reset_partial_root : started at " + Time.now.to_s)
            FolderDatum.reset_partial_root(my_session_id, paramshash[:cont_location], paramshash[:domain_hash_key])
            #        FileManager.rails_logger(">> FolderDatum.set_partial_root : started at " + Time.now.to_s)
            FolderDatum.set_partial_root(my_session_id, paramshash[:cont_location], target_hashkey, paramshash[:domain_hash_key])
            rethash = {:success => true, :status => STAT_DATA_NOT_LOADED_YET, :isDirty => false, :parent_node => parent_folder}
          end
        end
        FolderDatum.select_folder my_session_id, parent_folder, paramshash[:cont_location], paramshash[:domain_hash_key]
        locations = CONT_LOCATIONS_LIST
        locations -= [paramshash[:cont_location]]
        #        FolderDatum.select_folder my_session_id, parent_folder, paramshash[:cont_location], paramshash[:domain_hash_key]
        #        FileManager.rails_logger(">> FolderDatum.has_updated : started at " + Time.now.to_s)
        FolderDatum.has_updated(my_session_id, parent_folder, NEW_CHILD)
        #        locations.each {|loc|
        ##        FileManager.rails_logger(">> FolderDatum.copy_folder_data_from_location_to_location : started at " + Time.now.to_s)
        #          reth = FolderDatum.copy_folder_data_from_location_to_location my_session_id, paramshash[:cont_location], loc, paramshash[:domain_hash_key]
        #        }\\\\\
        DomainDatum.set_domain_dirty(my_session_id, paramshash[:cont_location], paramshash[:domain_hash_key])
        #        FolderDatum.set_parent_folders_dirty target_hash_key
        #        FolderDatum.set_folder_dirty target_hash_key
        FileManager.rails_logger(">> create_sub_folder : finished at " + Time.now.to_s)
        FileDatum.fill_file_list my_session_id, paramshash[:cont_location], target_hashkey
      end
    when 'create_root_folder'
      # coord_value is an array : [x,y,prx,v,h]
      error_coord = [-1, -1, -1, -1]
      flag_make_dir_if_not_exeits = true
      hk = nil
      if paramshash[:folder_hash_key]
        hk = paramshash[:folder_hash_key]
      elsif paramshash[:hash_key]
        hk = paramshash[:hash_key]
      else
        hk = nil
      end
      # current_dir = DatabaseUtility::SessionUtility.get_current_directory my_session_id
      coord_value = SpinLocationManager.get_location_coordinates my_session_id, 'root_node_location', paramshash[:new_folder_name], flag_make_dir_if_not_exeits, ACL_NO_VALUE, ACL_NO_VALUE, ACL_NO_VALUE
      # coord_value = SpinLocationManager.get_location_coordinates paramshash[:new_root_folder], flag_make_dir_if_not_exeits
      if coord_value[X..V] == error_coord
        rethash[:success] = false
        rethash[:status] = false
        rethash[:errors] = coord_value.to_s
      else
        rethash[:success] = true
        rethash[:status] = true
        rethash[:result] = coord_value
        hash_key = SpinLocationManager.location_to_key(coord_value, NODE_DIRECTORY)
        DomainDatum.domains_have_updated(my_session_id, SpinNode.get_domains(hash_key))
        FolderDatum.has_updated(my_session_id, hash_key, NEW_CHILD)
        #        FolderDatum.set_folder_dirty hash_key
      end
    when 'create_folder'
      # coord_value is an array : [x,y,prx,v,h]
      error_coord = [-1, -1, -1, -1]
      flag_make_dir_if_not_exeits = true
      hk = nil
      if paramshash[:folder_hash_key]
        hk = paramshash[:folder_hash_key]
      elsif paramshash[:hash_key]
        hk = paramshash[:hash_key]
      else
        hk = nil
      end
      #      current_dir = DatabaseUtility::SessionUtility.get_current_directory my_session_id
      coord_value = SpinLocationManager.get_location_coordinates my_session_id, paramshash[:cont_location], paramshash[:new_root_folder], flag_make_dir_if_not_exeits, ACL_NO_VALUE, ACL_NO_VALUE, ACL_NO_VALUE
      if coord_value[X..V] == error_coord
        rethash[:success] = false
        rethash[:status] = false
        rethash[:errors] = coord_value.to_s
      else
        rethash[:success] = true
        rethash[:status] = true
        rethash[:result] = coord_value
        #        DomainDatum.domains_have_updated( my_session_id, SpinNode.get_domains( SpinLocationManager.location_to_key(coord_value, NODE_DIRECTORY) ) )
        target_hash_key = SpinLocationManager.location_to_key(coord_value, NODE_DIRECTORY)
        DomainDatum.domains_have_updated(my_session_id, SpinNode.get_domains(target_hash_key))
        FolderDatum.has_updated(my_session_id, target_hash_key, NEW_CHILD)
      end
    when 'ui_upload_file'
      # create meta data for uploading file
      # //items[0].value (request_type   =) "upload_file"
      # //items[1].value (session_id     =) ********
      # //items[2].value (cont_location  =) "folder_a"/"folder_b"
      # //items[3].value (hash_key       =) ************
      # //items[4].value (text           =) upload先フォルダ名
      # //items[5].value (upload_filename=) uploadファイル名
      # //items[6].value (another_name   =) uploadファイル名(session_id + hashkey)    # then return redirect url of file manager
      unless FileManager.is_alive(my_session_id) == true
        # => not writable
        rethash[:success] = false
        rethash[:status] = ERROR_SYSTEM_FILE_MANAGER_DIED
        return rethash
      end
      if FileManager.is_busy
        # => not writable
        rethash[:success] = false
        rethash[:status] = ERROR_SYSTEM_FILE_MANAGER_BUSY
        return rethash
      end
      upload_file_name = paramshash[:upload_filename].gsub("C:\\fakepath\\", "")
      upload_dir_key = paramshash[:text]
      paramshash.keys.each {|k| printf "%s = %s\n", k, paramshash[k]}
      upload_sid = my_session_id
      folder_data_rec = FolderDatum.find_by_hash_key paramshash[:hash_key]
      if folder_rec.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No folder record is found at ui_upload_file'
        return rethash
      end
      upload_dir_key = folder_data_rec[:spin_node_hashkey]

      pcnode = nil
      file_nodes = DatabaseUtility::VirtualFileSystemUtility.search_virtual_file upload_sid, upload_file_name, upload_dir_key, ANY_VALUE, ANY_VALUE, SEARCH_EXISTING_VFILE
      vfile_key = ''
      file_nodes.each {|file_node|
        if file_node[:latest]
          pcnode = file_node
        end
        if file_node[:in_trash_flag]
          rethash[:success] = false
          rethash[:status] = ERROR_SAME_FILE_PATH_IN_RECYCLER
          rethash[:errors] = '同じパス名のファイルがゴミ箱の中にあります'
          return rethash
        end
        next if file_node[:is_pending] or file_node[:is_void]
        # => yes there is!
        unless SpinAccessControl.is_writable upload_sid, file_node[:spin_node_hashkey], ACL_TYPE_FILE
          # => not writable
          rethash[:success] = false
          rethash[:status] = ERROR_NOT_WRITABLE
          rethash[:errors] = 'ファイルを書き込む権限が有りません'
          return rethash
        else
          break
        end
      }
      vloc = NoXYPV
      # => Is there a node that is pending upload status?
      if pcnode.present?

        ActiveRecord::Base.lock_optimistically = false
        catch(:update_spin_nodes_again) {
          SpinLocationMapping.trasnaction do
            begin
              pclocman = SpinLocationMapping.readonly.find_by_node_hash_key(pcnode[:spin_node_hashkey])
              if pclocman.present?
                if pclocman[:size_of_data] == pcnode[:node_size] and pclocman[:size_of_data_upper] == pcnode[:node_size_upper] # => upload is completed
                  vloc = SpinNode.create_virtual_file upload_sid, upload_file_name, upload_dir_key, REQUEST_VERSION_NUMBER, nil, true, true
                else # => upload is not completed
                  vloc[X] = pcnode[:node_x_coord]
                  vloc[Y] = pcnode[:node_y_coord]
                  vloc[PRX] = pcnode[:node_x_pr_coord]
                  vloc[V] = pcnode[:node_version]
                  vloc[K] = pcnode[:spin_node_hashkey]
                end
              else # => There is a node record but no location mapping record
                vloc[X] = pcnode[:node_x_coord]
                vloc[Y] = pcnode[:node_y_coord]
                vloc[PRX] = pcnode[:node_x_pr_coord]
                vloc[V] = pcnode[:node_version]
                vloc[K] = pcnode[:spin_node_hashkey]
              end
              pcnode[:is_pending] = false
              pcnode.save
            rescue ActiveRecord::StaleObjectError
              sleep(AR_RETRY_WAIT_MSEC)
              throw :update_spin_nodes_again
            end
          end # => end of transaction
        }
      else
        vloc = SpinNode.create_virtual_file upload_sid, upload_file_name, upload_dir_key, REQUEST_VERSION_NUMBER, nil, true, true
      end
      vfile_key = vloc[K]
      if vfile_key == nil
        # => failed to create new node ( may be another process is uploading file at the same location )
        msg = 'Error : failed to create virtual file at upload_file : [' + upload_sid + ', ' + upload_file_name + ', ' + upload_dir_key + ']'
        FileManager.rails_logger(msg)
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_CREATE_NEW_NODE_REC
        return rethash
      end
      rsa_key_pem = SpinNode.get_root_rsa_key
      pdata = ''
      fmargs = ''
      retry_encrypt = ENCRYPTION_RETRY_COUNT
      catch(:encrypt_again_6) {
        begin
          pdata = my_session_id + vfile_key + upload_file_name
          # make encrypted data
          file_manager_params = Security.public_key_encrypt2 rsa_key_pem, pdata
          # and encode into base64
          # fmargs = file_manager_params
          enc_len = file_manager_params[:data].length
          if enc_len < (KEY_SIZE / 8)
            if retry_encrypt > 0
              retry_encrypt -= 1
              sleep(AR_RETRY_WAIT_MSEC)
              throw :encrypt_again_6
            end
          end
          fmargs = Security.urlsafe_encode_base64(file_manager_params[:length].to_s + file_manager_params[:data])
          if ENV['RAILS_ENV'] != 'production'
            my_host = $http_host.split(/:|\//)[-2]
            # => get URL server
            my_url_host = SpinFileServer.find_by_server_port(SYSTEM_DEFAULT_SPIN_SERVER_PORT)
            if my_url_host.present?
              my_host = my_url_host[:spin_url_server_name]
            end
            #          if my_host.length == 2
            rethash[:redirect_uri] = my_host + "/secret_files/uploader/upload_proc?fmargs=" + fmargs
          else
            rethash[:redirect_uri] = '/secret_files/uploader/upload_proc?fmargs=' + fmargs
          end
          #          my_host = $http_host.split(/:/)
          #          if my_host.length == 2
          #            rethash[:redirect_uri] = "http://#{my_host[0]}:18881/filemanager/uploader/upload_proc?fmargs=" + fmargs
          #          else
          #            rethash[:redirect_uri] = '/secret_files/uploader/upload_proc?fmargs=' + fmargs
          #          end
          rethash[:success] = true
          FolderDatum.set_folder_dirty my_session_id, upload_dir_key
        rescue OpenSSL::PKey::RSAError
          if retry_encrypt > 0
            retry_encrypt -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :encrypt_again_6
          end
          rethash[:success] = false
          rethash[:status] = ERROR_UPLOAD_FILE
          rethash[:errors] = 'Failed to generate encrypted URL by OpenSSL::PKey::RSA'
        rescue
          if retry_encrypt > 0
            retry_encrypt -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :encrypt_again_6
          end
          rethash[:success] = false
          rethash[:status] = ERROR_UPLOAD_FILE
          rethash[:errors] = 'Failed to generate encrypted urlsafe URL'
        end
      }
    when 'create_thumbnail'
      unless FileManager.is_alive(my_session_id) == true
        rethash[:success] = false
        rethash[:status] = ERROR_SYSTEM_FILE_MANAGER_DIED
        return rethash
      end
      if FileManager.is_busy
        rethash[:success] = false
        rethash[:status] = ERROR_SYSTEM_FILE_MANAGER_BUSY
        return rethash
      end
      unless paramshash[:hash_key]
        msg = 'Error : failed to create thumbnail file : hash_key is not specified'
        FileManager.rails_logger(msg)
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_CREATE_THUMBNAIL
        rethash[:errors] = msg
        return rethash
      end
      thumbnail_hash_key = paramshash[:hash_key]
      thumbnail_file_name = paramshash[:file_name]
      respj = SpinNode.create_thumbnail_file(my_session_id, thumbnail_hash_key, thumbnail_file_name)
      FileManager.rails_logger(respj.to_s)
      reth = JSON.parse(respj.to_s)
      unless reth["success"]
        # => failed to create new node ( may be another process is uploading file at the same location )
        msg = 'Error : failed to create thumbnail file for : [' + my_session_id + ', ' + thumbnail_hash_key + ':' + ']'
        FileManager.rails_logger(msg)
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_CREATE_THUMBNAIL
        rethash[:errors] = msg
        return rethash
      end

      rethash[:success] = true
      rethash[:status] = INFO_CREATE_THUMBNAIL_SUCCESS
      rethash[:result] = reth["result"]

    when 'remove_thumbnail'
      unless FileManager.is_alive(my_session_id) == true
        rethash[:success] = false
        rethash[:status] = ERROR_SYSTEM_FILE_MANAGER_DIED
        return rethash
      end
      if FileManager.is_busy
        rethash[:success] = false
        rethash[:status] = ERROR_SYSTEM_FILE_MANAGER_BUSY
        return rethash
      end
      unless paramshash[:hash_key]
        msg = 'Error : failed to remove thumbnail file : hash_key is not specified'
        FileManager.rails_logger(msg)
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_REMOVE_THUMBNAIL
        rethash[:errors] = msg
        return rethash
      end
      thumbnail_hash_key = paramshash[:hash_key]
      # check thumbnail is or not
      thumbnail_is = SpinLocationManager.thumbnail_exists(thumbnail_hash_key)
      unless thumbnail_is
        msg = 'Error : No thumbnail file for : [' + my_session_id + ', ' + thumbnail_hash_key + ':' + ']'
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_REMOVE_THUMBNAIL
        rethash[:errors] = msg
        return rethash
      end
      respj = SpinNode.remove_thumbnail_file(my_session_id, thumbnail_hash_key)
      #respj.to_s: ファイルマネージャに返すときは文字列に変換して渡さなければならない。
      FileManager.rails_logger(respj.to_s)
      reth = JSON.parse(respj.to_s)
      unless reth["success"]
        # => failed to create new node ( may be another process is uploading file at the same location )
        msg = 'Error : failed to remove thumbnail file for : [' + my_session_id + ', ' + thumbnail_hash_key + ':' + ']'
        FileManager.rails_logger(msg)
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_REMOVE_THUMBNAIL
        rethash[:errors] = msg
        return rethash
      end

      rethash[:success] = true
      rethash[:status] = INFO_CREATE_THUMBNAIL_SUCCESS
      rethash[:result] = reth["result"]

    when 'set_dir_sticky'
      my_uid = ANY_UID
      node_hash_key = ''
      if paramshash[:user_name]
        my_uid = SpinUser.get_uid(paramshash[:user_name])
      end
      if paramshash[:hash_key]
        node_hash_key = paramshash[:hash_key]
      end
      respb = SpinNode.set_sticky(my_session_id, node_hash_key, my_uid)
      unless respb
        # => failed to create new node ( may be another process is uploading file at the same location )
        msg = 'Error : failed to set directory sticky : [' + my_session_id + ', ' + node_hash_key + ':' + ']'
        FileManager.rails_logger(msg)
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_SET_DIRECTORY_STICKY
        rethash[:errors] = 'スティッキービットの設定に失敗しました'
        return rethash
      end

      rethash[:success] = true
      rethash[:status] = INFO_SET_DIRECTORY_STICKY_SUCCESS

    when 'reset_dir_sticky'
      my_uid = ANY_UID
      node_hash_key = ''
      if paramshash[:user_name]
        my_uid = SpinUser.get_uid(paramshash[:user_name])
      end
      if paramshash[:hash_key]
        node_hash_key = paramshash[:hash_key]
      end
      respb = SpinNode.set_sticky(my_session_id, node_hash_key, my_uid)
      unless respb
        # => failed to create new node ( may be another process is uploading file at the same location )
        msg = 'Error : failed to reset directory sticky : [' + my_session_id + ', ' + node_hash_key + ':' + ']'
        FileManager.rails_logger(msg)
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_SET_DIRECTORY_STICKY
        rethash[:errors] = 'スティッキービットのリセットに失敗しました'
        return rethash
      end

      rethash[:success] = true
      rethash[:status] = INFO_SET_DIRECTORY_STICKY_SUCCESS

    when 'recover_trash_error'
      respb = RecyclerDatum.recover_pending_trash_operation(my_session_id)
      unless respb
        # => failed to create new node ( may be another process is uploading file at the same location )
        msg = 'Error : failed to recover nodes from trashbox : [' + my_session_id + ']'
        FileManager.rails_logger(msg)
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_RECOVER_TRAHSH_ERROR
        return rethash
      end

      rethash[:success] = true
      rethash[:status] = INFO_RECOVER_TRAHSH_ERROR_SUCCESS

    when 'upload_file'
      # create meta data for uploading file
      # //items[0].value (request_type   =) "upload_file"
      # //items[1].value (session_id     =) ********
      # //items[2].value (cont_location  =) "folder_a"/"folder_b"
      # //items[3].value (hash_key       =) ************
      # //items[4].value (text           =) upload先フォルダ名de
      # //items[5].value (upload_filename=) uploadファイル名
      # //items[6].value (another_name   =) uploadファイル名(session_id + hashkey)    # then return redirect url of file manager
      #      upload_file_name = paramshash[:upload_filename].gsub("C:\\fakepath\\","")
      unless FileManager.is_alive(my_session_id) == true
        # => not writable
        rethash[:success] = false
        rethash[:status] = ERROR_SYSTEM_FILE_MANAGER_DIED
        rethash[:errors] = 'A file manager, you cannot communicate.'
        FileManager.rails_logger(rethash[:errors])
        FileManager.logger(my_session_id, rethash[:errors])
        return rethash
      end
      if FileManager.is_busy
        # => not writable
        rethash[:success] = false
        rethash[:status] = ERROR_SYSTEM_FILE_MANAGER_BUSY
        rethash[:errors] = 'A file manager is Busy. Please communicate after it has passed for a while.'
        FileManager.rails_logger(rethash[:errors])
        FileManager.logger(my_session_id, rethash[:errors])
        return rethash
      end
      upload_file_name = paramshash[:upload_filename].gsub(/\\u([\da-fA-F]{4})/) {[$1].pack('H*').unpack('n*').pack('U*')}
      if paramshash[:upload_filename].include?('\\')
        tmp_path_array = paramshash[:upload_filename].split(/\\/)
        upload_file_name = tmp_path_array[-1]
      end
      upload_dir_key = ''
      paramshash.keys.each {|k| printf "%s = %s\n", k, paramshash[k]}
      upload_sid = my_session_id
      upload_uid = SessionManager.get_uid(upload_sid, true)
      target_hashkey = nil
      #      folder_data_rec = FolderDatum.find_by_hash_key paramshash[:hash_key]
      user_agent = $http_user_agent
      #if /HTTP_Request2.+/ =~ user_agent # => PHP API
      if user_agent == "BoomboxAPI" # => PHP API
        upload_dir_key = paramshash[:hash_key]
      else # => from UI
        if paramshash[:original_place] == 'folder_tree' # it is in folder tree
          folder_rec = FolderDatum.find_by_hash_key paramshash[:hash_key]
          unless folder_rec.blank?
            upload_dir_key = folder_rec[:spin_node_hashkey]
          else
            upload_dir_key = paramshash[:hash_key]
          end
          #upload_dir_key = folder_rec[:spin_node_hashkey]
        else
          folder_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
          unless folder_rec.blank?
            upload_dir_key = folder_rec[:spin_node_hashkey]
          else
            upload_dir_key = paramshash[:hash_key]
          end
          #upload_dir_key = folder_rec[:spin_node_hashkey]
        end
        #        folder_data_rec = FolderDatum.find_by_hash_key paramshash[:hash_key]
        #        upload_dir_key = folder_data_rec[:spin_node_hashkey]
      end
      pcnode = nil
      my_upload_file_name = ''
      vloc = NoXYPV
      vfile_key = ''
      SpinAccessControl.transaction do
        #        SpinLockSpinNodes.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        #        SpinLockSpinNodes.find_by_sql('LOCK TABLE spin_lock_spin_nodes IN EXCLUSIVE MODE;')
        #        lock_records = SpinLockSpinNodes.find(1)
        file_nodes = DatabaseUtility::VirtualFileSystemUtility.search_virtual_file upload_sid, upload_file_name, upload_dir_key, ANY_VALUE, ANY_VALUE, SEARCH_EXISTING_VFILE
        if file_nodes.size() > 0
          file_nodes.each {|file_node|
            if file_node[:latest]
              if FSTAT_WRITE_LOCKED == file_node[:lock_mode] && FSTAT_LOCKED == file_node[:lock_status]
                if upload_uid != file_node[:lock_uid] && -1 != file_node[:lock_uid]
                  rethash[:success] = false
                  rethash[:status] = ERROR_UPLOAD_FILE
                  #rethash[:errors] = '他のユーザーにロックされているファイルはアップロードできません'
                  rethash[:errors] = 'The other users cannot upload a locked file.'
                  return rethash
                end
              end
              pcnode = file_node
            end
            if file_node[:in_trash_flag]
              rethash[:success] = false
              rethash[:status] = ERROR_SAME_FILE_PATH_IN_RECYCLER
              rethash[:errors] = 'A file of the same pathname is in the trash can.'
              #rethash[:errors] = '同じパス名のファイルがゴミ箱の中にあります'
              FileManager.rails_logger(rethash[:errors])
              FileManager.logger(my_session_id, rethash[:errors])
              return rethash
            end
            next if file_node[:is_pending] or file_node[:is_void]
            # => yes there is!
            unless SpinAccessControl.is_writable upload_sid, file_node[:spin_node_hashkey], ACL_TYPE_FILE
              # => not writable
              rethash[:success] = false
              rethash[:status] = ERROR_NOT_WRITABLE
              rethash[:errors] = 'ファイルを書き込む権限が有りません'
              #rethash[:errors] = 'ファイルを書き込む権限が有りません'
              FileManager.rails_logger(rethash[:errors])
              FileManager.logger(my_session_id, rethash[:errors])
              return rethash
            else
              break
            end
          }
        end
        my_upload_file_name = upload_file_name
      end # => end of transaction

      # => Is there a node that is pending upload status?
      if pcnode.present?
        catch(:update_spin_nodes_again) {
          SpinLocationMapping.transaction do
            begin
              pclocman = SpinLocationMapping.readonly.find_by_node_hash_key(pcnode[:spin_node_hashkey])
              if pclocman.present?
                if pclocman[:size_of_data] == pcnode[:node_size] and pclocman[:size_of_data_upper] == pcnode[:node_size_upper] # => upload is completed
                  vloc = SpinNode.create_virtual_file upload_sid, upload_file_name, upload_dir_key, REQUEST_VERSION_NUMBER, nil, true, true
                else # => upload is not completed
                  vloc[X] = pcnode[:node_x_coord]
                  vloc[Y] = pcnode[:node_y_coord]
                  vloc[PRX] = pcnode[:node_x_pr_coord]
                  vloc[V] = pcnode[:node_version]
                  vloc[K] = pcnode[:spin_node_hashkey]
                end
              else # => There is a node record but no location mapping record
                vloc[X] = pcnode[:node_x_coord]
                vloc[Y] = pcnode[:node_y_coord]
                vloc[PRX] = pcnode[:node_x_pr_coord]
                vloc[V] = pcnode[:node_version]
                vloc[K] = pcnode[:spin_node_hashkey]
              end
              pcnode[:is_pending] = false
              pcnode.save
            rescue ActiveRecord::StaleObjectError
              sleep(AR_RETRY_WAIT_MSEC)
              throw :update_spin_nodes_again
            end
          end # => end of transaction
        } # => end of catch
      else
        vloc = SpinNode.create_virtual_file upload_sid, upload_file_name, upload_dir_key, REQUEST_VERSION_NUMBER, nil, true, true
      end
      vfile_key = vloc[K]
      #      vfile_key = SpiNode.create_virtual_file upload_sid, upload_file_name, upload_dir_key, nil, true, true
      if vfile_key == nil
        # => failed to create new node ( may be another process is uploading file at the same location )
        msg = 'Error : failed to create virtual file at upload_file : [' + upload_sid + ', ' + upload_file_name + ', ' + upload_dir_key + ']'
        FileManager.rails_logger(msg)
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_CREATE_NEW_NODE_REC
        rethash[:errors] = msg
        FileManager.rails_logger(rethash[:errors])
        FileManager.logger(my_session_id, rethash[:errors])
        return rethash
      end
      # ロック状態引き継ぎ
      if nil != pcnode
        spin_node_upd = Hash.new
        spin_node_upd[:upd_lock_uid] = pcnode[:lock_uid]
        spin_node_upd[:upd_lock_status] = pcnode[:lock_status]
        spin_node_upd[:upd_lock_mode] = pcnode[:lock_mode]
        lock_ret = SpinNode.set_lock upload_uid, upload_dir_key, upload_file_name, upload_sid, spin_node_upd
        if !lock_ret
          rethash[:success] = false
          rethash[:status] = ERROR_UPLOAD_FILE
          rethash[:errors] = "Failed to set lock of " + upload_file_name
          FileManager.rails_logger(rethash[:errors])
          FileManager.logger(my_session_id, rethash[:errors])
          return rethash
        end
      end

      rsa_key_pem = SpinNode.get_root_rsa_key
      pdata = ''
      fmargs = ''
      retry_encrypt = ENCRYPTION_RETRY_COUNT
      catch(:encrypt_again_7) {
        begin
          pdata = my_session_id + vfile_key + upload_file_name
          # make encrypted data
          file_manager_params = Security.public_key_encrypt2 rsa_key_pem, pdata
          # and encode into base64
          # fmargs = file_manager_params
          enc_len = file_manager_params[:data].length
          if enc_len < (KEY_SIZE / 8)
            if retry_encrypt > 0
              retry_encrypt -= 1
              sleep(AR_RETRY_WAIT_MSEC)
              throw :encrypt_again_7
            end
          end
          fmargs = Security.urlsafe_encode_base64(file_manager_params[:length].to_s + file_manager_params[:data])
          if ENV['RAILS_ENV'] != 'production'
            my_host = $http_host.split(/:|\//)[-2]
            # => get URL server
            my_url_host = SpinFileServer.find_by_server_port(SYSTEM_DEFAULT_SPIN_SERVER_PORT)
            if my_url_host.present?
              my_host = my_url_host[:spin_url_server_name]
            end
            #          if my_host.length == 2
            rethash[:redirect_uri] = my_host + "/secret_files/uploader/upload_proc?fmargs=" + fmargs
          else
            rethash[:redirect_uri] = '/secret_files/uploader/upload_proc?fmargs=' + fmargs
          end
          rethash[:success] = true
          FolderDatum.set_folder_dirty my_session_id, upload_dir_key
        rescue OpenSSL::PKey::RSAError
          if retry_encrypt > 0
            retry_encrypt -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :encrypt_again_7
          end
          rethash[:success] = false
          rethash[:status] = ERROR_UPLOAD_FILE
          rethash[:errors] = 'Failed to generate encrypted URL by OpenSSL::PKey::RSA'
          FileManager.rails_logger(rethash[:errors])
          FileManager.logger(my_session_id, rethash[:errors])
        rescue
          if retry_encrypt > 0
            retry_encrypt -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :encrypt_again_7
          end
          rethash[:success] = false
          rethash[:status] = ERROR_UPLOAD_FILE
          rethash[:errors] = 'Failed to generate encrypted urlsafe URL'
          FileManager.rails_logger(rethash[:errors])
          FileManager.logger(my_session_id, rethash[:errors])
        end
      }

      unless $http_user_agent == 'BoomboxAPI'
        target_folder = FolderDatum.find_by_session_id_and_spin_node_hashkey(my_session_id, upload_dir_key)
        #        target_folder = FolderDatum.get_parent_folder(my_session_id, upload_dir_key);
        if target_folder.present?
          target_hashkey = target_folder[:spin_node_hashkey]
        else
          target_hashkey = SessionManager.get_selected_folder(my_session_id, "folder_a")
        end
        #        FolderDatum.set_partial_root(my_session_id,paramshash[:cont_location], upload_dir_key)F
        unless FolderDatum.is_dirty_folder(my_session_id, 'folder_a', target_hashkey)
          session_rec = SpinSession.readonly.find_by_spin_session_id my_session_id
          if session_rec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'No folder record is found at upload_file'
            return rethash
          end
          FolderDatum.fill_folders(paramshash[:session_id], "folder_a", session_rec[:selected_domain_a], target_hashkey, PROCESS_FOR_UNIVERSAL_REQUEST, false, 3)
          FolderDatum.has_updated(upload_sid, upload_dir_key, NEW_CHILD, true)
          #FolderDatum.add_child_to_parent upload_dir_key, target_hashkey, my_session_id
          FolderDatum.set_folder_dirty upload_sid, target_hashkey
          #          FolderDatum.set_parent_folders_dirty target_hashkey
        end

        FileDatum.fill_file_list paramshash[:session_id], "folder_a", target_hashkey
        res_msg = '>> upload_file (Rails) : result = ' + rethash.to_s
        FileManager.logger(my_session_id, res_msg, 'LOCAL')
      else
        res_msg = '>> upload_file (BoomboxAPI) : result = ' + rethash.to_s
        FileManager.logger(my_session_id, res_msg, 'LOCAL')
      end # => end of UI agent
    when 'upload_file_virtual_path'
      # create meta data for uploading file
      # //items[0].value (request_type   =) "upload_file"
      # //items[1].value (session_id     =) ********
      # //items[2].value (cont_location  =) "folder_a"/"folder_b"
      # //items[3].value (hash_key       =) ************
      # //items[4].value (text           =) upload先フォルダ名de
      # //items[5].value (upload_filename=) uploadファイル名
      # //items[6].value (another_name   =) uploadファイル名(session_id + hashkey)    # then return redirect url of file manager
      #      upload_file_name = paramshash[:upload_filename].gsub("C:\\fakepath\\","")
      unless FileManager.is_alive(my_session_id) == true
        # => not writable
        rethash[:success] = false
        rethash[:status] = ERROR_SYSTEM_FILE_MANAGER_DIED
        return rethash
      end
      if FileManager.is_busy
        # => not writable
        rethash[:success] = false
        rethash[:status] = ERROR_SYSTEM_FILE_MANAGER_BUSY
        return rethash
      end
      upload_file_name = paramshash[:upload_filename]
      if paramshash[:upload_filename].include?('\\')
        tmp_path_array = paramshash[:upload_filename].split(/\\/)
        upload_file_name = tmp_path_array[-1]
      end
      upload_dir_key = ''
      upload_dir_vpath = ''
      paramshash.keys.each {|k| printf "%s = %s\n", k, paramshash[k]}
      upload_sid = my_session_id
      upload_uid = SessionManager.get_uid(upload_sid, true)
      upload_dir_vpath = paramshash[:upload_directory]
      upload_dir_key = SpinLocationManager.get_vpath_key(upload_dir_vpath)
      pcnode = nil
      file_nodes = DatabaseUtility::VirtualFileSystemUtility.search_virtual_file upload_sid, upload_file_name, upload_dir_key, ANY_VALUE, ANY_VALUE, SEARCH_EXISTING_VFILE
      vfile_key = ''
      if file_nodes.size() > 0
        file_nodes.each {|file_node|
          if file_node[:latest]
            if FSTAT_WRITE_LOCKED == file_node[:lock_mode] && FSTAT_LOCKED == file_node[:lock_status]
              if upload_uid != file_node[:lock_uid] && -1 != file_node[:lock_uid]
                rethash[:success] = false
                rethash[:status] = ERROR_UPLOAD_FILE
                rethash[:errors] = '他のユーザーにロックされているファイルはアップロードできません'
                return rethash
              end
            end
            pcnode = file_node
          end
          if file_node[:in_trash_flag]
            rethash[:success] = false
            rethash[:status] = ERROR_SAME_FILE_PATH_IN_RECYCLER
            rethash[:errors] = '同じパス名のファイルがゴミ箱の中にあります'
            return rethash
          end
          next if file_node[:is_pending] or file_node[:is_void]
          # => yes there is!
          unless SpinAccessControl.is_writable upload_sid, file_node[:spin_node_hashkey], ACL_TYPE_FILE
            # => not writable
            rethash[:success] = false
            rethash[:status] = ERROR_NOT_WRITABLE
            rethash[:errors] = 'ファイルを書き込む権限が有りません'
            return rethash
          else
            break
          end
        }
      end
      my_upload_file_name = upload_file_name
      vloc = NoXYPV
      # => Is there a node that is pending upload status?
      if pcnode.present?
        pclocman = SpinLocationMapping.readonly.find_by_node_hash_key(pcnode[:spin_node_hashkey])
        if pclocman.present?
          if pclocman[:size_of_data] == pcnode[:node_size] and pclocman[:size_of_data_upper] == pcnode[:node_size_upper] # => upload is completed
            vloc = SpinNode.create_virtual_file upload_sid, upload_file_name, upload_dir_key, REQUEST_VERSION_NUMBER, nil, true, true
          else # => upload is not completed
            vloc[X] = pcnode[:node_x_coord]
            vloc[Y] = pcnode[:node_y_coord]
            vloc[PRX] = pcnode[:node_x_pr_coord]
            vloc[V] = pcnode[:node_version]
            vloc[K] = pcnode[:spin_node_hashkey]
          end
        else # => There is a node record but no location mapping record
          vloc[X] = pcnode[:node_x_coord]
          vloc[Y] = pcnode[:node_y_coord]
          vloc[PRX] = pcnode[:node_x_pr_coord]
          vloc[V] = pcnode[:node_version]
          vloc[K] = pcnode[:spin_node_hashkey]
        end
        pcnode[:is_pending] = false
        pcnode.save
      else
        vloc = SpinNode.create_virtual_file upload_sid, upload_file_name, upload_dir_key, REQUEST_VERSION_NUMBER, nil, true, true
      end
      vfile_key = vloc[K]
      #      vfile_key = SpiNode.create_virtual_file upload_sid, upload_file_name, upload_dir_key, nil, true, true
      if vfile_key == nil
        # => failed to create new node ( may be another process is uploading file at the same location )
        msg = 'Error : failed to create virtual file at upload_file : [' + upload_sid + ', ' + upload_file_name + ', ' + upload_dir_key + ']'
        FileManager.rails_logger(msg)
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_CREATE_NEW_NODE_REC
        return rethash
      end
      # ロック状態引き継ぎ
      if nil != pcnode
        spin_node_upd = Hash.new
        spin_node_upd[:upd_lock_uid] = pcnode[:lock_uid]
        spin_node_upd[:upd_lock_status] = pcnode[:lock_status]
        spin_node_upd[:upd_lock_mode] = pcnode[:lock_mode]
        lock_ret = SpinNode.set_lock upload_uid, upload_dir_key, upload_file_name, upload_sid, spin_node_upd
        if !lock_ret
          rethash[:success] = false
          rethash[:status] = ERROR_UPLOAD_FILE
          rethash[:errors] = "Failed to set lock of " + upload_file_name
          return rethash
        end
      end
      rsa_key_pem = SpinNode.get_root_rsa_key
      pdata = ''
      fmargs = ''
      retry_encrypt = ENCRYPTION_RETRY_COUNT
      catch(:encrypt_again_8) {
        begin
          pdata = my_session_id + vfile_key + upload_file_name
          # make encrypted data
          file_manager_params = Security.public_key_encrypt2 rsa_key_pem, pdata
          # and encode into base64
          # fmargs = file_manager_params
          enc_len = file_manager_params[:data].length
          if enc_len < (KEY_SIZE / 8)
            if retry_encrypt > 0
              retry_encrypt -= 1
              sleep(AR_RETRY_WAIT_MSEC)
              throw :encrypt_again_8
            end
          end
          fmargs = Security.urlsafe_encode_base64(file_manager_params[:length].to_s + file_manager_params[:data])
          if ENV['RAILS_ENV'] != 'production'
            my_host = $http_host.split(/:|\//)[-2]
            # => get URL server
            my_url_host = SpinFileServer.find_by_server_port(SYSTEM_DEFAULT_SPIN_SERVER_PORT)
            if my_url_host.present?
              my_host = my_url_host[:spin_url_server_name]
            end
            #          if my_host.length == 2
            rethash[:redirect_uri] = my_host + "/secret_files/uploader/upload_proc?fmargs=" + fmargs
          else
            rethash[:redirect_uri] = '/secret_files/uploader/upload_proc?fmargs=' + fmargs
          end
          #          my_host = $http_host.split(/:|\//)[-2]
          #          if my_host.length == 2
          #            rethash[:redirect_uri] = "http://#{my_host[0]}:18881/filemanager/uploader/upload_proc?fmargs=" + fmargs
          #          else
          #            rethash[:redirect_uri] = '/secret_files/uploader/upload_proc?fmargs=' + fmargs
          #          end
          rethash[:success] = true
          FolderDatum.set_folder_dirty my_session_id, upload_dir_key
        rescue OpenSSL::PKey::RSAError
          if retry_encrypt > 0
            retry_encrypt -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :encrypt_again_8
          end
          rethash[:success] = false
          rethash[:status] = ERROR_UPLOAD_FILE
          rethash[:errors] = 'Failed to generate encrypted URL by OpenSSL::PKey::RSA'
        rescue
          if retry_encrypt > 0
            retry_encrypt -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :encrypt_again_8
          end
          rethash[:success] = false
          rethash[:status] = ERROR_UPLOAD_FILE
          rethash[:errors] = 'Failed to generate encrypted urlsafe URL'
        end
      }
      #      pdata = my_session_id + vfile_key + my_upload_file_name
      #      # make encrypted data
      #      file_manager_params = Security.public_key_encrypt2 rsa_key_pem,  pdata
      #      # and encode into base64
      #      # fmargs = file_manager_params
      #      fmargs = Security.urlsafe_encode_base64(file_manager_params[:length].to_s + file_manager_params[:data])
      #      # then URI escape
      #      # uri_fmargs = Security.escape_base64 fmargs
      #      # rethash[:redirect_uri] = 'http://192.168.2.119:18080/secret_files/uploader/upload_proc?fmargs=' + fmargs
      #      my_host = $http_host.split(/:/)
      #      if $http_port != 80
      #        rethash[:redirect_uri] = "http://#{my_host[0]}:18881/filemanager/uploader/upload_proc?fmargs=" + fmargs
      #      else
      #        rethash[:redirect_uri] = '/secret_files/uploader/upload_proc?fmargs=' + fmargs
      #      end
      #      rethash[:success] = true
      #      #      folder_key = SpinLocationManager.get_parent_key(delete_file_key)
      #      FolderDatum.has_updated(upload_sid, upload_dir_key, NEW_CHILD, true)
      #      FolderDatum.set_folder_dirty upload_sid, upload_dir_key

    when 'search_files'
      rethash[:success] = true
      # set folder privilege
      conditions = Hash.new
      search_sid = my_session_id
      location = 'folder_a'
      if paramshash[:cont_location].present?
        location = paramshash[:cont_location]
      end
      search_hash_key = paramshash[:hash_key]
      search_folder = FolderDatum.select("spin_node_hashkey").find_by_session_id_and_hash_key_and_cont_location search_sid, search_hash_key, location
      if search_folder.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No folder record is found at search_files'
        return rethash
      end
      conditions[:target_file_name] = paramshash[:target_file_name]
      if paramshash[:hash_key].length == 0
        #        cwdrec = DatabaseUtility::SessionUtility.get_current_directory(search_sid, location)
        #        conditions[:folder_hash_key] = SpinLocationManager.get_parent_key(cwdrec, NODE_DIRECTORY)
        conditions[:folder_hash_key] = DatabaseUtility::SessionUtility.get_current_directory(search_sid, location)
      else
        conditions[:folder_hash_key] = search_folder[:spin_node_hashkey]
      end

      if paramshash[:target_subfolder].present?
        conditions[:target_subfolder] = paramshash[:target_subfolder] # => bool : indicates search subfolders if true, or this folder only
      end

      if paramshash[:target_subfolder].present?
        conditions[:folder_name] = paramshash[:text]
      end

      if paramshash[:target_modifier].present?
        conditions[:target_modifier] = paramshash[:target_modifier]
      end

      if paramshash[:target_creator].present?
        conditions[:target_creator] = paramshash[:target_creator]
      end

      if paramshash[:locked_by_me].present?
        conditions[:locked_by_me] = paramshash[:locked_by_me] # => bool
      end

      if paramshash[:checked_out_by_me].present?
        conditions[:checked_out_by_me] = paramshash[:checked_out_by_me] # => bool
      end

      if paramshash[:target_created_by_me].present?
        conditions[:target_created_by_me] = paramshash[:target_created_by_me] # => bool
      end

      if paramshash[:target_modified_by_me].present?
        conditions[:target_modified_by_me] = paramshash[:target_modified_by_me] # => bool
      end

      if paramshash[:cont_location].present?
        conditions[:cont_location] = paramshash[:cont_location]
      end

      if paramshash[:target_modified_date_begin].present?
        conditions[:target_modified_date_begin] = paramshash[:target_modified_date_begin] # => yyyy-mm-ddThh:mm:ss
      end

      if paramshash[:target_modified_date_end].present?
        conditions[:target_modified_date_end] = paramshash[:target_modified_date_end] # => yyyy-mm-ddThh:mm:ss
      end

      if paramshash[:target_created_date_begin].present?
        conditions[:target_created_date_begin] = paramshash[:target_created_date_begin] # => yyyy-mm-ddThh:mm:ss
      end

      if paramshash[:target_created_date_end].present?
        conditions[:target_created_date_end] = paramshash[:target_created_date_end] # => yyyy-mm-ddThh:mm:ss
      end

      if paramshash[:target_file_size_min].present?
        conditions[:target_file_size_min] = paramshash[:target_file_size_min] # => B(default),KB,MB,GB,TB...
      end

      if paramshash[:target_file_size_max].present?
        conditions[:target_file_size_max] = paramshash[:target_file_size_max] # => B(default),KB,MB,GB,TB...
      end

      if paramshash[:target_check_str_size].present?
        conditions[:target_check_str_size] = paramshash[:target_check_str_size]
      end

      if paramshash[:target_check_str_char].present?
        conditions[:target_check_str_char] = paramshash[:target_check_str_char]
      end
      # get numbered property hashes
      list_optional_conditions = Array.new
      hash_params = Hash.new
      if paramshash[:property].present? and paramshash[:property].length > 0
        paramshash[:property].each {|value|
          #          if /[0-9]+/ =~ key # => number
          list_optional_conditions.append value # => value is a hash { :option_name => opname, :field_name => fldname, :value => val }
          #          end
        }
      end
      # search files
      searched_files = SearchConditionDatum.search_files(search_sid, conditions, list_optional_conditions)
      if searched_files.length >= 0
        rethash[:success] = true
        rethash[:status] = (searched_files.length == 0 ? INFO_SEARCH_FILE_RESULT_IS_EMPTY : INFO_SEARCH_FILE_RESULT_IS_NOT_EMPTY)
        rethash[:result] = searched_files
        FileDatum.fill_search_file_list_data_table search_sid, searched_files, conditions[:folder_hash_key], 'search_result'
      else
        rethash[:success] = false
      end
    when 'expand_folder' # => ,'expand_target_folder'
      f = FolderDatum.find_by_hash_key paramshash[:hash_key]
      if f.present?
        rethash = FolderDatum.set_expand_folder my_session_id, paramshash[:cont_location], f[:spin_node_hashkey], paramshash[:domain_hash_key]
        #        if rethash[:status] == STAT_DATA_NOT_LOADED_YET
        #          FolderDatum.load_folder_recs(my_session_id, f[:spin_node_hashkey], paramshash[:domain_hash_key], paramshash[:cont_location])
        #        end
        #        if rethash[:isDirty]
        #          FolderDatum.fill_folders(my_session_id, paramshash[:cont_location], paramshash[:domain_hash_key])
        #          #        else
        #          #          FolderDatum.fill_folders(my_session_id, paramshash[:cont_location], f[:spin_node_hashkey])
        #        end
        #        FolderDatum.select_folder my_session_id, f[:spin_node_hashkey], paramshash[:cont_location], paramshash[:domain_hash_key]
        #        if rethash[:status] != STAT_DATA_ALREADY_LOADED
        #          if rethash[:success]
        #            SessionManager.set_location_dirty my_session_id, paramshash[:cont_location]
        #          end
        #        end
        #      else
        #        rethash[:success] = false
        #      end
      end
      # rethash[:success] = truespin
    when 'open_folder'
      hk = ''
      user_agent = $http_user_agent
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        hk = paramshash[:hash_key]
      else # => from UI
        file_data_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
        unless file_data_rec.blank?
          hk = file_data_rec[:spin_node_hashkey]
        else
          rethash = {:success => false, :status => ERROR_FAILED_TO_OPEN_FOLDER, :errors => 'Failed to open folder'}
          return rethash
          # hk = paramshash[:hash_key]
        end
        #hk = file_data_rec[:spin_node_hashkey]
      end
      parent_folder = file_data_rec[:folder_hash_key]
      fd = FolderDatum.find_by(session_id: my_session_id, spin_node_hashkey: hk, cont_location: paramshash[:cont_location])
      if fd.blank?
        # loaded_recs = FolderDatum.load_folder_recs(my_session_id, hk, selected_domain, parent_folder, paramshash[:cont_location], DEPTH_TO_TRAVERSE, SessionManager.get_last_session(my_session_id))
        # if loaded_recs <= 0
        rethash = {:success => false, :status => ERROR_FAILED_TO_OPEN_FOLDER, :errors => 'Failed to open folder'}
        return rethash
        # end
      end
      parent_is_expanded = FolderDatum.is_expanded_folder(my_session_id, paramshash[:cont_location], parent_folder)
      selected_domain = SessionManager.get_selected_domain(my_session_id, paramshash[:cont_location])
      unless parent_is_expanded
        reth = FolderDatum.set_expand_folder(my_session_id, paramshash[:cont_location], parent_folder, selected_domain)
      end
      #        DomainDatum.set_domain_dirty(my_session_id, paramshash[:cont_location], fd[:domain_hash_key])
      # is_dirty = DomainDatum.is_dirty_domain(my_session_id, paramshash[:cont_location], selected_domain)
      #        is_dirty = FolderDatum.is_dirty_folder_tree my_session_id, paramshash[:cont_location], fd[:parent_hash_key]      #      current_partial_root = self.find_by_session_id_and_domain_hash_key_and_cont_location_and_is_partial_root sid, target_domain, cont_location, true
      # FolderDatum.reset_partial_root(my_session_id, paramshash[:cont_location], selected_domain)
      # if is_dirty
      #   FolderDatum.fill_folders(my_session_id, paramshash[:cont_location], selected_domain, parent_folder)
      # else
      #          FolderDatum.load_folder_recs(my_session_id, parent_folder, selected_domain, paramshash[:cont_location], 3)
      #          FolderDatum.fill_folders(my_session_id, paramshash[:cont_location], selected_domain)
      FolderDatum.fill_folders(my_session_id, paramshash[:cont_location], selected_domain, parent_folder)
      # end
      if FolderDatum.select_folder(my_session_id, hk, paramshash[:cont_location], selected_domain)
        # is_dirty = FolderDatum.is_dirty_folder_tree(my_session_id, paramshash[:cont_location], parent_folder) #      current_partial_root = self.find_by_session_id_and_domain_hash_key_and_cont_location_and_is_partial_root sid, target_domain, cont_location, true
        rethash = {:success => true, :status => STAT_DATA_ALREADY_LOADED, :isDirty => is_dirty, :folder_node => hk, :parent_node => parent_folder}
      else
        rethash = {:success => false, :status => ERROR_FAILED_TO_OPEN_FOLDER, :errors => 'Failed to open folder'}
      end
      # rethash = {:success => true, :status => STAT_DATA_ALREADY_LOADED, :isDirty => is_dirty, :folder_node => hk, :parent_node => parent_folder}
      # else
      #   reth = FolderDatum.set_expand_folder(my_session_id, paramshash[:cont_location], parent_folder, selected_domain)
      #   #        DomainDatum.set_domain_dirty(my_session_id, paramshash[:cont_location], paramshash[:domain_hash_key])
      #   #        is_dirty = FolderDatum.is_dirty_folder_tree my_session_id, paramshash[:cont_location], fd[:parent_hash_key]      #      current_partial_root = self.find_by_session_id_and_domain_hash_key_and_cont_location_and_is_partial_root sid, target_domain, cont_location, true
      #   #        is_dirty = DomainDatum.is_dirty_domain(my_session_id, paramshash[:cont_location], paramshash[:domain_hash_key])
      #   #        fk = FolderDatum.select_folder my_session_id, hk, paramshash[:cont_location], selected_domain
      #   #        if fk == true
      #   #          if reth[:isDirty]
      #   #            FolderDatum.fill_folders(my_session_id, paramshash[:cont_location], selected_domain)
      #   #          else
      #   ##            FolderDatum.fill_folders(my_session_id, paramshash[:cont_location], selected_domain)
      #   #            FolderDatum.fill_folders(my_session_id, paramshash[:cont_location], selected_domain, parent_folder)
      #   #          end
      #   #          rethash = { :success => true, :status => STAT_DATA_ALREADY_LOADED, :isDirty => false, :parent_node => parent_folder }
      # rethash = {:success => true, :status => STAT_DATA_NOT_LOADED_YET, :isDirty => true, :parent_node => parent_folder}
      #        end
      # rethash[:success] = true
    when 'expand_node'
      f = FolderDatum.find_by_hash_key paramshash[:hash_key]
      if f.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No folder record is found at expand_node'
        return rethash
      end
      rethash = FolderDatum.set_expand_folder my_session_id, paramshash[:cont_location], f[:spin_node_hashkey], paramshash[:domain_hash_key]
      if rethash[:success]
        SessionManager.set_location_dirty my_session_id, paramshash[:cont_location]
      end
      if rethash[:success]
        FolderDatum.fill_folders my_session_id, paramshash[:cont_location]
      end
      # rethash[:success] = true
      #    when 'expand_target_folder'
      #      f = FolderDatum.find_by_hash_key paramshash[:target_hash_key]
      ##      f = FolderDatum.find_by_hash_key paramshash[:hash_key]
      #      if f != nil
      #        rethash = FolderDatum.set_expand_folder my_session_id, paramshash[:target_cont_location], f[:spin_node_hashkey], paramshash[:domain_hash_key]
      #        FolderDatum.select_folder my_session_id, f[:spin_node_hashkey], paramshash[:target_cont_location]
      #        if rethash[:status] != STAT_DATA_ALREADY_LOADED
      #          if rethash[:success]
      #            SessionManager.set_location_dirty my_session_id, paramshash[:target_cont_location]
      #          end
      #        end
      #      else
      #        rethash[:success] = false
      #      end
      ##      rethash = FolderDatum.set_expand_folder my_session_id, paramshash[:target_cont_location], f[:spin_node_hashkey]
      ##      #      rethash = FolderDatum.set_expand_folder my_session_id, paramshash[:target_cont_location], paramshash[:target_hash_key]
      ##      if rethash[:success]
      ##        SessionManager.set_location_dirty my_session_id, paramshash[:target_cont_location]
      ##      end
      ##      if rethash[:success]
      ##        FolderDatum.fill_folders my_session_id, paramshash[:target_cont_location]
      ##      end
      #      # rethash[:success] = true
    when 'collapse_folder', 'collapse_target_folder'
      f = FolderDatum.find_by_hash_key paramshash[:hash_key]
      if f.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No folder record is found at collapse_folder'
        return rethash
      end
      rethash = FolderDatum.set_collapse_folder my_session_id, paramshash[:cont_location], f[:spin_node_hashkey], paramshash[:domain_hash_key]
      # rethash[:success] = true
      #    when 'collapse_target_folder'
      #      f = FolderDatum.find_by_hash_key paramshash[:target_hash_key]
      #      if f != nil
      #        rethash = FolderDatum.set_collapse_folder my_session_id, paramshash[:target_cont_location], f[:spin_node_hashkey]
      #      else
      #        rethash[:success] = false
      #      end
      #      #      rethash = FolderDatum.set_collapse_folder my_session_id, paramshash[:target_cont_location], paramshash[:target_hash_key]
      #      # rethash[:success] = true
    when 'logout'
      current_session = paramshash['session_id']
      #      ac = Hash.new
      cs = SpinSession.find_by_spin_session_id current_session
      if cs.blank?
        SpinSession.transaction do
          my_addr = get_my_address();
          #rethash[:initial_uri]="http://localhost:3000/secret_files_login/";
          rethash[:initial_uri]="http://"+my_addr+":3000/secret_files/";
          #rethash[:initial_uri] = @appl_conf["protocol"] + "://" + @appl_conf["host"] + ( @appl_conf["port"] != 0 ? ( ":" + @appl_conf["port"].to_s ) : "" ) + @appl_conf["start_url"]
        end # => end of transaction
        rethash[:success] = false
        rethash[:status] = ERROR_SESSION_ID_MISSING
        rethash[:errors] = "no session id"
      else
        initial_uri = cs[:initial_uri]
        #        ac = JSON.parse cs[:spin_session_conf]s
        cs.spin_last_logout = Time.now
        cs.save
        rethash[:initial_uri] = initial_uri
        rethash[:success] = true
      end
      #rethash[:success] = true
    when 'createUser'
      # coord_value is an array : [x,y,prx,v,hk]
      # check session id
      sid = nil
      my_session_id = paramshash[:session_id]
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = ERROR_SESSION_ID_MISSING
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = ERROR_INVALID_SESSION_ID
          rethash[:errors] = "session id is invalid"
          return rethash
        end
      end # => end of session id check
      unless paramshash[:formData].present?
        rethash[:success] = false
        rethash[:status] = ERROR_FORM_DATA_MISSING
        rethash[:errors] = "form data for createUser are missing"
        return rethash
      end
      if paramshash[:cont_location].present?
        location = paramshash[:cont_location]
      else
        location = LOCATION_ANY
      end
      rethash = SpinUser.create_user_from_form sid, paramshash[:formData], paramshash[:is_sticky]
      #      rethash = SpinUser.add_user sid, paramshash[:formData]['user_id'], paramshash[:formData]['user_id'], paramshash[:formData]['user_id']
      #      cwd = DatabaseUtility::SessionUtility.set_current_directory_path(sid, vpath, location)
      #      if cwd == nil
      #        rethash[:success] = false
      #        rethash[:status] = ERROR_FAILED_TO_SET_CURRENT_DIRECTORY
      #        rethash[:errors] = "指定されたディレクトリパスに移動出来ませんでした"
      #      else
      #        rethash[:success] = true
      #        rethash[:status] = INFO_SET_CURRENT_DIRECTORY_SUCCESS
      #        rethash[:result] = cwd
      #      end
    when 'createTemporaryUser'
      # coord_value is an array : [x,y,prx,v,hk]
      # check session id
      sid = nil
      my_session_id = paramshash[:session_id]
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = ERROR_SESSION_ID_MISSING
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = ERROR_INVALID_SESSION_ID
          rethash[:errors] = "session id is invalid"
          return rethash
        end
      end # => end of session id check
      if paramshash[:formData] == nil
        rethash[:success] = false
        rethash[:status] = ERROR_FORM_DATA_MISSING
        rethash[:errors] = "form data for createUser are missing"
        return rethash
      end
      if paramshash[:cont_location].present?
        location = paramshash[:cont_location]
      else
        location = LOCATION_ANY
      end
      rethash = SpinUser.create_user_from_form sid, paramshash[:formData], true, false
      #      rethash = SpinUser.add_user sid, paramshash[:formData]['user_id'], paramshash[:formData]['user_id'], paramshash[:formData]['user_id']
      #      cwd = DatabaseUtility::SessionUtility.set_current_directory_path(sid, vpath, location)
      #      if cwd == nil
      #        rethash[:success] = false
      #        rethash[:status] = ERROR_FAILED_TO_SET_CURRENT_DIRECTORY
      #        rethash[:errors] = "指定されたディレクトリパスに移動出来ませんでした"
      #      else
      #        rethash[:success] = true
      #        rethash[:status] = INFO_SET_CURRENT_DIRECTORY_SUCCESS
      #        rethash[:result] = cwd
      #      end
    when 'add_user'
      # coord_value is an array : [x,y,prx,v,hk]
      # check session id
      sid = nil
      my_session_id = paramshash[:session_id]
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = ERROR_SESSION_ID_MISSING
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = ERROR_INVALID_SESSION_ID
          rethash[:errors] = "session id is invalid"
          return rethash
        end
      end # => end of session id check
      if paramshash[:cont_location].present?
        location = paramshash[:cont_location]
      else
        location = LOCATION_ANY
      end
      rethash = SpinUser.add_user sid, paramshash[:user_id], paramshash[:group_id], paramshash[:user_name], paramshash[:password], paramshash[:group_editor], paramshash[:activated]
    when 'updateUser'
      # coord_value is an array : [x,y,prx,v,hk]
      # check session id
      sid = nil
      my_session_id = paramshash[:session_id]
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = ERROR_SESSION_ID_MISSING
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = ERROR_INVALID_SESSION_ID
          rethash[:errors] = "session id is invalid"
          return rethash
        end
      end # => end of session id check
      if paramshash[:formData] == nil
        rethash[:success] = false
        rethash[:status] = ERROR_FORM_DATA_MISSING
        rethash[:errors] = "form data for createUser are missing"
        return rethash
      end
      if paramshash[:cont_location].present?
        location = paramshash[:cont_location]
      else
        location = LOCATION_ANY
      end
      rethash = SpinUser.update_user_from_form sid, paramshash[:formData]
    when 'selectUser'
      # coord_value is an array : [x,y,prx,v,hk]
      # check session id
      sid = nil
      my_session_id = paramshash[:session_id]
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = ERROR_SESSION_ID_MISSING
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = ERROR_INVALID_SESSION_ID
          rethash[:errors] = "session id is invalid"
          return rethash
        end
      end # => end of session id check
      if paramshash[:formData] == nil
        rethash[:success] = false
        rethash[:status] = ERROR_FORM_DATA_MISSING
        rethash[:errors] = "form data for createUser are missing"
        return rethash
      end
      if paramshash[:cont_location].present?
        location = paramshash[:cont_location]
      else
        location = LOCATION_ANY
      end
      #l_offset = params[:start].to_i
      #l_limit = params[:limit].to_i
      disp_user_list_obj = SpinUser.select_user_from_form sid, paramshash[:formData]
      #rethash[:success] = disp_user_list_obj[:success]
      #rethash[:status] = disp_user_list_obj[:status]
      rethash = disp_user_list_obj
    when 'deleteUser'
      # coord_value is an array : [x,y,prx,v,hk]
      # check session id
      sid = nil
      my_session_id = paramshash[:session_id]
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = ERROR_SESSION_ID_MISSING
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = ERROR_INVALID_SESSION_ID
          rethash[:errors] = "session id is invalid"
          return rethash
        end
      end # => end of session id check
      unless paramshash[:formData].present?
        rethash[:success] = false
        rethash[:status] = ERROR_FORM_DATA_MISSING
        rethash[:errors] = "form data for createUser are missing"
        return rethash
      end
      if paramshash[:cont_location].present?
        location = paramshash[:cont_location]
      else
        location = LOCATION_ANY
      end
      rethash = SpinUser.delete_user_from_form sid, paramshash[:formData]

    when 'getUserInfo'
      # coord_value is an array : [x,y,prx,v,hk]
      # check session id
      sid = nil
      my_session_id = paramshash[:session_id]
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = ERROR_SESSION_ID_MISSING
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = ERROR_INVALID_SESSION_ID
          rethash[:errors] = "session id is invalid"
          return rethash
        end
      end # => end of session id check
      #if paramshash[:form_data] == nil
      #  rethash[:success] = false
      #  rethash[:status] = ERROR_FORM_DATA_MISSING
      #  rethash[:errors] = "form data for createUser are missing"
      #  return rethash
      #end
      unless paramshash[:user_name].present?
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_FAILED_TO_GET_USER_INFO
        rethash[:errors] = "user_name is null"
        return rethash
      end
      login_user_uid = SessionManager.get_uid(sid, true)
      login_uname = SpinUser.get_uname(login_user_uid);
      spin_uname = paramshash[:user_name]
      if login_uname != spin_uname and login_user_uid != 0
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_FAILED_TO_GET_USER_INFO
        rethash[:errors] = "Administrator and LoginUser can perform"
        return rethash
      end
      rethash[:success] = true
      rethash[:status] = INFO_SYSADMIN_GET_USER_INFO_SUCCESS
      #uid = SpinUser.get_uid spin_uname
      rtn = SpinUser.readonly.select("spin_uid,spin_gid,spin_login_directory").find_by_spin_uname spin_uname
      if rtn.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No user record is found at getUserInfo'
        return rethash
      end
      rethash[:result] = {:spin_uid => rtn[:spin_uid], :spin_gid => rtn[:spin_gid], :spin_login_directory => rtn[:spin_login_directory]}
      return rethash
    when 'getVpath'
      # coord_value is an array : [x,y,prx,v,hk]
      # check session id
      sid = nil
      my_session_id = paramshash[:session_id]
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = ERROR_SESSION_ID_MISSING
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = ERROR_INVALID_SESSION_ID
          rethash[:errors] = "session id is invalid"
          return rethash
        end
      end # => end of session id check
      #if paramshash[:form_data] == nil
      #  rethash[:success] = false
      #  rethash[:status] = ERROR_FORM_DATA_MISSING
      #  rethash[:errors] = "form data for createUser are missing"
      #  return rethash
      #end
      unless paramshash[:node_hash_key].present?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_GET_VPATH
        rethash[:errors] = "node_hash_key is null"
        return rethash
      end
      login_user_uid = SessionManager.get_uid(sid, true)
      login_uname = SpinUser.get_uname(login_user_uid);
      spin_uname = paramshash[:user_name]
      if login_uname != spin_uname and login_user_uid != 0
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_GET_VPATH
        rethash[:errors] = "Administrator and LoginUser can perform"
        return rethash
      end
      rethash[:success] = true
      rethash[:status] = INFO_GET_VPATH_SUCCESS
      node_hash_key = paramshash[:node_hash_key]
      virtual_path = SpinNode.get_vpath(node_hash_key)
      rethash[:result] = {:virtual_path => virtual_path}
      return rethash
    when 'create_my_group'
      # coord_value is an array : [x,y,prx,v,hk]
      # check session id
      sid = nil
      my_session_id = paramshash[:session_id]
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = ERROR_SESSION_ID_MISSING
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = ERROR_INVALID_SESSION_ID
          rethash[:errors] = "session id is invalid"
          return rethash
        end
      end # => end of session id check
      my_new_group_name = ''
      if paramshash[:new_my_group] == nil
        rethash[:success] = false
        rethash[:status] = ERROR_GROUP_NAME_MISSING
        rethash[:errors] = "no new group name"
        return rethash
      end # => end of session id check
      my_new_group_name = paramshash[:new_my_group]
      if paramshash[:cont_location].present?
        location = paramshash[:cont_location]
      else
        location = LOCATION_ANY
      end
      # gid
      my_new_group_id = ANY_GID # => -1
      if paramshash[:group_id].present? and paramshash[:group_id] != ''
        my_new_group_id = paramshash[:group_id]
      end
      my_new_group_description = '' # => empty
      if paramshash[:new_group_description] != nil
        my_new_group_description = paramshash[:new_group_description]
      end
      rethash = SpinGroup.create_group my_session_id, my_new_group_name, my_new_group_id, my_new_group_description
      #      rethash = SpinUser.add_user sid, paramshash[:formData]['user_id'], paramshash[:formData]['user_id'], paramshash[:formData]['user_id']
      #      cwd = DatabaseUtility::SessionUtility.set_current_directory_path(sid, vpath, location)
      #      if cwd == nil
      #        rethash[:success] = false
      #        rethash[:status] = ERROR_FAILED_TO_SET_CURRENT_DIRECTORY
      #        rethash[:errors] = "指定されたディレクトリパスに移動出来ませんでした"
      #      else
      #        rethash[:success] = true
      #        rethash[:status] = INFO_SET_CURRENT_DIRECTORY_SUCCESS
      #        rethash[:result] = cwd
      #      end
    when 'select_my_group'
      # coord_value is an array : [x,y,prx,v,hk]
      # check session id
      sid = nil
      my_session_id = paramshash[:session_id]
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = ERROR_SESSION_ID_MISSING
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = ERROR_INVALID_SESSION_ID
          rethash[:errors] = "session id is invalid"
          return rethash
        end
      end # => end of session id check
      my_selected_group_name = ''
      if paramshash[:selected_group] == nil
        rethash[:success] = false
        rethash[:status] = ERROR_SELECTED_GROUP_MISSING
        rethash[:errors] = "no selected group data"
        return rethash
      end # => end of session id check
      my_selected_group = paramshash[:selected_group]
      my_selected_group_name = my_selected_group[:group_name]
      retgid = SpinGroup.select_group my_session_id, my_selected_group_name
      if retgid < 0
        rethash[:success] = false
        rethash[:status] = ERROR_SELECTED_GROUP_MISSING
        rethash[:errors] = "no selected group data"
        return rethash
      else
        rethash[:success] = true
        rethash[:status] = INFO_SELECT_GROUP_SUCCESS
        rethash[:result] = retgid
      end
    when 'key_to_location'
      # coord_value is an array : [x,y,prx,v,hk]
      # check session id
      sid = nil
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = false
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = false
          rethash[:errors] = "session id is not valid"
          return rethash
        end
      end # => end of session id check
      flag_make_dir_if_not_exeits = true
      user_agent = $http_user_agent
      hk = nil
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        hk = paramshash[:hash_key]
      else # => from UI
        file_data_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
        if file_data_rec.present? #COnfigured at 20150416 by imai
          hk = file_data_rec[:spin_domain_hash_key]
        else
          hk = paramshash[:hash_key]
        end
      end
      #      if paramshash[:hash_key]
      #        hk = paramshash[:hash_key]
      #      else
      #        hk = nil
      #      end
      if paramshash[:node_type].present?
        nt = paramshash[:node_type]
      else
        nt = NODE_DIRECTORY
      end
      coord_value = SpinLocationManager.key_to_location hk, nt
      if coord_value == [-1, -1, -1, -1]
        rethash[:success] = false
        rethash[:status] = false
        rethash[:errors] = coord_value.to_s
      else
        rethash[:success] = true
        rethash[:status] = true
        rethash[:result] = coord_value
      end
    when 'get_vfile_attributes'
      # coord_value is an array : [x,y,prx,v,hk]
      # check session id
      sid = nil
      if my_session_id == nil
        rethash[:success] = false
        #rethash[:status] = false
        rethash[:status] = ERROR_SESSION_ID_MISSING
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          #rethash[:status] = false
          rethash[:status] = ERROR_SESSION_ID_MISSING
          rethash[:errors] = "session id is not valid"
          return rethash
        end
      end # => end of session id check
      if paramshash[:virtual_path].present?
        SpinNode.transaction do
          #           SpinNode.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
          virtual_path = paramshash[:virtual_path]
          nodes = SpinNode.where(["virtual_path = ? AND node_type <> ? AND latest = true AND in_trash_flag = false AND is_void = false", virtual_path, NODE_THUMBNAIL]).order("node_version DESC")
          node = nil
          if nodes.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_GET_ATTRIBUTES
            rethash[:errors] = "Specified node doesn\'t exist"
            return rethash
          else
            node = nodes[0]
          end
          #node = SpinNode.find(["virtual_path = ? AND node_type <> ?",virtual_path,NODE_THUMBNAIL]).order("node_version DESC")
          #          node = SpinNode.where(["spin_node_tree = 0 AND virtual_path = ? AND in_trash_flag = false AND is_void = false",virtual_path]).order("node_version DESC")
          if node.blank?
            #          unless nodes.length > 0
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_GET_ATTRIBUTES
            rethash[:errors] = "Specified node doesn\'t exist"
          else
            #            node = nodes[0]
            #            rethash[:success] = true
            #            rethash[:status] = INFO_GET_ATTRIBUTES_SUCCESS
            mt = 0
            ct = 0
            ntree = 0
            unless node[:mtime].present?
              mt = 0
            else
              mt = node[:mtime].to_i
            end
            unless node[:ctime].present?
              ct = 0
            else
              ct = node[:ctime].to_i
            end
            unless node[:spin_node_tree].present?
              ntree = 0
            else
              ntree = node[:spin_node_tree].to_i
            end
            ns_upper = (node[:node_size_upper].present? ? node[:node_size_upper] : 0)
            ns = (node[:node_size].present? ? node[:node_size] : 0)
            vfile_size = (MAX_INTEGER + 1) * ns_upper + ns
            ver = node[:node_version]
            location_mapping = SpinLocationMapping.readonly.find_by_spin_node_tree_and_node_hash_key(ntree, node[:spin_node_hashkey])
            has_thumbnail = true
            if location_mapping.blank? or location_mapping[:thumbnail_location_path].present? == false
              has_thumbnail = false
            end
            rethash[:success] = true
            rethash[:status] = INFO_GET_ATTRIBUTES_SUCCESS
            rethash[:result] = {:file_name => node[:node_name], :hash_key => node[:spin_node_hashkey], :mtime => mt, :ctime => ct, :size => vfile_size, :version => ver, :thumbnail => has_thumbnail, :is_pending => node[:is_pending]}
          end
        end # => end of ActiveRecord::Base.transaction
      else # => virtual_path os nil!
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_GET_ATTRIBUTES
        rethash[:errors] = "Virtual path is not specified"
      end
    when 'xget_vfile_attributes'
      # coord_value is an array : [x,y,prx,v,hk]
      # check session id
      sid = nil
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = false
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = false
          rethash[:errors] = "session id is not valid"
          return rethash
        end
      end # => end of session id check
      if paramshash[:virtual_path].present?
        #        ActiveRecord::Base.transaction do
        virtual_path = paramshash[:virtual_path]
        node_hashkey = SpinLocationManager.get_vpath_key(virtual_path)
        if node_hashkey == nil
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_GET_ATTRIBUTES
          rethash[:errors] = "Virtual path doesn\'t exist or is invalid."
        end
        node = SpinNode.find_by_spin_node_hashkey node_hashkey
        if node.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_GET_ATTRIBUTES
          rethash[:errors] = "Specified node doesn\'t exist"
        else
          rethash[:success] = true
          rethash[:status] = INFO_GET_ATTRIBUTES_SUCCESS
          mt = 0
          ct = 0
          unless node[:mtime]
            mt = 0
          else
            mt = node[:mtime].to_i
          end
          unless node[:ctime]
            ct = 0
          else
            ct = node[:ctime].to_i
          end
          ns_upper = (node[:node_size_upper] ? node[:node_size_upper] : 0)
          ns = (node[:node_size] ? node[:node_size] : 0)
          ver = node[:node_version]
          rethash[:result] = {:file_name => node[:node_name], :hash_key => node_hashkey, :mtime => mt, :ctime => ct, :size => ((MAX_INTEGER + 1) * ns_upper + ns), :version => ver}
        end
        #        end # => end of ActiveRecord::Base.transaction
      else # => virtual_path os nil!
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_GET_ATTRIBUTES
        rethash[:errors] = "Virtual path is not specified"
      end
    when 'get_domain_info'
      # coord_value is an array : [x,y,prx,v,hk]
      # check session id
      sid = nil
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = false
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = false
          rethash[:errors] = "session id is not valid"
          return rethash
        end
      end # => end of session id check
      if paramshash[:domain_disp_name].present?
        domain_name = paramshash[:domain_disp_name]
      elsif paramshash[:domain_name].present?
        domain_name = paramshash[:domain_name]
      else
        domain_name = DOMAIN_ANY
      end
      domains = []
      if domain_name == DOMAIN_ANY
        domains = SpinDomain.where(["id > 0"])
      else
        domains = SpinDomain.where :spin_domain_name => domain_name
      end
      if domains.length > 0
        rethash[:success] = true
        rethash[:status] = domains.length
        rethash[:result] = domains
      else
        rethash[:success] = true
        rethash[:status] = INFO_NO_DOMAIN
        rethash[:result] = domain_name
      end
    when 'get_domain_root_by_name'
      # coord_value is an array : [x,y,prx,v,hk]
      # check session id
      sid = nil
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = false
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = false
          rethash[:errors] = "session id is not valid"
          return rethash
        end
      end # => end of session id check
      if paramshash[:domain_disp_name].present?
        domain_name = paramshash[:domain_disp_name]
      elsif paramshash[:domain_name].present?
        domain_name = paramshash[:domain_name]
      else
        domain_name = DOMAIN_ANY
      end
      domains = []
      if domain_name == DOMAIN_ANY
        domains = SpinDomain.where(["id > 0"])
      else
        domains = SpinDomain.select("spin_domain_root").where :spin_domain_disp_name => domain_name
      end
      if domains.length > 0
        rethash[:success] = true
        rethash[:status] = domains.size
        rethash[:result] = domains
      else
        rethash[:success] = true
        rethash[:status] = INFO_NO_DOMAIN
        rethash[:result] = domain_name
      end
    when 'get_cwd'
      # coord_value is an array : [x,y,prx,v,hk]
      # check session id
      sid = nil
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = false
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = false
          rethash[:errors] = "session id is not valid"
          return rethash
        end
      end # => end of session id check
      if paramshash[:cont_location].present?
        location = paramshash[:cont_location]
      else
        location = LOCATION_ANY
      end
      cwd = DatabaseUtility::SessionUtility.get_current_directory_path(sid, location)
      if cwd == nil
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_GET_CURRENT_DIRECTORY
        rethash[:errors] = "Failed to get the current directory"
      else
        rethash[:success] = true
        rethash[:status] = INFO_GET_CURRENT_DIRECTORY_SUCCESS
        rethash[:result] = cwd
      end
    when 'set_cwd'
      # coord_value is an array : [x,y,prx,v,hk]
      # check session id
      sid = nil
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = false
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = false
          rethash[:errors] = "session id is not valid"
          return rethash
        end
      end # => end of session id check
      if paramshash[:virtual_path].present?
        vpath = paramshash[:virtual_path]
      else
        vpath = "/"
      end
      if paramshash[:cont_location].present?
        location = paramshash[:cont_location]
      else
        location = LOCATION_ANY
      end
      cwd = DatabaseUtility::SessionUtility.set_current_directory_path(sid, vpath, location)
      if cwd == nil
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_SET_CURRENT_DIRECTORY
        rethash[:errors] = "指定されたディレクトリパスに移動出来ませんでした"
      else
        FolderDatum.select_folder(my_session_id, SpinLocationManager.get_vpath_key(cwd), LOCATION_A)
        my_current_folder = SpinLocationManager.get_vpath_key(cwd)
        FileDatum.fill_file_list(my_session_id, LOCATION_A, my_current_folder)
        FolderDatum.fill_folders(my_session_id, LOCATION_A, nil, my_current_folder)
        rethash[:success] = true
        rethash[:status] = INFO_SET_CURRENT_DIRECTORY_SUCCESS
        rethash[:result] = cwd
      end
    when 'hash_key_s'
      # check session id
      sid = nil
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = false
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = false
          rethash[:errors] = "session id is not valid"
          return rethash
        end
      end # => end of session id check
      seed = String.new
      hash_key = String.new
      if paramshash[:seed]
        seed = paramshash[:seed]
      end
      r = Random.new
      hash_key = Security.hash_key_s seed + Time.now.to_s + r.rand.to_s
      if hash_key == nil
        rethash[:success] = false
        rethash[:status] = false
        rethash[:errors] = "Failed to generate hash key in sha1"
      else
        rethash[:success] = true
        rethash[:status] = true
        rethash[:result] = hash_key
      end
    when 'get_location_vpath'
      # args : node_location = [ x,y,prx,v]
      # check session id
      sid = nil
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = false
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = false
          rethash[:errors] = "session id is not valid"
          return rethash
        end
      end # => end of session id check
      nl = nil
      if paramshash[:node_location]
        nl = paramshash[:node_location]
      else
        nl = nil
      end
      vpath = SpinLocationManager.get_location_vpath nl
      if vpath == nil
        rethash[:success] = false
        rethash[:status] = false
        rethash[:errors] = ""
      else
        rethash[:success] = true
        rethash[:status] = true
        rethash[:result] = vpath
      end
    when 'get_vpath_key'
      # args : node_location = [ x,y,prx,v]
      vp = nil
      key = nil
      if paramshash[:virtual_path]
        vp = paramshash[:virtual_path]
      else
        vp = nil
      end
      key = SpinLocationManager.get_vpath_key vp
      if key == ""
        rethash[:success] = false
        rethash[:status] = false
        rethash[:errors] = ""
      else
        rethash[:success] = true
        rethash[:status] = true
        rethash[:result] = key
      end
    when 'get_and_make_vpath'
      #      ActiveRecord::Base.transaction do
      # args : node_location = [ x,y,prx,v]
      vp = nil
      key = nil
      owner_uid = NO_USER
      owner_gid = NO_GROUP
      u_acl = 15
      g_acl = 7
      w_acl = 0
      acls = nil
      get_node_attributes = false
      # check session id
      sid = nil
      if my_session_id == nil
        rethash[:success] = false
        #rethash[:status] = false
        rethash[:status] = ERROR_SESSION_ID_MISSING
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          #rethash[:status] = false
          rethash[:status] = ERROR_SESSION_ID_MISSING
          rethash[:errors] = "session id is not valid"
          return rethash
        end
      end # => end of session id check
      if paramshash[:virtual_path].present?
        vp0 = paramshash[:virtual_path].gsub(/\\u([\da-fA-F]{4})/) {[$1].pack('H*').unpack('n*').pack('U*')}


        vpt = ''
        dnt = ''
        if (vp0 =~ /:/) != nil and !vp0.start_with?("/")
          vpath_parts = vp0.partition(/:/)
          if vpath_parts.size == 3 # => [domainname, ':', path]
            vpt = vpath_parts[-1]
            dnt = vpath_parts[0]
            unless dnt.starts_with?("/")
              droot = SpinDomain.get_domain_root_node_by_name dnt
              vp = droot + '/' + vpt
            else
              vp = vpt
            end
            msg = '>> get_and_make_vpath : vp0 = ' + vp0 + ', vp = ' + vp
            FileManager.logger(my_session_id, msg, 'LOCAL')
          else
            begin
              cdom = DomainDatum.find_by_session_id_and_cont_location my_session_id, 'folder_a'
              if cdom.blank?
                rethash[:success] = false
                rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
                rethash[:errors] = 'No domain record is found'
                return rethash
              end
              my_domain_root_key = cdom[:folder_hash_key]
              tvp = SpinNode.get_vpath(my_domain_root_key)
              if tvp != nil
                vp = tvp + '/' + vp0
              else
                vp = nil
              end
              msg = '>> get_and_make_vpath : vp0 = ' + vp0 + ', vp = ' + vp
              FileManager.logger(my_session_id, msg, 'LOCAL')
            rescue ActiveRecord::RecordNotFound
              vp = nil
              msg = '>> get_and_make_vpath : vp0 = ' + vp0 + ', vp = nil'
              FileManager.logger(my_session_id, msg, 'LOCAL', LOG_ERROR)
            end
          end
        else
          vp = vp0
          msg = '>> get_and_make_vpath : vp0 = ' + vp0 + ', vp = ' + vp
          FileManager.logger(my_session_id, msg, 'LOCAL')
          FileManager.rails_logger(msg)
        end


      else
        vp = nil
      end

      if paramshash[:uid].present?
        owner_uid = paramshash[:uid]
      end
      if paramshash[:gid].present?
        owner_gid = paramshash[:gid]
      end
      if paramshash[:acl].present?
        acls = paramshash[:acl]
      end
      if paramshash[:make_directory].present?
        mkdirf = paramshash[:make_directory]
      else
        mkdirf = false
      end
      if paramshash[:user].present?
        u_acl = paramshash[:user]
      end
      if paramshash[:group].present?
        g_acl = paramshash[:group]
      end
      if paramshash[:world].present?
        w_acl = paramshash[:world]
      end
      if paramshash[:get_node_attributes].present?
        get_node_attributes = paramshash[:get_node_attributes]
      end

      res_msg = ''
      # set pesimistic lock
      #      ActiveRecord::Base.lock_optimistically = false
      SpinLocationMapping.transaction do
        #        SpinLockSpinNodes.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        #        SpinLockSpinNodes.find_by_sql('LOCK TABLE spin_lock_spin_nodes IN EXCLUSIVE MODE;')
        #        lock_records = SpinLockSpinNodes.find(1)

        loc = SpinLocationManager.get_location_coordinates sid, 'folder_a', vp, mkdirf, owner_uid, owner_gid, u_acl, g_acl, w_acl
        #      pp loc
        if loc[X..V] == NoXYPV
          node_rec = SpinNode.readonly.find_by_virtual_path(vp)
          if node_rec.blank?
            if mkdirf == false
              rethash[:success] = true
              rethash[:status] = INFO_NO_VPATH
              rethash[:errors] = "Specified vpath dosen\'t exist"
              rethash[:info] = "Specified vpath dosen\'t exist"
              rethash[:result] = 0
            else
              rethash[:success] = false
              rethash[:status] = ERROR_CREATE_VPATH_FAILED
              rethash[:errors] = "Failed to create specified vpath : " + vp
              rethash[:result] = -1
            end
          else
            rethash[:success] = true
            rethash[:status] = true
            rethash[:result] = key
            rethash[:virtual_path] = node_rec[:virtual_path]
            if get_node_attributes == true
              begin
                hash_attr = JSON.parse(node_rec[:node_attributes])
                log_msg = 'node_attributes = ' + hash_attr.to_s
                FileManager.logger sid, log_msg, 'LOCAL'
                rethash[:node_attributes] = hash_attr
              rescue JSON::ParserError
                log_msg = 'error parsing node_attributes = [ ' + node_rec[:node_attributes] + ' ]'
                FileManager.logger sid, log_msg, 'LOCAL', LOG_ERROR
                rethash[:node_attributes] = {:node_name => "NONAME", :node_path => "Not found"}
              end
              rethash[:is_deleted] = node_rec[:is_void]
              rethash[:deleted_at] = node_rec[:spin_updated_at]
            end
          end
        else # => valid loc
          key = loc[K]
          key = SpinLocationManager.location_to_key loc, NODE_DIRECTORY
          unless key.present? # => key doesn't exist
            node_rec = SpinNode.readonly.find_by_node_x_coord_and_node_y_coord_and_node_x_pr_coord_and_node_vedsion(loc[X], loc[Y], loc[PRX], loc[V])
          else # => key is!
            node_rec = SpinNode.readonly.find_by_spin_node_hashkey(key)
          end

          unless node_rec.present?
            rethash[:success] = false
            rethash[:status] = ERROR_CREATE_VPATH_FAILED
            rethash[:errors] = "Failed to find specified vpath : " + vp
            rethash[:result] = -1
          else
            rethash[:success] = true
            rethash[:status] = true
            rethash[:result] = key
            rethash[:virtual_path] = node_rec[:virtual_path]
            if get_node_attributes == true
              begin
                hash_attr = JSON.parse(node_rec[:node_attributes])
                log_msg = 'node_attributes = ' + hash_attr.to_s
                FileManager.logger sid, log_msg, 'LOCAL'
                rethash[:node_attributes] = hash_attr
              rescue JSON::ParserError
                log_msg = 'error parsing node_attributes = [ ' + node_rec[:node_attributes] + ' ]'
                FileManager.logger sid, log_msg, 'LOCAL', LOG_ERROR
                rethash[:node_attributes] = {:node_name => "NONAME", :node_path => "Not found"}
              end
              rethash[:is_deleted] = node_rec[:is_void]
              rethash[:deleted_at] = node_rec[:spin_updated_at]
            end
          end
          res_msg = '>> get_and_make_vpath : result = ' + rethash.to_s
        end
      end # => end of transaction with lock
      #      ActiveRecord::Base.lock_optimistically = true
      FileManager.logger(my_session_id, res_msg, 'LOCAL')
      FileManager.rails_logger(res_msg)
    when 'clear_folder_tree'
      clear_sid = my_session_id
      clear_cont_locations = CONT_LOCATIONS_LIST
      if paramshash[:clear_sid].present? and paramshash[:clear_sid].blank? == false
        clear_sid = paramshash[:clear_sid]
      end
      if paramshash[:clear_cont_locations].present? and paramshash[:clear_cont_locations].blank? == false
        clear_cont_locations = paramshash[:clear_cont_locations]
      end
      reth = FolderDatum.clear_folder_tree(my_session_id, clear_sid, clear_cont_locations)
      rethash[:success] = reth[:success]
      rethash[:status] = reth[:status]

    when 'system_delete_user'
      # check session id
      sid = nil
      my_session_id = paramshash[:session_id]
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = ERROR_SESSION_ID_MISSING
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = ERROR_INVALID_SESSION_ID
          rethash[:errors] = "session id is invalid"
          return rethash
        end
      end # => end of session id check
      #if paramshash[:form_data] == nil
      #  rethash[:success] = false
      #  rethash[:status] = ERROR_FORM_DATA_MISSING
      #  rethash[:errors] = "form data for createUser are missing"
      #  return rethash
      #end
      if paramshash[:user_name] == nil
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_FAILED_TO_SYSTEM_DELETE_USER
        rethash[:errors] = "user_name is null"
        return rethash
      end
      login_user_uid = SessionManager.get_uid(sid, true)
      login_uname = SpinUser.get_uname(login_user_uid);
      spin_uname = paramshash[:user_name]
      if login_user_uid != 0
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_FAILED_TO_SYSTEM_DELETE_USER
        rethash[:errors] = "Only an administrator can perform"
        return rethash
      end
      if spin_uname === "root"
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_FAILED_TO_SYSTEM_DELETE_USER
        rethash[:errors] = "Administrator cann't delete"
        return rethash
      end
      spin_uid = SpinUser.get_uid(spin_uname);
      if spin_uid === 0
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_FAILED_TO_SYSTEM_DELETE_USER
        rethash[:errors] = "Administrator cann't delete"
        return rethash
      elsif spin_uid < 0
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_FAILED_TO_SYSTEM_DELETE_USER
        rethash[:errors] = "No such user"
        return rethash
      end
      rethash = SpinUser.delete_user(sid, spin_uid)
      #respjはファイルマネージャのログに渡すので文字列に変換しなければならない。
      FileManager.rails_logger(rethash.to_s)
      #rethash = JSON.parse(respj)
      #respjは文字列に変換する必要はない。なぜならクライアントに直接渡すからである。
      return rethash
    when 'system_update_user'
      sid = nil
      my_session_id = paramshash[:session_id]
      if my_session_id == nil
        rethash[:success] = false
        rethash[:status] = ERROR_SESSION_ID_MISSING
        rethash[:errors] = "no session id"
        return rethash
      else
        if SessionManager.auth_spin_session my_session_id
          sid = my_session_id
        else
          rethash[:success] = false
          rethash[:status] = ERROR_INVALID_SESSION_ID
          rethash[:errors] = "session id is invalid"
          return rethash
        end
      end # => end of session id check
      if paramshash[:user_name] == nil
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_FAILED_TO_SYSTEM_UPDATE_USER
        rethash[:errors] = "user_name is null"
        return rethash
      end
      login_user_uid = SessionManager.get_uid(sid, true)
      login_uname = SpinUser.get_uname(login_user_uid);
      spin_uname = paramshash[:user_name]
      if login_uname != spin_uname and login_user_uid != 0
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_FAILED_TO_SYSTEM_UPDATE_USER
        rethash[:errors] = "Only an administrator and LoginUser can perform"
        return rethash
      end
      spin_uid = SpinUser.get_uid(spin_uname);
      #rethash[:success] = true
      #rethash[:status] = INFO_SYSADMIN_SYSTEM_UPDATE_USER
      change_password_params = {:uid => spin_uid.to_i,
                                :current_password => paramshash[:operator_pw], :new_password => paramshash[:operator_new_pw]}
      rethash = SpinUser.change_password my_session_id, change_password_params
      return rethash

    when 'copy_clipboard'
      user_agent = $http_user_agent
      copy_file_key = ''
      copy_file_name = ''
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        copy_file_key = paramshash[:hash_key]
        copy_file_name = paramshash[:file_name]
      else # => from UI
        if paramshash[:original_place] === 'folderPanelA'
          file_rec = FolderDatum.find_by_hash_key paramshash[:hash_key]
          if file_rec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'No file record is found'
            return rethash
          end
          copy_file_key = file_rec[:spin_node_hashkey]
          copy_file_name = file_rec[:folder_name]
        else
          file_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
          if file_rec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'No folder record is found at copy_clipboard'
            return rethash
          end
          copy_file_key = file_rec[:spin_node_hashkey]
          copy_file_name = file_rec[:file_name]
        end
      end

      copy_sid = my_session_id

      copy_file_hash_keys = Array.new
      copy_file_hash_keys.push copy_file_key
      r = Random.new
      t = Time.now

      opr_id = Security.hash_key_s(copy_sid + copy_file_key + t.to_s + r.rand.to_s)

      rethash = ClipBoards.put_nodes(opr_id, copy_sid, copy_file_hash_keys, OPERATION_COPY)
      unless rethash[:success]
        rethash[:status] = ERROR_COPY_FILE
        return rethash
      end

      rethash[:success] = true
      rethash[:status] = INFO_COPY_FOLDER_SUCCESS
    when 'cut_clipboard'
      user_agent = $http_user_agent
      copy_file_key = ''
      copy_file_name = ''
      parent_hash_key = ''
      if /HTTP_Request2.+/ =~ user_agent # => PHP API
        copy_file_key = paramshash[:hash_key]
        copy_file_name = paramshash[:file_name]
      else # => from UI
        if paramshash[:original_place] === 'folderPanelA'
          file_rec = FolderDatum.find_by_hash_key paramshash[:hash_key]
          if file_rec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'No file record is found'
            return rethash
          end
          copy_file_key = file_rec[:spin_node_hashkey]
          copy_file_name = file_rec[:folder_name]
          parent_hash_key = file_rec[:parent_hash_key]
        else
          file_rec = FileDatum.find_by_hash_key paramshash[:hash_key]
          if file_rec.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'No file record is found'
            return rethash
          end
          copy_file_key = file_rec[:spin_node_hashkey]
          copy_file_name = file_rec[:file_name]
          parent_hash_key = file_rec[:folder_hash_key]
        end
      end

      copy_sid = my_session_id
      copy_uid = SessionManager.get_uid(copy_sid, true)

      # ロック状態排他制御
      file_nodes = []
      if paramshash[:original_place] === 'file_list'
        if file_rec[:file_type] === 'folder'
          file_nodes = DatabaseUtility::VirtualFileSystemUtility.search_virtual_file_on_tree copy_file_key
        else
          file_nodes = DatabaseUtility::VirtualFileSystemUtility.search_virtual_file copy_sid, copy_file_name, parent_hash_key, ANY_VALUE, ANY_VALUE, SEARCH_EXISTING_VFILE
        end
      else
        file_nodes = DatabaseUtility::VirtualFileSystemUtility.search_virtual_file_on_tree copy_file_key
      end

      if file_nodes.size() > 0
        file_nodes.each {|file_node|
          if file_node[:latest]
            if FSTAT_WRITE_LOCKED == file_node[:lock_mode] && FSTAT_LOCKED == file_node[:lock_status]
              if copy_uid != file_node[:lock_uid] && -1 != file_node[:lock_uid]
                rethash[:success] = false
                rethash[:status] = ERROR_MOVE_FILE
                rethash[:errors] = '他のユーザーにロックされているため移動できません'
                return rethash
              end
            end
          end
        }
      end

      # check trash can
      can_file_nodes = DatabaseUtility::VirtualFileSystemUtility.search_virtual_file my_session_id, copy_file_name, copy_target_folder_hashkey, ANY_VALUE, ANY_VALUE, SEARCH_EXISTING_VFILE
      can_file_nodes.each {|canf|
        if canf[:in_trash_flag]
          rethash[:success] = false
          rethash[:status] = ERROR_SAME_FILE_PATH_IN_RECYCLER
          if canf[:node_type] == NODE_FILE
            rethash[:errors] = '同じパス名のファイルがゴミ箱の中にあります'
          else
            rethash[:errors] = '同じパス名のフォルダがゴミ箱の中にあります'
          end
        else
          rethash[:success] = false
          rethash[:status] = ERROR_SAME_FILE_PATH_IN_DIRECTORY
          if canf[:node_type] == NODE_FILE
            rethash[:errors] = '同じパス名のファイルがフォルダの中にあります'
          else
            rethash[:errors] = '同じパス名のフォルダがフォルダの中にあります'
          end
        end
        return rethash
      }

      copy_file_hash_keys = Array.new
      copy_file_hash_keys.push copy_file_key
      r = Random.new
      t = Time.now

      opr_id = Security.hash_key_s(copy_sid + copy_file_key + t.to_s + r.rand.to_s)

      rethash = ClipBoards.put_nodes(opr_id, copy_sid, copy_file_hash_keys, OPERATION_CUT)
      unless rethash[:success]
        return rethash
      end
      rethash[:success] = true
      rethash[:status] = INFO_COPY_FOLDER_SUCCESS

    when 'clipboard_all_clear'
      rethash = ClipBoards.clear_nodes_all(my_session_id)
      unless rethash[:success]
        return rethash
      end
      rethash[:success] = true
      rethash[:status] = INFO_CLEAR_CLIPBOARD_SUCCESS

    when 'clipboard_clear'
      n = paramshash.length # => I need it!
      clear_files = n - 5 # => I hate this kind of logic but client send me fucking json data!
      clear_sid = my_session_id
      1.upto(clear_files) {|i|
        rethash = ClipBoards.clear_nodes_hashkey(my_session_id, paramshash["#{i-1}"][:node_hash_key])
        unless rethash[:success]
          return rethash
        end
      }
      rethash[:success] = true
      rethash[:status] = INFO_CLEAR_CLIPBOARD_SUCCESS

    when 'paste_file'
      copy_sid = my_session_id

      target_cont_location = 'folder_a'

      target_folder_rec = FolderDatum.find_by_session_id_and_cont_location_and_selected copy_sid, target_cont_location, true
      if target_folder_rec.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No folder record is found at paste_file'
        return rethash
      end
      target_hash_key = target_folder_rec[:spin_node_hashkey]
      target_folder_writable_status = SpinAccessControl.is_writable(copy_sid, target_hash_key, NODE_DIRECTORY)

      if target_folder_writable_status != true # => not copyable
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_COPY_FOLDER
        rethash[:errors] = "Failed to copy folder : target folder is not writable"
        return rethash
      end

      n = paramshash.length # => I need it!
      copy_files = n - 5 # => I hate this kind of logic but client send me fucking json data!
      if copy_files > 0

        1.upto(copy_files) {|i|
          cl = ClipBoards.find_by_session_id_and_node_hash_key(copy_sid, paramshash["#{i-1}"][:node_hash_key])
          if cl.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'No clipboard record is found'
            return rethash
          end

          #ファイル(フォルダ)名取得
          copying_node = SpinNode.find_by_spin_node_hashkey cl[:node_hash_key]
          if copying_node.blank?
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
            rethash[:errors] = 'No node record is found'
            return rethash
          end
          copy_file_name = copying_node[:node_name]
          copy_file_key = copying_node[:spin_node_hashkey]

          # check trash can
          can_file_nodes = DatabaseUtility::VirtualFileSystemUtility.search_virtual_file my_session_id, copy_file_name, target_hash_key, ANY_VALUE, ANY_VALUE, SEARCH_EXISTING_VFILE
          can_file_nodes.each {|canf|
            if canf[:in_trash_flag]
              rethash[:success] = false
              rethash[:status] = ERROR_SAME_FILE_PATH_IN_RECYCLER
              if canf[:node_type] == NODE_FILE
                rethash[:errors] = '同じパス名のファイルがゴミ箱の中にあります'
              else
                rethash[:errors] = '同じパス名のフォルダがゴミ箱の中にあります'
              end
            else
              rethash[:success] = false
              rethash[:status] = ERROR_SAME_FILE_PATH_IN_DIRECTORY
              if canf[:node_type] == NODE_FILE
                rethash[:errors] = '同じパス名のファイルがフォルダの中にあります'
              else
                rethash[:errors] = '同じパス名のフォルダがフォルダの中にあります'
              end
            end
            return rethash
          }

          copy_source_folder_hashkey = SpinLocationManager.get_parent_key(copy_file_key)

          # Are source folder and target folder the same?
          if copy_file_key == target_hash_key
            rethash[:success] = false
            rethash[:status] = ERROR_TRIED_TO_COPY_TO_SAME_FOLDER
            rethash[:errors] = '自分自身にはコピー出来ません'
            return rethash
          end
          if copy_source_folder_hashkey == target_hash_key
            rethash[:success] = false
            rethash[:status] = ERROR_TRIED_TO_COPY_TO_SAME_FOLDER
            rethash[:errors] = '同じフォルダにはコピー出来ません'
            return rethash
          end
          if SpinLocationManager.is_in_sub_tree(copy_file_key, target_hash_key)
            rethash[:success] = false
            rethash[:status] = ERROR_TRIED_TO_COPY_TO_SAME_FOLDER
            rethash[:errors] = '自分のサブフォルダにはコピー出来ません'
            return rethash
          end

          if cl[:opr] == OPERATION_COPY
            ret = DatabaseUtility::VirtualFileSystemUtility.copy_virtual_files_in_clipboard cl[:opr_id], copy_sid, copy_source_folder_hashkey, target_hash_key, target_cont_location
            if ret
              FolderDatum.has_updated(copy_sid, copy_source_folder_hashkey, NO_UPDATE_TYPE, true)
            else
              rethash[:success] = false
              rethash[:status] = ERROR_COPY_FILE
              rethash[:errors] = 'Failed to copy files'
              return rethash
            end
          else
            ret = DatabaseUtility::VirtualFileSystemUtility.move_virtual_files_in_clipboard cl[:opr_id], copy_sid, copy_source_folder_hashkey, target_hash_key, target_cont_location
            if ret
              FolderDatum.has_updated(copy_sid, copy_source_folder_hashkey, DISMISS_CHILD, true)
              ClipBoards.clear_nodes_hashkey(copy_sid, cl[:node_hash_key])
            else
              rethash[:success] = false
              rethash[:status] = ERROR_MOVE_FILE
              rethash[:errors] = 'Failed to move files'
              return rethash
            end
          end
        }
        rethash[:success] = true
        rethash[:status] = INFO_COPY_FILE_SUCCESS
      else
        rethash[:success] = false
        rethash[:status] = ERROR_MOVE_FILE
        rethash[:errors] = 'Failed to paste files'
        return rethash
      end
    when 'paste_file_all'
      copy_sid = my_session_id

      target_cont_location = 'folder_a'

      target_hash_key = ''
      if paramshash[:hash_key] == nil
        target_folder_rec = FolderDatum.find_by_session_id_and_cont_location_and_selected copy_sid, target_cont_location, true
        if target_folder.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No folder record is found at paste_file_all'
          return rethash
        end
        target_hash_key = target_folder_rec[:spin_node_hashkey]
      else
        target_file_rec = FileDatum.find_by_session_id_and_cont_location_and_hash_key copy_sid, target_cont_location, paramshash[:hash_key]
        if target_file_rec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No file record is found'
          return rethash
        end
        target_hash_key = target_file_rec[:spin_node_hashkey]
      end

      target_folder_writable_status = SpinAccessControl.is_writable(copy_sid, target_hash_key, NODE_DIRECTORY)

      if target_folder_writable_status != true # => not copyable
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_COPY_FOLDER
        rethash[:errors] = "Failed to copy folder : target folder is not writable"
        return rethash
      end

      clipboards = ClipBoards.where(["session_id = ? AND parent_flg = ?", copy_sid, true])
      clipboards.each {|cl|

        #ファイル(フォルダ)名取得
        copying_node = SpinNode.find_by_spin_node_hashkey cl[:node_hash_key]
        if copying_node.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No node record is found'
          return rethash
        end
        copy_file_name = copying_node[:node_name]
        copy_file_key = copying_node[:spin_node_hashkey]

        # check trash can
        can_file_nodes = DatabaseUtility::VirtualFileSystemUtility.search_virtual_file my_session_id, copy_file_name, target_hash_key, ANY_VALUE, ANY_VALUE, SEARCH_EXISTING_VFILE
        can_file_nodes.each {|canf|
          if canf[:in_trash_flag]
            rethash[:success] = false
            rethash[:status] = ERROR_SAME_FILE_PATH_IN_RECYCLER
            if canf[:node_type] == NODE_FILE
              rethash[:errors] = '同じパス名のファイルがゴミ箱の中にあります'
            else
              rethash[:errors] = '同じパス名のフォルダがゴミ箱の中にあります'
            end
            #          else
            #            rethash[:success] = false
            #            rethash[:status] = ERROR_SAME_FILE_PATH_IN_DIRECTORY
            #            if canf[:node_type] == NODE_FILE
            #              rethash[:errors] = '同じパス名のファイルがフォルダの中にあります'
            #            else
            #              rethash[:errors] = '同じパス名のフォルダがフォルダの中にあります'
            #            end
          end
          return rethash
        }

        copy_source_folder_hashkey = SpinLocationManager.get_parent_key(copy_file_key)

        # Are source folder and target folder the same?
        if copy_file_key == target_hash_key
          rethash[:success] = false
          rethash[:status] = ERROR_TRIED_TO_COPY_TO_SAME_FOLDER
          rethash[:errors] = '自分自身にはコピー出来ません'
          return rethash
        end
        if copy_source_folder_hashkey == target_hash_key
          rethash[:success] = false
          rethash[:status] = ERROR_TRIED_TO_COPY_TO_SAME_FOLDER
          rethash[:errors] = '同じフォルダにはコピー出来ません'
          return rethash
        end
        if SpinLocationManager.is_in_sub_tree(copy_file_key, target_hash_key)
          rethash[:success] = false
          rethash[:status] = ERROR_TRIED_TO_COPY_TO_SAME_FOLDER
          rethash[:errors] = '自分のサブフォルダにはコピー出来ません'
          return rethash
        end

        if cl[:opr] == OPERATION_COPY
          ret = DatabaseUtility::VirtualFileSystemUtility.copy_virtual_files_in_clipboard cl[:opr_id], copy_sid, copy_source_folder_hashkey, target_hash_key, target_cont_location
          #          if ret
          #            FolderDatum.has_updated(copy_sid, copy_source_folder_hashkey, NO_UPDATE_TYPE, true)
          #          else
          #            rethash[:success] = false
          #            rethash[:status] = ERROR_COPY_FILE
          #            rethash[:errors] = 'Failed to copy files'
          #            return rethash
          #          end
        else
          ret = DatabaseUtility::VirtualFileSystemUtility.move_virtual_files_in_clipboard cl[:opr_id], copy_sid, copy_source_folder_hashkey, target_hash_key, target_cont_location
          puts ret;
          if ret
            temp = FolderDatum.has_updated(copy_sid, copy_source_folder_hashkey, DISMISS_CHILD, true)
            puts temp;
            FileDatum.fill_force_file_list(copy_sid, target_cont_location, target_hash_key)
            ClipBoards.clear_nodes_hashkey(copy_sid, cl[:node_hash_key])
          else
            rethash[:success] = false
            rethash[:status] = ERROR_MOVE_FILE
            rethash[:errors] = 'Failed to move files'
            return rethash
          end
        end
      }
      rethash[:success] = true
      rethash[:status] = INFO_COPY_FILE_SUCCESS
    when 'clear_file_list'
      frecs2del = FileDatum.where(["session_id = ?", my_session_id])
      frecs2del.each {|dr| dr.destroy}
      rethash[:success] = true
      rethash[:status] = INFO_THROW_FILES_SUCCESS # => 1031
    when 'fill_force_file_list'
      my_current_folder = paramshash[:folder_hash_key]
      FileDatum.fill_force_file_list(my_session_id, 'folder_a', my_current_folder)
      rethash[:success] = true
      rethash[:status] = INFO_LOAD_FILE_LIST_REC_SUCCESS # => 1062
    when 'create_alias_domain'
      ret = SpinDomain.create_domain(my_session_id, paramshash[:hash_key], paramshash[:target])
      if ret
        rethash[:success] = true
        rethash[:status] = INFO_COPY_FILE_SUCCESS
        rethash[:result] = {} #20161111 T2L ADD START
        rethash[:result][:spin_did] = ret[:spin_did]
        rethash[:result][:spin_domain_disp_name] = ret[:spin_domain_disp_name]
        rethash[:result][:spin_domain_name] = ret[:spin_domain_name]
        rethash[:result][:hash_key] = ret[:hash_key]
        rethash[:result][:spin_domain_root] = ret[:spin_domain_root]
        rethash[:result][:domain_root_node_hashkey] = ret[:domain_root_node_hashkey] #20161111 T2L ADD END
      else
        rethash[:success] = false
        rethash[:status] = ERROR_COPY_FILE
        rethash[:errors] = 'Cannot create alias.' #20161111 T2L Change
      end
    when 'delete_alias_domain'
      ret = SpinDomain.delete_domain(my_session_id, paramshash[:hash_key])
      if ret == true
        DomainDatum.select_domain(my_session_id, nil)
        rethash[:success] = true
        rethash[:status] = INFO_COPY_FILE_SUCCESS
      else
        rethash[:success] = false
        rethash[:status] = ERROR_COPY_FILE #20161111 T2L ADD
        rethash[:errors] = 'Cannot delete alias.' #20161111 T2L Change
      end
    when 'modify_alias_domain'
      ret = SpinDomain.modify_domain(my_session_id, paramshash)
      if ret
        rethash[:success] = true
        rethash[:status] = INFO_CHANGE_DOMAIN_NAME_SUCCESS
        rethash[:result] = {} #20161111 T2L ADD START
        rethash[:result][:spin_did] = ret[:spin_did]
        rethash[:result][:spin_domain_disp_name] = ret[:spin_domain_disp_name]
        rethash[:result][:spin_domain_name] = ret[:spin_domain_name]
        rethash[:result][:hash_key] = ret[:hash_key]
        rethash[:result][:spin_domain_root] = ret[:spin_domain_root]
        rethash[:result][:domain_root_node_hashkey] = ret[:domain_root_node_hashkey] #20161111 T2L ADD END
      else
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_CHANGE_DOMAIN_NAME
        rethash[:errors] = 'Failed to modify alias.' #20161111 T2L Change
      end
    when 'update_file_lock'
      # set folder privilege
      user_agent = $http_user_agent
      sid = my_session_id
      uid = SessionManager.get_uid(sid, true)

      rethash[:success] = true
      rethash[:errors] = ''
      paramshash[:file_list].each {|fl|
        spin_node_upd = Hash.new
        upd_lock_uid = nil
        upd_lock_status = nil
        upd_lock_mode = nil
        if fl[:lock] == 0
          upd_lock_uid = uid
          upd_lock_status = 1
          upd_lock_mode = 1
        elsif fl[:lock] == 1
          upd_lock_uid = -1
          upd_lock_status = 0
          upd_lock_mode = 0
        else
          rethash[:success] = false
          rethash[:errors] += "Lock status is abnormal at " + fl[:file_name] + "<br/>"
          next
        end
        spin_node_upd[:upd_lock_uid] = upd_lock_uid
        spin_node_upd[:upd_lock_status] = upd_lock_status
        spin_node_upd[:upd_lock_mode] = upd_lock_mode

        lock_ret = SpinNode.set_lock uid, fl[:folder_hash_key], fl[:file_name], sid, spin_node_upd
        if !lock_ret
          rethash[:success] = false
          rethash[:errors] += "Failed to set lock of " + fl[:file_name] + "<br/>"
        end
      }
    when 'update_force_file_list'
      # set folder privilege
      user_agent = $http_user_agent

      domain_hash_key = ''
      folder_spin_node_hashkey = ''
      hash_key = paramshash[:hash_key]
      cont_location = paramshash[:cont_location]
      frec = FolderDatum.find_by_session_id_and_cont_location_and_hash_key my_session_id, cont_location, hash_key
      if frec.blank?
        firec = FileDatum.find_by_session_id_and_cont_location_and_hash_key my_session_id, cont_location, hash_key
        if frec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
          rethash[:errors] = 'No file record is found'
          return rethash
        end
        domain_hash_key = SessionManager.get_selected_domain(my_session_id, cont_location)
        folder_spin_node_hashkey = firec[:folder_hash_key]
      else
        domain_hash_key = frec[:domain_hash_key]
        folder_spin_node_hashkey = frec[:spin_node_hashkey]
      end
      if FolderDatum.select_folder(my_session_id, folder_spin_node_hashkey, paramshash[:cont_location], domain_hash_key)
        FileDatum.fill_force_file_list(my_session_id, cont_location, folder_spin_node_hashkey)
        rethash[:success] = true
      else
        rethash[:success] = false
        rethash[:errors] = 'failed to set current folder'
      end
    when 'file_preview'
      hash_key = paramshash[:hash_key]
      #      sql1="select thumbnail_image from file_data where hash_key='"+hash_key+"';"
      #      fd=FileDatum.find_by_sql(sql1);
      fd = FileDatum.readonly.select("thumbnail_image,t_file_type").find_by_hash_key(hash_key)
      if fd.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
        rethash[:errors] = 'No preview record is found'
        return rethash
      end
      #sql1="select virtual_path,node_x_coord,node_y_coord,node_x_pr_coord,node_version from spin_nodes where spin_node_hashkey=(select spin_node_hashkey from file_data where hash_key='"+hash_key+"'); "
      #sn1=SpinNode.find_by_sql(sql1);
      #if(sn1==[])
      #  rethash[:success] = false;
      #  rethash[:errors]="ファイルが見つかりませんでした。"
      #  return rethash;
      #end
      #sql2="select spin_node_hashkey from spin_nodes where node_type=8 and virtual_path='"+sn1[0]["virtual_path"].to_s+"' and node_x_coord='"+sn1[0]["node_x_coord"].to_s+"' and node_y_coord='"+sn1[0]["node_y_coord"].to_s+"' and node_x_pr_coord='"+sn1[0]["node_x_pr_coord"].to_s+"' and node_version='"+sn1[0]["node_version"].to_s+"';";
      #sn2=SpinNode.find_by_sql(sql2);
      #if(sn2==[])
      #  rethash[:success] = false;
      #  rethash[:errors]="サムネイルが見つかりませんでした。"
      #  return rethash;
      #end
      #sql3="select spin_url from spin_urls where spin_node_hashkey='"+sn2[0]["spin_node_hashkey"].to_s+"';";
      #su=SpinUrl.find_by_sql(sql3);
      #if(su==[])
      #  rethash[:success] = false;
      #  rethash[:errors]="URLが見つかりませんでした。"
      #  return rethash;
      #end
      rethash[:success] = true;
      #rethash[:preview_file_path]="http://210.196.120.219/secret_files/urldownloader/w9KZ24Eb6vRGbhBn5ZWHko1lFuYhRU6U8Xv_dGNgkUqoOsqD5InENx4nBSPPYV-rCH9Hakod8kNsvzTONTJTee6PwEorgJwq5Pf0KNsy05s9nlo_UYcJwJpVSejch4Y-ih4Mx3x-OfYEYpdTSK2ARTFmx0AghGonvBep9T91TKuwUJyWY8K0RLmJP3dGulltrTLqCPxsUoLtVpD0HATJHpc9Hcl9sMKZAw6pFsW2GIgoOYyG-5aIDAUiXDA74i-XxauvBDRcoDmznVrtnR-WqLwki57HxTH-tibm5_tBGzFFlEvf-iXkw5UobJQS44QuZq2epao3-Sr33n0HVemOeSxVM9el5dUb7EVkFnrQJ6hqCImAJ5x0QjOpAasIdYVtnkSSXMHHyhL-JGCe9wnpot2hPnh-2wQVRjERFM-6rzLtkz9fMtQi72x1hMpUjJf9dD2yegg2MR3xbflafSvlKee6Z5Q5jfydqcDvEpGcPXq4BBfTIoKWP4lzR76Z6jtstVA2g0uvxu1yqlJ_DnhopZvEvYOuLa8l7_LWyu3p3f1AphDloweic_X6KaNpcs-sqwllZv_P-6IsCkXHz8HQ1VqLmr8esfniTzk0FVXCcmSaXi28SY9_aPkCBp-TAMvagZ9bEuBTJyZnhBSNdDLXd_WTXI7gqAOWxa2eEzjPCeI=";
      #rethash[:preview_file_path]=su[0]["spin_url"];
      #      rethash[:preview_file_path]=fd[0]["thumbnail_image"]
      preview_path = fd[:thumbnail_image] + '.' + fd[:t_file_type]
      preview_download_path = preview_path.gsub(/urldownloader/, 'previewdownloader')
      rethash[:preview_file_path] = preview_download_path
    when 'create_urlLink'
      file_data=paramshash[:file_data]
      hash_key = file_data[0]["hash_key"];
      session_id = paramshash[:session_id];
      urlLink_pf = paramshash[:urlLink_pf];
      urlLink_adr = paramshash[:urlLink_adr];
      urlLink_limit_day = paramshash[:urlLink_limit_day];
      urlLink_limit_time = paramshash[:urlLink_limit_time];

      padding_urlLink=urlLink_pf.ljust(40, ' ');
      limit=(urlLink_limit_day+" "+urlLink_limit_time).ljust(40, ' ');
      rsa_key_pem = SpinNode.get_root_rsa_key
      pdata = ''
      fmargs = ''
      retry_encrypt = ENCRYPTION_RETRY_COUNT
      catch(:encrypt_again_9) {
        begin
          pdata = padding_urlLink + limit;
          url_parts = Security.public_key_encrypt2 rsa_key_pem, pdata
          #      test=Security.private_key_decrypt rsa_key_pem,  url_parts
          #      test_url=Security.public_key_encrypt rsa_key_pem,  padding_urlLink
          #      test_limit=Security.public_key_encrypt rsa_key_pem,  limit
          #      puts test
          #      puts '********************************************************'
          #      puts test_url
          #      puts '********************************************************'
          #      puts test_limit
          #      puts '********************************************************'
          #      puts url_parts
          return_url=Array.new;
          return_file_name=Array.new;
          for i in 0..file_data.length-1 do
            hash_key = file_data[i]["hash_key"];
            sql1="select id,spin_url from spin_urls where hash_key='"+hash_key+"' and generator_session='"+session_id+"' order by id desc offset 0 limit 1;";
            su=SpinUrl.find_by_sql(sql1);
            if su.blank?
              rethash[:success] = false
              rethash[:status] = ERROR_FAILED_TO_UPDATE_FILE_LIST
              rethash[:errors] = 'No url record is found'
              return rethash
            end
            sql2="update spin_urls set url_valid_from='"+limit+"',url_pass_phrase='"+urlLink_pf+"' where id="+su[0]["id"].to_s
            SpinUrl.find_by_sql(sql2);
            return_url[i]=su[0]["spin_url"].to_s+url_parts[:data];
            return_file_name[i]=file_data[i]["file_name"]
          end
          rethash[:urlLink]=return_url;
          rethash[:fileName]=return_file_name;
          rethash[:test]=url_parts;
        rescue OpenSSL::PKey::RSAError
          if retry_encrypt > 0
            retry_encrypt -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :encrypt_again_9
          end
          rethash[:success] = false
          rethash[:status] = ERROR_UPLOAD_FILE
          rethash[:errors] = 'Failed to generate encrypted URL by OpenSSL::PKey::RSA'
        rescue
          if retry_encrypt > 0
            retry_encrypt -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :encrypt_again_9
          end
          rethash[:success] = false
          rethash[:status] = ERROR_UPLOAD_FILE
          rethash[:errors] = 'Failed to generate encrypted urlsafe URL'
        end
      }
      #      pdata = padding_urlLink + limit;
      #      url_parts = Security.public_key_encrypt2 rsa_key_pem,  pdata
      #      #      test=Security.private_key_decrypt rsa_key_pem,  url_parts
      #      #      test_url=Security.public_key_encrypt rsa_key_pem,  padding_urlLink
      #      #      test_limit=Security.public_key_encrypt rsa_key_pem,  limit
      #      #      puts test
      #      #      puts '********************************************************'
      #      #      puts test_url
      #      #      puts '********************************************************'
      #      #      puts test_limit
      #      #      puts '********************************************************'
      #      #      puts url_parts
      #      return_url=Array.new;
      #      return_file_name=Array.new;
      #      for i in 0..file_data.length-1 do
      #        hash_key = file_data[i]["hash_key"];
      #        sql1="select id,spin_url from spin_urls where hash_key='"+hash_key+"' and generator_session='"+session_id+"' order by id desc offset 0 limit 1;";
      #        su=SpinUrl.find_by_sql(sql1);
      #        sql2="update spin_urls set url_valid_from='"+limit+"',url_pass_phrase='"+urlLink_pf+"' where id="+su[0]["id"].to_s
      #        SpinUrl.find_by_sql(sql2);
      #        return_url[i]=su[0]["spin_url"].to_s+url_parts[:data];
      #        return_file_name[i]=file_data[i]["file_name"]
      #      end
      #      rethash[:urlLink]=return_url;
      #      rethash[:fileName]=return_file_name;
      #      rethash[:test]=url_parts;
    when 'send_url_link'
      addr=paramshash[:addr].split(/(,|\n|\t)/);
      url_list=paramshash[:url_list];

      addr.each {|recep_addr|
        unless recep_addr.blank?
          notify_url_mail = BoomboxNotifier.send_url_link(recep_addr, url_list)
          notify_url_mail.deliver
        end
      }
      rethash[:success] = true
      rethash[:status] = INFO_BASE
      #      notify_url_mail = BoomboxNotifier.send_url_link(addr,url_list);
    when 'get_folder_property'
      display_data=Hash.new;
      session_id = paramshash[:session_id];
      cont_location = paramshash[:cont_location];
      hash_key = paramshash[:hash_key];
      fd=FolderDatum.find_by_hash_key hash_key, :select => "spin_node_hashkey"
      if (fd.blank?)
        rethash[:success] = true;
        rethash[:errors]='フォルダデータ取得失敗';
        return rethash
      end
      sn=SpinNode.find_by_spin_node_hashkey fd[:spin_node_hashkey];
      if (sn.blank?)
        rethash[:success] = true;
        rethash[:errors]='フォルダデータ取得失敗';
        return rethash
      end
      display_data[:node_name]=sn[:node_name];
      display_data[:memo1]=sn[:memo1];
      display_data[:memo2]=sn[:memo2];
      display_data[:memo3]=sn[:memo3];
      display_data[:memo4]=sn[:memo4];
      display_data[:memo5]=sn[:memo5];
      display_data[:node_description]=sn[:node_description];
      display_data[:details]=sn[:details];
      rethash[:success] = true;
      rethash[:display_data] = display_data;
      rethash[:errors]='';
    else
      rethash[:success] = false
    end #=> end of 'case'
    return rethash
  end
end
