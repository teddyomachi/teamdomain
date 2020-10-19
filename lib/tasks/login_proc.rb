# coding: utf-8

require 'yaml'
require 'pg'
require 'tasks/security'
require 'tasks/session_management'

module LoginProc
  class Exec
    def self.auth(uid,passwd)
      ret = Hash.new
      # raws = SpinUser.where(:spin_uname => "#{uid}",:spin_passwd => "#{passwd}").count
      begin
        user_rec = SpinUser.find_by_spin_uname uid
        if user_rec[:spin_passwd] == passwd
          node_rec = SpinNode.readonly.find_by_spin_node_hashkey(user_rec[:spin_login_directory])
          ret[:success] = true
          ret[:result] = { :uid => user_rec[:spin_uid], :uname => user_rec[:spin_uname], :login_vpath => user_rec[:spin_login_directory], :login_pname => node_rec[:virtual_path], :spin_default_domain => user_rec[:spin_default_domain]}
        else
          ret[:success] = false
          ret[:errors] = 'ユーザ名、パスワードを確認して、ログインして下さい!'
        end
        # ret['session'] = {:id => "#{session[:session_id]}"}
      rescue ActiveRecord::RecordNotFound
        ret[:success] = false
        ret[:errors] = 'ユーザ名、パスワードを確認して、ログインして下さい!'
      end
      return ret
    end
    
    #  # login options
    #  LOGIN_WITH_SESSION = 0
    #  LOGIN_FRESH_LOGIN = 1
    #  LOGIN_FRESH_LOGIN_AND_CLEAR_SESSIONS = 2
    #  LOGIN_DEFAULT_LOGIN = LOGIN_FRESH_LOGIN_AND_CLEAR_SESSIONS
    
    def self.spin_login(uid,passwd)
      ssid = ''
      reth = {}
      reth = self.auth(uid,passwd)
      return ssid unless reth[:success]
      
      # generate session id hash key string
      tmpt = Time.now
      seed_string = rand.to_s + tmpt.to_s
      ssid = Security.hash_key_s seed_string
      # ssid.chomp!
      reth[:session] = ssid
      login_option = 2
      res = reth[:result]
      
      user_agent = 'SPIN_LOGIN'
      SessionManager.register_spin_session ssid, res[:uid], res[:uname], user_agent, login_option
      
      SpinProcess.transaction do
        #        SpinProcess.find_by_sql('LOCK TABLE spin_processes IN EXCLUSIVE MODE;')

        logged_out_sessions = SpinSession.where(["spin_uid = ? AND spin_last_logout NOTNULL",res[:uid]])
        logged_out_sessions.each { |los|
          logged_outs = SpinProcess.where(["session_id = ?",los[:spin_session_id]])
          logged_outs.each { |lo|
            lo.destroy
          }
        }
      end
      # set up login environments for view's
      pwd = SessionManager.setup_login_environment ssid, login_option
      reth[:current_directory] = SpinLocationManager.get_key_vpath ssid, pwd
      
      return reth
    end
  end
end
