# coding: utf-8
require 'const/stat_const'
require 'tasks/request_broker'
require 'tasks/session_management'
require 'pg'
require 'pp'

class SecretFilesController < ApplicationController
  protect_from_forgery :except => [:proc_login_view, :php, :allow_cross_domain_access]
  include RequestBroker
  # after_action :set_spin_session

  before_action :allow_cross_domain_access

  def allow_cross_domain_access
    #    response.headers["Content-Type"] = "application/pdf"
    #    response.headers["Content-Disposition"] = "inline"
  end

  # this is where requests from clients are routed via apache-passenger-rails
  def proc_login_view
    render :json => "{:success => true}"
  end

  def php
    #####################################################################################################
    # set application name and start url unless they aren't set
    #####################################################################################################
    unless @appl_conf.present?
      @appl_conf = Hash.new
    end
    if @appl_conf["appl_name"].present?
      @appl_conf["appl_name"] = "securedomain"
      @appl_conf["start_url"] = "/securedomain/"
    end
    # refresh sever info
    @appl_conf["host"] = request.headers["SERVER_NAME"]
    @appl_conf["port"] = request.headers["SERVER_PORT"]
    # logger.debug request.headers["REQUEST_URI"].split(/:/)
    if request.headers["HTTP_REFERER"] == nil
      @appl_conf["protocol"] = 'http'
    else
      @appl_conf["protocol"] = request.headers["HTTP_REFERER"].split(/:/)[0]
    end
    $http_user_agent = request.headers["HTTP_USER_AGENT"]
    $http_host = request.headers["HTTP_HOST"]
    if $http_host.include?(":")
      t_host = $http_host
      host_port = t_host.split(/:/)
      $http_port = host_port[1].to_i
    else
      $http_port = 80
    end
    $spin_session_id = ''
    if request.headers["HTTP_REFERER"] != nil
      stmp = request.headers["HTTP_REFERER"]
      if stmp != nil # => there is REFERFER
        stmp2 = stmp.split(/=/)
        $spin_session_id = stmp2[-1] # => the last element is the spin session id
      end
    end

    logger.debug @appl_conf
    #####################################################################################################
    # push params to spin_session table
    #####################################################################################################
    current_session = params['session_id']
    if current_session.empty?
      current_session = $spin_session_id
    end
    app_conf = @appl_conf.to_json
    app_params = params.to_s
    #    app_params = params.to_json
    #####################################################################################################
    # Authenticate session
    #####################################################################################################
    cks = request.headers["HTTP_COOKIE"]
    if cks != nil
      ck = cks.split(/=/)
    end
    # current_session = ck[1]
    #####################################################################################################
    # save parameters in spin_session table
    #####################################################################################################

    cs = SpinSession.find_by_spin_session_id current_session
    rses = false
    if cs.present?
      retry_save = ACTIVE_RECORD_RETRY_COUNT
      catch(:cella_session_again) {
        SpinSession.transaction do
          begin
            cs[:spin_session_params] = app_params
            cs[:spin_session_conf] = app_conf
            if ck.blank?
              cs[:server_session_id] = current_session
            else
              # cs[:server_session_id] = current_session
              cs[:server_session_id] = ck[1]
            end
            cs.save
            rses = true
          rescue ActiveRecord::StaleObjectError
            if retry_save > 0
              retry_save -= 1
              sleep(AR_RETRY_WAIT_MSEC)
              throw :cella_session_again
            end
          end
        end # => end of transaction
      }
    elsif params[:request_type] == 'logout'
      rses = true
    else
      errors_str = '無効なセッションです'
      render :json => {:success => false, :status => false, :errors => errors_str}
      return
    end
    # rses = SessionManager.auth_rails_session ck[1]
    if rses != true
      rses = SessionManager.auth_rails_session cookies['_secret_files_session']
    end
    #    rses = true   #=> fake!
    if rses == false
      puts ">> authentication failed at auth_rails_session"
      errors_str = 'セッション情報が不正のためアクセスが拒否されました!'
      render :json => {:success => false, :status => false, :errors => errors_str} and return
    else
      # pp request.headersl
      cmp_req = 'delete_folder'
      if params[:request_type] == cmp_req
        # call request broker
        #        if params[:request_type] == 'delete_folder'
        #          render :json => { :success => true, :status => INFO_PUT_NODE_INTO_RECYCLER_SUCCESS }
        #        end
        xcall_params = params
        xcall_params[:request_type] = 'thread_delete_folder'
        rethash = RequestBroker.xcall(params, current_session)

        status_code = (rethash[:status].class == Fixnum ? rethash[:status] : 0)

        unless status_code > 0 and (status_code & INFO_RENDERING_DONE) == 1

          if rethash[:success] == true
            # special case
            #  upload_file and download_file request
            if rethash[:redirect_uri] # => upload_request
              if rethash[:is_download]
                # flash[:notice] = params['session_id']
                # redirect_to rethash[:redirect_uri]
                render :json => rethash  and return
              else
                render :json => rethash  and return
              end
              return
            else # => other requests
              render :json => rethash  and return
            end
          else # => RequestBroker returned false status
            if params[:request_type] == 'login_auth'
              errors_str = 'ユーザIDかパスワードが間違っています'
              render :json => {:success => false, :status => ERROR_SYSADMIN_INVALID_PASSWORD, :errors => errors_str}  and return
            else
              #              err_str = "#{params[:request_type]}:リクエスト処理が失敗しました!"
              render :json => rethash  and return
              #            render :json => { success: false, status: false, errors: err_str}
            end
          end
        end
      elsif params[:request_type] == 'file_preview' or params[:request_type] == 'logout' or SessionManager.auth_request(params, cookies['_secret_files_session'].present? ? cookies['_secret_files_session'] : nil) or current_session.present?
        # call request broker
        #        if params[:request_type] == 'delete_folder'
        #          render :json => { :success => true, :status => INFO_PUT_NODE_INTO_RECYCLER_SUCCESS }
        #        end
        #        temp=params[:request_type];
        rethash = RequestBroker.xcall(params, current_session)

        if rethash[:status].present?
          status_code = (rethash[:status].class == Integer ? rethash[:status] : 0)
        else
          status_code = 0
        end

        unless status_code > 0 and (status_code & INFO_RENDERING_DONE) == 1

          if rethash[:success].present? and rethash[:success] == true
            # special case
            #  upload_file and download_file request
            if rethash[:redirect_uri] # => upload_request
              if rethash[:is_download]
                # flash[:notice] = params['session_id']
                # redirect_to rethash[:redirect_uri]
                render :json => rethash  and return
                # redirect_to rethash[:redirect_uri]
              else
                render :json => rethash  and return
                # redirect_to rethash[:redirect_uri]
              end
              return
            else # => other requests
              render :json => rethash  and return
            end
          else # => RequestBroker returned false status
            if params[:request_type] == 'login_auth'
              errors_str = 'ユーザIDかパスワードが間違っています'
              render :json => {:success => false, :status => false, :errors => errors_str}  and return
            else
              #              err_str = "#{params[:request_type]}:リクエスト処理が失敗しました!"
              render :json => rethash  and return
              #            render :json => { success: false, status: false, errors: err_str}
            end
          end
        end
      else # => SessionManager.auth_request returned false
        errors_str = '不正リクエストでアクセスが拒否されました!'
        render :json => {:success => false, :status => false, :errors => errors_str} and return
      end
    end
    render :json => rethash
  end # => end of php

end # => end of cella

# class SpinAppl
# def initialize
# # my declarations and definitions
# @appl_conf = {
# appl_name: "spin",
# start_url: "/spin_login"
# }
# if defined? production
# @appl_conf["protocol"] = "https"
# @appl_conf["host"] = "192.168.2.119",
# @appl_conf["port"] = 443
# else
# @appl_conf["protocol"] = "http"
# @appl_conf["host"] = "192.168.2.119",
# @appl_conf["port"] = 0
# end
# end
# 
# def appl_conf_values
# return @appl_conf
# end
# # end of my decs. and defs.
# end
