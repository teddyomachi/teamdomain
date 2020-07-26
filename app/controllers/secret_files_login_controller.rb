# coding: utf-8

require 'tasks/request_broker'
require 'tasks/security'
require 'tasks/session_management'
require 'pp'
require_relative './application_controller'

class SecretFilesLoginController < ApplicationController
  protect_from_forgery :except => [:proc_login]
  include RequestBroker


  before_action :allow_cross_domain_access

  def allow_cross_domain_access
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "*"
  end

  def proc_login
    # pp params
    rparams = params
    rparams['request_type'] = 'login_auth'
    ssid = ""

    #    pp request.headers
    # get request uri for later LOGOUT
    request_uri = ''
    server_name = request.headers['SERVER_NAME']
    server_port = request.headers['SERVER_PORT']
    protocol = (server_port == '443' ? 'https:' : 'http:')
    FileManager.rails_logger request.headers['PATH_INFO']
    request_path_tmp = request.headers['PATH_INFO'].split('/')
    request_path = request_path_tmp[1]
    if server_port == '443' or server_port == 80
      request_uri = protocol + '//' + server_name + '/' + request_path + '/'
    else
      request_uri = protocol + '//' + server_name + ':' + server_port + '/' + request_path + '/'
    end
    FileManager.rails_logger request_uri

    # set login mode
    login_option = LOGIN_DEFAULT_LOGIN
    if ENV['RAILS_ENV'] == 'production'
      login_option = rparams['default_login'] = LOGIN_WITH_SESSION
    else
      #login_option = rparams['default_login'] = LOGIN_FRESH_LOGIN_AND_CLEAR_SESSIONS
      login_option = rparams['default_login'] = LOGIN_WITH_SESSION
    end
    # authenticate user
    ret = RequestBroker.xcall(rparams)

    # proceed if authenticated
    if ret[:success] && ret[:success] == true
      # generate session id hash key string
      tmpt = Time.now
      seed_string = rand.to_s + tmpt.to_s
      ssid = Security.hash_key_s seed_string
      # ssid.chomp!
      ret[:session] = ssid
      #      login_option = ret[:login_option]
      res = ret[:result]

      # Is it an activated user?
      user_activation_status = SpinUser.get_user_activation_status res[:uid]
      if user_activation_status == INFO_USER_ACOUNT_IS_NOT_ACTIVATED
        ret[:u_id] = res[:uid]
        ret[:status] = INFO_USER_ACOUNT_IS_NOT_ACTIVATED
      else
        ret[:u_id] = res[:uid]
        ret[:status] = INFO_USER_ACOUNT_ACTIVATED
      end

      user_agent = request.env['HTTP_USER_AGENT']
      SessionManager.register_spin_session ssid, res[:uid], res[:uname], user_agent, login_option, request_uri
      logged_out_sessions = SpinSession.where(["spin_uid = ? AND spin_last_logout NOTNULL", res[:uid]])

      if logged_out_sessions.count > 0
        SpinProcess.transaction do
          logged_out_sessions.each {|los|
            logged_outs = SpinProcess.where(session_id: los[:spin_session_id])
            logged_outs.each {|lo|
              begin
                lo.destroy
              rescue ActiveRecord::StaleObjectError
                msg = '>> StatleObjectError in proc_login to destroy process'
                FileManager.rails_logger(msg, LOG_INFO)
              end
            }
          }
        end
      end


      # set up login environments for view's
      #      rethash = DomainDatum.fill_domains(ssid, 'folder_a')
      #      rethash = DomainDatum.fill_domains(ssid, 'folder_b')

      rethash_setup = SessionManager.setup_login_environment ssid, login_option
      ret[:current_directory] = SpinLocationManager.get_key_vpath ssid, rethash_setup[:cfolder], NODE_DIRECTORY
      # render :json => ret and return
    else
      # render :json => ret and return
    end
    render :json => ret
  end

  def proc_mobile_login
    # pp params
    rparams = params
    rparams['request_type'] = 'mobile_login'
    ssid = ""

    # get request uri for later LOGOUT
    request_uri = ''
    server_name = request.headers['SERVER_NAME']
    server_port = request.headers['SERVER_PORT']
    protocol = (server_port == '443' ? 'https:' : 'http:')
    logger.warn request.headers['PATH_INFO']
    request_path_tmp = request.headers['PATH_INFO'].split('/')
    request_path = request_path_tmp[1]
    if server_port == '443' or server_port == 80
      request_uri = protocol + '//' + server_name + '/' + request_path + '/'
    else
      request_uri = protocol + '//' + server_name + ':' + server_port + '/' + request_path + '/'
    end
    logger.warn request_uri

    # authenticate user
    ret = RequestBroker.xcall(rparams)

    # proceed if authenticated
    if ret[:success] && ret[:success] == true
      # generate session id hash key string
      tmpt = Time.now
      seed_string = rand.to_s + tmpt.to_s
      ssid = Security.hash_key_s seed_string
      # ssid.chomp!
      ret[:session] = ssid
      login_option = ret[:login_option]
      res = ret[:result]

      # Is it an activated user?
      user_activation_status = SpinUser.get_user_activation_status res[:uid]
      if user_activation_status == INFO_USER_ACOUNT_IS_NOT_ACTIVATED
        ret[:u_id] = res[:uid]
        ret[:status] = INFO_USER_ACOUNT_IS_NOT_ACTIVATED
      else
        ret[:u_id] = res[:uid]
        ret[:status] = INFO_USER_ACOUNT_ACTIVATED
      end

      user_agent = request.env['HTTP_USER_AGENT']
      SessionManager.register_spin_session ssid, res[:uid], res[:uname], user_agent, login_option, request_uri
      SpinProcess.transaction do
        #        SpinProcess.find_by_sql('LOCK TABLE spin_processes IN EXCLUSIVE MODE;')

        logged_out_sessions = SpinSession.where(["spin_uid = ? AND spin_last_logout NOTNULL", res[:uid]])
        logged_out_sessions.each {|los|
          logged_outs = SpinProcess.where(["session_id = ?", los[:spin_session_id]])
          logged_outs.each {|lo|
            lo.destroy
          }
        }
      end
      # set up login environments for view' 
      rethash = DomainDatum.fill_domains(ssid, 'folder_a')
      rethash = DomainDatum.fill_domains(ssid, 'folder_b')
      pwd = SessionManager.setup_login_environment ssid, login_option
      ret[:current_directory] = SpinLocationManager.get_key_vpath ssid, pwd, NODE_DIRECTORY
      render :json => ret
    else
      render :json => ret
    end
  end

  def proc_activation
    # pp params
    rparams = params
    #    rparams['request_type'] = 'user_activation'

    # activate user
    ret = RequestBroker.xcall(rparams)

    if ret[:success] == true
      frecs = FolderDatum.find_by_session_id rparams[:session_id]
      frecs.each {|fr|
        fr.destroy
      }
    end
    render :json => ret

  end

  #  def render_proc
  #    render :json => flash['my_auth_return']
  #  end

  def proc_secret_files_login_view
    # pp request
    # pp session
    protocol = 'http'
    req_uri = request.headers['REQUEST_URI']
    logger.debug req_uri
    if req_uri =~ /https:*/
      protocol = 'https'
    elsif req_uri =~ /http:*/
      protocol = 'http'
    end
    logger.debug "protocol = " + protocol
    host = request.headers['HTTP_HOST']
    # target_uri = protocol + '://' + host + '/login/auth.html'
    target_uri = protocol + '://' + host + '/secret_files/index.html'
    # pp target_uri
    logger.debug " target_uri = " + target_uri
    redirect_to target_uri
  end

  def proc_secret_files_ipad_login_view
    # pp request
    # pp session
    protocol = 'http'
    req_uri = request.headers['REQUEST_URI']
    logger.debug req_uri
    if req_uri =~ /https:*/
      protocol = 'https'
    elsif req_uri =~ /http:*/
      protocol = 'http'
    end
    logger.debug "protocol = " + protocol
    host = request.headers['HTTP_HOST']
    target_uri = protocol + '://' + host + '/tlogin/auth.html'
    #    target_uri = protocol + '://' + host + '/secret_files_ipad/auth.html'
    # pp target_uri
    logger.debug " target_uri = " + target_uri
    redirect_to target_uri
  end

  def proc_secret_files_iphone_login_view
    # pp request
    # pp session
    protocol = 'http'
    req_uri = request.headers['REQUEST_URI']
    logger.debug req_uri
    if req_uri =~ /https:*/
      protocol = 'https'
    elsif req_uri =~ /http:*/
      protocol = 'http'
    end
    logger.debug "protocol = " + protocol
    host = request.headers['HTTP_HOST']
    target_uri = protocol + '://' + host + '/slogin/auth.html'
    #    target_uri = protocol + '://' + host + '/secret_files_iphone/auth.html'
    # pp target_uri
    logger.debug " target_uri = " + target_uri
    redirect_to target_uri

  end

end
