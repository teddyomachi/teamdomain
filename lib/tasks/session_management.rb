# coding: utf-8
require 'pg'
require 'pp'
require 'const/vfs_const'
require 'const/acl_const'
require 'const/stat_const'

module SessionManager
  include Vfs
  include Acl
  include Stat

  def self.register_spin_session(sid, uid, uname, user_agent, login_option, request_uri = '', spin_application = 'spin')
    # go through spin_sessions table
    ss_rec = nil

    if request_uri.blank? or request_uri == ''
      default_server_name = SYSTEM_DEFAULT_SPIN_SERVER
      default_server_port = SYSTEM_DEFAULT_SPIN_SERVER_PORT
      default_server = SpinFileServer.select('spin_url_server_name').find_by_server_port(default_server_port)
      request_uri = default_server[:spin_url_server_name] + '/secret_files/'
    end

    retry_register = ACTIVE_RECORD_RETRY_COUNT
    catch (:try_registration_again) {
      updates_spin_session = 0
      SpinSession.transaction do
        begin
          last_ss = Array.new
          last_session_id = sid
          last_login_time = Time.now
          case login_option
            when LOGIN_FRESH_LOGIN, LOGIN_FRESH_LOGIN_AND_CLEAR_SESSIONS
              if LOGIN_FRESH_LOGIN_AND_CLEAR_SESSIONS
                last_ss = SpinSession.where(spin_uid: uid)
              end
              begin
                ss_rec = SpinSession.create {|ss|
                  ss[:spin_session_id] = sid
                  ss[:spin_last_session] = last_session_id
                  ss[:spin_uid] = uid
                  ss[:spin_uname] = uname
                  ss[:spin_last_login] = last_login_time
                  ss[:spin_login_time] = Time.now
                  ss[:created_at] = Time.now
                  ss[:updated_at] = Time.now
                  ss[:last_access] = Time.now
                  ss[:initial_uri] = request_uri
                  ss[:spin_application] = spin_application
                  ss[:spin_agent_name] = user_agent
                  if user_agent == "BoomboxAPI" # => PHP API
                    ss[:spin_agent_type] = SPIN_API_AGENT_TYPE1
                  else
                    ss[:spin_agent_type] = SPIN_DEFAULT_AGENT
                  end
                }
                if ss_rec.present?
                  updates_spin_session = 1
                end
              rescue ActiveRecord::RecordNotUnique
                return nil
              rescue ActiveRecord::RecordNotSaved
                return nil
              end
            else
              last_ss = SpinSession.where(spin_uid: uid).order("last_access DESC")
              # get the last session id
              if last_ss.count > 0
                last_session_id = last_ss[0][:spin_session_id]
                last_login_time = last_ss[0][:spin_login_time]
                updates_spin_session = SpinSession.where(spin_session_id: last_session_id).update_all(
                    spin_session_id: sid,
                    spin_login_time: Time.now,
                    updated_at: Time.now,
                    last_access: Time.now,
                    spin_agent_type: (user_agent != "BoomboxAPI" ? SPIN_DEFAULT_AGENT : SPIN_API_AGENT_TYPE1)
                )
                ss_rec = SpinSession.find_by(spin_session_id: sid)
              else
                ss_rec = SpinSession.create {|ss|
                  ss[:spin_session_id] = sid
                  ss[:spin_last_session] = last_session_id
                  ss[:spin_uid] = uid
                  ss[:spin_uname] = uname
                  ss[:spin_last_login] = last_login_time
                  ss[:spin_login_time] = Time.now
                  ss[:created_at] = Time.now
                  ss[:updated_at] = Time.now
                  ss[:last_access] = Time.now
                  ss[:initial_uri] = request_uri
                  ss[:spin_application] = spin_application
                  ss[:spin_agent_name] = user_agent
                  if user_agent == "BoomboxAPI" # => PHP API
                    ss[:spin_agent_type] = SPIN_API_AGENT_TYPE1
                  else
                    ss[:spin_agent_type] = SPIN_DEFAULT_AGENT
                  end
                }
                if ss_rec.present?
                  updates_spin_session = 1
                end
              end
          end

          if updates_spin_session <= 0
            return nil
          end
        rescue ActiveRecord::StaleObjectError
          if retry_register > 0
            retry_register -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :try_registration_again
          else
            return nil
          end
        end # => end of block
      end # end of transaction
    } # => end of catch block
    return ss_rec
  end

  def self.register_server_session(sid)
    # go through spin_sessions table
    ss = SpinSession.find_by_server_session_id sid
    if ss == nil
      ss = SpinSession.new
      ss.server_session_id = sid
      ss.save
    end
    return ss
  end

  def self.put_timestamp sid
    retry_save = ACTIVE_RECORD_RETRY_COUNT
    catch(:put_timestamp_again) {
      SpinSession.transaction do
        begin
          ss = SpinSession.find_by_spin_session_id sid
          if ss
            ss[:last_access] = Time.now
            ss.save
          end
        rescue ActiveRecord::StaleObjectError
          if retry_save > 0
            retry_save -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :put_timestamp_again
          end
        end
      end
    }
  end

  # => end of put_timestamp

  def self.get_last_access session_id
    ss = SpinSession.find_by_spin_session_id session_id
    if ss.present?
      la = ss[:last_access]
      return la
    else
      return nil
    end
  end

  # => end of get_last_access session_id

  def self.set_last_access session_id, my_request, request_params_string
    if $http_user_agent == 'BoomboxAPI'
      return true
    end
    retry_save = ACTIVE_RECORD_RETRY_COUNT
    catch(:setLast_access_again) {

      SpinSession.transaction do

        begin
          #      SpinSession.find_by_sql('LOCK TABLE spin_sessions IN EXCLUSIVE MODE;')
          ss = SpinSession.find_by_spin_session_id session_id
          if ss.present?
            if ss[0].present?
              ss[0][:last_access] = Time.now
              my_uid = self.get_uid session_id
              log_msg = ':set_last_accdess => uid[' + my_uid.to_s + '] : request[' + my_request.to_s + '] : ' + request_params_string.to_s
              FileManager.logger(session_id, log_msg)
              return ss[0].save
            else
              return false
            end # => end of if ss[0]
          end # => end of unless-block
        rescue ActiveRecord::StaleObjectError
          if retry_save > 0
            retry_save -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :setLast_access_again
          end
        end
      end # => end of transaction
    }
    return false
  end

  # => end of get_last_access session_id

  def self.force_logout session_id
    ss = SpinSession.find_by_spin_session_id session_id
    if ss
      ss[:spin_last_logout] = Time.now
      if ss.save
        return true
      else
        return false
      end
    else
      return false
    end
  end

  # => end of self.force_logout

  def self.is_logged_out session_id
    ss = SpinSession.find_by_spin_session_id session_id
    if ss.present?
      if ss[:spin_last_logout].present?
        return true
      else
        return false
      end
    else
      return true
    end
  end

  # => end of self.is_logged_out

  def self.auth_request(p, rses)
    sps = p['session_id']
    #    if rses
    return auth_session sps, rses
    #    else
    #      return false
    #    end
  end

  def self.extract_cookies(my_request_header)
    cks = nil
    my_request_header.each do |key, value|
      # printf "%s:%s\n",key,value
      if key == "HTTP_COOKIE"
        # pp cks
        cks = value
        break
      end
    end
    return cks
  end

  def self.extract_cookie_value(cks, ckname)
    # pp cks
    ssid = nil
    cks.split(/;\s*/).each do |ses|
      if ses.start_with? "#{ckname}="
        ssid = ses.split(/=/)[1]
        break
      end
    end
    return ssid
  end

  def self.auth_session_store(my_cookies, my_cookie_name)
    ssid = nil
    ret = false
    conn = nil
    my_cookies.split(/;\s*/).each do |ses|
      if ses.start_with? "#{my_cookie_name}="
        ssid = ses.split(/=/)[1]
        break
      end
    end
    printf "ssid = %s\n", ssid
    case ENV['RAILS_ENV']
      when 'development'
        logger.debug 'development env@session_management'
        conn = PG::Connection.open(:dbname => "spin_development", :user => "spinadmin", :password => "postgres")
      when 'test'
        logger.debug 'test env@session_management'
        conn = PG::Connection.open(:dbname => "test", :user => "spinadmin", :password => "postgres")
      when 'production'
        logger.debug 'production env@session_management'
        conn = PG::Connection.open(:dbname => "spin", :user => "spinadmin", :password => "postgres")
      else
        logger.debug 'production env@session_management'
        conn = PG::Connection.open(:dbname => "spin", :user => "spinadmin", :password => "postgres")
    end
    # sql = "SELECT * FROM sessions"
    res = conn.exec(%{SELECT * FROM sessions WHERE session_id=\'#{ssid}\'})
    res.each do |i|
      puts i
      if i['session_id'] == ssid
        ret = true
        break
      end
    end
    conn.close
    # return true if session id is valid
    return ret
  end

  # authenticate session using ASctiveRecord
  # It verifies session id passed from caller by with ActiveRecord::SessionStore:Session 
  def self.auth_rails_session(my_request_session_id)
    #    ret = true 
    #    printf "ssid = %s\n", my_request_session_id
    ret = ActiveRecord::SessionStore::Session.find_by_session_id my_request_session_id
    # return ret # => returns ActiveRecord object
    if ret
      return true
    else
      #      return false
      return true
    end
  end

  # => end of auth_rails_session

  # not used!
  def self.auth_rails_session_old(my_request_session_id)
    ret = false
    conn = nil
    printf "ssid = %s\n", my_request_session_id
    case ENV['RAILS_ENV']
      when 'development'
        conn = PG::Connection.open(:dbname => "spin_development", :user => "spinadmin", :password => "postgres")
      when 'test'
        conn = PG::Connection.open(:dbname => "test", :user => "spinadmin", :password => "postgres")
      when 'production'
        conn = PG::Connection.open(:dbname => "spin", :user => "spinadmin", :password => "postgres")
      else
        conn = PG::Connection.open(:dbname => "spin", :user => "spinadmin", :password => "postgres")
    end
    # sql = "SELECT * FROM sessions"
    res = conn.exec(%{SELECT * FROM sessions WHERE session_id=\'#{my_request_session_id}\'})
    res.each do |i|
      puts i
      if i['session_id'] == my_request_session_id
        ret = true
      end
    end
    conn.close
    # return true if session id is valid
    return ret
  end

  def self.auth_session(my_spin_session, my_server_session)
    # this method works only under the condition that both session id's are unique.     
    # initialise
    ssrec = SpinSession.find_by_spin_session_id my_spin_session
    if ssrec.present?
      return true
    else
      emsg = "SessionManager.auth_spin_session : invalid session id = " + my_spin_session
      FileManager.rails_logger(emsg)
      return false
    end
  end

  # => end of auth_session

  def self.auth_spin_session(my_spin_session)
    # this method works only under the condition that both session id's are unique.     
    # initialise
    # printf "(spin_session,server_session) = ( %s, %s )\n", my_spin_session,my_server_session
    # search spin_session
    ssrec = SpinSession.find_by_spin_session_id my_spin_session
    if ssrec.present?
      return true
    else
      emsg = "SessionManager.auth_spin_session : invalid session id = " + my_spin_session
      FileManager.rails_logger(emsg)
      return false
    end
    # return true if session id is valid
  end

  # => end of auth_session

  def self.get_uid_gid ssid, primary_group_id_only = false
    # this method works only under the condition that both session id's are unique.     
    # initialise
    if ssid == nil
      FileManager.rails_logger("SessionManager.get_uid_gid : null session id has passed")
      return nil
    end
    rethash = {}
    #    my_proc = proc {|my_sid,my_rethash|
    if ssid == ADMIN_SESSION_ID
      rethash[:uid] = ACL_SUPERUSER_UID
      rethash[:gid] = ACL_SUPERUSER_GID
      rethash[:gids] = [ACL_SUPERUSER_UID]
      return rethash
    end
    ssrec = {}
    ssrec = SpinSession.readonly.select("spin_uid").find_by_spin_session_id(ssid)
    if ssrec.blank?
      return nil
    end

    my_uid = ssrec[:spin_uid]
    #    my_gid = ssrec[:spin_gid]
    spin_user_obj = nil
    spin_user_obj = SpinUser.readonly.select("spin_gid").find_by_spin_uid(my_uid)
    if spin_user_obj.blank?
      return nil
    end

    my_gid = spin_user_obj[:spin_gid] # => primary gruop id

    if primary_group_id_only
      rethash[:uid] = my_uid
      rethash[:gid] = my_gid
      return rethash
    end

    pgids = SpinGroupMember.get_parent_gids(my_gid)

    my_gids = [my_gid]
    my_gids += pgids
    rethash[:uid] = my_uid
    rethash[:gid] = my_gid
    rethash[:gids] = my_gids.uniq

    # return true if session id is valid
    return rethash
  end

  def self.get_uid ssid, transaction_control = true
    if ssid == nil
      FileManager.rails_logger("SessionManager.get_uid : null session id has passed")
      return nil
    end
    # this method works only under the condition that both session id's are unique.     
    # initialise
    # search spin_session

    ssrec = nil
    ssrec = SpinSession.readonly.select("spin_uid").find_by_spin_session_id ssid
    if ssrec.blank?
      return nil
    end

    return ssrec[:spin_uid]
  end

  # => end of self.get_uid ssid

  def self.get_last_session sid
    # returns the last session but me
    uid = self.get_uid sid
    if uid.blank?
      return nil
    end
    begin
      ses = SpinSession.readonly.select("spin_session_id").where(spin_uid: uid).order("last_access DESC")
      if ses.count == 1
        return nil
      elsif ses.count > 1
        return ses[1][:spin_session_id]
      else
        return nil
      end # =>  end of if
    rescue ActiveRecord::RecordNotFound
      return nil
    end

  end

  # => end of self.get_last_session uid

  def self.get_timed_out_sessions session_timeout_var = ANY_VALUE, spin_uid = ANY_UID
    timed_out_sessions = Array.new
    # get session timeout
    server_port = SYSTEM_DEFAULT_SPIN_SERVER_PORT

    sfs = nil
    sfs = SpinFileServer.find_by_server_port server_port
    if sfs.blank?
      return timed_out_sessions
    end

    session_timeout = DEFAULT_SPIN_SESSION_TIMEOUT

    if session_timeout_var != ANY_VALUE
      session_timeout = session_timeout_var
    else
      session_timeout = (sfs[:session_timeout] > 0 ? sfs[:session_timeout] : DEFAULT_SPIN_SESSION_TIMEOUT)
    end

    ses = []
    begin
      if spin_uid == ANY_UID
        ses = SpinSession.readonly.select("spin_session_id").where(["last_access < ?", (Time.now - session_timeout)])
      else
        ses = SpinSession.readonly.select("spin_session_id").where(["last_access < ? AND spin_uid = ?", (Time.now - session_timeout), spin_uid])
      end
    rescue ActiveRecord::RecordNotFound
      return timed_out_sessions
    end

    ses.each {|s|
      timed_out_sessions.push(s[:spin_session_id])
    }

    return timed_out_sessions

  end

  # => end of self.get_timedout_sessoin uid = -1

  def self.is_login_directory sid, dir_key
    # search spin_session
    ssrec = nil
    begin
      ssrec = SpinSession.find_by_spin_session_id ssid
    rescue ActiveRecord::RecordNotFound
      return false
    end

    begin
      login_user = SpinUser.find_by_spin_uid ssrec[:spin_uid]
      if dir_key == login_user[:spin_login_directory]
        return true
      else
        return false
      end
    rescue ActiveRecord::RecordNotFound
      return false
    end

  end

  # => end of self.is_login_directory sid, dir_key

  def self.setup_login_environment sid, login_option
    user_obj = Hash.new
    cwdoma = nil
    cwda = nil
    my_login_domain = ''
    my_login_directory = ''
    my_current_directory = ''
    my_current_domain = ''

    # get uid for the session 'sid'
    my_uid_gids = self.get_uid_gid sid
    my_uid = my_uid_gids[:uid]

    # clear expired domain data, folder data amd file data
    expired_sessions = self.get_timed_out_sessions(ANY_VALUE, my_uid)
    if expired_sessions.size > 0
      expired_sessions.each {|xps|
        expired_domain_records = DomainDatum.where(["session_id = ?", xps])
        expired_domain_records.each {|xpr|
          begin
            xpr.destroy
          rescue ActiveRecord::StaleObjectError
            msg = "setup_loginenvironment : session [" + xpr[:session_id] + "] domain #{xpr[:domain_name]} is already destoryed."
            FileManager.logger(sid, msg, 'LOCAL', LOG_ERROR)
            break
          end
        }
        expired_folder_records = FolderDatum.where(["session_id = ?", xps])
        expired_folder_records.each {|xpr|
          begin
            xpr.destroy
          rescue ActiveRecord::StaleObjectError
            msg = "setup_loginenvironment : session [" + xpr[:session_id] + "] folder #{xpr[:text]} is already destoryed."
            FileManager.logger(sid, msg, 'LOCAL', LOG_ERROR)
            break
          end
        }
        expired_file_records = FileDatum.where(["session_id = ?", xps])
        expired_file_records.each {|xprf|
          begin
            xprf.destroy
          rescue ActiveRecord::StaleObjectError
            msg = "setup_loginenvironment : session [" + xprf[:session_id] + "] file #{xprf[:file_name]} is already destoryed."
            FileManager.logger(sid, msg, 'LOCAL', LOG_ERROR)
            break
          end
        }
        expired_clip_boards_data = ClipBoards.where(["session_id = ?", xps])
        expired_clip_boards_data.each {|old_clip_boards_datum|
          begin
            old_clip_boards_datum.destroy
          rescue ActiveRecord::StaleObjectError
            msg = "setup_loginenvironment : session [" + xprf[:session_id] + "] clip_board #{xprf[:node_hash_key]} is already destoryed."
            FileManager.logger(sid, msg, 'LOCAL', LOG_ERROR)
            break
          end
        }
      }
    end

    user_obj = nil
    begin
      user_obj = SpinUser.find_by(spin_uid: my_uid)
    rescue ActiveRecord::RecordNotFound
      return false
    end

    # get the last session data
    last_session_id = self.get_last_session sid # last_session_id = { nil, session str }

    # get login directory
    logd = nil
    if user_obj[:spin_login_directory].present?
      my_login_directory = user_obj[:spin_login_directory]
    else
      begin
        logd = SpinUser.find_by(spin_uid: DEFAUTL_TEMPLATE_UID)
        my_login_directory = logd[:spin_login_directory]
      rescue ActiveRecord::RecordNotFound
        return false
      end
    end

    if user_obj[:spin_default_domain].present?
      my_login_domain = user_obj[:spin_default_domain]
    else
      # get my_login_domain
      begin
        logd = SpinUser.find_by(spin_uid: DEFAUTL_TEMPLATE_UID)
        if logd.blank?
          logdoms = SpinNode.get_domains(my_login_directory)
          ids = SessionManager.get_uid_gid(sid)
          adoms = SpinDomain.search_accessible_domains(sid, ids[:gids])
          my_login_domain = nil
          logdoms.each {|ld|
            adoms.each {|ad|
              if ld == ad[:hash_key]
                my_login_domain = ld
                break
              end
            }
            break unless my_login_domain.blank?
          }
        else
          my_login_domain = logd[:spin_default_domain]
        end
      end
    end

    cwdoma = my_login_domain
    cwda = my_login_directory
    sesssion_obj = nil
    if last_session_id.present? and login_option == LOGIN_WITH_SESSION # => there is latest session data and default login action
      # setup environment based on the last session data
      retry_save = ACTIVE_RECORD_RETRY_COUNT
      retry_set_session = ACTIVE_RECORD_RETRY_COUNT
      catch(:my_session_again) {
        SpinSession.transaction do

          begin

            session_obj = SpinSession.find_by(spin_session_id: sid)
            if session_obj.blank?
              return false
            end
            cwda = (session_obj[:selected_folder_a].blank? ? my_login_directory : session_obj[:selected_folder_a])
            cwdoma = (session_obj[:selected_domain_a].blank? ? my_login_domain : session_obj[:selected_domain_a])
          rescue ActiveRecord::StaleObjectError
            if retry_save > 0
              retry_save -= 1
              sleep(AR_RETRY_WAIT_MSEC)
              throw :my_session_again
            end
          end # => end of begin-rescue
        end # => end of transaction
      } # => end of catch
    else # => no session before this session
      # setup new session
      my_session = nil
      retry_save = ACTIVE_RECORD_RETRY_COUNT
      catch(:setup_new_session_again) {
        SpinSession.transaction do
          begin

            # get login directory from SpinUser
            user_obj = nil
            user_obj = SpinUser.find_by_spin_uid my_uid
            if user_obj.blank?
              return nil
            end

            SpinSession.where(spin_session_id: sid).update_all(
                spin_current_directory: my_login_directory,
                selected_folder_a: my_login_directory,
                spin_current_domain: my_login_domain,
                selected_domain_a: my_login_domain,
                domain_a_is_dirty: true,
                folder_a_is_dirty: true,
                cont_location_domain: 'folder_a',
                file_list_a_is_dirty: true
            )
            cwdoma = my_login_domain
            cwda = my_login_directory
          rescue ActiveRecord::StaleObjectError
            if retry_save > 0
              retry_save -= 1
              sleep(AR_RETRY_WAIT_MSEC)
              throw :setup_new_session_again
            end
          end
        end # => end of transaction
      }
    end # => end of if last_session_id.present? and login_option == LOGIN_WITH_SESSION
    $domain_at_lolgin = cwdoma
    $folder_at_login = cwda
    DomainDatum.fill_domains(sid, 'folder_a')
    FolderDatum.fill_folders(sid, 'folder_a', cwdoma, nil, PROCESS_FOR_UNIVERSAL_REQUEST, false, DEPTH_TO_TRAVERSE, true)

    rethash_setup = { :cdomain => my_login_domain, :cfolder => my_login_directory}
    if DomainDatum.select_domain(sid, cwdoma, 'folder_a')
      rethash_setup[:cdomain] = cwdoma
    end
    if FolderDatum.select_folder(sid, cwda, 'folder_a', cwdoma)
      rethash_setup[:cfolder] = cwda
    end

    return rethash_setup
  end

  # => end of setup_login_environment

  def self.is_selected_domain sid, hash_key, location
    s = nil

    case location
      when 'folder_a', 'folder_at', 'folder_atfi'
        s = SpinSession.find_by_spin_session_id_and_selected_domain_a sid, hash_key
      when 'folder_b', 'folder_bt', 'folder_btfi'
        s = SpinSession.find_by_spin_session_id_and_selected_domain_b sid, hash_key
    end
    if s.blank?
      return false
    end

    case location
      when 'folder_a'
        if hash_key == s[:selected_domain_a]
          return true
        end
      when 'folder_b'
        if hash_key == s[:selected_domain_b]
          return true
        end
      else
        return false
    end
  end

  # => end of is_selected_domain ssid, dd[:hash_key], location

  def self.is_selected_folder sid, folder_key, location
    #    ActiveRecord::Base.transaction do
    ses = nil
    ses = SpinSession.find_by_spin_session_id sid
    if ses.blank?
      return false
    end

    case location
      when 'folder_a'
        if ses[:selected_folder_a] == folder_key
          return true
        else
          return false
        end
      when 'folder_b'
        if ses[:selected_folder_b] == folder_key
          return true
        else
          return false
        end
      when 'folder_at'
        if ses[:selected_folder_at] == folder_key
          return true
        else
          return false
        end
      when 'folder_bt'
        if ses[:selected_folder_bt] == folder_key
          return true
        else
          return false
        end
      when 'folder_atfi'
        if ses[:selected_folder_atfi] == folder_key
          return true
        else
          return false
        end
      when 'folder_btfi'
        if ses[:selected_folder_btfi] == folder_key
          return true
        else
          return false
        end
      else
        return false
    end
  end

  # => end of is_selected_folder ssid, dd[:hash_key], location

  def self.get_selected_folder sid, cont_location
    #    ActiveRecord::Base.transaction do
    #    location = cont_location.sub(/folder_/,'domain_')
    srec = nil
    srec = SpinSession.find_by_spin_session_id sid
    if srec.blank?
      return nil
    end

    case cont_location
      when 'folder_a'
        return (srec[:selected_folder_a].blank? ? $folder_at_login : srec[:selected_folder_a])
      when 'folder_b'
        return srec[:selected_folder_b]
      when 'folder_at'
        return srec[:selected_folder_at]
      when 'folder_bt'
        return srec[:selected_folder_bt]
      when 'folder_atfi'
        return srec[:selected_folder_atfi]
      when 'folder_btfi'
        return srec[:selected_folder_btfi]
      else
        return nil
    end
  end

  # => end of is_selected_folder ssid, dd[:hash_key], location

  def self.get_selected_domain sid, cont_location = 'folder_a'
    #    ActiveRecord::Base.transaction do
    #    location = cont_location.sub(/folder_/,'domain_')
    srec = nil
    srec = SpinSession.find_by_spin_session_id sid
    if srec.blank?
      return nil
    end

    case cont_location
      when 'folder_a'
        return (srec[:selected_domain_a].blank? ? $domain_at_lolgin : srec[:selected_domain_a])
      when 'folder_b', 'folder_b', 'folder_bt', 'folder_btfi'
        return srec[:selected_domain_b]
      else
        return nil
    end
  end

  # => end of is_selected_folder ssid, dd[:hash_key], location

  def self.get_current_location sid
    #    ActiveRecord::Base.transaction do
    #    location = cont_location.sub(/folder_/,'domain_')
    srec = nil
    srec = SpinSession.find_by_spin_session_id sid
    if srec.blank?
      return nil
    end

    if srec[:cont_location_folder].blank?
      return DEFAULT_FOLDER_CONT_LOCATION
    else
      return srec[:cont_location_folder]
    end
  end

  # => end of is_selected_folder ssid, dd[:hash_key], location

  def self.set_location_dirty sid, location, is_list = false, bflag = true
    my_session = nil
    retry_save = ACTIVE_RECORD_RETRY_COUNT
    f = nil
    catch(:set_location_dirty_again) {

      ActiveRecord::Base.transaction do

        begin
          my_session = nil
          begin
            my_session = SpinSession.find_by(spin_session_id: sid)
            selected_folder_at_location_a = nil
            selected_domain_at_location_a = nil
            if my_session[:selected_folder_a].blank?
              selected_folder_at_location_a = SessionManager.get_selected_folder(sid, location)
            else
              selected_folder_at_location_a = my_session[:selected_folder_a]
            end
            if my_session[:selected_domain_a].blank?
              selected_domain_at_location_a = SessionManager.get_selected_domain(sid, location)
            else
              selected_domain_at_location_a = my_session[:selected_domain_a]
            end
          rescue ActiveRecord::RecordNotFound
            return nil
          end

          case location
            when 'folder_a'
              if is_list
                urecs = FolderDatum.where(session_id: sid, spin_node_hashkey: selected_folder_at_location_a, domain_hash_key: selected_domain_at_location_a).update_all(is_dirty_list: bflag, is_new_list: false)
                return (urecs == 1 ? true : false)
                # f = FolderDatum.find_by_spin_node_hashkey selected_folder_at_location_a
                # f[:is_dirty_list] = bflag
                # f[:is_new_list] = false
                # return f.save
              else
                urecs = FolderDatum.where(session_id: sid, spin_node_hashkey: selected_folder_at_location_a, domain_hash_key: selected_domain_at_location_a).update_all(is_dirty_list: bflag, is_new_list: false)
                return (urecs == 1 ? true : false)
                #   f = FolderDatum.find_by_spin_node_hashkey selected_folder_at_location_a
                #   f[:is_dirty] = bflag
                #   f[:is_new] = false
                #   return f.save
              end
            when 'folder_b'
              if is_list
                f = FolderDatum.find_by_spin_node_hashkey my_session[:selected_folder_b]
                f[:is_dirty_list] = bflag
                f[:is_new_list] = false
                return f.save
              else
                f = FolderDatum.find_by_spin_node_hashkey my_session[:selected_folder_b]
                f[:is_dirty] = bflag
                f[:is_new] = false
                return f.save
              end
            when 'folder_at'
              f = FolderDatum.find_by_spin_node_hashkey my_session[:selected_folder_at]
              f[:is_dirty] = bflag
              f[:is_new] = false
              return f.save
            when 'folder_bt'
              f = FolderDatum.find_by_spin_node_hashkey my_session[:selected_folder_bt]
              f[:is_dirty] = bflag
              f[:is_new] = false
              return f.save
            when 'folder_atfi'
              f = FolderDatum.find_by_spin_node_hashkey my_session[:selected_folder_atfi]
              f[:is_dirty] = bflag
              f[:is_new] = false
              return f.save
            when 'folder_btfi'
              f = FolderDatum.find_by_spin_node_hashkey my_session[:selected_folder_btfi]
              f[:is_dirty] = bflag
              f[:is_new] = false
              return f.save
            when 'domain_a'
              f = DomainDatum.find_by_spin_domain_hashkey my_session[:selected_domain_a]
              f[:is_dirty] = bflag
              f[:is_new] = false
              return f.save
            when 'domain_b'
              f = DomainDatum.find_by_spin_domain_hashkey my_session[:selected_domain_b]
              f[:is_dirty] = bflag
              f[:is_new] = false
              return f.save
            when 'file_listA'
              f = FolderDatum.find_by_spin_node_hashkey my_session[:selected_folder_a]
              f[:is_dirty_list] = bflag
              f[:is_new_list] = false
              return f.save
            when 'file_listB'
              f = FolderDatum.find_by_spin_node_hashkey my_session[:selected_folder_b]
              f[:is_dirty_list] = bflag
              f[:is_new_list] = false
              return f.save
            else
              return nil
          end
        rescue ActiveRecord::StaleObjectError
          if retry_save > 0
            retry_save -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :set_location_dirty_again
          end
        end
      end # => end of transaction
    }
    return f[:is_dirty]
  end

  # => end of set_location_dirty

  def self.set_location_clean sid, location, is_list = false
    self.set_location_dirty sid, location, is_list, false
  end

  def self.is_dirty_location sid, location, obj_key, is_list = false
    #    ActiveRecord::Base.transaction do
    begin
      case location
        when 'domain_a', 'domain_b'
          bool_dirty = DomainDatum.is_dirty_domain sid, location, obj_key
          return bool_dirty
        when 'folder_a', 'folder_b', 'folder_at', 'folder_bt', 'folder_atfi', 'folder_btfi'
          bool_dirty = FolderDatum.is_dirty_folder sid, location, obj_key, is_list
          return bool_dirty
        else
          return true
      end
    rescue ActiveRecord::RecordNotFound
      return false
    end
    #    end # => end of transaction
  end

  # => endof is_dirty_location sid, location

  def self.get_current_selected_group_name session_id
    srec = nil
    srec = SpinSession.find_by_spin_session_id session_id
    if srec.blank?
      return nil
    end
    return srec[:current_selected_group_name]
  end

# => end of get_current_selected_group_name session_id

end
