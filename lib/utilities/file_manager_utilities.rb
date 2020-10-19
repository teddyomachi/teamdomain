# coding: utf-8
require 'net/http'
require 'uri'
require 'open-uri'
require 'const/vfs_const'
require 'const/acl_const'
require 'const/ssl_const'
require 'const/stat_const'

module FileManager
  include Vfs
  include Acl
  include Ssl
  include Stat

  def self.is_alive session_id, server_port = SYSTEM_DEFAULT_SPIN_SERVER_PORT
    # test if the file manager is alive or not
    my_server_params = SpinFileServer.find_by_server_port server_port
    if my_server_params.blank?
      return false
    end
    host = my_server_params[:server_host_name]
    port = my_server_params[:server_port]
    protocol = my_server_params[:server_protocol]
    #    my_host = $http_host.split(/:/)
    uri_str = ''
    if ENV['RAILS_ENV'] == 'development'
      uri_str = '127.0.0.1:18880'
      if port == HTTP_DEFAULT_PORT or port == HTTPS_DEFAULT_PORT
        uri_str = protocol + '://' + host + '/secret_files/system/is_alive.tdx'
      else
        uri_str = protocol + '://' + host + ':' + port.to_s + '/secret_files/system/is_alive.tdx'
      end

      log_msg = 'Rails : request is_alive. URI = ' + uri_str
      self.rails_logger(log_msg)

      http_request = Typhoeus::Request.new(
          uri_str,
          params: {:session_id => "#{session_id}", :request => "is_alive", :spin_params => []}
      )
    else
      uri_str = protocol + '://' + host + '/secret_files/system/is_alive.tdx'

      log_msg = 'Rails : request is_alive. URI = ' + uri_str
      self.rails_logger(log_msg)

      http_request = Typhoeus::Request.new(
          uri_str,
          params: {:session_id => "#{session_id}", :request => "is_alive", :spin_params => []}
      )
    end
    #    uri = URI(uri_str)
    #    res = Net::HTTP.get_response(uri)

    http_request.run

    resp = http_request.response

    if resp.code == 200 # => is OK
      return true
    else
      return false
    end
    #    if res.is_a?(Net::HTTPSuccess)
    #      return true
    #    else
    #      return false
    #    end
  end

  def self.is_busy server_port = SYSTEM_DEFAULT_SPIN_SERVER_PORT
    my_server_params = SpinFileServer.find_by_server_port server_port
    return false if my_server_params.blank?
    max_connections = my_server_params[:max_connections]
    if max_connections == nil
      max_connections = -1
    end

    begin
      SpinProcess.transaction do
        #        SpinProcess.find_by_sql('LOCK TABLE spin_processes IN EXCLUSIVE MODE;')
        active_procs = SpinProcess.readonly.where(["( proc_action = 1 OR proc_action = 2 ) AND proc_status = 1"])
        if active_procs.size > (max_connections != -1 ? max_connections : MAX_CONCURRENT_FILEMANAGER_PROCS)
          return true # => busy
        else
          return false
        end
      end
    rescue ActiveRecord::RecordNotFound
      self.rails_logger 'no active spin spocesses in table'
      return false
    end

    #    begin
    #      all_procs = SpinProcess.readonly.where(["id > 0"])
    #      if all_procs.size > 0
    #        return true
    #      else
    #        return false
    #      end
    #    rescue ActiveRecord::RecordNotFound
    #      self.rails_logger 'no spin spocesses in table'
    #      return false
    #    end
    #    # test if the file manager is alive or not
    #    my_server_params = SpinFileServer.find_by_server_name server_name
    #    host = my_server_params[:server_host_name]
    #    port = my_server_params[:server_port]
    #    uri_str = 'http://' + host + ':' + port.to_s + '/filemanager/system/is_alive.tdx'
    #    uri = URI(uri_str)
    #    res = Net::HTTP.get_response(uri)
    #    if res.is_a?(Net::HTTPSuccess)
    #      return true
    #    else
    #      return false
    #    end
  end

  def self.logger sid, log_msg, server_host_name = 'LOCAL', log_level = LOG_INFO, server_port = SYSTEM_DEFAULT_SPIN_SERVER_PORT
    # buid request params hash
    ret = true
    server_params = SpinFileServer.find_by_server_port server_port
    if server_params.blank?
      self.rails_logger log_msg, log_level
    else
      if server_params[:server_host_name] == server_host_name
        self.rails_logger log_msg, log_level
      else
        request_params = {:session_id => sid, :request => "put_log", :params => [log_msg]}
        ret = self.post_request request_params, server_params
      end
    end
    return ret
    #    return true
  end

  # => end of self.logger sid, log_msg, server_name = '127.0.0.1:18880'

  def self.rails_logger message, log_level = LOG_INFO
    case log_level
    when LOG_ERROR
      t = Time.now
      log_message = t.to_s + ' : ' + message
      Rails.logger.error(log_message)
    when LOG_WARNING
      t = Time.now
      log_message = t.to_s + ' : ' + message
      Rails.logger.warn(log_message)
    when LOG_INFO
      t = Time.now
      log_message = t.to_s + ' : ' + message
      Rails.logger.info(log_message)
    else
      if $my_application_env != 'production'
        t = Time.now
        log_message = t.to_s + ' : ' + message
        Rails.logger.warn(log_message)
      end
    end
  end

  def self.request_remove_node sid, node_key, server_params = nil
    # buid request params hash
    request_params = {:session_id => sid, :request => "remove_node", :params => [node_key]}
    ret = self.post_request request_params, server_params
    return ret
  end

  # => end of self.request_remove_node sid, node_key, server_params = nil

  def self.request_trash_node sid, node_key, server_params = nil
    # buid request params hash
    request_params = {:session_id => sid, :request => "trash_node", :params => [node_key]}
    ret = self.post_request request_params, server_params
    return ret
  end

  # => end of self.request_trash_node sid, node_key, server_params = nil

  def self.post_request request_params, server_params = nil
    # use default server if server_params = nil
    resp = String.new # => response
    if server_params.present? # => server params are passed
      resp = self.my_http_post server_params, request_params
    else # => use default
      if $my_sever_params_g.present?
        my_server_params = $my_server_params_g
      else
        my_server_params = SpinFileServer.find_by_server_port SYSTEM_DEFAULT_SPIN_SERVER_PORT
        $my_server_params_g = my_server_params
      end
      resp = self.my_http_post my_server_params, request_params
    end
    return resp
  end

  # => end of self.post_request request_params, server_params

  def self.my_http_post(server_params, request_params)
    #    params_a = []
    #    request_params.each do |k,v|
    #      v = ERB::Util.u(v)
    #      params_a.push "#{k}=#{v}"
    #    end
    #    query = params_a.join '&'

    # my_server_name = SYSTEM_DEFAULT_SPIN_SERVER
    # my_server_port = SYSTEM_DEFAULT_SPIN_SERVER_PORT
    if ENV['RAILS_ENV'] == 'development'
      my_server_name = server_params[:server_host_name]
      #      my_server_name = my_host[0]
      my_server_port = SYSTEM_DEFAULT_SPIN_SERVER_PORT
    else
      my_server_name = server_params[:server_host_name]
      my_server_port = server_params[:server_port]
    end

    target_url = my_server_name + ":" + my_server_port.to_s + server_params[:api_path]

    http_request = Typhoeus::Request.new(
        target_url,
        method: :post,
        headers: {'Content-Type' => "application/json", 'Connection' => "close"},
        body: request_params.to_json
    )

    http_request.on_complete do |response|
      if response.success?
        # hell yeah
      elsif response.timed_out?
        # aw hell no
        FileManager.rails_logger("HTTP request = " + request_params.to_s + " got a time out")
      elsif response.code == 0
        # Could not get an http response, something's wrong.
        FileManager.rails_logger("HTTP request failed with msg = " + response.return_message)
        FileManager.rails_logger(response.return_message)
      else
        # Received a non-successful http response.
        FileManager.rails_logger("HTTP request = " + request_params.to_s + " failed: " + response.code.to_s)
      end
    end

    http_request.run

    resp = http_request.response

    return resp.body
  end

end # => end of FileManager


class OldFileManagerClient

  def initialize(protocol, host, port, location, user, passwd)
    @protocol = protocol
    @host = host
    @port = port
    @location = location
    @user = user
    res = file_manager_login(user, passwd)
    if res.key?(:MVFS_ERROR_MSG)
      raise res[:MVFS_ERROR_MSG]
    end
    @session_id = res[:SessionID]
    @group_editor = res[:IamGroupEditor]
    @delete_authority = res[:DeleteAuthorityLikeUNIX]
    @work_folder = res[:WorkFolder]
    @license = res[:CurrentWorkLicense]
  end

  attr_reader :user
  attr_reader :session_id
  attr_reader :group_editor
  attr_reader :delete_authority
  attr_reader :work_folder

  def self.http_post(path, params)
    params_a = []
    params.each do |k, v|
      v = ERB::Util.u(v)
      params_a.push "#{k}=#{v}"
    end
    query = params_a.join '&'
    http = Net::HTTP.new(@host, @port)
    resp, body = http.post("#{@location}/#{path}.mvfs", query,
                           {'Content-Type' => 'application/x-www-form-urlencoded'})

    if resp.instance_of?(Net::HTTPOK)
      #body = body, Kconv::UTF8, Kconv::SJIS)
    elsif resp.is_a?(Net::HTTPFound)
      body = resp['location']
      #body = body, Kconv::UTF8, Kconv::SJIS)
      #      uri = URI.parse(resp['location'])
      #      resp, body = http.get(uri.path)
      #      unless resp.instance_of?(Net::HTTPOK)
      #        raise 'HTTP REDIRECT ERROR'
      #      end
    else
      raise 'HTTP ERROR'
    end
    body
  end

  def _mvfs_folders(body)
    res = {}
    if /MVFS_FOLDERS_NUMBER=(.+)/m =~ body
      fn = $1
      fn_array = fn.split("\n")
      res.store(:MVFS_FOLDERS_NUMBER, fn_array[0])
      fnum = fn_array[0].split(".")[0].to_i
      res_array = []
      fn_array[1, fnum].each {|f|
        if /(.+)\/(\d+).(\d+)/ =~ f
          res_array.push({:name => $1, :child => $2.to_i, :id => $3.to_i})
        end
      }
      res.store(:MVFS_FOLDER, res_array)
    end
    res
  end

  # DONE
  def file_manager_login(user, passwd)
    body = http_post('MemberLogin', {
        :ClientVersion => '2.0.0',
        :UserID => "#{user}/#{passwd}",
        # :ClientOSUserName    => 'p01-0001/p01-0001.',
        # :ClientDnsHostName   => 'CLIENTPC',
        :NoRecursibleSearch => 'TRUE',
        # :ClientDnsDomainName => 'CLIENTPC'
    })
    res = {}
    if /MVFS_ERROR_MSG=(.+)/m =~ body
      res.store(:MVFS_ERROR_MSG, $1)
    else
      if /SessionID_=(.+)/ =~ body
        res.store(:SessionID, $1)
      end
      if /Operator_=(.+)/ =~ body
        res.store(:Operator, $1)
      end
      if /IamGroupEditor=(.+)/ =~ body
        res.store(:IamGroupEditor, $1)
      end
      if /DeletAuthorityLikeUNIX=(.+)/ =~ body
        res.store(:DeleteAuthorityLikeUNIX, $1)
      end
      if /WorkFolder_=(.+)/ =~ body
        wf = $1
        wf_hash = {}
        wf.split("\017").each {|w|
          wf_array = w.split("\016")
          wf_hash.store(wf_array[0], wf_array[1])
        }
        res.store(:WorkFolder, wf_hash)
      end
      if /CurrentWorkLicense=(.+)/ =~ body
        res.store(:CurrentWorkLicense, $1)
      end
      res.merge! _mvfs_folders(body)
    end
    res
  end

  # DONE
  def logout
    body = http_post('MemberLogout', {
        :SessionID_ => @session_id,
        # :Referer             => 'CLIENTPC'
    })
  end

  # DONE
  def change_work_dir(work_dir)
    @license = @work_folder[work_dir]
    body = http_post('MemberChangeWorkDir', {
        :SessionID_ => @session_id,
        :LicenseCode => @license,
        :NoRecursibleSearch => 'TRUE',
        #:Referer => $this->_referer()
    })
    res = {}
    if /MVFS_ERROR_MSG=(.+)/m =~ body
      res.store(:MVFS_ERROR_MSG, $1)
    else
      lines = body.split("\n")
      if /MVFS_CHANGEWORKDIR=(.+)/ =~ lines[2]
        res.store(:MVFS_CHANGEWORKDIR, $1)
      end
      res.merge! _mvfs_folders(body)
    end
    res
  end

  # DONE
  def tree_folder(folder)
    body = http_post('MemberTreeFolder', {
        :SessionID_ => @session_id,
        :FolderPath => folder,
        #:FolderPath          => folder,
        :NoRecursibleSearch => 'TRUE',
        # :Referer             => 'CLIENTPC'
    })
    res = {}
    if /MVFS_ERROR_MSG=(.+)/m =~ body
      res.store(:MVFS_ERROR_MSG, $1)
    else
      res.merge! _mvfs_folders(body)
    end
    res
  end

  def tree_folder_recursive(folder)
    body = http_post('MemberTreeFolder', {
        :SessionID_ => @session_id,
        :FolderPath => folder,
        #:FolderPath          => folder,
        :NoRecursibleSearch => 'FALSE',
        # :Referer             => 'CLIENTPC'
    })
    res = {}
    if /MVFS_ERROR_MSG=(.+)/m =~ body
      res.store(:MVFS_ERROR_MSG, $1)
    else
      if /MVFS_FOLDERS_NUMBER=(.+)/m =~ body
        fn = $1
        fn_array = fn.split("\n")
        if /(\d+)\.(\d+)\|([0-9.]+)\|([0-9.]+)/ =~ fn_array[0]
          res.store(:ALLOC, $3.to_i)
          res.store(:FREE, $4.to_i)
        end
        res.store(:FOLDER_TREE, _folder_tree(folder, $1.to_i, fn_array[1..-2]))
        res.store(:FOLDERS_COUNT, fn_array.count - 2)
      end
    end
    res
  end

  def _folder_tree(folder, count, fn_array)
    if folder == '/'
      folder = ''
    end
    base_folder = [folder]
    counter_by_level = [[count, 0]]
    folder_tree = []
    fn_array.each do |f|
      if /(.+)\/(\d+)\.\d+/ =~ f
        counter_by_level.push [$2.to_i, 0]
        folder_tree.push base_folder.join('/') + '/' + $1
        base_folder.push $1

        if $2.to_i == 0
          counter_by_level[-1][1] += 1
          n = counter_by_level.length - 1
          if n > 0
            n.downto(1) do |i|
              if counter_by_level[i][0] <= counter_by_level[i][1]
                counter_by_level.pop
                base_folder.pop
                counter_by_level[-1][1] += 1
              end
            end
          end
        else
          #          counter_by_level[-1][1] += 1
          #          counter_by_level.push [$2.to_i,0]
        end

      end
    end
    folder_tree
  end

  # DONE
  def list_files(folder)
    res = file_attribute_def(folder)
    if res.blank?
      return res
    end
    item_id = res[:META_ID]
    item_names = item_id.join("\x1e")
    body = http_post('MemberListFiles', {
        :SessionID_ => @session_id,
        :ItemNames => item_names,
        :FolderPath => folder,
        # :Referer    => ''
    })
    if /MVFS_ERROR_MSG=(.+)/m =~ body
      res.store(:MVFS_ERROR_MSG, $1)
    else
      lines = body.split("\n")
      if /MVFS_FILE_NUMBER=(\d+)/ =~ lines[2]
        fn = $1.to_i
        res.store(:MVFS_FILE_NUMBER, fn)
        res_array = []
        files = lines[3..-1].join("\n").split("\036")[0, fn]
        files.each {|f|
          items = f.split("\017", -1)
          res_array.push(items)
        }
        res.store(:MVFS_FILE, res_array)
      end
    end
    res
  end

  def list_file_path(folder)
    item_names = ['FilePath_', 'FileName_'].join("\x1e")
    body = http_post('MemberListFiles', {
        :SessionID_ => @session_id,
        :ItemNames => item_names,
        :FolderPath => folder,
        # :Referer    => ''
    })
    res = {}
    if /MVFS_ERROR_MSG=(.+)/m =~ body
      res.store(:MVFS_ERROR_MSG, $1)
    else
      lines = body.split("\n")
      if /MVFS_FILE_NUMBER=(\d+)/ =~ lines[2]
        fn = $1.to_i
        res.store(:MVFS_FILE_NUMBER, fn)
        res_array = []
        files = lines[3..-1].join("\n").split("\036")[0, fn]
        files.each {|f|
          items = f.split("\017", -1)
          res_array.push(items)
        }
        res.store(:MVFS_FILE, res_array)
      end
    end
    res
  end

  # DONE
  def get_all_permissions(target, is_folder)
    body = http_post('MemberGetAllPermissions', {
        :TargetPath => target,
        :SessionID_ => @session_id,
        :TargetIsFolder => is_folder,
        #:Referer => $this->_referer()
    })
    res = {}
    if /MVFS_ERROR_MSG=(.+)/m =~ body
      res.store(:MVFS_ERROR_MSG, $1)
    else
      lines = body.split("\n")
      if /MVFS_OBJECT_ALLPERMISSIONS=(.+)/ =~ lines[2]
        res.store(:MVFS_OBJECT_ALLPERMISSIONS, $1)
      end
      res.store(:OTHER, lines[3])
      gn = lines[4].to_i
      group_array = []
      # 0:group_id, :1 => permission :2 => group_name
      gn.times {|i| group_array.push([lines[i * 3 + 5], lines[i * 3 + 6], lines[i * 3 + 7]])}
      res.store(:GROUP, group_array)
    end
    res
  end

  # DONE
  def get_permission_for_user(target, is_folder)
    body = http_post('MemberGetPermissionForUser', {
        :TargetPath => target,
        :SessionID_ => @session_id,
        :TargetIsFolder => is_folder
        #:Referer => $this->_referer()
    })
    res = {}
    if /MVFS_ERROR_MSG=(.+)/m =~ body
      res.store(:MVFS_ERROR_MSG, $1)
    elsif /MVFS_PERMISSION_FOR_USER=(\d)/ =~ body
      res.store(:PERM, $1)
    end
    res
  end

  #TEST
  def set_all_permissions(target,
                          set_target, permission, group_permission, is_folder, own_permission, set_sub_folders_too)

    body = http_post('MemberSetAllPermissions', {
        :SetTarget => set_target,
        :GroupPermission => group_permission,
        :Permission => permission,
        :TargetPath => target,
        :SessionID_ => @session_id,
        :OwnPermission => own_permission,
        :TargetIsFolder => is_folder,
        :SetSubFoldersToo => set_sub_folders_too,
        #:Referer => $this->_referer()
    })
  end

  # DONE  
  def file_attribute_def(folder)
    file_attribute_set = get_file_attribute_set("#{folder}")
    folder_items = file_attribute_set[:MVFS_FILE_ATTRIBUTE]
    if folder_items.nil?
      return {}
    end
    res = {}
    if file_attribute_set.key?(:MVFS_FOLDER_SHOWING_ATTRIBUTES)
      show_items = file_attribute_set[:MVFS_FOLDER_SHOWING_ATTRIBUTES]
      res.store(:MVFS_FOLDER_SHOWING_ATTRIBUTES, show_items)
    end

    item_id = folder_items.map {|f| f[:id]}
    file_name_i = item_id.index('FileName_')
    file_name = folder_items.slice!(file_name_i)
    folder_items.insert(0, file_name)

    file_type_i = item_id.index('FileType_')
    file_type = folder_items.slice!(file_type_i)
    folder_items.insert(0, file_type)

    item_id = folder_items.map {|f| f[:id]}
    res.store(:META_ID, item_id)
    item_label = folder_items.map {|f| f[:name]}
    res.store(:META_LABEL, item_label)
    item_type = folder_items.map {|f| f[:type]}
    res.store(:META_TYPE, item_type)
    item_opt = folder_items.map {|f| f.key?(:opt) ? f[:opt] : nil}
    res.store(:META_OPT, item_opt)
    res
  end

  #DONE
  def get_file_attribute_set(folder)
    body = http_post('MemberGetFileAttributeSet', {
        :SessionID_ => @session_id,
        :FolderPath => folder,
        #  :Referer => ''
    })
    res = {}
    if /MVFS_ERROR_MSG=(.+)/m =~ body
      res.store(:MVFS_ERROR_MSG, $1)
    else
      lines = body.split("\n")
      if /MVFS_FOLDER_SHOWING_ATTRIBUTES=(.+)/ =~ lines[2]
        res.store(:MVFS_FOLDER_SHOWING_ATTRIBUTES, $1.split(":"))
      end
      if /MVFS_FILE_ATTRIBUTE_NUMBER=(\d+)/ =~ lines[3]
        fan = $1.to_i
        res.store(:MVFS_FILE_ATTRIBUTE_NUMBER, fan)
        fa_array = []
        lines[4, fan].each {|fa|
          fa_token = fa.split("\017")
          if fa_token.count == 3
            fa_array.push({:id => fa_token[0], :name => fa_token[1], :type => fa_token[2]})
          elsif fa_token.count > 3
            opt_array = []
            fa_token[3..-1].each {|opt|
              opt_pair = opt.split(":")
              opt_array.push({:text => opt_pair[0], :value => opt_pair[1]})
            }
            fa_array.push({:id => fa_token[0], :name => fa_token[1], :type => fa_token[2], :opt => opt_array})
          end
        }
        res.store(:MVFS_FILE_ATTRIBUTE, fa_array)
      end
    end
    res
  end

  # DONE
  def get_folder_attributes(folder)
    item_names = ["FolderName_", "SubFolders_", "SubFiles_", "SessionTimeout_", "Message_",
                  "DateCreated_", "Creator_", "DateUpdated_", "Operator_",
                  "ShowingFileAttributes", "LockingUser_",
                  "OwnerUser_", "Permission_", "MaxFileVersion_",
                  "ReleaseIng", "OwnPermission"].join("\x1e")

    body = http_post('MemberGetFolderAttributes', {
        :SessionID_ => @session_id,
        :ItemNames => item_names,
        :FolderPath => folder,
        #  :Referer => ''
    })
    res = {}
    if /MVFS_ERROR_MSG=(.+)/m =~ body
      res.store(:MVFS_ERROR_MSG, $1)
    else
      lines = body.split("\n")
      if /MVFS_FOLDER_ATTRIBUTES=(.+)/ =~ lines[2]
        fa = $1.split("\036")
        res.store(:MVFS_FOLDER_ATTRIBUTES, fa)
      end
    end
    res
  end

  #DONE
  def set_folder_attributes(folder, showing_attributes)
    attributes = showing_attributes.join(":")
    body = http_post('MemberSetFolderAttributes', {
        :SessionID_ => @session_id,
        :FolderPath => folder,
        :Attributes => "ShowingFileAttributes=#{attributes}",
        #      :Referer => ''
    })
    _mvfs_error_msg(body)
  end

  #DONE
  def add_file_attribute(folder, new_item_def)
    body = http_post('MemberAddFileAttribute', {
        :SessionID_ => @session_id,
        :NewItem => new_item_def.join("\x0f"),
        :FolderPath => folder,
    })
    _mvfs_error_msg(body)
  end

  #DONE
  def modify_file_attribute(folder, item_name, new_item_def)
    body = http_post('MemberModifyFileAttribute', {
        :SessionID_ => @session_id,
        :NewItem => new_item_def.join("\x0f"),
        :FolderPath => folder,
        :ItemName => item_name,
    })
    _mvfs_error_msg(body)
  end

  #DONE
  def remove_file_attribute(folder, item_name)
    body = http_post('MemberRemoveFileAttribute', {
        :SessionID_ => @session_id,
        :FolderPath => folder,
        :ItemName => item_name,
    })
    _mvfs_error_msg(body)
  end

  #TEST
  def get_file_url_enable_state(file_path)
    body = http_post('MemberGetFileUrlEnableState', {
        :SessionID_ => @session_id,
        :FilePath => file_path,
    })
  end

  #TEST
  def get_file_attributes(file_path)
    folder = file_path[0..file_path.rindex('/')]
    res = file_attribute_def(folder)
    if res.blank?
      return res
    end
    item_id = res[:META_ID]
    item_names = item_id.join("\x1e")
    body = http_post('MemberGetFileAttributes', {
        :SessionID_ => @session_id,
        :FilePath => file_path,
        :ItemNames => item_names,
    })
    file_attributes = []
    if /MVFS_FILE_ATTRIBUTES=(.+)/m =~ body
      file_attributes = $1.split("\036")
    end
    res.store(:FILE_ATTRIBUTES, file_attributes)
    res
  end

  #TEST
  def set_file_attributes(file_path, attributes_hash)
    attributes = ''
    attributes_hash.each do |k, v|
      if attributes != ''
        attributes = attributes + "\x1e"
      end
      if v.instance_of?(Array)
        vi = v.join(',')
        attributes = attributes + "#{k}=#{vi}"
      else
        attributes = attributes + "#{k}=#{v}"
      end
    end
    body = http_post('MemberSetFileAttributes', {
        :SessionID_ => @session_id,
        :FilePath => file_path,
        :Attributes => attributes,
    })
  end

  def get_file_url_enableState(file_path)
    body = http_post('MemberGetFileUrlEnableState', {
        :SessionID_ => @session_id,
        :FilePath => file_path,
    })
  end

  # DONE
  def search_group(opt = {})
    param = {
        :MaxRows_ => 2500,
        :SessionID_ => @session_id,
        #        :Name_ => '',
        #        :UserName_InGroup => '',
        #:EditGroup => 'TRUE'
        #:Referer => $this->_referer()
    }
    param.merge! opt
    body = http_post('MemberSearchGroup', param)
    res = {}
    if /MVFS_ERROR_MSG=(.+)/m =~ body
      res.store(:MVFS_ERROR_MSG, $1)
    else
      lines = body.split("\n")
      if /MVFS_GROUP_LIST=(\d+)/ =~ lines[2]
        group = {}
        lines[3, $1.to_i].each {|g|
          if /(\d+)\.(.+)/ =~ g
            group.store($1, $2)
          end
        }
        res.store(:MVGS_GROUP_LIST, group)
      end
    end
    res
  end

  # DONE
  def group_member_list(group_id_code)
    body = http_post('MemberGroupMemberList', {
        :NeedMemberIDCode => 'TRUE',
        :SessionID_ => @session_id,
        :UseGroupIDCode => 'TRUE',
        :GroupIDCode => group_id_code,
        #:Referer => $this->_referer()
    })
    res = {}
    if /MVFS_ERROR_MSG=(.+)/m =~ body
      res.store(:MVFS_ERROR_MSG, $1)
    else
      if /MVFS_GROUP_MEMBER_LIST=(.+)/m =~ body
        member = []
        $1.split("\r\n").each {|m|
          if /(\d+)\.\[(.+)\](.+)/ =~ m
            member.push([$1, $2, $3])
          end
        }
        res.store(:MVFS_GROUP_MEMBER_LIST, member)
      end
    end
    res
  end

  def _edit_group(param)
    body = http_post('MemberEditGroup', param)
  end

  def create_group(group_name)
    body = _edit_group({
                           :SessionID_ => @session_id,
                           :Operation => 'ADD',
                           :UseGroupIDCode => 'TRUE',
                           :TargetGroup => group_name
                       })
  end

  def rename_group(old_group, new_name)
    body = _edit_group({
                           :Groups => new_name,
                           :SessionID_ => @session_id,
                           :Operation => 'REN',
                           :UseGroupIDCode => 'TRUE',
                           :TargetGroup => old_group
                       })
  end

  def delete_group(group)
    body = _edit_group({
                           :Groups => group,
                           :SessionID_ => @session_id,
                           :Operation => 'DEL',
                           :UseGroupIDCode => 'TRUE',
                           :TargetGroup => group
                       })
  end

  def add_member(group, members)
    m = members.join("\x0a") + "\x0a"
    body = _edit_group({
                           :Groups => m,
                           :SessionID_ => @session_id,
                           :Operation => 'ADD',
                           :UseGroupIDCode => 'TRUE',
                           :TargetGroup => group
                       })
  end

  def delete_member(group, members)
    m = members.join("\x0a") + "\x0a"
    body = _edit_group({
                           :Groups => m,
                           :SessionID_ => @session_id,
                           :Operation => 'M_SUB',
                           :UseGroupIDCode => 'TRUE',
                           :TargetGroup => group
                       })
  end

  # DONE
  def lock_file(file)
    body = http_post('MemberLockFile', {
        :FilePath => file,
        :SessionID_ => @session_id,
        #:Referer => $this->_referer()
    })
  end

  # DONE
  def unlock_file(file)
    body = http_post('MemberUnLockFile', {
        :FilePath => file,
        :SessionID_ => @session_id,
        #:Referer => $this->_referer()
    })
  end

  # DONE
  def copy_file(from_file, to_file, license)
    body = http_post('MemberCopyFile', {
        :SessionID_ => @session_id,
        :ToFile => to_file,
        :FromFile => from_file,
        :OldLicenseCode => license,
        #:Referer => $this->_referer()
    })
  end

  #DONE
  def move_file(from_file, to_file, license)
    body = http_post('MemberMoveFile', {
        :SessionID_ => @session_id,
        :ToFile => to_file,
        :FromFile => from_file,
        :OldLicenseCode => license,
        #:Referer => $this->_referer()
    })
  end

  # DONE
  def remove_file(file)
    body = http_post('MemberRemoveFile', {
        :FilePath => file,
        :SessionID_ => @session_id,
        #:Referer => $this->_referer()
    })
  end

  # DONE
  def copy_folder(from_folder, to_folder, license)
    body = http_post('MemberCopyFolder', {
        :SessionID_ => @session_id,
        :ToFolder => to_folder,
        :FromFolder => from_folder,
        :OldLicenseCode => license,
        #:Referer => $this->_referer()
    })
  end

  #DONE
  def move_folder(from_folder, to_folder, license)
    body = http_post('MemberMoveFolder', {
        :SessionID_ => @session_id,
        :ToFolder => to_folder,
        :FromFolder => from_folder,
        :OldLicenseCode => license,
        #:Referer => $this->_referer()
    })
  end

  # TEST
  def create_folder(folder_path)
    body = http_post('MemberCreateFolder', {
        :SessionID_ => @session_id,
        :FolderPath => folder_path,
        #:Referer => $this->_referer()
    })
    res = {}
    if /MVFS_ERROR_MSG=(.+)/m =~ body
      res.store(:MVFS_ERROR_MSG, $1)
    end
    res
  end

  #DONE
  def rename_folder(folder_path, rename_to)
    body = http_post('MemberRenameFolder', {
        :SessionID_ => @session_id,
        :FolderPath => folder_path,
        :RenameTo => rename_to,
        #:Referer => $this->_referer()
    })
  end

  # DONE
  def remove_folder(folder)
    body = http_post('MemberRemoveFolder', {
        :FolderPath => folder,
        :SessionID_ => @session_id,
        #:Referer => $this->_referer()
    })
  end

  # DONE
  def get_recycle_box
    body = http_post('MemberGetRecycleBox', {
        :SessionID_ => @session_id,
        #:Referer => $this->_referer()
    })
    res = {}
    if /MVFS_ERROR_MSG=(.+)/m =~ body
      res.store(:MVFS_ERROR_MSG, $1)
    else
      lines = body.split("\n")
      if /MVFS_RECYCLEBOX_NUMBER=(\d+)/ =~ lines[2]
        res.store(:MVFS_RECYCLEBOX_NUMBER, $1)
      end
      if /MVFS_RECYCLEBOX_SIZE=(\d+)/ =~ lines[4]
        res.store(:MVFS_RECYCLEBOX_SIZE, $1)
      end
      files = []
      lines[3].split("\036").each {|f|
        files.push(f.split("\017"))
      }
      res.store(:MVFS_RECYCLEBOX, files)
    end
    res
  end

  # DONE
  def delete_recycle_box(old_path)
    body = http_post('MemberDeleteFromRecycleBox', {
        #      :OldPath => 'MVFSALLOBJECTS',
        :OldPath => old_path,
        :SessionID_ => @session_id,
        #:Referer => $this->_referer()
    })
  end

  # DONE
  def return_from_recycle_box(old_path)
    body = http_post('MemberReturnFromRecycleBox', {
        :OldPath => old_path,
        :SessionID_ => @session_id,
        #:Referer => $this->_referer()
    })
  end

  # OBSOLETE
  def get_updater_status
    body = http_post('MemberGetUpdaterStatus', {
        :CurrentVersion => '1.5.2',
        #:Referer => $this->_referer()
    })
  end

  # DONE
  def search_file(opt)
    param = {
        :SessionID_ => @session_id,
        :SearchCount => '10',
        :IsSubSearch => 'TRUE',
        :IsRoot => 'TRUE',
        :FolderPath => '/',
        :MVFS_ArgumentCount => '0',
        #:Referer => $this->_referer()
    }
    param.merge!(opt)

    param[:FolderPath] = param[:FolderPath]
    if param.key?(:FileName_)
      param[:FileName_] = param[:FileName_]
    end

    body = http_post('MemberSearchFile', param)
    res = {}
    lines = body.split("\n")
    if /MVFS_SEARCH_FILE=(\d+)/m =~ lines[2]
      res.store(:MVFS_SEARCH_FILE_COUNT, $1)
      files = []
      lines[3..-2].each do |hit|
        file_info = hit.split("\017")
        files.push file_info if file_info.size == 2
      end
      res.store(:MVFS_SEARCH_FILE, files)
    end
    res
  end

  # DONE
  def get_file(file, version = nil)
    param = {
        :FilePath => file,
        :SessionID_ => @session_id,
        #:Referer => $this->_referer()
    }
    unless version.nil?
      param[:Version] = version
    end
    body = http_post('MemberGetFile', param)
    body
  end

  # DONE
  def put_file(filename, f)

    lock_file(filename)

    body = _post_multipart_no_data('MemberPutFile', {
        :SessionID_ => @session_id,
        :FilePath => filename,
        :FileSize_ => f.size,
        'MVFS-PreUpload' => 'TRUE',
        #:Referer => $this->_referer()
    })
    # "\r\n500\r\nMVFS_ERROR_MSG=OK PreUpload-Result:MVFS_UPLOAD_TOBE_CONTINUE=TRUE\r\n"

    today = Time.now
    file_update_time = "#{today.year}.#{today.month}.#{today.day} #{today.hour}:#{today.min}:#{today.sec}"

    body = _post_multipart('MemberPutFile', {
        :SessionID_ => @session_id,
        :FilePath => filename,
        :FileUpdateTime => file_update_time,
        #:Referer => $this->_referer()
    }, f)
    # "\r\n200 OK\r\nMVFS_PUTFILE_RESPONSE=OK\017/AJAX/\203X\203^\203b\203N\202ɂ\242\202?.pdf\r\n"

  end

  def _post_multipart_no_data(path, params)
    params_a = []
    params.each do |k, v|
      #      v = ERB::Util.u(v)
      params_a.push "#{k}=#{v}"
    end
    mvfs_args = params_a.join '&'

    http = Net::HTTP.new(@host, @port)

    query = ""
    resp, body = http.post("#{@location}/#{path}.mvfs", query,
                           {'Content-Type' => 'multipart/form-data; boundary=myboundary',
                            'MVFS-Arguments' => mvfs_args})
    body
  end

  def _post_multipart(path, params, f)
    filename = params[:FilePath]
    boundary = "--1290980320--dsm1932canton--23140044--0----"
    query = ""
    params.each do |k, v|
      #      v = ERB::Util.u(v)
      query << "--#{boundary}\r\n"
      query << "content-:disposition => form-data; name=\"#{k}\"\r\n"
      query << "\r\n"
      query << "#{v}\r\n"
    end
    query << "--#{boundary}\r\n"
    query << "content-:disposition => form-data; name=\"FileStream\"; filename=\"#{filename}\"\r\n"
    query << "Content-:type => application/octec-stream\r\n"
    #    query << "Content-:type => #{f.content_type}\r\n"
    #    query << "Content-Transfer-E:ncoding => binary\r\n"
    query << "\r\n"
    query << f.read
    query << "\r\n"
    query << "--#{boundary}--\r\n"

    http = Net::HTTP.new(@host, @port)
    resp, body = http.post("#{@location}/#{path}.mvfs", query,
                           {'Content-Type' => "multipart/form-data; boundary=#{boundary}"})
    #    p f.path
    f.close(true)
    body
  end

  # TEST
  def change_passwd(id, old_password, password)
    body = http_post('MemberChangePasswd', {
        :SessionID_ => @session_id,
        :ID_ => id,
        :OldPassWord_ => old_password,
        :PassWord_ => password,
        #:PassWord_2 => password2,
        #:Referer => $this->_referer()
    })
    _mvfs_error_msg(body)
  end

  private

  def _mvfs_error_msg(body)
    res = {}
    if /MVFS_ERROR_MSG=(.+)/m =~ body
      res.store(:MVFS_ERROR_MSG, $1)
    end
    res
  end
end
  
  
