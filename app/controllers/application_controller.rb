# class ApplicationController < ActionController::API
# end
require 'const/vfs_const'
require 'const/acl_const'
require 'const/ssl_const'
require 'const/stat_const'
require 'utilities/system'
require 'pp'

class ApplicationController < ActionController::Base
  protect_from_forgery :except => [:render_404]
  protect_from_forgery with: :null_session
  # protect_from_forgery with: :exception
  rescue_from ActiveRecord::RecordNotFound, with: :render_404
  rescue_from ActionController::RoutingError, with: :render_404
  rescue_from Exception, with: :render_500

  after_action :set_access_control_headers

  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = '*'
  end

  def render_404(exception = nil)
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
        render :status => 404, :text => "#{exception.to_s}", :template => 'blackhole/application.html.erb'
      else
        log_message = 'Request from : ' + var_http_host + ', Params : ' + var_request_params_s
        Rails.logger.warn(log_message)
        render :status => 404, :text => "page not found", :template => 'blackhole/application.html.erb'
      end
    end
  end

  def render_500(exception = nil)
    var_request_params_s = String.new
    var_http_host = '0.0.0.0'
    unless params.blank?
      var_request_params_s = params.as_json
    end
    unless request.blank? or request.headers.blank? or request.headers['HTTP_HOST'].blank?
      var_http_host = request.headers['HTTP_HOST']
    end
    unless exception.blank?
      log_message = 'Request from : ' + var_http_host + ', Params : ' + " #{exception.to_s}"
      Rails.logger.error(log_message)
      render(:status => 500, :text => "#{exception.to_s}") {pp var_request_params_s} # => , :template => 'secret_files/application.html.erb'
    else
      log_message = 'Request from : ' + var_http_host + ', Params : ' + var_request_params_s.to_s
      Rails.logger.error(log_message)
      render(:status => 500, :text => "internal error" + log_message, :template => 'secret_files/application.html.erb') {pp var_request_params_s}
    end
  end

  # def initialize
  #   # my declarations and definitions
  #   @appl_conf = {
  #       :appl_name => nil,
  #       :start_url => nil
  #   }
  #
  #   case ENV['RAILS_ENV']
  #     when 'development'
  #       logger.debug 'production env@application_controller'
  #       @appl_conf["appl_env"] = {:dbname => "spin_development", :user => "spinadmin", :password => "postgres"}
  #       $my_application_env = 'development'
  #     when 'test'
  #       logger.debug 'test env@application_controller'
  #       @appl_conf["appl_env"] = {:dbname => "test", :user => "spinadmin", :password => "postgres"}
  #       $my_application_env = 'test'
  #     when 'production'
  #       logger.debug 'production env@application_controller'
  #       @appl_conf["appl_env"] = {:dbname => "spin", :user => "spinadmin", :password => "postgres"}
  #       $my_application_env = 'production'
  #     else
  #       logger.debug 'production env@application_controller'
  #       @appl_conf["appl_env"] = {:dbname => "spin", :user => "spinadmin", :password => "postgres"}
  #       $my_application_env = 'development'
  #   end
  #   # @appl_conf["appl_name"] = nil
  #   # @appl_conf["start_url"] = nil
  #   if defined? production
  #     @appl_conf["protocol"] = "http"
  #     @appl_conf["host"] = "192.168.2.119"
  #     @appl_conf["port"] = 443
  #   else
  #     @appl_conf["protocol"] = "http"
  #     @appl_conf["host"] = "192.168.2.119"
  #     @appl_conf["port"] = 3000
  #   end
  #
  #   # pp ENV['RAILS_ENV']
  #   # load parametgers from JSON file "application parameters from applname_appl.json" if there is!
  #   conf_fname = File.dirname(__FILE__) + "/../../config/" + "spin_appl.json"
  #   icon_list = File.dirname(__FILE__) + "/../../config/" + "file_type_icons.json"
  #   if File.exist? conf_fname
  #     spin_params = ""
  #     File.open(conf_fname) {|f| spin_params << f.read}
  #     @appl_conf = JSON.parse spin_params
  #   end
  #   if File.exist? icon_list
  #     icon_list_params = ""
  #     File.open(icon_list) {|f| icon_list_params << f.read}
  #     $file_type_icons = JSON.parse icon_list_params
  #   end
  #
  #   # initialize spin_node_keeper
  #   SpinNodeKeeper::init_spin_node_keeper
  #
  #   # # initialize spin_nodes if count = 0
  #   # if SpinNode.count == 0
  #   #   SpinNode::create_spin_node(Vfs::INITIALIZE_SESSION,0,0,0,Vfs::CREATE_NEW,"/",Vfs::NODE_DIRECTORY,0,0)
  #   # end
  #   # initialize spin_users user templae
  #   # SystemTools::DbTools.init_user_template
  #
  #   # set root node flag in spin_nodes
  #   SystemTools::DbTools.set_domain_root_node_flag
  #
  #   # render "layouts/app_garage"
  # end

  def self.appl_conf_values
    # pp @appl_conf
    return @appl_conf
  end

  def self.get_appl_env(env_name)
    case env_name
      when "dbname"
        if ENV['RAILS_ENV'] == 'development'
          return "spin_development"
        elsif ENV['RAILS_ENV'] == 'production'
          return "production"
        end
      when "user"
        return "spinadmin"
      when "password"
        return "postgres"
      else
        return nil
    end
    #elf.appl_conf_values
    # = @appl_conf["appl_env"]
    #eturn e["#{env_name}"]
  end
end

class String
  def is_binary_data?
    (self.count("^ -~", "^\r\n").fdiv(self.size) > 0.3 || self.index("\x00")) unless empty?
  end
end
