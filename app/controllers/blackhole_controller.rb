# coding: utf-8
require 'const/vfs_const'
require 'const/acl_const'
require 'const/ssl_const'
require 'const/stat_const'

class BlackholeController < ApplicationController
  protect_from_forgery :except => [:reject_proc]
  include Vfs
  include Acl
  include Ssl
  include Stat

  def reject_proc(exception = nil)
    var_request_params_s = ''
    var_http_host = '0.0.0.0'
    unless params.blank?
      var_request_params_s = params.to_s
    end
    unless request.blank? or request.headers.blank? or request.headers['HTTP_HOST'].blank?
      var_http_host = request.headers['HTTP_HOST']
    end
    unless params.blank?
      var_request_params_s = params.to_s
      unless exception.blank?
        log_message = 'Request from : ' + var_http_host + ', Params : ' + var_request_params_s + " #{exception.to_s}"
        Rails.logger.warn(log_message)
        render :status => 404, :text => "#{exception.to_s}"
      else
        log_message = 'Request from : ' + var_http_host + ', Params : ' + var_request_params_s
        Rails.logger.warn(log_message)
        render :status => 404, :text => "page not found"
      end
    end
  end  
end
