# coding: utf-8
require 'const/vfs_const'
require 'const/acl_const'
require 'const/stat_const'
require 'tasks/session_management'
require 'tasks/security'
require 'utilities/set_utilities'
require 'pg'
require 'pp'


module DatabaseUtility
  class StateUtility < ActiveRecord::Base
    include Vfs
    include Acl
    include Stat

    def self.is_updated_after tdata, qtime, cond = 'all'
      # initialize variables
      qt = Time.new
      SpinDomain.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        case tdata
          when 'SpinDomain'
            if cond == 'all'
              qt = SpinDomain.maximum(:updated_at).to_time
            else
              qto = SpinDomain.readonly.select(:updated_at).where(["id > 0"])
              qt = nil
              qto.each {|q|
                if qt == nil
                  qt = q[:updated_at]
                else
                  if qt < q[:updated_at]
                    qt = q[:updated_at]
                  end
                end
              }
            end # => end of 'SpinDomain' case
        end # => end of case
      end
      if qt > qtime
        return true
      else
        return false
      end
    end # => end of self.is_updated_after tdata, qtime, cond = 'all'
  end

  class SessionUtility < ActiveRecord::Base
    include Vfs
    include Acl

    # set session infomation to spin_sessions
    # params : 
    # sid : session_id
    # type : type of request that call this
    # pharray : hash of parameters which are specific with each request
    def self.set_session_info(sid, type, hkey, location)
      SpinSession.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        sr = SpinSession.find_by(spin_session_id: sid)
        # initialize
        if sr.blank?
          return false
        end
        contl = 'folder_a'
        unless sr # => no record?
          return false
        end
        # do specific process for each request type
        case type
          # change_domain request
          when 'change_domain'
            # folder in concern is folder_a or folder_b
            cl = location
            case cl
              when 'folder_a'
                # sr.spin_domaindata_A_id = hkey
                # sr.spin_domaindata_B_id = nil
                sr.cont_location_domain = 'folder_a'
                sr[:selected_domain_a] = hkey
                sr[:spin_current_domain] = hkey
                sr.save
              when 'folder_b'
                # sr.spin_domaindata_B_id = hkey
                # sr.spin_domaindata_B_id = nil
                sr.cont_location_domain = 'folder_b'
                sr[:selected_domain_b] = hkey
                sr[:spin_current_domain] = hkey
                sr.save
              when 'folder_a'
                # sr.spin_domaindata_A_id = hkey
                # sr.spin_domaindata_B_id = nil
                sr.cont_location_domain = 'folder_a'
                sr[:selected_domain_a] = hkey
                sr[:spin_current_domain] = hkey
                sr.save
              when 'folder_b'
                # sr.spin_domaindata_B_id = hkey
                # sr.spin_domaindata_B_id = nil
                sr.cont_location_domain = 'folder_b'
                sr[:selected_domain_b] = hkey
                sr[:spin_current_domain] = hkey
                sr.save
            end
          # change_foldwer request
          when 'change_folder'
            # folder in concern is folder_a or folder_b
            cl = location
            # current_domain = String.new
            case cl # => check content location
              when 'folder_a'
                sr.cont_location_folder = 'folder_a'
                sr[:selected_folder_a] = hkey
                sr[:spin_current_directory] = hkey
                # current_domain = sr[:selected_folder_a]
                # sr.spin_folderdata_B_id = nil
                sr.save
              when 'folder_b'
                sr.cont_location_folder = 'folder_b'
                sr[:selected_folder_b] = hkey
                sr[:spin_current_directory] = hkey
                # current_domain = sr[:selected_folder_b]
                # sr.spin_folderdata_A_id = nil
                sr.save # => update spin_sessions table
            end
        end # => end of case
      end # => end of transaction
      return true
    end

    # => end of self.set_session_info( sid, type, pharray )

    def self.get_current_directory sid, location = LOCATION_ANY
      # if sid == ADMIN_SESSION_ID
      # return "/"
      # else
      SpinSession.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        ss = SpinSession.readonly.find_by(spin_session_id: sid)
        if ss.blank?
          return nil
        end
        if ss
          case location
            when 'folder_a'
              return ss[:selected_folder_a]
            when 'folder_b'
              return ss[:selected_folder_b]
            when 'folder_at'
              return ss[:selected_folder_at]
            when 'folder_bt'
              return ss[:selected_folder_bt]
            when 'folder_atfi'
              return ss[:selected_folder_atfi]
            when 'folder_btfi'
              return ss[:selected_folder_btfi]
            else
              return ss[:spin_current_directory]
          end
        else
          return nil
          # end
        end
      end
    end

    # => end of get_current_directory sid

    def self.get_selected_domain sid, location = LOCATION_ANY
      # if sid == ADMIN_SESSION_ID
      # return "/"
      # else
      SpinSession.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        ss = SpinSession.readonly.find_by(spin_session_id: sid)
        if ss.present?
          case location
            when 'folder_a', 'domain_a'
              return ss[:selected_domain_a]
            when 'folder_b', 'domain_b'
              return ss[:selected_domain_b]
            when 'folder_at'
              return ss[:selected_domain_a]
            when 'folder_bt'
              return ss[:selected_domain_b]
            when 'folder_atfi'
              return ss[:selected_domain_a]
            when 'folder_btfi'
              return ss[:selected_domain_b]
            else
              return ss[:selected_domain_a]
          end
        else
          return nil
          # end
        end
      end
    end

    # => end of get_current_directory sid

    def self.get_location_current_directory sid, location
      SpinSession.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        ss = SpinSession.readonly.select("selected_folder_a,selected_folder_b,selected_folder_at,selected_folder_bt,selected_folder_atfi,selected_folder_btfi,spin_current_directory").find_by(spin_session_id: sid)
        if ss.present?
          case location
            when 'folder_a'
              return ss[:selected_folder_a]
            when 'folder_b'
              return ss[:selected_folder_b]
            when 'folder_at'
              return ss[:selected_folder_at]
            when 'folder_bt'
              return ss[:selected_folder_bt]
            when 'folder_atfi'
              return ss[:selected_folder_atfi]
            when 'folder_btfi'
              return ss[:selected_folder_btfi]
            else
              return ss[:spin_current_directory]
          end
        end
      end
      return nil
    end

    # => end of get_location_current_directory sid

    def self.get_current_directory_path sid, location = LOCATION_ANY
      # if sid == ADMIN_SESSION_ID
      # return "/"
      # else
      ss = ''
      SpinSession.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        ss = SpinSession.readonly.find_by(spin_session_id: sid)
      end
      if ss.present?
        case location
          when 'folder_a'
            return VirtualFileSystemUtility.key_to_path ss[:selected_folder_a]
          when 'folder_b'
            return VirtualFileSystemUtility.key_to_path ss[:selected_folder_b]
          when 'folder_at'
            return VirtualFileSystemUtility.key_to_path ss[:selected_folder_at]
          when 'folder_bt'
            return VirtualFileSystemUtility.key_to_path ss[:selected_folder_bt]
          when 'folder_atfi'
            return VirtualFileSystemUtility.key_to_path ss[:selected_folder_atfi]
          when 'folder_btfi'
            return VirtualFileSystemUtility.key_to_path ss[:selected_folder_btfi]
          else
            return VirtualFileSystemUtility.key_to_path ss[:selected_folder_a]
        end
      else
        return nil
        # end
      end
    end

    # => end of get_current_directory_path

    # set current directory in db spin_sessions
    def self.set_current_directory sid, vpath, location = LOCATION_ANY
      path_is_relative = false
      current_path = vpath
      if vpath[0, 1] != "/" or vpath[0, 2] == "./"
        path_is_relative = true
      end
      if path_is_relative
        cd = self.get_current_directory sid
        current_path = cd + (vpath[0, 2]=="./" ? vpath[1..-1] : ("/"+vpath))
      else
        current_path = vpath
      end
      ss = ''
      SpinSession.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        ss = SpinSession.readonly.find_by(spin_session_id: sid)
      end

      retry_set_current_director = ACTIVE_RECORD_RETRY_COUNT
      cp = nil
      catch(:set_current_directory_again) {

        SpinSession.transaction do

          begin
            if ss.present? # => check session
              cp = VirtualFileSystemUtility.path_to_key current_path
              # ss[:spin_current_directory] = VirtualFileSystemUtility.path_to_key current_path
              # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
              ss[:updated_at] = Time.now
              ss[:spin_current_location] = location
              ss[:cont_location_folder] = location
              ss[:spin_current_directory] = cp
              case location
                when 'folder_a'
                  ss[:selected_folder_a] = cp
                when 'folder_b'
                  ss[:selected_folder_b] = cp
                when 'folder_at'
                  ss[:selected_folder_at] = cp
                when 'folder_bt'
                  ss[:selected_folder_bt] = cp
                when 'folder_atfi'
                  ss[:selected_folder_atfi] = cp
                when 'folder_btfi'
                  ss[:selected_folder_btfi] = cp
                else
                  ss[:selected_folder_a] = cp
              end
              ss.save
            elsif sid == ADMIN_SESSION_ID # => no session is found and sid is ADMIN_SESSION_ID. special case!
              cp = VirtualFileSystemUtility.path_to_key current_path
              # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
              new_session = SpinSession.new
              new_session[:spin_session_id] = sid
              if location == 'folder_a' or location == 'folder_b'
                new_session[:spin_current_directory] = cp
              else
                new_session[:spin_current_directory] = ''
              end
              new_session.created_at = Time.now
              new_session.updated_at = Time.now
              case location
                when 'folder_a'
                  new_session[:selected_folder_a] = cp
                when 'folder_b'
                  new_session[:selected_folder_b] = cp
                when 'folder_at'
                  new_session[:selected_folder_at] = cp
                when 'folder_bt'
                  new_session[:selected_folder_bt] = cp
                when 'folder_atfi'
                  new_session[:selected_folder_atfi] = cp
                when 'folder_btfi'
                  new_session[:selected_folder_btfi] = cp
                else
                  new_session[:selected_folder_a] = cp
              end
              new_session.save
            else # => simply session is not found
              return nil
            end # => end of check session
          rescue ActiveRecord::StaleObjectError
            retry_set_current_director -= 1
            if retry_set_current_director > 0
              sleep(AR_RETRY_WAIT_MSEC)
              throw :set_current_directory_again
            else
              return nil
            end
          end
        end # => end of transaction
      }
      return cp
    end

    # => end of set_current_directory

    def self.set_current_location sid, location
      if location == LOCATION_ANY
        return false # => accept valid location only!
      end
      ss = SpinSession.find_by(spin_session_id: sid)
      if ss.blank?
        return false
      end

      retry_set_current_location = ACTIVE_RECORD_RETRY_COUNT
      catch(:set_current_location_again) {
        SpinSession.transaction do
          begin

            ss[:spin_current_location] = location
            ss.save
          rescue ActiveRecord::StaleObjectError
            retry_set_current_location -= 1
            if retry_set_current_location > 0
              sleep(AR_RETRY_WAIT_MSEC)
              throw :set_current_location_again
            else
              return false
            end
          end
        end
      }
      return true
    end

    def self.set_current_folder_location sid, location
      if location == LOCATION_ANY
        return false # => accept valid location only!
      end
      ss = SpinSession.find_by(spin_session_id: sid)
      if ss.blank?
        return false
      end

      retry_set_current_folder_location = ACTIVE_RECORD_RETRY_COUNT
      catch(:set_current_folder_location_again) {
        SpinSession.transaction do
          begin
            ss[:spin_current_location] = location
            ss[:cont_location_folder] = location
            ss.save
          rescue ActiveRecord::StaleObjectError
            retry_set_current_folder_location -= 1
            if retry_set_current_folder_location > 0
              sleep(AR_RETRY_WAIT_MSEC)
              throw :set_current_folder_location_again
            end
          end
        end

      }
      return true
    end

    def self.get_current_location sid
      ss = SpinSession.find_by(spin_session_id: sid)
      if ss.blank?
        return nil
      end
      return ss[:spin_current_location]
    end

    def self.get_current_folder_location sid
      ss = SpinSession.find_by(spin_session_id: sid)
      if ss.blank?
        return nil
      end
      return ss[:cont_location_folder]
    end

    # set current directory in db spin_sessions
    def self.set_current_folder sid, folder_hashkey, location = LOCATION_ANY, domain_hashkey = nil
      if domain_hashkey == nil
        domain_hashkey = SessionManager.get_selected_domain(sid, location)
      end

      retry_set_current_folder = ACTIVE_RECORD_RETRY_COUNT
      catch(:set_current_folder_again) {
        SpinSession.transaction do
          begin
            #        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            ss = SpinSession.find_by(spin_session_id: sid)
            if ss.present? # => check session
              # cp = VirtualFileSystemUtility.path_to_key current_path
              # ss[:spin_current_directory] = VirtualFileSystemUtility.path_to_key current_path
              ss[:updated_at] = Time.now
              ss[:spin_current_location] = location
              ss[:cont_location_folder] = location
              #          DomainDatum.set_selected_folder sid, domain_key, folder_hashkey, location
              case location
                when 'folder_a'
                  SpinSession.where(spin_session_id: sid).update_all(spin_current_directory: folder_hashkey, selected_folder_a: folder_hashkey, spin_current_domain: domain_hashkey, selected_domain_a: domain_hashkey, updated_at: Time.now, spin_current_location: location, cont_location_folder: location)
                #                ss[:spin_current_directory] = folder_hashkey
                #                ss[:selected_folder_a] = folder_hashkey
                #                ss[:selected_domain_a] = domain_hashkey
                # DomainDatum.set_selected_folder sid, domain_hashkey, folder_hashkey, location
                when 'folder_b'
                  ss[:spin_current_directory] = folder_hashkey
                  ss[:selected_folder_b] = folder_hashkey
                  ss[:selected_domain_b] = domain_hashkey
                # DomainDatum.set_selected_folder sid, domain_hashkey, folder_hashkey, location
                when 'folder_at'
                  ss[:selected_folder_at] = folder_hashkey
                #            domain_hashkey = ss[:selected_domain_at]
                # DomainDatum.set_selected_folder sid, domain_hashkey, folder_hashkey, location
                when 'folder_bt'
                  ss[:selected_folder_bt] = folder_hashkey
                #            domain_hashkey = ss[:selected_domain_bt]
                # DomainDatum.set_selected_folder sid, domain_hashkey, folder_hashkey, location
                when 'folder_atfi'
                  ss[:selected_folder_atfi] = folder_hashkey
                #            domain_hashkey = ss[:selected_domain_atfi]
                # DomainDatum.set_selected_folder sid, domain_hashkey, folder_hashkey, location
                when 'folder_btfi'
                  ss[:selected_folder_btfi]= folder_hashkey
                #            domain_hashkey = ss[:selected_domain_btfi]
                # DomainDatum.set_selected_folder sid, domain_hashkey, folder_hashkey, location
              end
              # ss.save
            elsif sid == ADMIN_SESSION_ID # => no session is found and sid is ADMIN_SESSION_ID. special case!
              # cp = VirtualFileSystemUtility.path_to_key ADMIN_DEFAULT_PATH
              new_session = SpinSession.create {|ns|
                ns[:spin_session_id] = sid
                if location == 'folder_a' or location == 'folder_b'
                  ns[:spin_current_directory] = folder_hashkey
                else
                  ns[:spin_current_directory] = ''
                end
                ns.created_at = Time.now
                ns.updated_at = Time.now
                case location
                  when 'folder_a'
                    ns[:selected_folder_a] = folder_hashkey
                    ns[:selected_domain_a] = domain_hashkey
                    ns[:spin_current_domain] = domain_hashkey
                  when 'folder_b'
                    ns[:selected_folder_b] = folder_hashkey
                    ns[:selected_domain_b] = domain_hashkey
                    ns[:spin_current_domain] = domain_hashkey
                  when 'folder_at'
                    ns[:selected_folder_at] = folder_hashkey
                  when 'folder_bt'
                    ns[:selected_folder_bt] = folder_hashkey
                  when 'folder_atfi'
                    ns[:selected_folder_atfi] = folder_hashkey
                  when 'folder_btfi'
                    ns[:selected_folder_btfi] = folder_hashkey
                  else
                    ns[:selected_folder_a] = folder_hashkey
                    ns[:spin_current_domain] = domain_hashkey
                end
              }
              if new_session.blank?
                return nil
              end
            else # => simply session is not found
              return nil
            end # => end of check session
          rescue ActiveRecord::StaleObjectError
            if retry_set_current_folder > 0
              retry_set_current_folder -= 1
              sleep(AR_RETRY_WAIT_MSEC)
              throw :set_current_folder_again
            else
              return nil
            end
          end
        end # => end of transaction
      } # => end of catch
      return folder_hashkey
    end

    # => end of set_current_directory

    # set current directory in db spin_sessions
    def self.set_current_directory_path sid, vpath, location = LOCATION_ANY
      path_is_relative = false
      current_path = vpath
      if vpath[0, 1] != "/" or vpath[0, 2] == "./"
        path_is_relative = true
      end
      if path_is_relative
        cd = self.get_current_directory_path sid, location
        current_path = cd + (vpath[0, 2]=="./" ? vpath[1..-1] : ("/"+vpath))
      else
        current_path = vpath
      end
      ss = SpinSession.find_by(spin_session_id: sid)
      if ss.present? # => check session
        cp = VirtualFileSystemUtility.path_to_key current_path
        if SpinAccessControl.is_accessible_node(sid, cp, NODE_DIRECTORY) == false
          return nil
        end
        SpinSession.transaction do
          # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
          ss[:spin_current_directory] = cp
          ss.updated_at = Time.now
          case location
            when 'folder_a'
              ss[:selected_folder_a] = cp
            when 'folder_b'
              ss[:selected_folder_b] = cp
            when 'folder_at'
              ss[:selected_folder_at] = cp
            when 'folder_bt'
              ss[:selected_folder_bt] = cp
            when 'folder_atfi'
              ss[:selected_folder_atfi] = cp
            when 'folder_btfi'
              ss[:selected_folder_btfi] = cp
            else
              ss[:selected_folder_a] = cp
          end
          if ss.save
            self.set_current_folder(sid, cp, 'folder_b')
            return current_path
          else
            return "/"
          end
        end
      elsif sid == ADMIN_SESSION_ID # => no session is found and sid is ADMIN_SESSION_ID. special case!
        cp = VirtualFileSystemUtility.path_to_key current_path
        if SpinAccessControl.is_accessible_node(sid, cp, NODE_DIRECTORY) == false
          return nil
        end
        SpinSession.transaction do
          # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
          new_session = SpinSession.new
          new_session[:spin_session_id] = sid
          if location == 'folder_a' or location == 'folder_b'
            new_session[:spin_current_directory] = cp
          else
            new_session[:spin_current_directory] = ''
          end
          new_session.created_at = Time.now
          new_session.updated_at = Time.now
          case location
            when 'folder_a'
              ss[:selected_folder_a] = cp
            when 'folder_b'
              ss[:selected_folder_b] = cp
            when 'folder_at'
              ss[:selected_folder_at] = cp
            when 'folder_bt'
              ss[:selected_folder_bt] = cp
            when 'folder_atfi'
              ss[:selected_folder_atfi] = cp
            when 'folder_btfi'
              ss[:selected_folder_btfi] = cp
            else
              ss[:selected_folder_a] = cp
          end
          if ss.save
            self.set_current_folder(sid, cp, 'folder_b')
            return current_path
          else
            return "/"
          end
        end
      end # => end of check session
    end

    # => end of set_current_directory_path

    # set current directory in db spin_sessions
    def self.set_current_domain sid, domain_hashkey, location = 'folder_a'
      selected_folder = ''
      # get selected folder
      cand_folders = FolderDatum.where(session_id: sid, cont_location: location, domain_hash_key: domain_hashkey)
      unless cand_folders.count > 0
        FolderDatum.fill_folders(sid, location, domain_hashkey)
      end
      selected_folder = DomainDatum.get_selected_folder(sid, domain_hashkey, location)
      # if selected_folder.blank?
      #   selected_folder = FolderDatum.get_first_folder_of_domain(sid, domain_hashkey, location)
      #   # if selected_folder.blank?
      #   #   return domain_hashkey
      #   # end
      # end

      retry_set_current_domain = ACTIVE_RECORD_RETRY_COUNT
      catch(:set_current_domain_again) {
        SpinSession.transaction do
          begin
            ssrecs = SpinSession.where(spin_session_id: sid).update_all(
                cont_location_domain: location,
                spin_current_domain: domain_hashkey,
                selected_domain_a: domain_hashkey,
                selected_folder_a: selected_folder
            )
          rescue ActiveRecord::StaleObjectError
            if retry_set_current_domain > 0
              retry_set_current_domain -= 1
              throw :set_current_domain_again
            else
              return nil
            end
          end # end of begin-rescue block
        end # end of transaction
      } # end of catch-block
      return domain_hashkey

    end

    # => end of set_current_domain

    def self.get_current_domain sid, location
      # get current domain and returns its hash_key
      ss = nil
      SpinSession.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        ss = SpinSession.readonly.find_by(spin_session_id: sid)
      end
      if ss.present?
        case location
          when 'folder_a', 'folder_at', 'folder_atbi'
            return ss[:spin_current_domain]
          when 'folder_b', 'folder_bt', 'folder_btbi'
            return ss[:selected_domain_b]
          else
            return ss[:spin_current_domain]
        end
      else
        return nil
      end
    end

    # => end of get_current_domain

    def self.get_default_domain sid
      if sid.nil?
        return SpinDomain.get_system_default_domain
      else
        # get current domain and returns its hash_key
        ur = nil
        ids = SessionManager.get_uid_gid(sid, false)
        if ids.blank? # => sid may be null
          return SpinDomain.get_system_default_domain
        end
        SpinUser.transaction do
          # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')

          #        u = SpinSession.readonly.find_by_spin_session_id sid
          ur = SpinUser.readonly.find_by(spin_uid: ids[:uid])
        end
        if ur.present?
          return ur[:spin_default_domain]
        else
          dds = SpinDomain.search_accessible_domains(sid, ids[:gids])
          if dds.length > 0
            return dds[0][:hash_key]
          else
            return nil
          end
        end # => end of if ur
      end # => end of if sid.nil?
    end # => end of get_current_domain

  end

# => end of class SessionUtility

  class VirtualFileSystemUtility < ActiveRecord::Base
    include Vfs
    include Acl
    include Stat

    def self.open_meta_db_connection
      conn = nil
      # return PG::Connection.open( :dbname => ApplicationController.get_appl_env("dbname"),
      # :user => ApplicationController.get_appl_env("user"),
      # :password => ApplicationController.get_appl_env("password") )
      case ENV['RAILS_ENV']
        when 'development'
          #        logger.debug 'development env'
          conn = PG::Connection.new(:dbname => "spin_development", :user => "spinadmin", :password => "postgres")
        when 'test'
          #        logger.debujg 'testr env'
          conn = PG::Connection.new(:dbname => "test", :user => "spinadmin", :password => "postgres")
        when 'production'
          #        logger.debug 'production env'
          conn = PG::Connection.new(:dbname => "spin", :user => "spinadmin", :password => "postgres")
        else
          #        logger.debug 'production env'
          conn = PG::Connection.new(:dbname => "spin", :user => "spinadmin", :password => "postgres")
      end
      return conn
    end

    def self.close_meta_db_connection dbcon
      dbcon.close
    end

    def self.virtual_file_system_query(query_string)
      reta = {:status => false, :result => nil}
      printf "ssid = %s\n", query_string
      # conn = PG::Connection.open( :dbname => "spin_development", :user => "spinadmin", :password => "postgres")
      conn = self.open_meta_db_connection
      # do exec query
      reta[:result] = conn.exec(query_string)
      # conn.close
      self.close_meta_db_connection conn
      # return reta["status"] = nil if result is nil
      # else return status and result in reta
      return reta
    end

    def self.virtual_file_system_query2(conn, query_string)
      reta = {:status => false, :result => nil}
      printf "ssid = %s\n", query_string
      # conn = PG::Connection.open( :dbname => "spin_development", :user => "spinadmin", :password => "postgres")
      # conn = self.open_meta_db_connection
      # do exec query
      reta[:result] = conn.exec(query_string)
      # conn.close
      # self.close_meta_db_connection conn
      # return reta["status"] = nil if result is nil
      # else return status and result in reta
      return reta
    end

    def self.is_existing_directory vp, depth, parent_x
      # use spin_nodes table
      ret_a = []
      SpinNode.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        ret_a = self.find_directory_node vp, depth, parent_x, true
        if ret_a.blank?
          return [-1, -1, -1, -1]
        end
      end
      if ret_a == [-1, -1, -1, -1] # not found
        return [-1, -1, -1, -1]
      end
      #
      return ret_a # => returns [ x, y, prx, v, hashkey ]
    end

    # => end of is_existing_directory

    def self.is_existing_node vp, depth, parent_x, get_latest = true
      # use spin_nodes table
      ret_a = []
      SpnNode.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        ret_a = self.readonly.find_node vp, depth, parent_x, true, get_latest
        if ret_a.blank?
          return [-1, -1, -1, -1]
        end
      end
      if ret_a == [-1, -1, -1, -1] # not found
        return [-1, -1, -1, -1]
      end
      #
      return ret_a # => returns [ x, y, prx, v, hashkey ]
    end

    # => end of is_existing_directory

    def self.create_virtual_directory_path sid, location, vdir, flag_make_path = false, owner_uid = NO_USER, owner_gid = NO_GROUP, acls = nil
      # create virtual directory path which is specifierd by vdir
      # vdir = /x/y/z/.../dirname
      vpath = vdir
      # status var.
      if vdir[0, 1] != "/" or vdir[0, 2] == "./"
        cd = SessionUtility::get_current_directory_path sid, location
        vpath = cd + (vdir[0, 1]!="/" ? vdir[1, -1] : vdir[2, -1])
      end

      path_array = vpath.scan(/[^\/]+/) # => ex. [ "usr", "local", "spin path" ]
      n = 1
      prx = 0
      vn = [-1, -1, -1, -1]

      path_array.each {|dirname|
        printf "dirname = %s", dirname
        # create directory 'dirname' in the current directory
        vn = self.create_virtual_directory_node sid, dirname, n, prx, owner_uid, owner_gid, acls
        if vn[X..V] == [-1, -1, -1, -1] # => failed to create directory
          return [-1, -1, -1, -1]
        end
        if vn[V] < 0
          vn[V] *= (-1)
        end
        #        end
        # check next
        n += 1
        prx = vn[X]
      }
      # conn.close
      # self.close_meta_db_connection conn
      return vn
    end

    def self.create_virtual_directory_node(sid, dirname, depth, prx, owner_uid = NO_USER, owner_gid = NO_GROUP, acls = nil)
      # get new node location
      # is there specified layer ( depth )?
      # create new directory node at the layer if there isn't
      #      new_layer = SpinNodeKeeper.test_and_set_layer_info depth
      request_loc = [REQUEST_COORD_VALUE, depth, prx, REQUEST_VERSION_NUMBER]

      new_dir_loc = nil
      while new_dir_loc.blank?
        new_dir_loc = SpinNodeKeeper.test_and_set_xy(sid, request_loc, dirname, NODE_DIRECTORY)
      end

      if new_dir_loc[X..V] == [-1, -1, -1, -1]
        return [-1, -1, -1, -1]
      end

      # create new node
      # new_node = self.create_virtual_node new_layer.last_x, depth, prx, 0, dirname, NODE_DIRECTORY, 0, 0 # => root and root group
      s_ids = SessionManager.get_uid_gid sid
      if new_dir_loc[V] < 0
        new_node = SpinNode.create_spin_node sid, new_dir_loc[X], new_dir_loc[Y], new_dir_loc[PRX], new_dir_loc[V]*(-1), dirname, NODE_DIRECTORY, (owner_uid == NO_USER ? s_ids[:uid] : owner_uid), (owner_gid == NO_USER ? s_ids[:gid] : owner_gid), acls # => root and root group
        #        new_node = self.create_virtual_node sid, new_dir_loc[X], new_dir_loc[Y],  new_dir_loc[PRX], new_dir_loc[V], dirname, NODE_DIRECTORY, (owner_uid == NO_USER ? s_ids[:uid] : owner_uid), (owner_gid == NO_USER ? s_ids[:gid] : owner_gid), acls # => root and root group
        # new_node = self.create_virtual_node 0, depth, prx, 0, NODE_DIRECTORY, get_uid, get_gid
        SpinAccessControl.copy_parent_acls sid, new_node, NODE_DIRECTORY # => new_node = [x,y,prx,v,hashkey]
        return new_node[X..K]
      elsif new_dir_loc[V] == 1
        new_nd = SpinNode.find_by(spin_tree_type: 0, node_x_coord: new_dir_loc[X], node_y_coord: new_dir_loc[Y], node_type: NODE_DIRECTORY)
        if new_nd.present?
          new_dir_loc[K] = new_nd[:spin_node_hashkey]
        else
          log_msg = ':create_virtual_directory_node => SpinNode.find returned nil {new_dir_loc[X],new_dir_loc[Y]} = {' + new_dir_loc[X].to_s + ',' + new_dir_loc[Y].to_s + '}'
          FileManager.logger(sid, log_msg, 'LOCAL', LOG_ERROR)
        end
        new_dir_loc[V] *= (-1)
        return new_dir_loc
      else
        new_dir_loc[V] *= (-1)
        return new_dir_loc[X..K]
      end
    end

    def self.move_virtual_file move_sid, move_file_key, target_folder_key, target_cont_location
      # Does the user have any right to delete or trash file?
      SpinAccessControl.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        acls = SpinAccessControl.has_acl_values move_sid, move_file_key
        target_acls = SpinAccessControl.has_acl_values move_sid, target_folder_key, NODE_DIRECTORY
        has_right_to_delete = false
        target_has_right_to_delete = false
        acls.each {|key, value|
          if value & ACL_NODE_WRITE or value & ACL_NODE_DELETE # => has right to delete
            has_right_to_delete = true
            break
          end
        }
        target_acls.each {|key, value|
          if value & ACL_NODE_WRITE or value & ACL_NODE_DELETE # => has right to delete
            target_has_right_to_delete = true
            break
          end
        }
        # return false unless it has right to delete file
        if has_right_to_delete == false or target_has_right_to_delete == false
          return false
        end
        # delete or trash file node
        ret = SpinNode.move_node move_sid, move_file_key, target_folder_key, target_cont_location
      end
    end

    # => end of delete_virtual_file delete_sid, delete_file_key, true # => the last argument is trash_it flag

    def self.move_virtual_files_in_clipboard_org operation_id, move_sid, source_folder_key, target_folder_key, target_cont_location
      # Does the user have any right to delete or trash file?
      ret_key = ''

      # Are source and target the same?
      if source_folder_key == target_folder_key
        return false
      end
      # get vpath of the source folder
      svloc = SpinLocationManager.key_to_location(source_folder_key, NODE_DIRECTORY)
      vps = SpinLocationManager.get_location_vpath(svloc)

      # get vpath of the target folder
      tvloc = SpinLocationManager.key_to_location(target_folder_key, NODE_DIRECTORY)
      vpt = SpinLocationManager.get_location_vpath(tvloc)

      # get 1 node from clipboard and process it
      # unitl all data that has same opr_id are proccessed
      while true do
        # get 1
        get_node_hash = ClipBoards.get_node operation_id, move_sid, OPERATION_CUT
        mvf = get_node_hash[:node_hash_key]
        break if mvf == nil # => end of proccess

        # Does it have ACL to do move operation?
        has_right_to_delete = SpinAccessControl.is_writable(move_sid, mvf, ANY_TYPE)
        #        has_right_to_delete = SpinAccessControl.is_deletable(move_sid, mvf, ANY_TYPE)
        if has_right_to_delete != true
          return false
        end

        # get vpath of the node to be moved
        xvloc = SpinLocationManager.key_to_location(mvf, ANY_TYPE)
        vpx = SpinLocationManager.get_location_vpath(xvloc)

        # vpath mapping!
        vvps = vps
        vvpt = vpt
        FileManager.rails_logger("(vps,vpt) = (" + vps + "," + vpt + ")")
        fvpx = SpinLocationManager.vpath_mapping_locations(vpx, vvps, vvpt)

        # get location
        fpvpx = SpinLocationManager.vpath_mapping_parent_vpath(fvpx)

        node_type = ANY_TYPE
        if SpinNode.is_directory(mvf) == true
          node_type = NODE_DIRECTORY
          # make new vpath
          vfile_name = fvpx.split(/\//)[-1]
          new_location = SpinLocationManager.get_location_coordinates(move_sid, target_cont_location, fvpx, true)
          new_dir_location = SpinLocationManager.get_location_coordinates(move_sid, target_cont_location, fpvpx, true)
          if new_location[0..3] != [-1, -1, -1, -1]
            if new_location[V] > 0 # => There isn't
              ret_key = SpinNode.move_node_location(move_sid, mvf, vfile_name, new_dir_location, false, target_cont_location, NODE_DIRECTORY)
            else # => There already is!
              ret_key = SpinNode.move_node_location(move_sid, mvf, vfile_name, new_dir_location, true, target_cont_location, NODE_DIRECTORY)
            end
          end
        else # => file
          node_type = NODE_FILE
          # get location
          new_dir_location = SpinLocationManager.get_location_coordinates(move_sid, target_cont_location, fpvpx, true)
          if tvloc != [-1, -1, -1, -1]
            vfile_name = fvpx.split(/\//)[-1]
            ret_key = SpinNode.move_node_location(move_sid, mvf, vfile_name, new_dir_location, false, target_cont_location, NODE_FILE, new_dir_location[K])
          end
          # delete or trash file node
          #          ret = SpinNode.copy_node cpf, target_folder_key, target_cont_location
        end # => end of if SpinNode.is_directory(cpf) == true

        break if ret_key.blank?

        ClipBoards.set_operation_processed operation_id, move_sid, OPERATION_CUT, mvf

      end # => end of while loop

      if ret_key.blank?
        FileManager.rails_logger "ret_key is empty"
        while true do
          # get 1
          get_node_hash = ClipBoards.get_node operation_id, move_sid, OPERATION_CUT, (GET_MARKER_PROCESSED|GET_MARKER_SET)
          mvfrb = get_node_hash[:node_hash_key]
          #          mvfrb = ClipBoards.get_node operation_id, move_sid, OPERATION_CUT, (GET_MARKER_PROCESSED|GET_MARKER_SET)
          break if mvfrb == nil # => end of proccess

          ClipBoards.rollback_operation operation_id, move_sid, OPERATION_CUT, mvfrb
        end # => end of while true do
      else
        FileManager.rails_logger ("ret_key is " + ret_key)
        while true do
          # get 1
          get_node_hash = ClipBoards.get_node operation_id, move_sid, OPERATION_CUT, GET_MARKER_PROCESSED
          mvfcmt = get_node_hash[:node_hash_key]
          break if mvfcmt == nil # => end of proccess
          FileManager.rails_logger ("mvfcmt = " + mvfcmt)

          # get vpath of the node to be moved
          xvloc = SpinLocationManager.key_to_location(mvfcmt, ANY_TYPE)
          vpx = SpinLocationManager.get_location_vpath(xvloc)

          # vpath mapping!
          fvpx = SpinLocationManager.vpath_mapping_locations(vpx, vps, vpt)

          # get location
          fpvpx = SpinLocationManager.vpath_mapping_parent_vpath(fvpx)

          ClipBoards.set_operation_completed operation_id, move_sid, OPERATION_CUT, mvfcmt, ret_key
          FileManager.rails_logger ("after set_operation_completed = " + ret_key)

          node_type = ANY_TYPE
          if SpinNode.is_directory(mvf) == true
            node_type = NODE_DIRECTORY
            # make new vpath
            vfile_name = fvpx.split(/\//)[-1]
            new_location = SpinLocationManager.get_location_coordinates(move_sid, target_cont_location, fvpx, true)
            new_key = SpinLocationManager.location_to_key(new_location, NODE_DIRECTORY)
            new_dir_location = SpinLocationManager.get_location_coordinates(move_sid, target_cont_location, fpvpx, true)
            if /folder_a/ =~ target_cont_location
              cont_location = 'folder_a'
            elsif /folder_b/ =~ target_cont_location
              cont_location = 'folder_b'
            else
              cont_location = 'folder_a'
            end
            domain_key = SessionManager.get_selected_domain(move_sid, cont_location)
            FolderDatum.remove_folder_rec(move_sid, cont_location, mvfcmt)
            FolderDatum.load_folder_recs(move_sid, new_dir_location, domain_key, cont_location, DEPTH_TO_TRAVERSE, SessionManager.get_last_session(move_sid))
            locations = CONT_LOCATIONS_LIST - [cont_location]
            locations.each {|location|
              FolderDatum.copy_folder_data_from_location_to_location(move_sid, cont_location, location, domain_key)
            }
          else # => file
            node_type = NODE_FILE
            # get location
            new_dir_location = SpinLocationManager.get_location_coordinates(move_sid, target_cont_location, fpvpx, true)
            new_key = SpinLocationManager.location_to_key(new_dir_location, NODE_FILE)
            if /folder_a/ =~ target_cont_location
              cont_location = 'folder_a'
            elsif /folder_b/ =~ target_cont_location
              cont_location = 'folder_b'
            else
              cont_location = 'folder_a'
            end
            FileDatum.load_file_list_rec(move_sid, cont_location, ret_key, new_key)
            FileDatum.fill_file_list(move_sid, cont_location, new_key)
            # delete or trash file node
            #          ret = SpinNode.copy_node cpf, target_folder_key, target_cont_location
          end # => end of if SpinNode.is_directory(cpf) == true

        end # => end of while true do
      end # => end of if ret_key.blank?

      return (ret_key.blank? == true ? false : true)
    end

    # => end of delete_virtual_file delete_sid, delete_file_key, true # => the last argument is trash_it flag

    def self.move_virtual_files_in_clipboard operation_id, move_sid, source_folder_key, target_folder_key, target_cont_location
      # Does the user have any right to delete or trash file?
      ret_key = ''
      ret_keys = []
      ret_folder_keys = []
      # Are source and target the same?
      if source_folder_key == target_folder_key
        return false
      end
      # get vpath of the source folder
      svloc = SpinLocationManager.key_to_location(source_folder_key, NODE_DIRECTORY)
      vps = SpinLocationManager.get_location_vpath(svloc)

      # get vpath of the target folder
      tvloc = SpinLocationManager.key_to_location(target_folder_key, NODE_DIRECTORY)
      vpt = SpinLocationManager.get_location_vpath(tvloc)

      # get 1 node from clipboard and process it
      # unitl all data that has same opr_id are proccessed
      while true do
        # get 1
        get_node_hash = ClipBoards.get_node operation_id, move_sid, OPERATION_CUT
        mvf = get_node_hash[:node_hash_key]
        break if mvf == nil # => end of proccess

        # Does it have ACL to do move operation?
        has_right_to_delete = SpinAccessControl.is_writable(move_sid, mvf, ANY_TYPE)
        #        has_right_to_delete = SpinAccessControl.is_deletable(move_sid, mvf, ANY_TYPE)
        if has_right_to_delete != true
          return false
        end

        # get vpath of the node to be moved
        xvloc = SpinLocationManager.key_to_location(mvf, ANY_TYPE)
        vpx = SpinLocationManager.get_location_vpath(xvloc)

        # vpath mapping!
        vvps = vps
        vvpt = vpt
        FileManager.rails_logger("(vps,vpt) = (" + vps + "," + vpt + ")")
        fvpx = SpinLocationManager.vpath_mapping_locations(vpx, vvps, vvpt)

        # get location
        fpvpx = SpinLocationManager.vpath_mapping_parent_vpath(fvpx)

        if SpinNode.is_directory(mvf) == true
          # make new vpath
          vfile_name = fvpx.split(/\//)[-1]
          new_location = SpinLocationManager.get_location_coordinates(move_sid, target_cont_location, fvpx, true)
          new_dir_location = SpinLocationManager.get_location_coordinates(move_sid, target_cont_location, fpvpx, true)
          # 追加 移動元親ディレクトリを取得 ↓
          source_node = SpinNode.find_by(spin_node_hashkey: mvf)
          if source_node.blank?
            return false
          end
          # spin_nodesから親ノードのhash_keyを取得
          source_parent_node = SpinLocationManager.get_parent_node(source_node)
          if source_parent_node.blank?
            return false
          end
          # 追加 移動元親ディレクトリを取得 ↑
          if new_location[0..3] != [-1, -1, -1, -1]
            if new_location[V] > 0 # => There isn't
              ret_key = SpinNode.move_node_location(move_sid, mvf, vfile_name, new_dir_location, false, target_cont_location, NODE_DIRECTORY)
            else # => There already is!
              ret_key = SpinNode.move_node_location(move_sid, mvf, vfile_name, new_dir_location, true, target_cont_location, NODE_DIRECTORY)
            end

            unless ret_key.blank?
              domain_key = SessionManager.get_selected_domain(move_sid, target_cont_location)
              FolderDatum.remove_folder_rec(move_sid, target_cont_location, mvf)
              # 追加 移動元親ディレクトリのchildを更新 ↓
              if source_node != source_parent_node
                FolderDatum.remove_child_from_parent(source_node[:spin_node_hashkey], source_parent_node[:spin_node_hashkey], move_sid);
              end
              # 追加 移動元親ディレクトリのchildを更新 ↑
              ret_folder_keys.push ret_key
            end

          end
        else # => file
          # get location
          new_dir_location = SpinLocationManager.get_location_coordinates(move_sid, target_cont_location, fpvpx, true)
          if tvloc != [-1, -1, -1, -1]
            vfile_name = fvpx.split(/\//)[-1]
            ret_key = SpinNode.move_node_location(move_sid, mvf, vfile_name, new_dir_location, false, target_cont_location, NODE_FILE, new_dir_location[K])
            puts ret_key;
          end
          # delete or trash file node
          #          ret = SpinNode.copy_node cpf, target_folder_key, target_cont_location
        end # => end of if SpinNode.is_directory(cpf) == true

        puts 'test';
        break if ret_key.blank?

        ret_keys.push ret_key
        ClipBoards.set_operation_processed operation_id, move_sid, OPERATION_CUT, mvf

      end # => end of while loop

      if ret_key.blank?
        FileManager.rails_logger "ret_key is empty"
        while true do
          # get 1
          get_node_hash = ClipBoards.get_node operation_id, move_sid, OPERATION_CUT, (GET_MARKER_PROCESSED|GET_MARKER_SET)
          mvfrb = get_node_hash[:node_hash_key]
          break if mvfrb == nil # => end of proccess

          ClipBoards.rollback_operation operation_id, move_sid, OPERATION_CUT, mvfrb
        end # => end of while true do
      else
        idx = 0
        while true do
          # get 1
          get_node_hash = ClipBoards.get_node operation_id, move_sid, OPERATION_CUT, (GET_MARKER_PROCESSED|GET_MARKER_SET)
          mvfrb = get_node_hash[:node_hash_key]

          break if mvfrb == nil

          ClipBoards.set_operation_completed operation_id, move_sid, OPERATION_COPY, mvfrb, ret_keys[idx]
          if get_node_hash[:node_type] == NODE_DIRECTORY
            FolderDatum.load_folder_recs(move_sid, ret_keys[idx], domain_key, target_cont_location, DEPTH_TO_TRAVERSE, SessionManager.get_last_session(move_sid))
            # 追加 移動先親ディレクトリのchildを更新 ↓
            # spin_nodesから親ノードのhash_keyを取得
            move_node = SpinNode.find_by(spin_node_hashkey: ret_keys[idx])
            if move_node.blank?
              return false
            end
            move_parent_node = SpinLocationManager.get_parent_node(move_node)
            if move_parent_node.blank?
              return false
            end
            if move_node != move_parent_node
              FolderDatum.add_child_to_parent(ret_keys[idx], move_parent_node[:spin_node_hashkey], move_sid);
            end
            # 追加 移動先親ディレクトリのchildを更新 ↑
          end
          idx += 1
        end
      end # => end of if ret_key.blank?

      return (ret_key.blank? == true ? false : true)
    end

    # => end of delete_virtual_file delete_sid, delete_file_key, true # => the last argument is trash_it flag

    def self.copy_virtual_files_in_clipboard operation_id, copy_sid, source_folder_key, target_folder_key, target_cont_location
      # Does the user have any right to delete or trash file?
      ret_key = ''
      new_location = []

      # Are source and target the same?
      if source_folder_key == target_folder_key
        return false
      end
      # get vpath of the source folder
      svloc = SpinLocationManager.key_to_location(source_folder_key, NODE_DIRECTORY)
      vps = SpinLocationManager.get_location_vpath(svloc)

      # get vpath of the target folder
      tvloc = SpinLocationManager.key_to_location(target_folder_key, NODE_DIRECTORY)
      vpt = SpinLocationManager.get_location_vpath(tvloc)

      # get 1 node from clipboard and process it
      # unitl all data that has same opr_id are proccessed
      while true do
        # get 1
        get_node_hash = ClipBoards.get_node operation_id, copy_sid, OPERATION_COPY
        cpf = get_node_hash[:node_hash_key]
        break if cpf == nil # => end of proccess

        # get vpath of the node to be copied
        xvloc = SpinLocationManager.key_to_location(cpf, ANY_TYPE)
        vpx = SpinLocationManager.get_location_vpath(xvloc)

        # vpath mapping!
        vvps = vps
        vvpt = vpt
        fvpx = SpinLocationManager.vpath_mapping_locations(vpx, vvps, vvpt)

        # get location
        fpvpx = SpinLocationManager.vpath_mapping_parent_vpath(fvpx)

        node_type = ANY_TYPE
        if SpinNode.is_directory(cpf) == true
          node_type = NODE_DIRECTORY
          # make new vpath
          new_dir_location = SpinLocationManager.get_location_coordinates(copy_sid, target_cont_location, fpvpx, true)
          if new_dir_location[0..3] != [-1, -1, -1, -1]
            #            if new_dir_location[V] > 0 # => There isn't
            #              ret_key = SpinNode.copy_node_location(copy_sid, cpf, vfile_name, new_dir_location, false, target_cont_location, NODE_DIRECTORY)
            #            else # => There already is!
            #              ret_key = SpinNode.copy_node_location(copy_sid, cpf, vfile_name, new_dir_location, true, target_cont_location, NODE_DIRECTORY)
            #            end
            vfile_name = fvpx.split(/\//)[-1]
            ret_key = SpinNode.copy_node_location(copy_sid, cpf, vfile_name, new_dir_location, false, target_cont_location, NODE_DIRECTORY)
          else
            next
          end
        else # => file
          node_type = NODE_FILE
          # get location
          new_dir_location = SpinLocationManager.get_location_coordinates(copy_sid, target_cont_location, fpvpx, true)
          if tvloc != [-1, -1, -1, -1]
            vfile_name = fvpx.split(/\//)[-1]
            ret_key = SpinNode.copy_node_location(copy_sid, cpf, vfile_name, new_dir_location, false, target_cont_location, NODE_FILE, new_dir_location[K])
          end
          # delete or trash file node
          #          ret = SpinNode.copy_node cpf, target_folder_key, target_cont_location
        end # => end of if SpinNode.is_directory(cpf) == true

        unless ret_key.blank?
          ClipBoards.set_operation_completed operation_id, copy_sid, OPERATION_COPY, cpf, ret_key
          if node_type == NODE_DIRECTORY
            new_key = ret_key
            if /folder_a/ =~ target_cont_location
              cont_location = 'folder_a'
            elsif /folder_b/ =~ target_cont_location
              cont_location = 'folder_b'
            else
              cont_location = 'folder_a'
            end
            domain_key = SessionManager.get_selected_domain(copy_sid, cont_location)
            #            FolderDatum.recopy_folder_rec(copy_sid, cont_location, cpf)
            if get_node_hash[:node_type] == NODE_DIRECTORY
              FolderDatum.load_folder_recs(copy_sid, new_key, domain_key, cont_location, DEPTH_TO_TRAVERSE, SessionManager.get_last_session(copy_sid))
              # 追加 コピー先親ディレクトリのchildを更新 ↓
              # spin_nodesから親ノードのhash_keyを取得
              new_node = SpinNode.find_by(spin_node_hashkey: new_key)
              if new_node.blank?
                return false
              end
              parent_node = nil
              if new_node.present?
                parent_node = SpinLocationManager.get_parent_node(new_node)
                if parent_node.blank?
                  return false
                end
                if new_node != parent_node
                  FolderDatum.add_child_to_parent(new_key, parent_node[:spin_node_hashkey], copy_sid);
                end
              end
              # 追加 コピー先親ディレクトリのchildを更新 ↑
            end
            #            locations = CONT_LOCATIONS_LIST - [ cont_location ]
            #            locations.each {|location|
            #              FolderDatum.copy_folder_data_from_location_to_location(copy_sid, cont_location, location, domain_key)
            #            }
          else
            new_key = SpinLocationManager.location_to_key(new_location, NODE_FILE)
            if /folder_a/ =~ target_cont_location
              cont_location = 'folder_a'
            elsif /folder_b/ =~ target_cont_location
              cont_location = 'folder_b'
            else
              cont_location = 'folder_a'
            end
            FileDatum.load_file_list_rec(copy_sid, cont_location, ret_key, new_key)
            FileDatum.fill_file_list(copy_sid, cont_location, new_key)
          end
        else
          FileManager.rails_logger(">> copy_virtual_file_in_clipboard : failed to copy " + vfile_name + '(' + cpf + ')')
          #          return false
        end

      end # => end of while loop

      if ret_key.blank?
        pp "ret_key is empty"
      end

      return (ret_key.blank? == true ? false : true)

    end

    # => end of delete_virtual_file delete_sid, delete_file_key, true # => the last argument is trash_it flag

    def self.symbolic_link_virtual_files_in_clipboard operation_id, copy_sid, source_folder_key, target_folder_key, target_cont_location
      # Does the user have any right to delete or trash file?
      ret_key = ''
      new_location = []

      # Are source and target the same?
      if source_folder_key == target_folder_key
        return false
      end
      # get vpath of the source folder
      svloc = SpinLocationManager.key_to_location(source_folder_key, NODE_DIRECTORY)
      vps = SpinLocationManager.get_location_vpath(svloc)

      # get vpath of the target folder
      tvloc = SpinLocationManager.key_to_location(target_folder_key, NODE_DIRECTORY)
      vpt = SpinLocationManager.get_location_vpath(tvloc)

      # get 1 node from clipboard and process it
      # unitl all data that has same opr_id are proccessed
      while true do
        # get 1
        get_node_hash = ClipBoards.get_node operation_id, copy_sid, OPERATION_COPY
        cpf = get_node_hash[:node_hash_key]
        break if cpf == nil # => end of proccess

        # get vpath of the node to be copied
        xvloc = SpinLocationManager.key_to_location(cpf, ANY_TYPE)
        vpx = SpinLocationManager.get_location_vpath(xvloc)

        # vpath mapping!
        vvps = vps
        vvpt = vpt
        fvpx = SpinLocationManager.vpath_mapping_locations(vpx, vvps, vvpt)

        # get location
        fpvpx = SpinLocationManager.vpath_mapping_parent_vpath(fvpx)

        node_type = ANY_TYPE
        if SpinNode.is_directory(cpf) == true
          node_type = NODE_DIRECTORY
          # make new vpath
          vfile_name = fvpx.split(/\//)[-1]
          new_location = SpinLocationManager.get_location_coordinates(copy_sid, target_cont_location, fvpx, true)
          new_dir_location = SpinLocationManager.get_location_coordinates(copy_sid, target_cont_location, fpvpx, true)
          if new_location[0..3] != [-1, -1, -1, -1]
            if new_location[V] > 0 # => There isn't
              ret_key = SpinNode.copy_node_location(copy_sid, cpf, vfile_name, new_dir_location, false, target_cont_location, NODE_DIRECTORY)
            else # => There already is!
              return false
              #              ret_key = SpinNode.copy_node_location(copy_sid, cpf, vfile_name, new_dir_location, true, target_cont_location, NODE_DIRECTORY)
            end
          end
        else # => file
          if new_location[V] > 0 # => There isn't

            node_type = NODE_FILE
            # get location
            new_dir_location = SpinLocationManager.get_location_coordinates(copy_sid, target_cont_location, fpvpx, true)
            if tvloc != [-1, -1, -1, -1]
              vfile_name = fvpx.split(/\//)[-1]
              ret_key = SpinNode.copy_node_location(copy_sid, cpf, vfile_name, new_dir_location, false, target_cont_location, NODE_FILE, new_dir_location[K])
            end
            # delete or trash file node
            #          ret = SpinNode.copy_node cpf, target_folder_key, target_cont_location
          else
            return false
          end
        end # => end of if SpinNode.is_directory(cpf) == true

        unless ret_key.blank?
          ClipBoards.set_operation_completed operation_id, copy_sid, OPERATION_COPY, cpf, ret_key
          if node_type == NODE_DIRECTORY
            new_key = ret_key
            if /folder_a/ =~ target_cont_location
              cont_location = 'folder_a'
            elsif /folder_b/ =~ target_cont_location
              cont_location = 'folder_b'
            else
              cont_location = 'folder_a'
            end
            domain_key = SessionManager.get_selected_domain(copy_sid, cont_location)
            #            FolderDatum.recopy_folder_rec(copy_sid, cont_location, cpf)
            if get_node_hash[:node_type] == NODE_DIRECTORY
              FolderDatum.load_folder_recs(copy_sid, new_key, domain_key, cont_location, DEPTH_TO_TRAVERSE, SessionManager.get_last_session(copy_sid))
            end
            #            locations = CONT_LOCATIONS_LIST - [ cont_location ]
            #            locations.each {|location|
            #              FolderDatum.copy_folder_data_from_location_to_location(copy_sid, cont_location, location, domain_key)
            #            }
          else
            new_key = SpinLocationManager.location_to_key(new_location, NODE_FILE)
            if /folder_a/ =~ target_cont_location
              cont_location = 'folder_a'
            elsif /folder_b/ =~ target_cont_location
              cont_location = 'folder_b'
            else
              cont_location = 'folder_a'
            end
            FileDatum.load_file_list_rec(copy_sid, cont_location, ret_key, new_key)
            FileDatum.fill_file_list(copy_sid, cont_location, new_key)
          end
        else
          FileManager.rails_logger(">> copy_virtual_file_in_clipboard : failed to copy " + vfile_name + '(' + cpf + ')')
          #          return false
        end

      end # => end of while loop

      if ret_key.blank?
        pp "ret_key is empty"
      end

      return (ret_key.blank? == true ? false : true)

    end

    # => end of delete_virtual_file delete_sid, delete_file_key, true # => the last argument is trash_it flag

    def self.move_virtual_files operation_id, move_sid, move_file_keys, target_folder_key, target_cont_location
      # Does the user have any right to delete or trash file?
      ret_key = ''
      # get location of the target folder

      # get 1 node from clipboard and process it
      # unitl all data that has same opr_id are proccessed
      while true do
        # get 1
        get_node_hash = ClipBoards.get_node operation_id, move_sid
        mvf = get_node_hash[:node_hash_key]
        break if mvf == nil # => end of proccess

        # Does it have ACL to do move operation?
        acls = SpinAccessControl.has_acl_values move_sid, mvf, ANY_TYPE
        target_acls = SpinAccessControl.has_acl_values move_sid, target_folder_key, NODE_DIRECTORY
        has_right_to_delete = false
        target_has_right_to_delete = false
        acls.values.each {|av|
          if av & ACL_NODE_WRITE or av & ACL_NODE_DELETE # => has right to delete
            has_right_to_delete = true
            break # => break from 'each' iterator
          end
        }
        target_acls.values.each {|tav|
          if tav & ACL_NODE_WRITE or tav & ACL_NODE_DELETE # => has right to delete
            target_has_right_to_delete = true
            break # => break from 'each' iterator
          end
        }
        if has_right_to_delete == false or target_has_right_to_delete == false
          next # => skip this and get next
        end

        # get location of the current target
        tloc = SpinLocationManager.key_to_location(target_folder_key, NODE_DIRECTORY)

        if SpinNode.is_directory(mvf) == true
          # get location
          my_loc = SpinLocationManager.key_to_location(mvf, NODE_DIRECTORY)
          my_move_file_keys = ClipBoards.get_keys_in_folder_loc move_sid, my_loc
          vfile_name = SpinNode.get_node_name mvf
          my_loc[X] = REQUEST_COORD_VALUE
          my_loc[Y] = tloc[Y] + 1
          my_loc[PRX] = tloc[X]
          #          my_loc[V] = REQUEST_VERSION_NUMBER
          new_location = nil
          while new_location.blank?
            new_location = SpinNodeKeeper.test_and_set_xy(move_sid, my_loc, vfile_name, NODE_DIRECTORY)
          end
          ret_key = SpinNode.move_node_location(move_sid, mvf, new_location, target_cont_location, NODE_DIRECTORY)
          if my_move_file_keys.length > 0
            ret_key = self.move_virtual_files move_sid, my_move_file_keys, mvf, target_cont_location
          end
        else # => file
          # get location
          my_loc = SpinLocationManager.key_to_location(mvf, NODE_FILE)
          vfile_name = SpinNode.get_node_name mvf
          my_loc[X] = ANY_VALUE
          my_loc[Y] = tloc[Y] + 1
          my_loc[PRX] = tloc[X]
          #          my_loc[V] = REQUEST_VERSION_NUMBER
          new_location = nil
          while new_location.blank?
            new_location = SpinNodeKeeper.test_and_set_xy(move_sid, my_loc, vfile_name, NODE_FILE)
          end
          if new_location[V] < 0
            new_location[V] *= (-1)
          end
          ret_key = SpinNode.move_node_location(move_sid, mvf, new_location, target_cont_location, NODE_FILE)
          # delete or trash file node
          #          ret = SpinNode.move_node mvf, target_folder_key, target_cont_location
        end
      end
      current_move_file_keys = []
      tloc = SpinLocationManager.key_to_location(target_folder_key, NODE_DIRECTORY)
      if move_file_keys == nil
        current_move_file_keys = ClipBoards.get_keys_in_folder_loc move_sid, tloc
      else
        current_move_file_keys = move_file_keys
      end
      current_move_file_keys.each {|mvf|
        acls = SpinAccessControl.has_acl_values move_sid, mvf, ANY_TYPE
        target_acls = SpinAccessControl.has_acl_values move_sid, target_folder_key, NODE_DIRECTORY
        has_right_to_delete = false
        target_has_right_to_delete = false
        acls.values.each {|av|
          if av & ACL_NODE_WRITE or av & ACL_NODE_DELETE # => has right to delete
            has_right_to_delete = true
            break
          end
        }
        target_acls.values.each {|tav|
          if tav & ACL_NODE_WRITE or tav & ACL_NODE_DELETE # => has right to delete
            target_has_right_to_delete = true
            break
          end
        }
        # return false unless it has right to delete file
        if has_right_to_delete == false or target_has_right_to_delete == false
          return ret_key
        end

        if SpinNode.is_directory(mvf) == true
          # get location
          my_loc = SpinLocationManager.key_to_location(mvf, NODE_DIRECTORY)
          my_move_file_keys = ClipBoards.get_keys_in_folder_loc move_sid, my_loc
          vfile_name = SpinNode.get_node_name mvf
          my_loc[X] = REQUEST_COORD_VALUE
          my_loc[Y] = tloc[Y] + 1
          my_loc[PRX] = tloc[X]
          new_location = nil
          while new_location.blank?
            new_location = SpinNodeKeeper.test_and_set_xy(move_sid, my_loc, vfile_name, NODE_DIRECTORY)
          end
          ret = SpinNode.move_node_location(move_sid, mvf, new_location, target_cont_location, NODE_DIRECTORY)
          if my_move_file_keys.length > 0
            ret_key = self.move_virtual_files move_sid, my_move_file_keys, mvf, target_cont_location
          end
        else
          # get location
          my_loc = SpinLocationManager.key_to_location(mvf, NODE_FILE)
          vfile_name = SpinNode.get_node_name mvf
          my_loc[X] = ANY_VALUE
          my_loc[Y] = tloc[Y] + 1
          my_loc[PRX] = tloc[X]
          new_location = nil
          while new_location.blank?
            new_location = SpinNodeKeeper.test_and_set_xy(move_sid, my_loc, vfile_name, NODE_FILE)
          end
          if new_location[V] < 0
            new_location[V] *= (-1)
          end
          ret = SpinNode.move_node_location(move_sid, mvf, new_location, target_cont_location, NODE_FILE)
          # delete or trash file node
          #          ret = SpinNode.move_node mvf, target_folder_key, target_cont_location
        end
        unless ret_key.blank?
          ClipBoards.set_operation_completed operation_id, move_sid, OPERATION_CUT, mvf, ret_key
        else
          break
        end
      }
      # tidy up!
      return ret_key
    end

    # => end of delete_virtual_file delete_sid, delete_file_key, true # => the last argument is trash_it flag

    #    def self.copy_virtual_files copy_sid, copy_file_keys, target_folder_key, target_cont_location
    #      # Does the user have any right to delete or trash file?
    #      ret = false
    #      ret_key = ''
    #      # get location of the target folder
    #      current_copy_file_keys = []
    #      tloc = SpinLocationManager.key_to_location(target_folder_key, NODE_DIRECTORY)
    #      if copy_file_keys == nil
    #        current_copy_file_keys = ClipBoards.get_keys_in_folder_loc copy_sid, tloc
    #      else
    #        current_copy_file_keys = copy_file_keys
    #      end
    #      current_copy_file_keys.each {|mvf|
    #        acls = SpinAccessControl.has_acl_values copy_sid, mvf, ANY_TYPE
    #        target_acls = SpinAccessControl.has_acl_values copy_sid, target_folder_key, NODE_DIRECTORY
    #        has_right_to_delete = false
    #        target_has_right_to_delete = false
    #        acls.values.each {|av|
    #          if av & ACL_NODE_WRITE or av & ACL_NODE_DELETE # => has right to delete
    #            has_right_to_delete = true
    #            break
    #          end
    #        }
    #        target_acls.values.each {|tav|
    #          if tav & ACL_NODE_WRITE or tav & ACL_NODE_DELETE # => has right to delete
    #            target_has_right_to_delete = true
    #            break
    #          end
    #        }
    #        # return false unless it has right to delete file
    #        if has_right_to_delete == false or target_has_right_to_delete == false
    #          return false
    #        end
    #        ret = false
    #        if SpinNode.is_directory(mvf) == true
    #          # get location
    #          my_loc = SpinLocationManager.key_to_location(mvf, NODE_DIRECTORY)
    #          my_copy_file_keys = ClipBoards.get_keys_in_folder_loc copy_sid, my_loc
    #          vfile_name = SpinNode.get_node_name mvf
    #          my_loc[X] = ANY_VALUE
    #          my_loc[Y] = tloc[Y] + 1
    #          my_loc[PRX] = tloc[X]
    #          new_location = SpinNodeKeeper.test_and_set_xy(copy_sid, my_loc, vfile_name, NODE_DIRECTORY)
    #          if new_location != [ -1, -1, -1, -1 ]
    #            ret = SpinNode.copy_node_location(copy_sid, mvf, tloc, new_location, (new_location[V] > 0 ? false : true), target_cont_location, NODE_DIRECTORY)
    #          end
    #          if my_copy_file_keys.length > 0
    #            ret_key = self.copy_virtual_files copy_sid, my_copy_file_keys, mvf, target_cont_location
    #          else
    #            ret = true
    #          end
    #        else
    #          # get location
    #          my_loc = SpinLocationManager.key_to_location(mvf, NODE_FILE)
    #          vfile_name = SpinNode.get_node_name mvf
    #          my_loc[X] = ANY_VALUE
    #          my_loc[Y] = tloc[Y] + 1
    #          my_loc[PRX] = tloc[X]
    #          new_location = SpinNodeKeeper.test_and_set_xy(copy_sid, my_loc, vfile_name, NODE_FILE)
    #          ret = SpinNode.copy_node_location(copy_sid, mvf, tloc, new_location, false, target_cont_location, NODE_FILE)
    #          # delete or trash file node
    #          #          ret = SpinNode.copy_node mvf, target_folder_key, target_cont_location
    #        end
    #        unless ret_key.emtpty?
    #          ClipBoards.set_operation_completed operation_id, copy_sid, OPERATIONS_COPY, mvf, ret_key
    #        else
    #          ret = false
    #          break
    #        end
    #      }
    #      # tidy up!
    #      if ret == true
    #      end
    #      return ret
    #    end # => end of delete_virtual_file delete_sid, delete_file_key, true # => the last argument is trash_it flag

    def self.change_virtual_file_properties sid, hash_key, properties
      if SpinAccessControl.is_writable(sid, hash_key, ANY_TYPE)
        retb = false
        node_attributes = {}
        target_node = SpinNode.find_by(spin_node_hashkey: hash_key)

        if target_node.blank?
          return false
        end
        vloc = []
        px = vloc[X] = target_node[:node_x_coord]
        py = vloc[Y] = target_node[:node_y_coord]
        vloc[PRX] = target_node[:node_x_pr_coord]
        vloc[V] = target_node[:node_version]
        ploc = SpinNode.get_parent_location(vloc)
        same_name_files = SpinNode.where(["spin_tree_type = 0 AND node_x_pr_coord = ? AND node_x_coord <> ? AND node_y_coord = ? AND node_name = ? AND is_void = false", ploc[X], px, py, properties[:file_name]])
        unless same_name_files.blank?
          return false
        end

        if /{.+}/ =~ target_node[:node_attributes] # => json text
          node_attributes = JSON.parse target_node[:node_attributes]
        end # => end of if /{.+}/ =~ target_node[:node_attributes] # => json text
        SpinNode.transaction do
          # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
          if properties[:file_name].present?
            target_node[:node_name] = properties[:file_name]
            vp = target_node[:virtual_path]
            fnindex = vp.rindex('/')
            newvp = vp[0..fnindex] + properties[:file_name]
            target_node[:virtual_path] = newvp
            subq = "virtual_path LIKE \'#{vp}/%\'"
            subnodes = SpinNode.where("#{subq}")
            spos = vp.length
            subnodes.each {|sn|
              vptmp = sn[:virtual_path]
              sn[:virtual_path] = newvp + vptmp[spos..-1]
              sn.save
            }
          end
          if properties[:description].present?
            target_node[:node_description] = properties[:description]
            node_attributes[:description] = properties[:description]
          end
          if properties[:title].present?
            node_attributes[:title] = properties[:title]
          end
          if properties[:subtitle].present?
            node_attributes[:subtitle] = properties[:subtitle]
          end
          if properties[:keyword].present?
            node_attributes[:keyword] = properties[:keyword]
            if node_attributes != {}
              target_node[:node_attributes] = node_attributes.to_json
            end
          end
          #          SpinNode.has_updated(sid, hash_key)
          #          ctime = Time.now
          #          target_node[:spin_updated_at] = ctime
          #          target_node[:ctime] = ctime
          if target_node.save
            SpinNodeKeeper.modify_node_keeper_node_name(px, py, properties[:file_name])
            SpinNode.has_updated(sid, hash_key)
            retb = true

            if target_node[:node_type] == NODE_DIRECTORY
              pn = SpinLocationManager.get_parent_node(target_node)
              parent_node = pn[:spin_node_hashkey]
              #              parent_node = SpinLocationManager.get_parent_key(hash_key, NODE_FILE)
              FolderDatum.has_updated(sid, parent_node, UPDATE_PROPERTY, true)
            end

          else
            retb = false
          end
        end # => end of transaction

        return retb
      else
        return false
      end
    end

    # => end of change_virtual_file_properties

    def self.change_virtual_file_extension sid, hash_key, properties
      if SpinAccessControl.is_writable(sid, hash_key, ANY_TYPE)
        retb = false
        #target_node = SpinNode.find_by_spin_node_hashkey hash_key
        node_attributes = {}
        target_node = SpinNode.find_by(spin_node_hashkey: hash_key)
        if target_node.blank?
          return false
        end
        if /{.+}/ =~ target_node[:node_attributes] # => json text
          target_node_node_attributes = target_node[:node_attributes]
          node_attributes = JSON.parse(target_node_node_attributes)
          #node_attributes = JSON.parse target_node[:node_attributes]
        end # => end of node_attributesif /{.+}/ =~ target_node[:node_attributes] # => json text
        SpinNode.transaction do
          # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
          #          properties.each {|key,value|
          #            node_attributes[key] = value
          #          }
          #cast = properties[:cast]
          node_attributes["cast"] = properties["cast"]
          node_attributes["client"] = properties["client"]
          node_attributes["copyright"] = properties["copyright"]
          node_attributes["duration"] = properties["duration"]
          node_attributes["location"] = properties["location"]
          node_attributes["music"] = properties["music"]
          node_attributes["producer"] = properties["producer"]
          node_attributes["produced_date"] = properties["produced_date"]
          if node_attributes != {}
            target_node[:node_attributes] = node_attributes.to_json
            target_node[:memo1] = properties["duration"] #Add memo By Imai 2015/1/14
            target_node[:memo2] = properties["producer"] #Add memo By Imai 2015/1/14
            target_node[:memo3] = properties["produced_date"] #Add memo By Imai 2015/1/14
            target_node[:memo4] = properties["location"] #Add memo By Imai 2015/1/14
            target_node[:memo5] = properties["cast"] #Add memo By Imai 2015/1/14
          end
          #ADD IMAI at 2015/12/26
          ctime = Time.now
          target_node[:spin_updated_at] = ctime
          if target_node.save
            retb = true
            #            parent_node = SpinLocationManager.get_parent_key(target_node, NODE_FILE)
            #            FolderDatum.has_updated(sid, parent_node, UPDATE_PROPERTY, true)

          else
            retb = false
          end
        end # => end of transaction

        return retb
      else
        return false
      end
    end

    # => end of change_virtual_file_properties

    def self.change_virtual_file_details sid, hash_key, properties
      if SpinAccessControl.is_writable(sid, hash_key, ANY_TYPE)
        retb = false
        target_node = SpinNode.find_by(spin_node_hashkey: hash_key)
        if target_node.blank?
          return false
        end
        SpinNode.transaction do
          # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
          target_node[:details] = properties[:details]
          target_node[:details] = properties[:details]
          target_node[:details] = properties[:details]
          target_node[:details] = properties[:details]
          target_node[:details] = properties[:details]
          #ADD IMAI at 2015/12/26
          ctime = Time.now
          target_node[:spin_updated_at] = ctime
          if target_node.save
            retb = true
          else
            retb = false
          end
        end # => end of transaction

        #        parent_node = SpinLocationManager.get_parent_key(hash_key, NODE_FILE)
        #        FolderDatum.has_updated(sid, parent_node, UPDATE_PROPERTY, true)

        return retb
      else
        return false
      end
    end

    # => end of change_virtual_file_properties

    def self.change_virtual_file_name sid, location, hash_key, new_name, is_in_list = false
      if SpinAccessControl.is_writable(sid, hash_key, ANY_TYPE)
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        n = SpinNode.find_by(spin_node_hashkey: hash_key)
        if n.blank?
          return false
        end

        vloc = []
        px = vloc[X] = n[:node_x_coord]
        py = vloc[Y] = n[:node_y_coord]
        vloc[PRX] = n[:node_x_pr_coord]
        vloc[V] = n[:node_version]
        ploc = SpinNode.get_parent_location(vloc)
        # same_name_files = SpinNode.where(["spin_tree_type = 0 AND node_x_pr_coord = ? AND node_y_coord = ? AND node_name = ? AND is_void = false",ploc[X],vloc[Y],new_name])
        # if same_name_files.count > 0
        #   return false
        # end

        retry_change_virtual_file_name = ACTIVE_RECORD_RETRY_COUNT
        catch(:change_virtual_file_name_again) {
          SpinNode.transaction do
            begin
              n[:node_name] = new_name
              vp = n[:virtual_path]
              fnindex = vp.rindex('/')
              newvp = vp[0..fnindex] + new_name
              n[:virtual_path] = newvp
              #          ctime = Time.now
              #          n[:spin_updated_at] = ctime
              #          n[:ctime] = ctime
              recs = SpinNode.where(["spin_node_hashkey = ?", hash_key]).update_all(node_name: new_name, virtual_path: newvp)
              if recs == 1
                subq = "virtual_path LIKE \'#{vp}/%\'"
                subnodes = SpinNode.where("#{subq}")
                spos = vp.length
                subnodes.each {|sn|
                  vptmp = sn[:virtual_path]
                  sn[:virtual_path] = newvp + vptmp[spos..-1]
                  recs = SpinNode.where(["spin_node_hashkey = ?", hash_key]).update_all(virtual_path: newvp + vptmp[spos..-1])
                  if recs != 1
                    return false
                  end
                }
                SpinNodeKeeper.modify_node_keeper_node_name(px, py, new_name)
                SpinNode.has_updated(sid, hash_key)
                frecs = FolderDatum.where(["session_id = ? AND spin_node_hashkey = ?", sid, hash_key]).update_all(text: new_name, folder_name: new_name)
                if frecs != 1
                  return false
                end
                flrecs = FileDatum.where(["session_id = ? AND spin_node_hashkey = ?", sid, hash_key]).update_all(file_name: new_name)
                if flrecs != 1
                  return false
                end

                parent_node = SpinLocationManager.get_parent_key(hash_key, NODE_FILE)
                FolderDatum.has_updated(sid, parent_node, UPDATE_PROPERTY, true)
              else
                return false
              end
            rescue ActiveRecord::StaleObjectError
              if retry_change_virtual_file_name > 0
                retry_change_virtual_file_name -= 1
                throw :change_virtual_file_name_again
              else
                return false
              end
            end
          end # end of transaction
        } # end of catch-block
      else
        return false
      end
    end

    # => self.change_virtual_file_name sid, location, hash_key, new_name, is_in_list = false

    def self.change_virtual_domain_name sid, hash_key, new_name
      # => find spin domain
      spin_domain_rec = nil
      retry_count = ACTIVE_RECORD_RETRY_COUNT
      catch(:change_virtual_domain_name_again) {
        SpinDomain.transaction do
          begin
            spin_domain_rec = SpinDomain.find_by(hash_key: hash_key)
            unless spin_domain_rec.present?
              return false
            end
            if SpinAccessControl.is_writable(sid, spin_domain_rec[:domain_root_node_hashkey], NODE_DOMAIN)
              # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
              #          n = SpinDomain.find_by_hash_key hash_key
              spin_domain_rec[:spin_domain_disp_name] = new_name
              if spin_domain_rec.save
                #            SessionManager.set_location_dirty(sid, location, is_in_list)
                SpinDomain.set_domain_has_updated(hash_key)
                return true
              else
                return false
              end
            else
              return false
            end
          rescue ActiveRecord::StaleObjectError
            retry_count -= 1
            if retry_count > 0
              sleep(AR_RETRY_WAIT_MSEC)
              throw :change_virtual_domain_name_again
            else
              return false
            end
          end
        end # => end of transaction
      }
    end

    # => end of self.change_virtual_domain_name sid, location, hash_key, new_name, is_in_list = false

    #    # Should be called in a transaction!
    #    def SpinNode.get_access_rights uid, gid, x, y
    #      # get node(x,y)
    #      if x < 0
    #        x = 0
    #      end
    #      if y < 0
    #        y = 0
    #      end
    #      acl = Hash.new
    #      n = SpinNode.readonly.find_by_node_x_coord_and_node_y_coord x, y
    #      if n
    #        acl[:spin_uid_access_right] = ( n[:spin_uid] == uid ? n[:spin_uid_access_right] : ACL_NODE_NO_ACCESS )
    #        acl[:spin_gid_access_right] = ( n[:spin_gid] == gid ? n[:spin_gid_access_right] : ACL_NODE_NO_ACCESS )
    #        acl[:spin_world_access_right] = n[:spin_world_access_right]
    #      else
    #        return nil
    #      end
    #      # pp "n = ",n
    #      # retreive access rights fr4om spin_access_controls
    #      u_acls = SpinAccessControl.readonly.where :managed_node_hashkey => n[:spin_node_hashkey], :spin_uid => uid
    #      g_acls = SpinAccessControl.readonly.where :managed_node_hashkey => n[:spin_node_hashkey], :spin_gid => gid
    #      if u_acls.length > 0
    #        u_acls.each {|ua|
    #          acl[:spin_uid_access_right] |= ua[:spin_uid_access_right]
    #        }
    #      end
    #      if g_acls.length > 0
    #        g_acls.each {|ga|
    #          acl[:spin_gid_access_right] |= ga[:spin_gid_access_right]
    #        }
    #      end
    #      # return access rights
    #      return acl
    #    end
    #
    #    # Sould be called in a transaction!
    #    def self.get_spin_vfs_id x, y
    #      # get node(x,y)
    #      n = nil
    #      if x < 0
    #        x = 0
    #      end
    #      if y < 0
    #        y = 0
    #      end
    #      acl = Hash.new
    #      n = SpinNode.readonly.find(["node_x_coord = ? AND node_y_coord = ?", x, y]).order("node_version DESC")
    #      # pp "n = ",n
    #      # return access rights
    #      return n[:spin_vfs_id]
    #    end
    #
    #    # Sould be called in a transaction!
    #    def self.get_spin_storage_id x, y
    #      # get node(x,y)
    #      n = nil
    #      if x < 0
    #        x = 0
    #      end
    #      if y < 0
    #        y = 0
    #      end
    #      acl = Hash.new
    #      #      n = SpinNode.readonly.find_by_node_x_coord_and_node_y_coord x, y
    #      n = SpinNode.readonly.find(["node_x_coord = ? AND node_y_coord = ?", x, y]).order("node_version DESC")
    #      # pp "n = ",n
    #      # return access rights
    #      return n[:spin_storage_id]
    #    end
    #
    #    # Sould be called in a transaction!
    #    def self.get_spin_node_tree x, y
    #      # get node(x,y)
    #      n = nil
    #      if x < 0
    #        x = 0
    #      end
    #      if y < 0
    #        y = 0
    #      end
    #      n = SpinNode.readonly.find(["node_x_coord = ? AND node_y_coord = ?", x, y]).order("node_version DESC")
    #      #      n = SpinNode.readonly.find_by_node_x_coord_and_node_y_coord x, y
    #      # pp "n = ",n
    #      # return access rights
    #      return n[:spin_node_tree]
    #    end
    #
    #    # Sould be called in a transaction!
    #    def self.get_max_versions x, y
    #      # get node(x,y)
    #      n = nil
    #      if x < 0
    #        x = 0
    #      end
    #      if y < 0
    #        y = 0
    #      end
    #      n = SpinNode.readonly.find(["node_x_coord = ? AND node_y_coord = ? ORDER BY node_version DESC LIMIT 1;", x, y])
    #      #      n = SpinNode.readonly.find_by_node_x_coord_and_node_y_coord x, y
    #      # pp "n = ",n
    #      # return access rights
    #      return n[:max_versions]
    #    end
    #
    #    def self.create_folder_at sid, folder_hash_key, virtual_folder_name
    #      # analyze virtual_path path
    #      virtual_path = virtual_folder_name
    #      # => ex. /clients/a_coorporation/orginization/.../
    #
    #      vloc = [ 0, 0, 0, 0 ]  # => means ROOT
    #      not_exists = [-1,-1,-1,-1,nil]
    #      loc = [ -1, -1, -1, -1 ]
    #
    #      # search directory path which has the folder_hash_key
    #      self.transaction do
    #        cloc_obj = SpinNode.readonly.find_by_spin_node_hashkey(folder_hash_key)
    #        if cloc_obj == nil
    #          return not_exists
    #        end
    #        cloc = cloc_obj.select("node_x_coord,node_y_coord,node_x_pr_coord,node_version")
    #        # get virtual path which is at the loc[x,y,prx,v]
    #        loc[X] = cloc[:node_x_coord]
    #        loc[Y] = cloc[:node_y_coord]
    #        loc[PRX] = cloc[:node_x_pr_coord]
    #        loc[V] = cloc[:node_version]
    #      end
    #
    #      cpath = SpinLocationManager.get_location_vpath loc
    #
    #      # Is it a relative path?
    #      if virtual_path[0,2] == "./" # => relative path
    #        # resolve it and make absolute path
    #        cpath << virtual_path[1..-1]    # => from '/' to the end of string
    #      elsif virtual_path[0,1] != "/" # => relative path
    #        # resolve it and make absolute path
    #        cpath << virtual_path        # => from '/' to the end of string
    #      else
    #        cpath << '/' << virtual_path
    #      end
    #      virtual_path = cpath
    #      # ret_path = DatabaseUtility::SessionUtility.set_current_directory ADMIN_SESSION_ID, cpath
    #      vloc = self.create_virtual_directory_path sid, virtual_path, true
    #      if vloc[X..V] == [ -1, -1, -1, -1 ] # => error!
    #        return [ -1, -1, -1, -1 ]
    #      end
    #      return vloc
    #    end   # => end of create_folder_at

    def self.create_virtual_file_dbu sid, vfile_name, dir_key, acls = nil, is_under_maintenance = true, set_pending = false
      # create virtual file in the directory specified by dir_key
      # acls : acl hash for the new file if it isn't nil
      # => default : use acls of the parent directory
      # get uid and gid { :uid => id, :gid => id }
      uidgid = SessionManager.get_uid_gid sid
      # get location [x,y,prx,v] from dir_key
      ploc = SpinLocationManager.key_to_location dir_key, NODE_DIRECTORY

      # Are there nodes in the target directory?
      #      existing_nodes = SpinNode.where(["spin_tree_type = 0 AND node_x_pr_coord = ? AND node_y_coord = ? AND is_void = false",ploc[X],ploc[Y] + 1])
      #      max_number = REQUEST_COORD_VALUE
      #      existing_nodes.each {|n|
      #        if n[:node_x_coord] > max_number
      #          max_number = n[:node_x_coord]
      #        end
      #      }
      # get full location [X,Y,P,V,K]
      loc = [REQUEST_COORD_VALUE, ploc[Y] + 1, ploc[X], REQUEST_VERSION_NUMBER]
      vfile_loc = nil
      while vfile_loc.blank?
        vfile_loc = SpinNodeKeeper.test_and_set_xy sid, loc, vfile_name # parent node loc and new file name
      end
      if vfile_loc[V] < 0
        vfile_loc[V] *= (-1)
      end
      # Is there a file that has the same name?
      same_locs = SpinNode.where(["spin_tree_type = 0 AND node_x_coord = ? AND node_y_coord = ?", vfile_loc[X], vfile_loc[Y]])
      same_locs.each {|sl|
        if sl[:node_name] != vfile_name
          SpinNode.delete_node(sid, sl[:spin_node_hashkey], true)
        else
          if sl[:node_version] < vfile_loc[V]
            sl[:latest] = false
            sl.save
          end
        end
      }
      log_msg = ":create_virtual_file_dbu => test_and_set_xy returned = #{vfile_loc.to_s}"
      FileManager.logger(sid, log_msg, 'LOCAL', LOG_ERROR)
      if vfile_loc[X..V] == [-1, -1, -1, -1]
        return vfile_loc
      end
      vfile_loc = SpinNode.create_spin_node sid, vfile_loc[X], vfile_loc[Y], vfile_loc[PRX], vfile_loc[V], vfile_name, NODE_FILE, uidgid[:uid], uidgid[:gid], acls, is_under_maintenance, set_pending
      if acls == nil
        # vfile_loc = self.create_virtual_node 0, depth, prx, 0, NODE_DIRECTORY, get_uid, get_gid
        SpinAccessControl.copy_parent_acls sid, vfile_loc, NODE_FILE.dir_key, uidgid[:uid] # => vfile_loc = [x,y,prx,v,hashkey]
      end
      return vfile_loc[X..K] # => return location array
      #      return vfile_loc[K] # => return hash key
    end

    # => self.create_virtual_file sid, vfile_name, dir_key

    #    def self.create_virtual_new_version sid, vfile_name, dir_key, acls = nil, is_under_maintenance = false, set_pending = false
    #      # create virtual file in the directory specified by dir_key
    #      # acls : acl hash for the new file if it isn't nil
    #      # => default : use acls of the parent directory
    #      # get uid and gid { :uid => id, :gid => id }
    #      uidgid = SessionManager.get_uid_gid sid
    #      # get location [x,y,prx,v] from vfile_key
    #      older_nodes = []
    #      ploc = SpinLocationManager.key_to_location dir_key, NODE_DIRECTORY
    #      self.transaction do
    #        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
    #        older_nodes = SpinNode.where(:spin_tree_type => SPIN_NODE_VTREE, :node_x_pr_coord => ploc[X],:node_y_coord => ploc[Y]+1,:node_name => vfile_name).order("node_version DESC")
    #        older_nodes.each {|n|
    #          n[:latest] = false
    #          n.save
    #        }
    #        vfile_key = older_nodes[0][:spin_node_hashkey]
    #      end # => end of transaction
    #      # get version info of vfile_key
    #      #       n = SpinNode.find_by_spin_node_hashkey vfile_key
    #      vfile_loc = [ -1, -1, -1, -1 ]
    #      self.transaction do
    #        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
    #        version_info = SpinNode.get_version_info older_nodes[0][:node_x_coord],older_nodes[0][:node_y_coord]
    #        vfile_loc = SpinNode.create_spin_node sid, older_nodes[0][:node_x_coord], older_nodes[0][:node_y_coord], older_nodes[0][:node_x_pr_coord], version_info[:latest_version]+1, version_info[:name], NODE_FILE, uidgid[:uid], uidgid[:gid], acls, is_under_maintenance, set_pending
    #      end # => end of transaction
    #      if vfile_loc[X..V] != [ -1, -1, -1, -1 ]
    #        if acls == nil
    #          # vfile_loc = self.create_virtual_node 0, depth, prx, 0, NODE_DIRECTORY, get_uid, get_gid
    #          SpinAccessControl.copy_parent_acls sid, vfile_loc, NODE_FILE, dir_key, uidgid[:uid] # => vfile_loc = [x,y,prx,v,hashkey]
    #        end
    #        return SpinLocationManager.location_to_key vfile_loc, NODE_FILE
    #      else
    #        return nil
    #      end
    #    end # => self.create_virtual_file sid, vfile_name, dir_key

    def self.get_latest_version vfile_key
      # get version info of vfile_key
      loc = SpinLocationManager.key_to_location vfile_key
      latest_node_key = SpinNode.get_latest_node loc[X], loc[Y]
    end

    # => end of get_latest_version open_file_key

    def self.get_prior_version vfile_key
      # get version info of vfile_key
      loc = SpinLocationManager.key_to_location vfile_key
      prior_node_key = SpinNode.get_prior_node loc[X], loc[Y]
    end

    # => end of get_latest_version open_file_key

    def self.search_virtual_file sid, file_name, dir_key, dir_x = ANY_VALUE, dir_y = ANY_VALUE, search_file_status = SEARCH_ACTIVE_VFILE
      # get location of the dir
      fs = []
      dir_loc = []
      if dir_x == ANY_VALUE or dir_y == ANY_VALUE
        dir_loc = SpinLocationManager.key_to_location dir_key
      else
        dir_loc[X] = dir_x
        dir_loc[Y] = dir_y
      end
      SpinNode.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        if dir_loc[Y] > 0
          case search_file_status
            when SEARCH_ACTIVE_VFILE
              fs = SpinNode.where(["spin_tree_type = ? AND node_x_pr_coord = ? AND node_y_coord = ? AND node_name = ? AND is_void = false AND is_pending = false AND in_trash_flag = false", SPIN_NODE_VTREE, dir_loc[X], dir_loc[Y]+1, file_name]).order("node_version DESC")
            when SEARCH_EXISTING_VFILE
              fs = SpinNode.where(["spin_tree_type = ? AND node_x_pr_coord = ? AND node_y_coord = ? AND node_name = ? AND is_void = false", SPIN_NODE_VTREE, dir_loc[X], dir_loc[Y]+1, file_name]).order("node_version DESC")
            #            fs = SpinNode.where(:spin_tree_type => SPIN_NODE_VTREE, :node_x_pr_coord => dir_loc[X], :node_y_coord => dir_loc[Y]+1, :node_name => file_name, :is_void => false).order("node_version DESC")
            when SEARCH_IN_TRASH_VFILE
              fs = SpinNode.where(["spin_tree_type = ? AND node_x_pr_coord = ? AND node_y_coord = ? AND node_name = ? AND in_trash_flag = true", SPIN_NODE_VTREE, dir_loc[X], dir_loc[Y]+1, file_name]).order("node_version DESC")
            #            fs = SpinNode.where(:spin_tree_type => SPIN_NODE_VTREE, :node_x_pr_coord => dir_loc[X], :node_y_coord => dir_loc[Y]+1, :node_name => file_name, :in_trash_flag => true).order("node_version DESC")
            when SEARCH_PENDING_VFILE
              fs = SpinNode.where(["spin_tree_type = ? AND node_x_pr_coord = ? AND node_y_coord = ? AND node_name = ? AND is_pending = true", SPIN_NODE_VTREE, dir_loc[X], dir_loc[Y]+1, file_name]).order("node_version DESC")
            #            fs = SpinNode.where(:spin_tree_type => SPIN_NODE_VTREE, :node_x_pr_coord => dir_loc[X], :node_y_coord => dir_loc[Y]+1, :node_name => file_name, :is_pending => true).order("node_version DESC")
            else # => same as SEARCH_ACTIVE_VFILE
              fs = SpinNode.where(["spin_tree_type = ? AND node_x_pr_coord = ? AND node_y_coord = ? AND node_name = ? AND is_void = false AND is_pending = false AND in_trash_flag = false", SPIN_NODE_VTREE, dir_loc[X], dir_loc[Y]+1, file_name]).order("node_version DESC")
            #            fs = SpinNode.where(:spin_tree_type => SPIN_NODE_VTREE, :node_x_pr_coord => dir_loc[X], :node_y_coord => dir_loc[Y]+1, :node_name => file_name, :is_void => false, :is_pending => false, :in_trash_flag => false).order("node_version DESC")
          end
          #          if active_file_only
          #            fs = SpinNode.where(:node_x_pr_coord => dir_loc[X], :node_y_coord => dir_loc[Y]+1, :node_name => file_name, :is_void => false, :is_pending => false, :in_trash_flag => false).order("node_version DESC")
          #          else
          #            fs = SpinNode.where(:node_x_pr_coord => dir_loc[X], :node_y_coord => dir_loc[Y]+1, :node_name => file_name).order("node_version DESC")
          #          end
        else
          case search_file_status
            when SEARCH_ACTIVE_VFILE
              fs = SpinNode.where(["spin_tree_type = ? AND node_x_pr_coord = ? AND node_y_coord = ? AND node_name = ? AND is_void = false AND is_pending = false AND in_trash_flag = false", SPIN_NODE_VTREE, 0, dir_loc[Y]+1, file_name]).order("node_version DESC")
            #            fs = SpinNode.where(:spin_tree_type => SPIN_NODE_VTREE, :node_x_pr_coord => 0, :node_y_coord => dir_loc[Y]+1, :node_name => file_name, :is_void => false, :is_pending => false, :in_trash_flag => false).order("node_version DESC")
            when SEARCH_EXISTING_VFILE
              fs = SpinNode.where(["spin_tree_type = ? AND node_x_pr_coord = ? AND node_y_coord = ? AND node_name = ? AND is_void = false", SPIN_NODE_VTREE, 0, dir_loc[Y]+1, file_name]).order("node_version DESC")
            #            fs = SpinNode.where(:spin_tree_type => SPIN_NODE_VTREE, :node_x_pr_coord => 0, :node_y_coord => dir_loc[Y]+1, :node_name => file_name, :is_void => false).order("node_version DESC")
            when SEARCH_IN_TRASH_VFILE
              fs = SpinNode.where(["spin_tree_type = ? AND node_x_pr_coord = ? AND node_y_coord = ? AND node_name = ? AND in_trash_flag = true", SPIN_NODE_VTREE, 0, dir_loc[Y]+1, file_name]).order("node_version DESC")
            #            fs = SpinNode.where(:spin_tree_type => SPIN_NODE_VTREE, :node_x_pr_coord => 0, :node_y_coord => dir_loc[Y]+1, :node_name => file_name, :in_trash_flag => true).order("node_version DESC")
            when SEARCH_PENDING_VFILE
              fs = SpinNode.where(["spin_tree_type = ? AND node_x_pr_coord = ? AND node_y_coord = ? AND node_name = ? AND is_pending = true", SPIN_NODE_VTREE, 0, dir_loc[Y]+1, file_name]).order("node_version DESC")
            #            fs = SpinNode.where(:spin_tree_type => SPIN_NODE_VTREE, :node_x_pr_coord => 0, :node_y_coord => dir_loc[Y]+1, :node_name => file_name, :is_pending => true).order("node_version DESC")
            else # => same as SEARCH_ACTIVE_VFILE
              fs = SpinNode.where(["spin_tree_type = ? AND node_x_pr_coord = ? AND node_y_coord = ? AND node_name = ? AND is_void = false AND is_pending = false AND in_trash_flag = false", SPIN_NODE_VTREE, 0, dir_loc[Y]+1, file_name]).order("node_version DESC")
            #            fs = SpinNode.where(:spin_tree_type => SPIN_NODE_VTREE, :node_x_pr_coord => 0, :node_y_coord => dir_loc[Y]+1, :node_name => file_name, :is_void => false, :is_pending => false, :in_trash_flag => false).order("node_version DESC")
          end
          #          if active_file_only
          #            fs = SpinNode.where(:node_x_pr_coord => 0, :node_y_coord => dir_loc[Y]+1, :node_name => file_name, :is_void => false, :is_pending => false, :in_trash_flag => false).order("node_version DESC")
          #          else
          #            fs = SpinNode.where(:node_x_pr_coord => 0, :node_y_coord => dir_loc[Y]+1, :node_name => file_name).order("node_version DESC")
          #          end
        end
      end
      return fs
    end

    # => end of search_virtual_file

    def self.delete_virtual_file delete_sid, v_delete_file_key, trash_it = true, is_thrown = false # => the last argument is trash_it flag
      # put it into trash can if trash_it is true
      # trash_itはゴミ箱に入れるときにtrue、ゴミ箱に入れずに削除するときはfalse
      # is_thrownはゴミ箱に一番上のフォルダのみを入れる場合にtrue、（この意味は階層が深いとゴミ箱に入れる時間がかかるため一番上のフォルダだけを入れる為）
      # get files at the same xy
      # lock spin_node_keeper(x,y)
      file_versions = []
      ret = false
      rethash = {}

      # return false if it is not deletable.
      file_is_deletable = SpinAccessControl.is_deletable(delete_sid, v_delete_file_key, ANY_TYPE) # => skip deleteing it if it is a sticky file.
      unless file_is_deletable == true
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_PUT_NODE_INTO_RECYCLER
        rethash[:errors] = '削除できないファイル／フォルダです'
        return rethash
      end


      tn = SpinNode.find_by(spin_node_hashkey: v_delete_file_key)
      if tn.blank?
        rethash[:success] = false
        rethash[:status] = Stat::ERROR_KEY_LIST_IS_EMPTY
        rethash[:errors] = '削除するファイルが指定されていません'
        return rethash
      end
      x = tn[:node_x_coord]
      y = tn[:node_y_coord]
      v = tn[:node_version]
      #      printf "(x,y) = (%d,%d)\n",x,y
      #      #      snklock = SpinNodeKeeper.find(["nx = ? AND ny = ?",x,( y == 0 ? 0 : (-1)*y)])
      #      #      snklock = SpinNodeKeeper.find(["nx = ? AND ny = ?",x,y])
      #      #      snklock.with_lock do
      #

      # Is it a file or diretory?
      ntype = tn[:node_type]
      # get parent node
      pn = SpinLocationManager.get_parent_node(tn)
      pnode = pn[:spin_node_hashkey]
      #      pnode = SpinLocationManager.get_parent_key v_delete_file_key

      # go through delete_files
      if ntype == NODE_FILE
        # get versions of a file
        ret = false
        file_versions = SpinNode.where(["spin_tree_type = 0 AND node_x_coord = ? AND node_y_coord = ? AND is_void = false AND node_version <= ?", x, y, v]).order("node_version DESC")

        if file_versions.length == 0 # => no file
          rethash[:success] = false
          rethash[:status] = Stat::ERROR_KEY_LIST_IS_EMPTY
          rethash[:errors] = '削除するファイルが指定されていません'
          return rethash
        end
        #        file_versions.push(tn[:spin_node_hashkey])
        #        file_versions_tmp = (SpinNode.select("spin_node_hashkey").where(["node_x_coord = ? AND node_y_coord = ? AND node_version < ? AND is_void = false AND in_trash_flag = false",x,y,v]).order("node_version DESC")).map {|x| x[:spin_node_hashkey]}
        #        file_versions += file_versions_tmp
        if is_thrown
          RecyclerDatum.set_busy(delete_sid, v_delete_file_key)
        end

        file_versions.each {|fv|
          if trash_it # => put it into recycler
            rethash = RecyclerDatum.put_node_into_recycler delete_sid, fv[:spin_node_hashkey], is_thrown
            # => set spin_updated_at of the parent node
            unless rethash[:success]
              return rethash
            end
          else # => remove it
            #ret =  SpinNode.delete_node delete_sid, fv
            ret = SpinNode.delete_node delete_sid, fv[:spin_node_hashkey]
            # => set spin_updated_at of the parent node
            unless ret
              rethash[:success] = false
              rethash[:status] = ERROR_FAILED_TO_PUT_NODE_INTO_RECYCLER
              rethash[:errors] = '削除できないファイル／フォルダがあります'
              return rethash
            end
            # delete spinLocation_manager rec
            #slms = SpinLocationMapping.where(["node_x_coord = ? AND node_y_coord = ? AND node_hash_key = ?",x,y,fv]) # Comment By imai at 20150618
            retry_save = ACTIVE_RECORD_RETRY_COUNT
            catch(:spin_location_mapping_save_again) {
              SpinLocationMapping.transaction do
                begin
                  #              SpinLocation<Mapping.find_by_sql("LOCK TABLE spin_location_mappings IN EXCLUSIVE MODE;")
                  slms = SpinLocationMapping.where(["node_x_coord = ? AND node_y_coord = ? AND node_hash_key = ?", x, y, fv[:spin_node_hashkey]])
                  slms.each {|slm|
                    slm[:is_void] = true
                    slm.save
                    #              slm.destroy
                  }
                rescue ActiveRecord::StaleObjectError
                  if retry_save > 0
                    retry_save -= 1
                    sleep(AR_RETRY_WAIT_MSEC)
                    throw :spin_location_mapping_save_again
                  end
                end
              end
            }
          end
          if is_thrown
            is_thrown = false
          end
        }
        if trash_it # add if ~ end by imai at 2015/6/18
          RecyclerDatum.complete_trash_operation delete_sid, v_delete_file_key
        end
        FolderDatum.has_updated delete_sid, pnode, DISMISS_CHILD, true
        rethash[:success] = true
        rethash[:status] = INFO_PUT_NODE_INTO_RECYCLER_SUCCESS
        return rethash

      elsif ntype == NODE_DIRECTORY
        if (trash_it === true)
          Rails.logger.warn(">> delete_virtual_file : select get_active_children_for_trash")
          children = SpinNode.get_active_children_for_trash(delete_sid, v_delete_file_key, ANY_TYPE)
        else
          Rails.logger.warn(">> delete_virtual_file : select get_active_children")
          children = SpinNode.get_active_children(delete_sid, v_delete_file_key, ANY_TYPE)
        end
        Rails.logger.warn(">> delete_virtual_file : n-children = " + children.length.to_s)
        Rails.logger.warn(">> delete_virtual_file : delete node = " + tn[:node_name])
        if trash_it # add if ~ end   2015/6/18 by imai
          rethash = RecyclerDatum.put_node_into_recycler delete_sid, v_delete_file_key, is_thrown
          unless rethash[:success] == true
            Rails.logger.warn(">> delete_virtual_file : put_node_into_recycler failed")
            Rails.logger.warn(">> delete_virtual_file : rethash = " + rethash.to_s)
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_PUT_NODE_INTO_RECYCLER
            rethash[:errors] = 'ゴミ箱に移動できないフォルダがあります'
            return rethash
          end
        else #ゴミ箱にいれない場合は、フォルダのis_voidフラグを立てるため以下のメソッドを実行する
          reth = SpinNode.delete_node delete_sid, v_delete_file_key
          unless reth == true
            Rails.logger.warn(">> delete_virtual_file : SpinNode.delete_node failed")
            Rails.logger.warn(">> delete_virtual_file : rethash = " + rethash.to_s)
            rethash[:success] = false
            rethash[:status] = ERROR_FAILED_TO_DELETE_NODE
            rethash[:errors] = '削除できないフォルダがあります'
            return rethash
          end
        end # add if ~ end   2015/6/18 by imai
        Rails.logger.warn(">> delete_virtual_file : before  remove_child_from_parent")
        locations = ['folder_a', 'folder_b']
        locations.each {|loc|
          FolderDatum.remove_child_from_parent(v_delete_file_key, pnode, delete_sid, loc)
        }
        Rails.logger.warn(">> delete_virtual_file : before  children iterator")

        if is_thrown
          RecyclerDatum.set_busy(delete_sid, v_delete_file_key)
        end
        count = 0
        rethash[:list] = {}
        children.each {|cn|
          Rails.logger.warn(">> delete_virtual_file : before  delete_virtual_file : node_name = " + cn['node_name'])
          rethash2 = self.delete_virtual_file delete_sid, cn['spin_node_hashkey'], trash_it, false
          unless rethash2[:success]
            #rethash[:status] = ERROR_FAILED_TO_PUT_NODE_INTO_RECYCLER
            rethash[:list][count] = {}
            rethash[:list][count][:spin_node_hashkey] = cn['spin_node_hashkey']
            rethash[:list][count][:node_name] = cn['node_name']
            count = count + 1
            #return rethash
          end
          #          ret =  RecyclerDatum.put_node_into_recycler delete_sid, cn[:spin_node_hashkey], false
        }
        FolderDatum.has_updated delete_sid, pnode, DISMISS_CHILD, true
        rethash[:success] = true
        rethash[:status] = INFO_PUT_NODE_INTO_RECYCLER_SUCCESS
        return rethash
      else # => undefined
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_PUT_NODE_INTO_RECYCLER
        rethash[:errors] = '削除できないファイル／フォルダがあります'
        return rethash
      end # => ntype == NODE_FILE

      if trash_it # add if ~ end by imai at 2015/6/18
        RecyclerDatum.complete_trash_operation delete_sid, v_delete_file_key
      end

      FolderDatum.has_updated delete_sid, pnode, DISMISS_CHILD, true

      if is_thrown
        RecyclerDatum.reset_busy(delete_sid, v_delete_file_key)
      end

      #      end # => end of snlock.with_lock
      rethash[:success] = true
      rethash[:status] = INFO_PUT_NODE_INTO_RECYCLER_SUCCESS
      return rethash
    end

    # => end of delete_virtual_file delete_sid, delete_file_key

    def self.retrieve_virtual_files retrieve_sid, retrieve_file_keys
      if retrieve_file_keys.length > 0
        retrieve_file_keys_in_recycler = Array.new
        retrieve_file_keys.each {|retf|
          retrieve_file_keys_in_recycler += RecyclerDatum.search_files_in_recycler(retrieve_sid, retf)
        }
      end

      return RecyclerDatum.retrieve_node_from_recycler retrieve_sid, retrieve_file_keys_in_recycler

    end

    # => end of self.retrieve_virtual_files retrieve_sid, retrieve_file_keys

    def self.find_directory_node dirname, depth, parent_x, return_hash_key = false
      # search spin_domains
      # seach node
      res = nil
      reta = []
      SpinNode.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        begin
          res = SpinNode.readonly.select("node_x_coord,node_y_coord,node_x_pr_coord,node_version,spin_node_hashkey").find_by(spin_tree_type: 0, node_y_coord: depth, node_x_pr_coord: parent_x, node_type: NODE_DIRECTORY, node_name: dirname)
          #          res.with_lock do
          if res.blank?
            return reta
          end
          reta = Array.new
          reta[X] = res[:node_x_coord]
          reta[Y] = res[:node_y_coord]
          reta[PRX] = res[:node_x_pr_coord]
          reta[V] = res[:node_version]
          if return_hash_key
            reta[HASHKEY] = res[:spin_node_hashkey]
          end
          #          end # => end of res.with_lock do
          return reta
        rescue ActiveRecord::RecordNotFound
          return [-1, -1, -1, -1]
        end
      end # => end of self.transaction do
    end

    # => end of find_directory_node

    def self.find_node dirname, depth, parent_x, return_hash_key = false, get_latest = true
      # search spin_domains
      # seach node
      res = nil
      reta = []
      nodes = []
      SpinNode.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        begin
          if get_latest
            #          nodes = SpinNode.readonly.where(:node_y_coord => depth, :node_x_pr_coord => parent_x, :node_name => dirname).order("node_version DESC")
            res = SpinNode.readonly.select("node_x_coord,node_y_coord,node_x_pr_coord,node_version,spin_node_hashkey").find_by(spin_tree_type: 0, node_y_coord: depth, node_x_pr_coord: parent_x, node_name: dirname).order(node_version: 'DESC')
          else
            #          nodes = SpinNode.readonly.where(:node_y_coord => depth, :node_x_pr_coord => parent_x, :node_name => dirname)
            res = SpinNode.readonly.select("node_x_coord,node_y_coord,node_x_pr_coord,node_version,spin_node_hashkey").find_by(spin_tree_type: 0, node_y_coord: depth, node_x_pr_coord: parent_x, node_name: dirname)
          end
          if res.blank?
            return reta
          end
          #          res.with_lock do
          reta = Array.new
          reta[X] = res[:node_x_coord]
          reta[Y] = res[:node_y_coord]
          reta[PRX] = res[:node_x_pr_coord]
          reta[V] = res[:node_version]
          if return_hash_key
            reta[HASHKEY] = res[:spin_node_hashkey]
          end
          #          end # => end of res.with_lock do
          return reta
        rescue ActiveRecord::RecordNotFoundrd
          return [-1, -1, -1, -1]
        end
        #        res = SpinNode.readonly.find(["node_y_coord = ? AND node_x_pr_coord = ? AND node_type = ? AND node_name = ?", depth, parent_x, NODE_DIRECTORY, dirname],:lock=>true)
      end # => end of self.transaction do
    end

    # => end of find_directory_node

    def self.throw_virtual_files remove_sid, remove_file_keys, async_mode = false
      # remove files from recycler and storage
      remove_count = 0
      remove_file_vpaths_in_recycler = []
      spin_uid = SessionManager.get_uid(remove_sid, true)

      if remove_file_keys.length > 0
        remove_file_vpaths_in_recycler = Array.new
        remove_file_keys.each {|rmfk|
          begin
            remove_file_vpaths_in_recycler += RecyclerDatum.search_file_vpaths_in_recycler(remove_sid, rmfk)
            remove_query = sprintf("DELETE FROM recycler_data WHERE spin_uid = %d AND spin_node_hashkey = \'%s\';", spin_uid, rmfk)
            RecyclerDatum.connection.select_all(remove_query)
          rescue ActiveRecord::StaleObjectError
            next
          end
        }
      end

      #      my_uid = SessionManager.get_uid(remove_sid)

      thr = Thread.new do

        remove_file_vpaths_in_recycler.each {|n|

          ret_key = ''
          #    ret = self.destroy_all :spin_uid => uid, :spin_node_hashkey => remove_file_key
          # set in_use_uid in spin_nodes rec
          remove_node = SpinNode.find_by(spin_node_hashkey: n[:spin_node_hashkey])
          next if remove_node.blank?
          #    nt = remove_node[:node_type]

          catch(:throw_virtual_files_set_flags) {
            SpinNode.transaction do
              begin
                remove_node[:in_use_uid] = n[:spin_uid]
                remove_node[:in_trash_flag] = false
                remove_node[:is_pending] = false
                unless remove_node.save
                  next
                end
              rescue ActiveRecord::StaleObjectError
                sleep(AR_RETRY_WAIT_MSEC)
                throw :throw_virtual_files_set_flags
              end
            end
          }
          # send remove-request to file manager
          # if nt != NODE_DIRECTORY
          # retf = SpinFileSystem::SpinFileManager.remove_node remove_sid, remove_file_key
          # end
          if remove_node[:node_type] != NODE_DIRECTORY or async_mode
            if SpinNode.delete_node(remove_sid, n[:spin_node_hashkey], true, false)
              ret_key = n[:spin_node_hashkey]
            end
          else # => directory node
            #      retk = SpinNodeKeeper.delete_node_keeper_record(remove_node[:node_x_coord],remove_node[:node_y_coord])
            if SpinNode.delete_node(remove_sid, n[:spin_node_hashkey], true, true)
              ret_key = n[:spin_node_hashkey]
            end
          end # => end of remove_node[:node_type] != NODE_DIRECTORY

          # remove node
          #              return ret #  removed rec

          if ret_key == n[:spin_node_hashkey]
            remove_count += 1
          end
        }

      end

      return remove_file_vpaths_in_recycler.length # => array of deleted nodes

    end

    # => end of self.throw_virtual_files remove_sid, remove_file_keys, remove_file_names

    def self.find_spin_domain domain_root
      # search spin_domains
      # query = "SELECT \"spin_domains\".\"hash_key\" FROM \"spin_domains\" WHERE \"spin_domains\".\"spin_domain_root\" = \'#{domain_root}\' LIMIT 1"
      # ret_array = virtual_file_system_query query
      res = {}
      SpinDomain.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        res = SpinDomain.readonly.select("hash_key").find_by(spin_domain_root: domain_root)
      end
      if res.present?
        return res[:hash_key]
      else # => gfo through ret_array
        return nil
      end
    end

    # => end of find_domain

    def self.find_spin_domain_root domain_hash_key
      # search spin_domains root vpath
      # query = "SELECT \"spin_domains\".\"hash_key\" FROM \"spin_domains\" WHERE \"spin_domains\".\"spin_domain_root\" = \'#{domain_root}\' LIMIT 1"
      # ret_array = virtual_file_system_query query
      res = {}
      SpinDomain.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        res = SpinDomain.readonly.select("domain_root_node_hashkey").find_by(hash_key: domain_hash_key)
      end
      if res.present?
        return res[:domain_root_node_hashkey]
      else # => gfo through ret_array
        return nil
      end
    end

    # => end of find_domain

    def self.path_to_key vpath
      dirs = vpath.split(/\//)
      if dirs[0] != "" # => not absolute path!
        return nil
      end
      key = String.new
      depth = 1
      parent_x = 0
      SpinNode.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        dirs[1..-1].each {|d|
          hk = self.find_directory_node d, depth, parent_x, true
          if hk.blank? or hk == [-1, -1, -1, -1]
            return nil
          end
          depth += 1
          parent_x = hk[X]
          key = hk[HASHKEY]
        }
      end
      return key
    end

    # => end of path_to_key

    def self.key_to_path key
      p = {}
      SpinNode.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        begin
          p = SpinNode.readonly.select("virtual_path").find_by(spin_node_hashkey: key)
        rescue ActiveRecord::RecordNotFound
          return nil
        end
        if p.blank?
          return nil
        end
        #        p = SpinNode.readonly.select("node_x_coord,node_y_coord,node_x_pr_coord,node_version").find_by(_spin_node_hashkey: key)
      end
      return p[:virtual_path]
      #      return SpinLocationManager.get_location_vpath [p[:node_x_coord],p[:node_y_coord],p[:node_x_pr_coord],p[:node_version]]
    end

    # => end of key_to_path

    def self.convert_to_timestamp date_time_string # => yyyy-mm-ddThh:mm:ss
      ts = date_time_string.to_time
      #      tss = ts.to_s.split(/ /)
      return ts.to_i
    end

    def self.search_virtual_file_on_tree dir_key, dir_x = ANY_VALUE, dir_y = ANY_VALUE
      # get location of the dir
      file_nodes = []

      fs = []
      dir_loc = []
      if dir_x == ANY_VALUE or dir_y == ANY_VALUE
        dir_loc = SpinLocationManager.key_to_location dir_key
      else
        dir_loc[X] = dir_x
        dir_loc[Y] = dir_y
      end
      SpinNode.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        if dir_loc[Y] > 0
          fs = SpinNode.where(["spin_tree_type = ? AND node_x_pr_coord = ? AND node_y_coord = ? AND is_void = false AND latest = true", SPIN_NODE_VTREE, dir_loc[X], dir_loc[Y]+1]).order("node_name ASC, node_version DESC")
        else
          fs = SpinNode.where(["spin_tree_type = ? AND node_x_pr_coord = ? AND node_y_coord = ? AND is_void = false AND latest = true", SPIN_NODE_VTREE, 0, dir_loc[Y]+1]).order("node_name ASC, node_version DESC")
        end
      end
      if fs.size() > 0
        work_file_name = ''
        fs.each {|f|
          if 1 == f[:node_type]
            # フォルダの場合は再帰的に検索
            file_nodes.concat(self.search_virtual_file_on_tree f[:spin_node_hashkey], f[:node_x_coord], f[:node_y_coord])
          else
            # ファイルの場合はリストに追加 (最新バージョンのみ追加)
            if work_file_name != f[:node_name]
              file_nodes.push(f)
              work_file_name = f[:node_name]
            end
          end
        }
      end
      return file_nodes
    end # => end of search_virtual_file_on_tree
  end # => end of class VirtualFiuleSystemUtility
end # => end of module DatabaseUtility
