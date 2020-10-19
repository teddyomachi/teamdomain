# coding: utf-8
require 'const/vfs_const'
require 'const/acl_const'
require 'const/stat_const'
require 'const/ssl_const'
require 'openssl'
require 'base64'
require 'uri'
require 'json'
require 'pp'

class SpinApiController < ApplicationController
  include Vfs
  include Acl
  include Stat
  include Ssl
  
  def request_broker
    # proccess params
    spin_api_args_e = params[:spinargs]
    # decode spin api args
    rsa_key_pem = SpinNode.get_root_rsa_key
    upload_file_params = params[:upload_file]
    api_params = params[:spinargs]
    fmargs64 = Security.unescape_base64 params[:fmargs]
    upload_params = fmargs64
    # upload_params = Base64.decode64 fmargs64
    file_manager_args = Security.private_key_decrypt_decode64 rsa_key_pem, upload_params
    ssid = file_manager_args[0..39]
    hkey = file_manager_args[40..79]
    file_name = file_manager_args[80..-1]
    
    ######
    @appl_conf["host"] = request.headers["SERVER_NAME"]
    @appl_conf["port"] = request.headers["SERVER_PORT"]
    # logger.debug request.headers["REQUEST_URI"].split(/:/)
    @appl_conf["protocol"] = request.headers["HTTP_REFERER"].split(/:/)[0]
    logger.debug @appl_conf
    #####################################################################################################
    # push params to spin_session table
    #####################################################################################################
    current_session = params['session_id']
    app_conf = @appl_conf.to_json
    app_params = params.to_json
    #####################################################################################################
    # Authenticate session
    #####################################################################################################
    cks = request.headers["HTTP_COOKIE"]
    ck = cks.split(/=/)
    # current_session = ck[1]
    #####################################################################################################
    # save parameters in spin_session table
    #####################################################################################################
    begin
      cs = SpinSession.find_by_spin_session_id current_session
      cs.spin_session_params = app_params
      cs.spin_session_conf = app_conf
      cs.server_session_id = ck[1]
      cs.save
    rescue ActiveRecord::RecordNotFound
      render :json => { :success => false, :status => false, :errors => '無効なセッションです invalid session'}
      return      
    end
    # rses = SessionManager.auth_rails_session ck[1]
    # rses = SessionManager.auth_rails_session cookies['_secret_files_session']
    rses = true   #=> fake!
    if rses == false
      puts ">> authentication failed at auth_rails_session"
      render :json => { :success => false, :status => false, :errors => 'アクセスが拒否されました! access denied'}
    else
      # pp request.headers
      test_phase1 = false
      if SessionManager.auth_request params, cookies['_secret_files_session']
        # call request broker
        rethash = RequestBroker.xcall(params)
        if rethash[:success] == true
          # special case
          #  upload_file and download_file request
          if rethash[:redirect_uri]  # => upload_request
            if rethash[:is_download]
              # flash[:notice] = params['session_id']
              # redirect_to rethash[:redirect_uri]
              render :json => rethash
            else
              render :json => rethash
            end
            return
          else  # => other requests
            render :json => rethash
          end
        else  # => RequestBroker returned false status
          render :json => { :success => false, :status => false, :errors => 'アクセスが拒否されました!'}
        end
      else  # => SessionManager.auth_request returned false
        render :json => { :success => false, :status => false, :errors => 'アクセスが拒否されました!'}
      end
    end
    ######    
  end # => end of request_broker
  
end
