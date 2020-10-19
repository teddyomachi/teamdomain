# coding: utf-8
require 'net/http'
require 'uri'
require 'open-uri'
require 'const/vfs_const'
require 'const/acl_const'
require 'const/ssl_const'
require 'const/stat_const'
require 'utilities/database_utilities'
require 'tasks/spin_location_manager'

module SystemTools
  include Vfs
  include Acl
  include Ssl
  include Stat

  class Numeric
    def self.size_with_unit(fsize, unit_s = 'N/A') # => fsize in BYTE
      size_string = '0B'
      unit_s.upcase!

      if fsize < Vfs::ONE_KILO_BYTE or unit_s == 'B'
        size_string = fsize.to_s + 'B'
      elsif fsize < Vfs::ONE_MEGA_BYTE or unit_s == 'KB'
        if (fsize.to_f / Vfs::ONE_KILO_BYTE) == (fsize / Vfs::ONE_KILO_BYTE)
          size_string = (fsize / Vfs::ONE_KILO_BYTE).to_s + 'KB'
        else
          size_string = (fsize.to_f / Vfs::ONE_KILO_BYTE).round(1).to_s + 'KB'
        end
      elsif fsize < Vfs::ONE_GIGA_BYTE or unit_s == 'MB'
        if (fsize.to_f / Vfs::ONE_MEGA_BYTE) == (fsize / Vfs::ONE_MEGA_BYTE)
          size_string = (fsize / Vfs::ONE_MEGA_BYTE).to_s + 'MB'
        else
          size_string = (fsize.to_f / Vfs::ONE_MEGA_BYTE).round(1).to_s + 'MB'
        end
      elsif fsize < Vfs::ONE_TERA_BYTE or unit_s == 'GB'
        if (fsize.to_f / Vfs::ONE_GIGA_BYTE) == (fsize / Vfs::ONE_GIGA_BYTE)
          size_string = (fsize / Vfs::ONE_GIGA_BYTE).to_s + 'GB'
        else
          size_string = (fsize.to_f / Vfs::ONE_GIGA_BYTE).round(1).to_s + 'GB'
        end
      elsif fsize < Vfs::ONE_PETA_BYTE or unit_s == 'TB'
        if (fsize.to_f / Vfs::ONE_TERA_BYTE) == (fsize / Vfs::ONE_TERA_BYTE)
          size_string = (fsize / Vfs::ONE_TERA_BYTE).to_s + 'TB'
        else
          size_string = (fsize.to_f / Vfs::ONE_TERA_BYTE).round(1).to_s + 'TB'
        end
      end
      return size_string
    end # => end of self.size_with_unit( fsize )
  end # => end of class Numeric

  class DbTools

    def self.build_sql_params table_name, conditions
      #       get table column info
      #      query = "SELECT * FROM pg_attribute WHERE attrelid = \'#{table_name}\'::regclass;"
      #      dbcon = DatabaseUtility::VirtualFileSystemUtility.open_meta_db_connection
      #      res = dbcon.exec(query)
      #      DatabaseUtility::VirtualFileSystemUtility.close_meta_db_connection(dbcon)
      conditions.each {|cond|

      }
    end

    # => end of build_sql_params 'spin_nodes', conditions

    def self.clear_databases
      FolderDatum.destroy_all
      TargetFolderDatum.destroy_all
      FileDatum.destroy_all
      DomainDatum.destroy_all
      SpinSession.destroy_all
    end

    def self.create_spin_attributes_master spin_attributes_master_name = 'spin_attributes_master'
      conn = DatabaseUtility::VirtualFileSystemUtility.open_meta_db_connection
      query = \
        "CREATE TABLE #{spin_attributes_master_name} ( \n\
          client_id           varchar(255) not null,\n\
          attr_key            varchar(255) not null,\n\
          attr_name           varchar(255) not null,\n\
          attr_value          varchar(255),\n\
          spin_node_hashkey   varchar(255) not null\n\
        );"
      res = conn.exec query
      DatabaseUtility::VirtualFileSystemUtility.close_meta_db_connection conn
    end

    # => end of create_spin_attributes_master

    def self.create_spin_attributes spin_attr_key_name, spin_attributes_master_name, constraints
      conn = DatabaseUtility::VirtualFileSystemUtility.open_meta_db_connection
      query = \
        "CREATE TABLE spin_attr_#{spin_attr_key_name}_tbl (\n\
          CHECK ( #{constraints} ) \n\
        ) INHERITS (#{spin_attributes_master_name});"
      res = conn.exec query
      query_index = "CREATE INDEX #{spin_attr_key_name}_snhk ON spin_attr_#{spin_attr_key_name}_tbl (spin_node_hashkey);"
      resi = conn.exec query_index
      query_index2 = "CREATE INDEX #{spin_attr_key_name}_clid ON spin_attr_#{spin_attr_key_name}_tbl (client_id);"
      resi2 = conn.exec query_index2
      DatabaseUtility::VirtualFileSystemUtility.close_meta_db_connection conn
    end

    # => end of create_spin_attributes

    def self.create_spin_attributes_trigger_function spin_attr_key_names, spin_client_id
      conn = DatabaseUtility::VirtualFileSystemUtility.open_meta_db_connection
      query_trigger = \
        "CREATE OR REPLACE FUNCTION #{spin_attributes_master_name}_trigger()\n\
          RETURNS TRIGGER AS $$\n\
          BEGIN\n"

      spin_attr_key_names.each_with_index {|attrkey, idx|
        if idx == 0
          query_trigger << ("IF ( NEW." + attrkey + "= \'" + attrkey + "\'" + " AND NEW.spin_client_id = \'" + spin_client_id + "\' ) THEN\nINSERT INTO spin_attr_#{attrkey}_tbl VALUES (NEW.*);\n")
        else
          query_trigger << ("ELSIF ( NEW." + attrkey + "= \'" + attrkey + "\'" + " AND NEW.spin_client_id = \'" + spin_client_id + "\' ) THEN\nINSERT INTO spin_attr_#{attrkey}_tbl VALUES (NEW.*);\n")
        end
      }
      query_trigger << ("END IF;\nRETURN NULL;\nEND;\n$$\nLANGUAGE plpgsql;")

      res = conn.exec query_trigger
      DatabaseUtility::VirtualFileSystemUtility.close_meta_db_connection conn
    end

    # => end of create_spin_attributes_trigger_function

    def self.create_spin_access_controls_master spin_attributes_master_name = 'spin_attributes_master'
      conn = DatabaseUtility::VirtualFileSystemUtility.open_meta_db_connection
      query = \
        "CREATE TABLE #{spin_attributes_master_name} ( \n\
          client_id           varchar(255) not null,\n\
          attr_key            varchar(255) not null,\n\
          attr_name           varchar(255) not null,\n\
          attr_value          varchar(255),\n\
          spin_node_hashkey   varchar(255) not null\n\
        );"
      res = conn.exec query
      DatabaseUtility::VirtualFileSystemUtility.close_meta_db_connection conn
    end

    # => end of create_spin_access_controls_master

    def self.create_spin_access_controls spin_attr_key_name, spin_attributes_master_name, constraints
      conn = DatabaseUtility::VirtualFileSystemUtility.open_meta_db_connection
      query = \
        "CREATE TABLE spin_attr_#{spin_attr_key_name}_tbl (\n\
          CHECK ( #{constraints} ) \n\
        ) INHERITS (#{spin_attributes_master_name});"
      res = conn.exec query
      query_index = "CREATE INDEX #{spin_attr_key_name}_snhk ON spin_attr_#{spin_attr_key_name}_tbl (spin_node_hashkey);"
      resi = conn.exec query_index
      query_index2 = "CREATE INDEX #{spin_attr_key_name}_clid ON spin_attr_#{spin_attr_key_name}_tbl (client_id);"
      resi2 = conn.exec query_index2
      DatabaseUtility::VirtualFileSystemUtility.close_meta_db_connection conn
    end

    # => end of create_spin_access_controls

    def self.create_spin_access_controls_trigger_function spin_attr_key_names, spin_client_id
      conn = DatabaseUtility::VirtualFileSystemUtility.open_meta_db_connection
      query_trigger = \
        "CREATE OR REPLACE FUNCTION #{spin_attributes_master_name}_trigger()\n\
          RETURNS TRIGGER AS $$\n\
          BEGIN\n"

      spin_attr_key_names.each_with_index {|attrkey, idx|
        if idx == 0
          query_trigger << ("IF ( NEW." + attrkey + "= \'" + attrkey + "\'" + " AND NEW.spin_client_id = \'" + spin_client_id + "\' ) THEN\nINSERT INTO spin_attr_#{attrkey}_tbl VALUES (NEW.*);\n")
        else
          query_trigger << ("ELSIF ( NEW." + attrkey + "= \'" + attrkey + "\'" + " AND NEW.spin_client_id = \'" + spin_client_id + "\' ) THEN\nINSERT INTO spin_attr_#{attrkey}_tbl VALUES (NEW.*);\n")
        end
      }
      query_trigger << ("END IF;\nRETURN NULL;\nEND;\n$$\nLANGUAGE plpgsql;")

      res = conn.exec query_trigger
      DatabaseUtility::VirtualFileSystemUtility.close_meta_db_connection conn
    end

    # => end of create_spin_access_controls_trigger_function

    def self.set_domain_root_node
      ds = SpinDomain.find :all
      if ds.length > 0
        ds.each {|dr|
          if dr[:spin_updated_at] == nil
            dr[:spin_updated_at] = Time.now
            dr.save
          end
          n = SpinNode.find_by_spin_node_hashkey dr[:domain_root_node_hashkey]
          if n
            n[:is_domain_root_node] = true
            n.save
          end
        }
      end
    end

    # => end of self.set_domain_root_node

    def self.init_user_template user_template_name = nil
      # DEFAULT_TEMPLATE_UNAME
      tmp = nil
      search_user_template_name = ''
      if user_template_name == nil
        user_template_name = Vfs::DEFAULT_TEMPLATE_UNAME
        search_user_template_name = Vfs::DEFAULT_TEMPLATE_UNAME + '-%'
      else
        user_template_name = user_template_name
        search_user_template_name = user_template_name + '-%'
      end
      tmp = nil
      tmp = nil
      begin
        # sql = 'SELECT * FROM spin_users WHERE spin_uname LIKE \'template-user%\''
        default_template_user = user_template_name + '-0'
        tmp = SpinUser.where(["spin_uname LIKE ?", search_user_template_name])
        # tmp = SpinUser.find_by_sql(sql) # => (:all,:conditions=>["spin_uname LIKE \'?\'",search_user_template_name])
        if tmp.size > 0
          default_template_user = user_template_name + '-' + tmp.length.to_s
        end
        new_template = SpinUser.create {|ntmpl|
          ntmpl[:spin_uid] = Vfs::DEFAUTL_TEMPLATE_UID + tmp.size
          ntmpl[:spin_gid] = Vfs::DEFAUTL_TEMPLATE_GID + tmp.size
          ntmpl[:spin_uname] = default_template_user
          ntmpl[:spin_projid] = Vfs::DEFAUTL_TEMPLATE_PROJID
          ntmpl[:spin_passwd] = nil
          ntmpl[:user_level_x] = Vfs::DEFAULT_TEMPLATE_USER_LEVEL_X
          ntmpl[:user_level_y] = Vfs::DEFAULT_TEMPLATE_USER_LEVEL_Y
          default_login_directory_path = Vfs::SYSTEM_DEFAULT_LOGIN_DIRECTORY
          loc = SpinLocationManager.get_location_coordinates Acl::ADMIN_SESSION_ID, 'folder_a', default_login_directory_path, true, Acl::ACL_SUPERUSER_UID, Acl::ACL_SUPERUSER_GID, Acl::ACL_DEFAULT_UID_ACCESS_RIGHT, Acl::ACL_DEFAULT_GID_ACCESS_RIGHT, Acl::ACL_DEFAULT_WORLD_ACCESS_RIGHT
          ntmpl[:spin_login_directory] = SpinLocationManager.location_to_key(loc, Vfs::NODE_DIRECTORY)
          rd = SpinDomain.readonly.select("hash_key").find_by_spin_domain_name('personal')
          if rd.blank?
            rd = SpinDomain.readonly.select("hash_key").find_by_spin_domain_name('root')
          end
          ntmpl[:spin_default_domain] = rd[:hash_key]
          ntmpl[:spin_default_server] = Vfs::SYSTEM_DEFAULT_SPIN_SERVER
        }
      end
    end

    # => end of self.init_user_template

    def self.set_domain_root_node_flag
      #      domains = SpinDomain.where(["id > 0"])
      SpinDomain.find_each do |d|
        begin
          unless d.blank?
            r = SpinNode.find_by_spin_node_hashkey d[:domain_root_node_hashkey]
            if r.present? and r[:is_domain_root_node] == false
              begin
                r[:is_domain_root_node] = true
                r.save
              rescue ActiveRecord::RecordNotSaved
                break
              end
            end
          end
        rescue ActiveRecord::RecordNotFound
          next
        end
      end
    end

    # => end of self.set_domain_root_node_flag

    def self.set_spin_node_keeper_locks
      begin
        SpinNodeKeeperLock.find_or_create_by_id(1)
      rescue ActiveRecord::RecordNotFound
        Rails.logger 'Failed to find spin_node_keeper_locks record'
      rescue
        Rails.logger 'Failed to set spin_node_keeper_locks'
      end
    end

    def self.set_spin_storages ss_server = Vfs::SYSTEM_DEFAULT_SPIN_SERVER, ss_store_name = Vfs::SYSTEM_DEFAULT_STORAGE_NAME, ss_root = Vfs::SYSTEM_DEFAULT_STORAGE_ROOT, ss_vfs = Vfs::SYSTEM_DEFAULT_VFS_NAME, ss_ml = 'LEAST_FILES', ss_max_size = -1, ss_max_ent = -1, ss_max_dirs = -1, ss_max_ent_per_dir = 0, is_default = true, ss_storage_tmp = Vfs::SYSTEM_DEFAULT_TEMP_DIR
      # => clear default flag
      default_recs = nil
      begin
        default_recs = SpinStorage.where(["is_default = true"])
        default_recs.each {|r|
          r[:is_default] = false
          r.save
        }
      rescue ActiveRecord::RecordNotFound
      end
      # => get vfs
      spin_vfs_id = ''
      vfs = SpinVirtualFileSystem.find_by_spin_vfs_name ss_vfs
      if vfs != nil
        spin_vfs_id = vfs[:spin_vfs_id]
      else # => new spin_vfs
        SpinVirtualFileSystem.transaction do
          default_vfs = nil
          begin
            default_vfs = SpinVirtualFileSystem.where(["is_default = true"])
            if default_vfs.size > 0
              default_vfs.each {|dfv|
                dfv[:is_default] = false
                dfv.save
              }
            end
          rescue ActiveRecord::RecordNotFound
          end
          spin_vfs_id = Security::hash_key_s(ss_vfs + Time.now.to_s)
          new_vfs = SpinVirtualFileSystem.new
          new_vfs[:spin_vfs_type] = 'LOAD_BALANCE'
          new_vfs[:spin_vfs_access_mode] = 'READ_WRITE'
          new_vfs[:spin_vfs_name] = ss_vfs
          new_vfs[:spin_vfs_attibutes] = ''
          new_vfs[:spin_vfs_id] = spin_vfs_id
          new_vfs[:is_default] = true
          new_vfs.save
        end
      end
      # => determine  vfs name
      same_storage_group_name = nil
      begin
        same_storage_group_names = SpinStorage.find_by_storage_name ss_store_name
        if same_storage_group_names != nil
          num = 1
          while true do
            ss_store_name_tmp = ss_store_name + '_' + num.to_s
            if SpinStorage.find_by_storage_name(ss_store_name_tmp) != nil
              num += 1
              next
            else
              break
            end
          end
          ss_store_name = ss_store_name + '_' + num.to_s
        end
      rescue ActiveRecord::RecordNotFound
      end
      # => create new root rec
      cnt = 1
      ss_root0 = ss_root
      while true
        if Dir.exists? ss_root
          ss_root = ss_root0 + cnt.to_s
          cnt += 1
        else
          Dir.mkdir(ss_root, 0775)
          Dir.mkdir(ss_root+'_thumbnail', 0775)
          break
        end
      end
      storage_id = ''
      last_id = 0
      last_rec = nil
      begin
        last_rec = SpinStorage.select("id").readonly.find(:first).order("id DESC")
        if last_rec.present?
          last_id = last_rec[:id]
        end
      rescue ActiveRecord::RecordNotFound
      end

      SpinStorage.transaction do

        rt = SpinStorage.new
        rt[:id] = last_id + 1
        rt[:storage_server] = ss_server
        rt[:storage_root] = ss_root
        rt[:mapping_logic] = ss_ml
        rt[:storage_max_size] = ss_max_size
        rt[:storage_attributes] = ''
        #      rt[:created_at]
        #      rt[:updated_at]
        rt[:size_gb] = ss_max_size > 0 ? ss_max_size / Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        rt[:size_sub_gb] = ss_max_size > 0 ? ss_max_size % Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        rt[:entries_b] = ss_max_ent > 0 ? ss_max_ent / Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        rt[:entries_sub_b] = ss_max_ent > 0 ? ss_max_ent % Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        rt[:storage_type] = 0
        rt[:max_directories] = ss_max_dirs > 0 ? ss_max_dirs % Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        rt[:max_entries_per_directory] = ss_max_ent_per_dir > 0 ? ss_max_ent_per_dir % Vfs::MAX_INTEGER : 1000
        rt[:storage_name] = ss_store_name
        rt[:load_balance_metric] = ''
        rt[:master_spin_storage_id] = 'MASTER'
        rt[:priority_in_spin_storage_group] = 0
        rt[:spin_storage_id] = Security.hash_key_s(ss_root + Time.now.to_s)
        rt[:spin_vfs_id] = spin_vfs_id
        rt[:is_default] = is_default
        rt[:spin_vfs_type] = 0
        rt[:spin_vfs_access_type] = 3
        rt[:spin_vfs_storage_logic] = 0
        rt[:storage_group_max_size] = ss_max_size > 0 ? ss_max_size / Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        rt[:storage_group_max_size_sub] = ss_max_size > 0 ? ss_max_size % Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        rt[:storage_group_max_entries] = ss_max_ent > 0 ? ss_max_ent / Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        rt[:storage_group_max_entries_sub] = ss_max_ent > 0 ? ss_max_ent % Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        rt[:storage_group_max_directories] = ss_max_dirs > 0 ? ss_max_dirs / Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        rt[:storage_group_max_directories_sub] = ss_max_dirs > 0 ? ss_max_dirs % Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        rt[:storage_group_max_entries_per_directory] = ss_max_ent_per_dir > 0 ? ss_max_ent_per_dir / Vfs::MAX_INTEGER : 0
        rt[:storage_group_max_entries_per_directory_sub] = ss_max_ent_per_dir > 0 ? ss_max_ent_per_dir % Vfs::MAX_INTEGER : 1000
        rt[:is_master] = true
        rt[:thumbnail_root] = ''
        rt[:storage_tmp] = ss_storage_tmp
        rt[:storage_max_entries_upper] = Vfs::MAX_INTEGER_MASK
        rt[:storage_max_size_upper] = Vfs::MAX_INTEGER_MASK
        rt[:storage_max_directories] = Vfs::MAX_INTEGER_MASK
        rt[:storage_max_directories_upper] = Vfs::MAX_INTEGER_MASK
        rt[:storage_max_entries_per_directory] = 1000
        rt[:storage_max_entries_per_directory_upper] = 0
        rt[:storage_priority] = 0
        rt[:storage_current_directory_entries] = 0
        rt[:storage_group_current_size] = 0
        rt[:storage_group_current_size_upper] = 0
        rt[:storage_group_current_entries] = 0
        rt[:storage_group_current_entries_upper] = 0
        rt[:storage_group_current_directories] = 0
        rt[:storage_group_current_directories_upper] = 0
        rt[:storage_current_size] = 0
        rt[:storage_current_size_upper] = 0
        rt[:storage_current_entries] = 0
        rt[:storage_current_entries_upper] = 0
        rt[:storage_current_directories] = 0
        rt[:storage_current_directories_upper] = 0
        rt[:lock_version] = 0

        #        rt[:id] = last_id + 1
        #        rt[:storage_server] = ss_server
        #        rt[:storage_root] = ss_root
        #        rt[:mapping_logic] = ss_ml
        #        rt[:storage_max_size] = ss_max_size
        #        rt[:storage_attributes] = ''
        #        #      rt[:created_at]
        #        #      rt[:updated_at]
        #        rt[:size_gb] = ss_max_size > 0 ? ss_max_size / Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        #        rt[:size_sub_gb] = ss_max_size > 0 ? ss_max_size % 1000 : ss_max_size
        #        rt[:entries_b] = ss_max_ent > 0 ? ss_max_ent / 1000 : ss_max_ent
        #        rt[:entries_sub_b] = ss_max_ent > 0 ? ss_max_ent % 1000 : ss_max_ent
        #        rt[:storage_type] = 0
        #        rt[:max_directories] = ss_max_dirs > 0 ? ss_max_dirs % 1000 : ss_max_dirs
        #        rt[:max_entries_per_directory] = ss_max_ent_per_dir > 0 ? ss_max_ent_per_dir : 1000
        #        rt[:storage_name] = ss_store_name
        #        rt[:load_balance_metric] = ''
        #        rt[:master_spin_storage_id] = 'MASTER'
        #        rt[:priority_in_spin_storage_group] = 0
        #        rt[:spin_storage_id] = Security.hash_key_s(ss_root + Time.now.to_s)
        #        storage_id = rt[:spin_storage_id]
        #        rt[:spin_vfs_id] = spin_vfs_id
        #        rt[:is_default] = is_default
        #        rt[:spin_vfs_type] = 0
        #        rt[:spin_vfs_access_type] = 3
        #        rt[:spin_vfs_storage_logic] = 0
        #        rt[:storage_group_max_size] = Vfs::MAX_INTEGER_MASK
        #        rt[:storage_group_max_size_sub] = Vfs::MAX_INTEGER_MASK
        #        rt[:storage_group_max_entries] = Vfs::MAX_INTEGER_MASK
        #        rt[:storage_group_max_entries_sub] = Vfs::MAX_INTEGER_MASK
        #        rt[:storage_group_max_directories] = Vfs::MAX_INTEGER_MASK
        #        rt[:storage_group_max_directories_sub] = Vfs::MAX_INTEGER_MASK
        #        rt[:storage_group_max_entries_per_directory] = 0
        #        rt[:storage_group_max_entries_per_directory_sub] =  ss_max_ent_per_dir > 0 ? ss_max_ent_per_dir : 1000
        #        rt[:is_master] = true
        #        rt[:thumbnail_root] = ''
        #        rt[:storage_tmp] = ss_storage_tmp
        #        rt[:storage_max_entries_upper] = Vfs::MAX_INTEGER_MASK
        #        rt[:storage_max_size_upper] = Vfs::MAX_INTEGER_MASK
        #        rt[:storage_max_directories] = Vfs::MAX_INTEGER_MASK
        #        rt[:storage_max_directories_upper] = Vfs::MAX_INTEGER_MASK
        #        rt[:storage_max_entries_per_directory] = ss_max_ent_per_dir > 0 ? ss_max_ent_per_dir : 1000
        #        rt[:storage_max_entries_per_directory_upper] = 0
        #        rt[:storage_priority] = 0
        #        rt[:storage_current_directory_entries] = 0
        #        rt[:storage_group_current_size] = 0
        #        rt[:storage_group_current_size_upper] = 0
        #        rt[:storage_group_current_entries] = 0
        #        rt[:storage_group_current_entries_upper] = 0
        #        rt[:storage_group_current_directories] = 0
        #        rt[:storage_group_current_directories_upper] = 0
        #        rt[:storage_current_size] = 0
        #        rt[:storage_current_size_upper] = 0
        #        rt[:storage_current_entries] = 0
        #        rt[:storage_current_entries_upper] = 0
        #        rt[:storage_current_directories] = 0
        #        rt[:storage_current_directories_upper] = 0
        #        rt[:lock_version] = 0

        rt.save

        tmrt = SpinStorage.new
        tmrt[:id] = last_id + 2
        tmrt[:storage_server] = ss_server
        tmrt[:storage_root] = ''
        tmrt[:mapping_logic] = ss_ml
        tmrt[:storage_max_size] = ss_max_size
        tmrt[:storage_attributes] = ''
        #      tmrt[:created_at]
        #      tmrt[:updated_at]
        tmrt[:size_gb] = ss_max_size > 0 ? ss_max_size / Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        tmrt[:size_sub_gb] = ss_max_size > 0 ? ss_max_size % Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        tmrt[:entries_b] = ss_max_ent > 0 ? ss_max_ent / Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        tmrt[:entries_sub_b] = ss_max_ent > 0 ? ss_max_ent % Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        tmrt[:storage_type] = 0
        tmrt[:max_directories] = ss_max_dirs > 0 ? ss_max_dirs % Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        tmrt[:max_entries_per_directory] = ss_max_ent_per_dir > 0 ? ss_max_ent_per_dir % Vfs::MAX_INTEGER : 1000
        tmrt[:storage_name] = ss_store_name
        tmrt[:load_balance_metric] = ''
        tmrt[:master_spin_storage_id] = 'MASTER'
        tmrt[:priority_in_spin_storage_group] = 0
        tmrt[:spin_storage_id] = Security.hash_key_s(ss_root + Time.now.to_s + 'thumbnail')
        tmrt[:spin_vfs_id] = spin_vfs_id
        tmrt[:is_default] = is_default
        tmrt[:spin_vfs_type] = 0
        tmrt[:spin_vfs_access_type] = 3
        tmrt[:spin_vfs_storage_logic] = 0
        tmrt[:storage_group_max_size] = ss_max_size > 0 ? ss_max_size / Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        tmrt[:storage_group_max_size_sub] = ss_max_size > 0 ? ss_max_size % Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        tmrt[:storage_group_max_entries] = ss_max_ent > 0 ? ss_max_ent / Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        tmrt[:storage_group_max_entries_sub] = ss_max_ent > 0 ? ss_max_ent % Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        tmrt[:storage_group_max_directories] = ss_max_dirs > 0 ? ss_max_dirs / Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        tmrt[:storage_group_max_directories_sub] = ss_max_dirs > 0 ? ss_max_dirs % Vfs::MAX_INTEGER : Vfs::MAX_INTEGER_MASK
        tmrt[:storage_group_max_entries_per_directory] = ss_max_ent_per_dir > 0 ? ss_max_ent_per_dir / Vfs::MAX_INTEGER : 0
        tmrt[:storage_group_max_entries_per_directory_sub] = ss_max_ent_per_dir > 0 ? ss_max_ent_per_dir % Vfs::MAX_INTEGER : 1000
        tmrt[:is_master] = true
        tmrt[:thumbnail_root] = ss_root + '_thumbnail'
        tmrt[:storage_tmp] = Vfs::SYSTEM_DEFAULT_TEMP_DIR
        tmrt[:storage_max_entries_upper] = Vfs::MAX_INTEGER_MASK
        tmrt[:storage_max_size_upper] = Vfs::MAX_INTEGER_MASK
        tmrt[:storage_max_directories] = Vfs::MAX_INTEGER_MASK
        tmrt[:storage_max_directories_upper] = Vfs::MAX_INTEGER_MASK
        tmrt[:storage_max_entries_per_directory] = 1000
        tmrt[:storage_max_entries_per_directory_upper] = 0
        tmrt[:storage_priority] = 0
        tmrt[:storage_current_directory_entries] = 0
        tmrt[:storage_group_current_size] = 0
        tmrt[:storage_group_current_size_upper] = 0
        tmrt[:storage_group_current_entries] = 0
        tmrt[:storage_group_current_entries_upper] = 0
        tmrt[:storage_group_current_directories] = 0
        tmrt[:storage_group_current_directories_upper] = 0
        tmrt[:storage_current_size] = 0
        tmrt[:storage_current_size_upper] = 0
        tmrt[:storage_current_entries] = 0
        tmrt[:storage_current_entries_upper] = 0
        tmrt[:storage_current_directories] = 0
        tmrt[:storage_current_directories_upper] = 0
        tmrt[:lock_version] = 0

        tmrt.save

        # => set storege-vfs mapping
        mp = nil
        begin
          mp = SpinVfsStorageMapping.find_by_spin_vfs_and_spin_storage spin_vfs_id, storage_id
        rescue ActiveRecord::RecordNotFound
          mpnew = SpinVfsStorageMapping.new
          mpnew[:spin_vfs] = spin_vfs_id
          mpnew[:spin_storage] = storage_id
          mpnew.save
        end
      end # => end of transaction

    end # => end of self.set_spin_storages

  end # => end of class DbTools

end # => end of module SystemTools