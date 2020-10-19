# coding: utf-8
require 'const/vfs_const'
require 'const/acl_const'
require 'openssl'
require 'base64'
require 'tasks/security'
require 'utilities/database_utilities'

class SpinNode < ActiveRecord::Base
  include Vfs
  include Acl
  # # constants internal
  # X = 0         # => position of X coordinate value 
  # Y = 1         # => position of Y coordinate value
  # PRX = 2       # => position of prX coordinate value
  # V = 3         # => position of V coordinate value
  # HASHKEY = 4   # => spin_node_hashkey
  # CONST_DOMAIN = 32768  # => indicates domain types
  #   
  # NODE_DIRECTORY = 1      # => node is a directory
  # NODE_FILE = 2           # => node is a file
  # NODE_SYMBOLIC_LINK = 4  # => node is a symbolic link
  #   
  # # for BI TruePivot data tree
  # NODE_CUBE = 32
  # NODE_DIMENSION = 64
  # NODE_MEASURE = 128
  # NODE_FACT = 256
  #   
  # # node acl
  # ACL_NODE_NO_ACCESS = 0
  # ACL_NODE_READ = 1
  # ACL_NODE_WRITE = 2
  # ACL_NODE_DELETE = 4
  # ACL_NODE_CONMTROL = 8
  #   
  # ACL_TYPE_DOMAIN = NODE_DIRECTORY + CONST_DOMAIN
  # ACL_TYPE_DIRECTORY = NODE_DIRECTORY
  # ACL_TYPE_FILE = NODE_FILE
  # ACL_TYPE_SYMBOLIC_LINK = NODE_SYMBOLIC_LINK

  # # masks for n NODE
  # MASK_CONST_DOMAIN = 0b1000000000000000  # => 32768 indicates domain types  
  # MASK_NODE_DIRECTORY = 0b1      # => node is a directory
  # MASK_NODE_FILE = 0b10           # => node is a file
  # MASK_NODE_SYMBOLIC_LINK = 0b100  # => node is a symbolic link
  #   
  # # for BI TruePivot data tree
  # MASK_NODE_CUBE = 0b100000 # => 32
  # MASK_NODE_DIMENSION = 0b1000000 # => 64
  # MASK_NODE_MEASURE = 0b10000000 # => 128
  # MASK_NODE_FACT = 0b100000000 # => 256
  #   
  # # masks for ACL  
  # MASK_ACL_CONTROL = 0b1000
  # MASK_ACL_DELETE = 0b100
  # MASK_ACL_WRITE = 0b10
  # MASK_ACL_READ = 0b1
  # MASK_ACL_SYMBOLIC_LINK = 0b100
  # 
  # # node value indicates no directory
  # [-1,-1,-1,-1,nil] = [-1,-1,-1,-1,nil]

  # for test
  # ADMIN_SESSION_ID = "_special_administrator_session"

  attr_accessor :node_attributes, :rsa_key, :spin_private_key, :spin_public_key, :spin_node_hashkey, :node_x_coord, :node_y_coord, :node_x_pr_coord, :node_version, :node_type, :node_name, :in_trash_flag, :is_dirty_flag, :is_under_maintenance_flag, :in_use_flag, :storage_id, :created_at, :updated_at, :trashed_at, :spin_updated_at, :spin_uid, :spin_gid, :spin_uid_access_right, :spin_gid_access_right, :spin_world_access_right

  def self.get_root_rsa_key get_public = false
    #    ActiveRecord::Base.lock_optimistically = false
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      begin
        root_node = self.find_by_node_x_coord_and_node_y_coord 0, 0
      rescue ActiveRecord::RecordNotFound
        return nil
      end

      # generate key's if root node has no key
      unless root_node[:spin_private_key].present? # => no key's
        # generate with RSA
        rsa = Security.rsa_key
        catch(:update_rsa_private_key) {
          begin
            ret = root_node[:spin_private_key] = rsa.to_pem
            rsa_public = rsa.public_key
            ret = root_node[:spin_public_key] = rsa_public.to_pem
            root_node.save
          rescue ActiveRecord::StaleObjectError
            sleep(AR_RETRY_WAIT_MSEC)
            throw :update_rsa_private_key
          end
        }
        if get_public == true # => public key is requested
          return root_node[:spin_public_key]
        else # => private key is requested
          return root_node[:spin_private_key]
        end # => end of if get_public == true
      else # => there is a private key
        if get_public == true # => public key is requested
          if root_node[:spin_public_key].present? # => public key is.
            return root_node[:spin_public_key]
          else # => no public key
            rsa_public = rsa.public_key
            ret = root_node[:spin_public_key] = rsa_public.to_pem
            root_node.save
            return root_node[:spin_public_key]
          end # => end of if root_node[:spin_public_key].present?
        else # => private key is requested
          unless root_node[:spin_public_key].present? # => public key is.
            catch(:update_rsa_public_key) {
              begin
                rsa_public = rsa.public_key
                ret = root_node[:spin_public_key] = rsa_public.to_pem
                root_node.save
              rescue ActiveRecord::StaleObjectError
                sleep(AR_RETRY_WAIT_MSEC)
                throw :update_rsa_public_key
              end
            }
          end # => end of unless root_node[:spin_public_key].present?
          return root_node[:spin_private_key]
        end # => end of if get_public == true
      end # => end of unless root_node[:spin_private_key].present?
    end
  end

  # => end of get_root_public_key

  def self.get_pending_flag spin_node_hashkey
    begin
      sn = self.readonly.select("is_pending").find_by_spin_node_hashkey(spin_node_hashkey)
    rescue ActiveRecord::RecordNotFound
      return nil
    end
    return sn[:is_pending]
  end

  # => end of self.get_pending_flag

  def self.get_in_trash_flag spin_node_hashkey
    begin
      sn = self.readonly.select("in_trash_flag").find_by_spin_node_hashkey(spin_node_hashkey)
    rescue ActiveRecord::RecordNotFound
      return nil
    end
    return sn[:in_trash_flag]
  end

  # => end of get_in_trash_flag

  def self.get_pending_flag_by_id id
    begin
    rescue ActiveRecord::RecordNotFound
      return nil
    end
    sn = self.readonly.select("is_pending").find(id)
    return sn[:is_pending]
  end

  # => end of self.get_pending_flag_by_id

  def self.get_in_trash_flag_used_id id
    begin
      sn = self.readonly.select("in_trash_flag").find(id)
    rescue ActiveRecord::RecordNotFound
      return nil
    end
    return sn[:in_trash_flag]
  end

  # => end of get_in_trash_flag_by_id


  def self.get_id_from_key hkey
    sn = self.select("id").find_by_spin_node_hashkey(hkey)
    if sn.blank?
      return nil
    else
      return sn[:id]
    end
  end

  # => end of self.get_id_from_key

  def self.get_key_from_id nid
    begin
      sn = self.select("spin_node_hashkey").find(nid)
    rescue ActiveRecord::RecordNotFound
      return nil
    end
    return sn[:spin_node_hashkey]
  end

  # => end of self.get_key_from_id

  def self.get_domains node_key # returns hash_key's of spin_domains record that contains node_key-node
    spin_domains = Array.new
    test_node_key = node_key
    domain_rec = nil
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      domain_rec = SpinDomain.find_by_domain_root_node_hashkey(test_node_key)
      if domain_rec.present?
        spin_domains.push(domain_rec[:hash_key])
      end

      while true do
        parent_node_key = SpinNode.get_parent(test_node_key)
        if parent_node_key == nil
          break
        elsif parent_node_key == test_node_key # => it means that it is root node
          break
        end
        domain_rec = SpinDomain.find_by_domain_root_node_hashkey(parent_node_key)
        if domain_rec.present?
          spin_domains.push(domain_rec[:hash_key])
        end
        test_node_key = parent_node_key
      end # => end of while
    end # => end of transaction

    return spin_domains # => id's
  end

  def self.xget_domains node_key # returns hash_key's of spin_domains record
    domains = Array.new
    spin_domains = Array.new
    loc = [-1, -1, -1, -1]
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      loc = SpinLocationManager.key_to_location(node_key, NODE_DIRECTORY)
      y = loc[Y]
      while y >= 0
        if SpinLocationManager.is_domain_root_location loc
          domains.append SpinLocationManager.location_to_key(loc, NODE_DIRECTORY)
        end
        parent_loc = self.get_parent_location loc
        if parent_loc == nil
          break
        end
        loc[X] = parent_loc[X]
        loc[Y] = parent_loc[Y]
        loc[PRX] = parent_loc[PRX]
        y = loc[Y]
      end
    end
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      domains.each {|d|
        dr = SpinDomain.find_by_domain_root_node_hashkey d
        if dr.present?
          spin_domains.append dr[:hash_key]
        end
      }
    end
    return spin_domains # => id's
  end

  def self.get_parent_location location
    parent_location = [-1, -1, -1, -1]
    self.transaction do
      if location[Y] > 0
        begin
          pn = self.find_by_node_x_coord_and_node_y_coord_and_node_type(location[PRX], location[Y] - 1, NODE_DIRECTORY)
          if pn.blank?
            return nil
          end
          parent_location = [pn[:node_x_coord], pn[:node_y_coord], pn[:node_x_pr_coord], pn[:node_version]]
        rescue ActiveRecord::RecordNotFound
          return nil
        end
      else
        return nil
      end
    end
    return parent_location
  end

  # => end of get_parent_location

  def self.get_version_info node_x, node_y
    # get location
    version_info = Hash.new
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      ns = self.where(["spin_tree_type = ? AND node_x_coord = ? AND node_y_coord = ?", node_x, node_y]).order("node_version DESC")
      #    loc = SpinLocationManager.key_to_location node_key
      unless ns.length > 0
        return [-1, -1, -1, -1]
      end
      # get version inforation
      #    ns = self.where( :node_x_coord => loc[X], :node_y_coord => loc[Y], :node_x_pr_coord => loc[PRX] ).order("node_version DESC")
      version_info = {:name => ns[0][:node_name], :versions => ns.count, :max_versions => ns[0][:max_versions], :oldest => ns[-1][:node_version], :latest_version => ns[0][:node_version]}
    end
    return version_info
  end

  # => end of get_version_info

  def self.get_latest_node node_x, node_y
    # get location
    ns = nil
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      #      loc = SpinLocationManager.key_to_location node_key
      #      if loc == [ -1, -1, -1, -1 ]
      #        return nil
      #      end
      # get version inforation
      ns = self.where(["spin_tree_type = ? AND node_x_coord = ? AND node_y_coord = ?", SPIN_NODE_VTREE, node_x, node_y]).order("node_version DESC")
    end
    if ns.size > 0
      return ns[0][:spin_node_hashkey]
    else
      return nil
    end
  end

  # => end of get_version_info

  def self.get_prior_node node_x, node_y
    # get location
    ns = nil
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      #      loc = SpinLocationManager.key_to_location node_key
      #      if loc == [ -1, -1, -1, -1 ]
      #        return nil
      #      end
      # get version inforation
      ns = self.where(["spin_tree_type = ? AND node_x_coord = ? AND node_y_coord = ?", SPIN_NODE_VTREE, node_x, node_y]).order("node_version DESC")
    end
    if ns.length > 1
      return ns[1][:spin_node_hashkey]
    elsif ns.length > 0
      return ns[0][:spin_node_hashkey]
    else
      return nil
    end
  end

  # => end of get_version_info

  def self.is_domain_root node_key
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      n = self.select("is_domain_root_node").find_by_spin_node_hashkey(node_key)
      if n.blank?
        return false
      end
      if n[:is_domain_root_node]
        return true
      else
        return false
      end
    end
  end

  # => end of is_domain_root

  def self.create_thumbnail_file(sid, thumbnail_hash_key, thumbnail_file_name)
    fm_args = Array.new
    fm_args.append sid
    fm_args.append thumbnail_hash_key
    fm_args.append thumbnail_file_name
    FileManager.rails_logger("create_thumbnail_file : fm_args = " + fm_args.to_s)
    retj = ''
    case ENV['RAILS_ENV']
    when 'development'
      retj = SpinFileManager.request sid, 'create_thumbnail', fm_args
      #              reth = JSON.parse retj
      #      return remove_file_key
    when 'production'
      retj = SpinFileManager.request sid, 'create_thumbnail', fm_args
      #              reth = JSON.parse retj
    else
      retj = SpinFileManager.request sid, 'create_thumbnail', fm_args
      #              reth = JSON.parse retj
    end
    return retj
  end

  # => end of create_thumbnail_file(my_session_id, thumbnail_hash_key, thumbnail_file_name)

  def self.remove_thumbnail_file(sid, thumbnail_hash_key)
    fm_args = Array.new
    #    fm_args.append sid
    fm_args.append thumbnail_hash_key
    FileManager.rails_logger("remove_thumbnail_file : fm_args = " + fm_args.to_s)
    retj = ''
    case ENV['RAILS_ENV']
    when 'development'
      retj = SpinFileManager.request sid, 'remove_thumbnail', fm_args
      #              reth = JSON.parse retj
      #      return remove_file_key
    when 'production'
      retj = SpinFileManager.request sid, 'remove_thumbnail', fm_args
      #              reth = JSON.parse retj
    else
      retj = SpinFileManager.request sid, 'remove_thumbnail', fm_args
      #              reth = JSON.parse retj
    end
    return retj
  end

  # => end of create_thumbnail_file(my_session_id, thumbnail_hash_key, thumbnail_file_name)

  def self.delete_node sid, delete_file_key, delete_all = true, delete_node_record = false
    # trash it if trash_it is true!
    target_node = nil
    #    target_node_type = ANY_TYPE
    #    ActiveRecord::Base.lock_optimistically = false
    catch(:delete_node_again) {
      self.transaction do

        target_node = self.find_by_spin_node_hashkey_and_is_void(delete_file_key, false)
        if target_node.blank?
          return true
        end
        #        target_node = self.find_by_spin_node_hashkey delete_file_key
        #      target_node_type = target_node[:node_type]
        if delete_all == false # =>  do same as Recycler.put_node_into_recycler
          if target_node.present?
            self.set_node_in_trash(sid, target_node)

            begin
              target_node[:spin_updated_at] = target_node[:updated_at]
              if target_node.save != true
                return false
              end
            rescue ActiveRecord::StaleObjectError
              #            target_node = self.find_by_spin_node_hashkey delete_file_key
              #            return true if target_node == nil
              sleep(AR_RETRY_WAIT_MSEC)
              throw :delete_node_again
            end

            thumbnail_key_rec = self.find_by_spin_tree_type_and_node_x_coord_and_node_y_coord_and_node_version(SPIN_THUMBNAIL_VTREE, target_node[:node_x_coord], target_node[:node_y_coord], target_node[:node_version])
            if thumbnail_key_rec.present?
              self.set_node_in_trash(sid, thumbnail_key_rec)
            end

            # delete from folder_data
            begin
              delquery = sprintf("DELETE FROM folder_data WHERE spin_node_hashkey = \'%s\';", target_node[:spin_node_hashkey])
              FolderDatum.find_by_sql(delquery)
            rescue ActiveRecord::StaleObjectError
              # => do nothing
            end

            begin
              delquery = sprintf("DELETE FROM file_data WHERE spin_node_hashkey = \'%s\';", target_node[:spin_node_hashkey])
              FileDatum.find_by_sql(delquery)
            rescue ActiveRecord::StaleObjectError
              # => do nothing
            end

            if target_node[:spin_tree_type] < NODE_THUMBNAIL
              pn = SpinLocationManager.get_parent_node(target_node)
              pkey = pn[:spin_node_hashkey]
              self.has_updated(sid, pkey)
            end
            #          self.negative_coordinates target_node
          else
            return false
          end
        else # => delete node
          if target_node.present?
            if target_node[:node_type] != NODE_DIRECTORY
              fm_args = Array.new
              fm_args.append target_node[:spin_node_hashkey]
              FileManager.rails_logger("delete_node : fm_args = " + fm_args[0])
              case ENV['RAILS_ENV']
              when 'development'
                retj = SpinFileManager.request sid, 'remove_node', fm_args
                #              reth = JSON.parse retj
                #      return remove_file_key
              when 'production'
                retj = SpinFileManager.request sid, 'remove_node', fm_args
                #              reth = JSON.parse retj
              else
                retj = SpinFileManager.request sid, 'remove_node', fm_args
                #              reth = JSON.parse retj
              end
              fm_args_t = Array.new
              begin
                thumbnail_key_rec = self.find_by_spin_tree_type_and_node_x_coord_and_node_y_coord_and_node_version(SPIN_THUMBNAIL_VTREE, target_node[:node_x_coord], target_node[:node_y_coord], target_node[:node_version])
                if thumbnail_key_rec.blank?
                  return false
                end
                fm_args_t.append thumbnail_key_rec[:spin_node_hashkey]
                FileManager.rails_logger("delete_node : fm_args_t = " + fm_args_t[0])
                case ENV['RAILS_ENV']
                when 'development'
                  retj = SpinFileManager.request sid, 'remove_node', fm_args_t
                  #                reth = JSON.parse retj
                  #      return remove_file_key
                when 'production'
                  retj = SpinFileManager.request sid, 'remove_node', fm_args_t
                  #                reth = JSON.parse retj
                else
                  retj = SpinFileManager.request sid, 'remove_node', fm_args_t
                  #                reth = JSON.parse retj
                end
                self.set_node_is_void(thumbnail_key_rec)
              end
              self.set_node_is_void(target_node)
            else # => NODE_DIRECTORY
              self.set_node_is_void(target_node)
            end # => end of target_node[:node_type] != NODE_DIRECTORY

            spin_access_control_recs = SpinAccessControl.where(["managed_node_hashkey = ?", delete_file_key])
            spin_access_control_recs.each {|sacrec|
              SpinAccessControl.remove_node_acls(sid, sacrec[:managed_node_hashkey])
            }

            begin
              delquery = sprintf("DELETE FROM folder_data WHERE spin_node_hashkey = \'%s\';", target_node[:spin_node_hashkey])
              FolderDatum.find_by_sql(delquery)
            rescue ActiveRecord::StaleObjectError
              # => do nothing
            end

            begin
              delquery = sprintf("DELETE FROM file_data WHERE spin_node_hashkey = \'%s\';", target_node[:spin_node_hashkey])
              FileDatum.find_by_sql(delquery)
            rescue ActiveRecord::StaleObjectError
              # => do nothing
            end

            parent = nil
            if target_node[:spin_tree_type] < SPIN_THUMBNAIL_VTREE
              # Is it ROOR?
              if target_node[:node_x_coord] == 0 and target_node[:node_y_coord] == 0
                parent = target_node
              else
                begin
                  parent = SpinNode.readonly.find_by_spin_tree_type_and_node_x_coord_and_node_y_coord_and_node_type_and_latest(SPIN_NODE_VTREE, target_node[:node_x_pr_coord], target_node[:node_y_coord] - 1, NODE_DIRECTORY, true)
                  if parent.blank?
                    return false
                  end
                  pkey = parent[:spin_node_hashkey]
                  self.has_updated(sid, pkey)
                rescue ActiveRecord::RecoredNotFound
                  # => do nothing
                end
              end

              #            parent = SpinLocationManager.get_parent_node(target_node)
              SpinNodeKeeper.delete_node_keeper_record(target_node[:node_x_coord], target_node[:node_y_coord], target_node[:node_version])
              if target_node[:node_type] == NODE_DIRECTORY
                DomainDatum.set_domains_dirty(target_node)
                #              DomainDatum.set_domains_dirty(target_node[:spin_node_hashkey])
                catch(:set_void_node_record_again) {
                  begin
                    target_node[:is_void] = true;
                    target_node.save
                  rescue ActiveRecord::StaleObjectError
                    sleep(AR_RETRY_WAIT_MSEC)
                    throw :set_void_node_record_again
                  rescue ActiveRecordError
                    sleep(AR_RETRY_WAIT_MSEC)
                    throw :set_void_node_record_again
                  end
                }
              end
            end
            #          self.negative_coordinates target_node
          else
            return false
          end
        end
      end # => end of transaction
    } # => end of catch block
    return true
  end

  # => end of delete_node delete_file_key, trash_it

  def self.delete_spin_node delete_file_key, delete_it = true, api_request = false
    # trash it if trash_it is true!
    target_node = nil
    target_node_type = ANY_TYPE
    #    ActiveRecord::Base.lock_optimistically = false
    catch(:delete_spin_node_again) {
      self.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        begin
          target_node = self.find_by_spin_node_hashkey delete_file_key
          if target_node.blank?
            return nil
          end
          target_node_type = target_node[:node_type]
          if delete_it == false # =>  set void flag true
            self.set_node_is_void(target_node)
            #          target_node[:is_void] = true
            #          target_node[:is_pending] = false
            #          target_node[:in_trash_flag] = false
            # target_node.updated_at = Time.now
            begin
              target_node[:spin_updated_at] = target_node[:updated_at]
              target_node.save
            rescue ActiveRecord::StaleObjectError
              sleep(AR_RETRY_WAIT_MSEC)
              throw :delete_spin_node_again
            end
            #          self.has_updated( SpinLocationManager.get_parent_key delete_file_key, ANY_TYPE )
            #          self.negative_coordinates target_node
          else # => remove node from spin_node table
            #          parent_key = SpinLocationManager.get_parent_key delete_file_key, ANY_TYPE
            target_node.destroy
            #          self.has_updated( parent_key )
            #          self.negative_coordinates target_node
          end # => end of if delete_it == false
        end
      end # => end of transaction
    } # => end of catch block
    if target_node_type == NODE_DIRECTORY and api_request == false
      DomainDatum.set_domains_dirty(target_node)
    end
    return delete_file_key
  end

  # => end of delete_node delete_file_key, trash_it

  def self.negative_coordinates node
    #    node = self.find_by_spin_node_hashkey node_key
    #    ActiveRecord::Base.lock_optimistically = false
    catch(:negative_coordinates_again) {
      self.transaction do
        begin
          p = [-1, -1, -1, -1]
          tx = node[:node_x_coord] * (-1)
          ty = node[:node_y_coord] * (-1)
          tprx = node[:node_x_pr_coord] * (-1)
          tv = node[:node_version] * (-1)
          node[:node_x_coord] = tx
          node[:node_y_coord] = ty
          node[:node_x_pr_coord] = tprx
          node[:node_version] = tv
          if node.save
            p = [tx, ty, tprx, tv]
            return p
          end
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :negative_coordinates_again
        end
      end # => end of transaction
    } # => end of catch block
  end

  # => end of self.negative_coordinates target_node

  def self.move_node move_sid, move_file_key, target_folder_key, target_cont_location
    # get new coordinates
    # get location [x,y,prx,v] from dir_key
    loc = SpinLocationManager.key_to_location target_folder_key, NODE_DIRECTORY
    #    vfx = SpinNodeKeeper.test_and_set_x loc[Y]+1
    req_loc = [REQUEST_COORD_VALUE, loc[Y] + 1, loc[X], REQUEST_VERSION_NUMBER]
    # rewrite location coordinates in move_file_key node
    src = []
    dst = []
    ret = false
    #    src_parent_key = SpinLocationManager.get_parent_key move_file_key, ANY_TYPE
    #    ActiveRecord::Base.lock_optimistically = false
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      moving_node = nil
      moving_node = self.find_by_spin_node_hashkey(move_file_key)
      if moving_node.blank?
        return nil
      end

      vfloc = nil
      while vfloc.blank?
        vfloc = SpinNodeKeeper.test_and_set_xy move_sid, req_loc, moving_node[:node_name], NODE_DIRECTORY
      end
      src[X] = moving_node[:node_x_coord]
      src[Y] = moving_node[:node_y_coord]
      src[PRX] = moving_node[:node_x_pr_coord]
      dst[X] = vfloc[X]
      dst[Y] = vfloc[Y]
      dst[PRX] = vfloc[PRX]

      rmvs = SpinNode.where(["spin_tree_type = 0 AND node_x_coord = ? AND node_y_coord = ?", dst[X], dst[Y]])
      if rmvs.length > 0
        rmvs.each {|rmv|
          rethash = {}
          if rmv[:is_void] == false
            rethash = DatabaseUtility::VirtualFileSystemUtility.delete_virtual_file(move_sid, rmv[:spin_node_hashkey], false)
          end
          if rethash[:success]
            SpinNode.delete_node(move_sid, rmv[:spin_node_hashkey])
          end
        }
      end
      moving_node_versions = SpinNode.where(["spin_tree_type = 0 AND node_x_coord = ? AND node_y_coord = ?", src[X], src[Y]])
      moving_node_versions.each {|movf|
        movf[:node_x_coord] = dst[X]
        movf[:node_y_coord] = dst[Y]
        movf[:node_x_pr_coord] = dst[PRX]
        if movf.save
          src_parent = self.find_by_node_x_coord_and_node_y_coord_and_node_type_and_node_version src[PRX], src[Y] - 1, NODE_DIRECTORY, INITIAL_VERSION_NUMBER
          if src_parent.blank?
            return false
          end
          moved_files = FileData.where :spin_node_hashkey => movf[:spin_node_hashkey], :folder_hash_key => src_parent[:spin_node_hashkey]
          moved_files.each {|m|
            m[:moved] = true
            m[:latest] = false # => to avoid to be on list
            m.save
          }
          #          file_list_nodes = FileDatum.where(["spin_node_hashkey = ?",movf[:spin_node_hashkey]])
          #          if file_list_nodes.length > 0
          #            file_list_nodes.destroy_all
          #          end
          self.has_updated move_sid, movf[:spin_node_hashkey]
          ret = true
        else
          ret = false
        end
      }
    end
    SpinLocationManager.move_location move_sid, src, dst
    return ret
  end

  # => end of self.move_node move_file_key, target_folder_key, target_cont_location

  def self.get_node_name node_hash_key
    n = self.readonly.select("node_name").find_by_spin_node_hashkey node_hash_key
    if n.present?
      return n[:node_name]
    else
      return nil
    end
  end

  # => end of self.get_node_name node_hash_key

  # new_location : target location of copy opr.
  def self.copy_node_location copy_sid, copy_file_key, vfile_name, new_dir_location, node_exists, target_cont_location = LOCATION_A, node_type = NODE_FILE, parent_dir_key = ''
    # rewrite location coordinates in file_key node
    loc = []
    loc[X] = REQUEST_COORD_VALUE
    loc[Y] = new_dir_location[Y] + 1
    loc[PRX] = new_dir_location[X]
    loc[V] = REQUEST_VERSION_NUMBER
    src = []
    dst = []
    ret_key = ''
    ids = SessionManager.get_uid_gid(copy_sid)
    my_uid = ids[:uid]
    my_gid = ids[:gid]
    acls = {}
    #    self.transaction do
    #    ActiveRecord::Base.lock_optimistically = false
    #    self.transaction do
    copying_node = nil
    copying_node = SpinNode.readonly.find_by_spin_node_hashkey copy_file_key
    if copying_node.blank?
      return nil
    end
    #      if node_type == NODE_DIRECTORY and new_location[V] < 0 # => is directory and already is at the target
    #        copying_node[:is_void] = true
    #        if copying_node.save
    #          return true
    #        else
    #          return false
    #        end 
    #      end
    src[X] = copying_node[:node_x_coord]
    src[Y] = copying_node[:node_y_coord]
    src[PRX] = copying_node[:node_x_pr_coord]
    src[V] = copying_node[:node_version]
    src[K] = copying_node[:spin_node_hashkey]
    vfile_name = copying_node[:node_name]

    if node_type == NODE_DIRECTORY
      if node_exists
        new_location = new_dir_location
        loc = self.update_spin_node_with_copy copy_sid, copying_node, new_location[X], new_location[Y], new_location[PRX], my_uid, my_gid
        if loc[X..K] != [-1, -1, -1, -1, nil]
          new_location[K] = loc[K]
          #            SpinAccessControl.copy_node_acls copy_sid, src, loc  # => new_node = [x,y,prx,v,hashkey]
          dst_parent = nil
          dst_parent = self.find_by_node_x_coord_and_node_y_coord_and_node_type_and_node_version(new_location[PRX], new_location[Y] - 1, NODE_DIRECTORY, INITIAL_VERSION_NUMBER)
          if dst_parent.blank?
            return nil
          end
          SpinAccessControl.copy_parent_acls copy_sid, loc, node_type, dst_parent[:spin_node_hashkey], my_uid # => new_node = [x,y,prx,v,hashkey]
          self.has_updated copy_sid, dst_parent[:spin_node_hashkey]
          #            self.delete_node copy_sid, copying_node[:spin_node_hashkey], true
          ret_key = loc[K]
        else
          return nil
        end
      else
        #          loc = self.create_spin_node copy_sid, new_location[X], new_location[Y], new_location[PRX], new_location[V], copying_node[:node_name], copying_node[:node_type]
        #          retbc = self.copy_spin_node_attribiutes copy_sid, movf, loc[X], loc[Y], loc[PRX], loc[V]
        #          my_new_location = self.create_virtual_file(copy_sid, vfile_name, parent_dir_key)
        my_new_location = nil
        my_new_location = SpinNodeKeeper.test_and_set_xy(copy_sid, loc, vfile_name, node_type)
        if my_new_location[V] < 0
          my_new_location[V] *= (-1)
        end
        #          my_loc = []
        #        my_loc = self.create_spin_node_with_copy copy_sid, copying_node, my_new_location[X], my_new_location[Y], my_new_location[PRX], my_uid, my_gid
        if my_new_location[0..4] != [-1, -1, -1, -1, nil]
          #          my_new_location[K] = my_loc[K]
          #            SpinAccessControl.copy_node_acls copy_sid, src, my_loc  # => new_node = [x,y,prx,v,hashkey]
          #          dst_parent = self.readonly.find_by_node_x_coord_and_node_y_coord_and_node_type_and_node_version loc[PRX],loc[Y]-1,NODE_DIRECTORY,INITIAL_VERSION_NUMBER
          #          SpinAccessControl.copy_parent_acls copy_sid, my_loc, node_type, dst_parent[:spin_node_hashkey], my_uid  # => new_node = [x,y,prx,v,hashkey]
          #          self.has_updated copy_sid, dst_parent[:spin_node_hashkey]
          #          #            self.delete_node copy_sid, copying_node[:spin_node_hashkey], true
          #          ret_key = my_loc[K]
          ret_key = my_new_location[K]
        else
          return nil
        end
      end
      #        dst[X] = new_location[X]
      #        dst[Y] = new_location[Y]
      #        dst[PRX] = new_location[PRX]
      #        void_nodes = SpinNode.where(:node_x_coord => dst[X], :node_y_coord => dst[Y], :is_void => true)
      #        void_nodes.each {|vn|
      ##          if vn[:is_void]
      #            vn.destroy
      ##          end
      #        }
    else # => file
      #      copying_node_versions = SpinNode.readonly.where(["spin_tree_type = 0 AND spin_node_hashkey_and_is_void = false AND in_trash_flag = false",copy_file_key],:order=>"node_version ASC")
      copying_node_versions = SpinNode.readonly.where(["spin_tree_type = 0 AND node_x_coord = ? AND node_y_coord = ? AND node_name = ? AND is_void = false AND in_trash_flag = false AND node_type = ?", src[X], src[Y], vfile_name, NODE_FILE]).order("node_version ASC")
      unless copying_node_versions.size == 0
        copying_node_versions.each {|movf|
          #          loc = self.create_spin_node copy_sid, new_location[X], new_location[Y], new_location[PRX], new_location[V], copying_node[:node_name], copying_node[:node_type]
          #          retbc = self.copy_spin_node_attribiutes copy_sid, movf, loc[X], loc[Y], loc[PRX], loc[V]
          loc[V] = REQUEST_VERSION_NUMBER # => movf[:node_version]
          vfile_name = movf[:node_name]
          #          my_new_location = self.create_virtual_file(copy_sid, vfile_name, parent_dir_key, loc[V])
          my_new_location = nil
          nodes_at_my_new_location = SpinNode.readonly.where(["node_x_pr_coord = ? AND node_y_coord = ? AND node_name = ? AND node_type = ? AND is_void = false AND in_trash_flag = false", loc[PRX], loc[Y], vfile_name, NODE_FILE]).order("node_version ASC")
          if nodes_at_my_new_location.size == 0 # => get new location for new node
            my_new_location = SpinNodeKeeper.test_and_set_xy(copy_sid, loc, vfile_name, node_type)
          else
            loc[X] = nodes_at_my_new_location[0][:node_x_coord]
            loc[Y] = nodes_at_my_new_location[0][:node_y_coord]
            loc[PRX] = nodes_at_my_new_location[0][:node_x_pr_coord]
            loc[V] = REQUEST_VERSION_NUMBER
            my_new_location = SpinNodeKeeper.test_and_set_xy(copy_sid, loc, vfile_name, node_type)
          end
          if my_new_location[V] < 0
            my_new_location[V] *= (-1)
          end

          my_loc = Array.new
          my_loc = self.create_spin_node_with_copy copy_sid, movf, my_new_location[X], my_new_location[Y], my_new_location[PRX], my_uid, my_gid
          # Is there thumbnail ?
          copying_thumbnail_node = self.get_thumbnail_node(movf[:spin_node_hashkey])
          my_thumbnail_loc = NoXYPV
          if copying_thumbnail_node.present?
            my_thumbnail_loc = self.create_spin_thumbnail_node_with_copy copy_sid, copying_thumbnail_node, my_new_location[X], my_new_location[Y], my_new_location[PRX], my_uid, my_gid
          end

          if my_loc[0..4] != [-1, -1, -1, -1, nil]
            #            my_new_location[K] = my_loc[K]
            #            SpinAccessControl.copy_parent_acls copy_sid, my_new_location, node_type  # => new_node = [x,y,prx,v,hashkey]
            #            src_parent = self.find_by_node_x_coord_and_node_y_coord_and_node_type_and_node_version src[PRX],src[Y]-1,NODE_DIRECTORY,INITIAL_VERSION_NUMBER
            #            rmfiles = FileDatum.where :spin_node_hashkey => movf[:spin_node_hashkey], :folder_hash_key => src_parent[:spin_node_hashkey]
            #            rmfiles.each {|rmf|
            #              rmf.destroy
            #            }
            # 追加 ↁE
            # ロチE��状態クリア
            self.clear_lock my_loc[4]
            # 追加 ↁE
            #              self.has_updated copy_sid, movf[:spin_node_hashkey]
            #            self.delete_node copy_sid, movf[:spin_node_hashkey], true
            ret_key = my_loc[K]
            copy_src = []
            copy_src[X] = movf[:node_x_coord]
            copy_src[Y] = movf[:node_y_coord]
            copy_src[PRX] = movf[:node_x_pr_coord]
            copy_src[V] = movf[:node_version]
            copy_src[K] = movf[:spin_node_hashkey]
            copy_src[VTREE] = SPIN_NODE_VTREE
            my_loc[VTREE] = SPIN_THUMBNAIL_VTREE
            #          copy_src[X] = movf[:node_x_coord]
            #          copy_src[Y] = movf[:node_y_coord]
            #          copy_src[PRX] = movf[:node_x_pr_coord]
            #          copy_src[V] = movf[:node_version]
            #          copy_src[K] = movf[:spin_node_hashkey]
            #          copy_src[VTREE] = movf[:spin_tree_type]
            #            SpinAccessControl.copy_node_acls copy_sid, copy_src, my_loc  # => new_node = [x,y,prx,v,hashkey]
            SpinAccessControl.copy_parent_acls copy_sid, my_loc, node_type, new_dir_location[K], my_uid # => new_node = [x,y,prx,v,hashkey]
            my_loc[VTREE] = movf[:spin_tree_type]
            retcploc = SpinLocationManager.copy_location copy_sid, copy_src, my_loc
            if retcploc != my_loc
              ret_key = ''
              break
            elsif my_thumbnail_loc[0..3] != NoXYPV
              copy_thumbnail_src = []
              copy_thumbnail_src[X] = copying_thumbnail_node[:node_x_coord]
              copy_thumbnail_src[Y] = copying_thumbnail_node[:node_y_coord]
              copy_thumbnail_src[PRX] = copying_thumbnail_node[:node_x_pr_coord]
              copy_thumbnail_src[V] = copying_thumbnail_node[:node_version]
              copy_thumbnail_src[K] = copying_thumbnail_node[:spin_node_hashkey]
              copy_thumbnail_src[VTREE] = SPIN_NODE_VTREE
              copy_thumbnail_src[K] = self.get_thumbnail_key(movf[:spin_node_hashkey])
              copy_thumbnail_src[VTREE] = SPIN_THUMBNAIL_VTREE
              my_thumbnail_loc[VTREE] = SPIN_THUMBNAIL_VTREE
              retcploc = SpinLocationManager.copy_location copy_sid, copy_thumbnail_src, my_thumbnail_loc
              if retcploc[0..4] == [-1, -1, -1, -1, nil]
                ret_key = ''
                break
              end
            end
          else # => error
            ret_key = ''
            break
          end
        }
      else
        Rails.logger('>> copying node is NULL')
      end # => end fo unless-block
      #        SpinLocationManager.copy_location copy_sid, src, dst
    end # => end of if node_type == NODE_DIRECTORY
    #    end # => end of transaction
    return ret_key
  end

  # => end of self.copy_node_location copy_file_key, new_location, target_cont_location = LOCATION_A, node_type = NODE_FILE

  # new_location : target location of copy opr.
  def self.move_node_location move_sid, move_file_key, vfile_name, new_dir_location, node_exists, target_cont_location = LOCATION_A, node_type = NODE_FILE, parent_dir_key = ''
    # rewrite location coordinates in file_key node
    loc = []
    loc[X] = ANY_VALUE
    loc[Y] = new_dir_location[Y] + 1
    loc[PRX] = new_dir_location[X]
    loc[V] = REQUEST_VERSION_NUMBER
    src = []
    dst = []
    ret_key = ''
    ids = SessionManager.get_uid_gid(move_sid)
    my_uid = ids[:uid]
    my_gid = ids[:gid]
    acls = {}
    moving_node = nil
    moving_node = SpinNode.find_by_spin_node_hashkey(move_file_key)
    if moving_node.blank?
      return nil
    end
    src[X] = moving_node[:node_x_coord]
    src[Y] = moving_node[:node_y_coord]
    src[PRX] = moving_node[:node_x_pr_coord]
    src[V] = moving_node[:node_version]
    src[K] = moving_node[:spin_node_hashkey]
    vfile_name = moving_node[:node_name]

    if node_type == NODE_DIRECTORY
      if node_exists
        new_location = new_dir_location
        loc = self.update_spin_node_with_copy move_sid, moving_node, new_location[X], new_location[Y], new_location[PRX], my_uid, my_gid
        if loc[X..K] != [-1, -1, -1, -1, nil]
          new_location[K] = loc[K]
          SpinAccessControl.copy_parent_acls move_sid, loc, node_type # => new_node = [x,y,prx,v,hashkey]
          dst_parent = self.find_by_node_x_coord_and_node_y_coord_and_node_type_and_node_version new_location[PRX], new_location[Y] - 1, NODE_DIRECTORY, INITIAL_VERSION_NUMBER
          if dst_parent.blank?
            return nil
          end
          self.has_updated move_sid, dst_parent[:spin_node_hashkey]
          self.delete_node move_sid, moving_node[:spin_node_hashkey], true
          ret_key = loc[K]
        else
          return nil
        end
      else
        my_new_location = nil
        while my_new_location.blank?
          my_new_location = SpinNodeKeeper.test_and_set_xy(move_sid, loc, vfile_name, node_type)
        end
        if my_new_location[V] < 0
          my_new_location[V] *= (-1)
        end
        my_loc = self.create_spin_node_with_copy move_sid, moving_node, my_new_location[X], my_new_location[Y], my_new_location[PRX], my_uid, my_gid
        if my_loc[X..K] != [-1, -1, -1, -1, nil]
          my_new_location[K] = my_loc[K]
          SpinAccessControl.copy_parent_acls move_sid, my_loc, node_type, new_dir_location[K], my_uid # => new_node = [x,y,prx,v,hashkey]
          dst_parent = nil
          dst_parent = self.find_by_node_x_coord_and_node_y_coord_and_node_type_and_node_version loc[PRX], loc[Y] - 1, NODE_DIRECTORY, INITIAL_VERSION_NUMBER
          if dst_parent.blank?
            return nil
          end
          self.has_updated move_sid, dst_parent[:spin_node_hashkey]
          self.delete_node move_sid, moving_node[:spin_node_hashkey], true
          ret_key = my_loc[K]
        else
          return nil
        end
      end
    else # => file
      moving_node_versions = SpinNode.where(["spin_tree_type = 0 AND spin_node_hashkey = ? AND is_void = false AND in_trash_flag = false", move_file_key]).order("node_version ASC")
      moving_node_versions.each {|movf|
        loc[V] = movf[:node_version]
        vfile_name = movf[:node_name]
        my_new_location = nil
        while my_new_location.blank?
          my_new_location = SpinNodeKeeper.test_and_set_xy(move_sid, loc, vfile_name, node_type)
        end
        if my_new_location[V] < 0
          my_new_location[V] *= (-1)
        end
        my_loc = self.create_spin_node_with_copy move_sid, movf, my_new_location[X], my_new_location[Y], my_new_location[PRX], my_uid, my_gid
        # Is there thumbnail ?
        moving_thumbnail_node = self.get_thumbnail_node(movf[:spin_node_hashkey])
        my_thumbnail_loc = NoXYPV
        if moving_thumbnail_node.present?
          my_thumbnail_loc = self.create_spin_thumbnail_node_with_copy move_sid, moving_thumbnail_node, my_new_location[X], my_new_location[Y], my_new_location[PRX], my_uid, my_gid
        end
        if my_loc[0..4] != [-1, -1, -1, -1, nil]
          self.has_updated move_sid, movf[:spin_node_hashkey]
          #            self.delete_node move_sid, movf[:spin_node_hashkey], true
          ret_key = my_loc[K]
          move_src = []
          move_src[X] = movf[:node_x_coord]
          move_src[Y] = movf[:node_y_coord]
          move_src[PRX] = movf[:node_x_pr_coord]
          move_src[V] = movf[:node_version]
          move_src[K] = movf[:spin_node_hashkey]
          move_src[VTREE] = SPIN_NODE_VTREE
          my_loc[VTREE] = SPIN_THUMBNAIL_VTREE
          SpinAccessControl.copy_parent_acls move_sid, my_loc, node_type, new_dir_location[K], my_uid # => new_node = [x,y,prx,v,hashkey]
          my_loc[VTREE] = movf[:spin_tree_type]
          retcploc = SpinLocationManager.move_location move_sid, move_src, my_loc
          if retcploc != my_loc
            ret_key = ''
            break
          elsif my_thumbnail_loc[0..3] != NoXYPV
            move_thumbnail_src = []
            move_thumbnail_src[X] = moving_thumbnail_node[:node_x_coord]
            move_thumbnail_src[Y] = moving_thumbnail_node[:node_y_coord]
            move_thumbnail_src[PRX] = moving_thumbnail_node[:node_x_pr_coord]
            move_thumbnail_src[V] = moving_thumbnail_node[:node_version]
            move_thumbnail_src[K] = moving_thumbnail_node[:spin_node_hashkey]
            move_thumbnail_src[VTREE] = SPIN_NODE_VTREE
            move_thumbnail_src[K] = self.get_thumbnail_key(movf[:spin_node_hashkey])
            move_thumbnail_src[VTREE] = SPIN_THUMBNAIL_VTREE
            my_thumbnail_loc[VTREE] = SPIN_THUMBNAIL_VTREE
            retcploc = SpinLocationManager.move_location move_sid, move_thumbnail_src, my_thumbnail_loc
            #            if retcploc[0..4] == [-1,-1,-1,-1,nil]
            #              ret_key = ''
            #              break
            #            else
            self.delete_node(move_sid, movf[:spin_node_hashkey], true)
            #              SpinLocationManager.remove_node_from_storage(move_sid, movf[:spin_node_hashkey], false)
            #            end
          else
            self.delete_node(move_sid, movf[:spin_node_hashkey], true)
          end
        else # => error
          ret_key = ''
          break
        end
      }
      #        SpinLocationManager.move_location move_sid, src, dst
    end # => end of if node_type == NODE_DIRECTORY
    #    end # => end of transaction
    return ret_key
  end

  # => end of self.move_node_location move_file_key, new_location, target_cont_location = LOCATION_A, node_type = NODE_FILE

  def self.xmove_node_location move_sid, move_file_key, vfile_name, new_dir_location, node_exists, target_cont_location = LOCATION_A, node_type = NODE_FILE, parent_dir_key = ''
    # rewrite location coordinates in file_key node
    loc = []
    loc[X] = ANY_VALUE
    loc[Y] = new_dir_location[Y] + 1
    loc[PRX] = new_dir_location[X]
    loc[V] = REQUEST_VERSION_NUMBER
    src = []
    dst = []
    ret_key = ''
    ids = SessionManager.get_uid_gid(move_sid)
    my_uid = ids[:uid]
    my_gid = ids[:gid]
    acls = {}
    #    self.transaction do
    moving_node = SpinNode.find_by_spin_node_hashkey move_file_key
    src[X] = moving_node[:node_x_coord]
    src[Y] = moving_node[:node_y_coord]
    src[PRX] = moving_node[:node_x_pr_coord]
    src[V] = moving_node[:node_version]
    src[K] = moving_node[:spin_node_hashkey]
    vfile_name = moving_node[:node_name]

    if node_type == NODE_DIRECTORY
      if node_exists
        new_location = new_dir_location
        loc = self.update_spin_node_with_copy move_sid, moving_node, new_location[X], new_location[Y], new_location[PRX], my_uid, my_gid
        if loc[X..K] != [-1, -1, -1, -1, nil]
          new_location[K] = loc[K]
          SpinAccessControl.copy_parent_acls move_sid, loc, NODE_DIRECTORY # => new_node = [x,y,prx,v,hashkey]
          dst_parent = self.find_by_node_x_coord_and_node_y_coord_and_node_type_and_node_version new_location[PRX], new_location[Y] - 1, NODE_DIRECTORY, INITIAL_VERSION_NUMBER
          self.has_updated move_sid, dst_parent[:spin_node_hashkey]
          #            self.delete_node move_sid, moving_node[:spin_node_hashkey], true
          ret_key = loc[K]
        else
          return ''
        end
      else
        my_new_location = nil
        while my_new_location.blank?
          my_new_location = SpinNodeKeeper.test_and_set_xy(move_sid, loc, vfile_name, node_type)
        end
        if my_new_location[V] < 0
          my_new_location[V] *= (-1)
        end
        my_loc = self.create_spin_node_with_copy move_sid, moving_node, my_new_location[X], my_new_location[Y], my_new_location[PRX], my_uid, my_gid
        if my_loc != [-1, -1, -1, -1, nil]
          my_new_location[K] = my_loc[K]
          SpinAccessControl.copy_parent_acls move_sid, my_loc, NODE_DIRECTORY # => new_node = [x,y,prx,v,hashkey]
          dst_parent = self.find_by_node_x_coord_and_node_y_coord_and_node_type_and_node_version loc[PRX], loc[Y] - 1, NODE_DIRECTORY, INITIAL_VERSION_NUMBER
          self.has_updated move_sid, dst_parent[:spin_node_hashkey]
          ret_key = my_loc[K]
        else
          return ''
        end
      end
    else # => file
      moving_node_versions = SpinNode.where(["spin_tree_type = 0 AND spin_node_hashkey = ? AND is_void = false AND in_trash_flag = false", move_file_key]).order("node_version ASC")
      #        moving_node_versions = SpinNode.where(["spin_tree_type = 0 AND node_x_coord = ? AND node_y_coord = ? AND is_void = false AND in_trash_flag = false",src[X],src[Y]],:order=>"node_version ASC")
      moving_node_versions.each_with_index {|movf, idx|
        loc[V] = movf[:node_version]
        vfile_name = movf[:node_name]
        my_new_location = nil
        while my_new_location.blank?
          my_new_location = SpinNodeKeeper.test_and_set_xy(move_sid, loc, vfile_name, node_type)
        end
        if my_new_location[V] < 0
          my_new_location[V] *= (-1)
        end
        my_loc = self.create_spin_node_with_copy move_sid, movf, my_new_location[X], my_new_location[Y], my_new_location[PRX], my_uid, my_gid
        if my_loc != [-1, -1, -1, -1, nil]
          self.has_updated move_sid, movf[:spin_node_hashkey]
          ret_key = my_loc[K]
          move_src = []
          move_src[X] = movf[:node_x_coord]
          move_src[Y] = movf[:node_y_coord]
          move_src[PRX] = movf[:node_x_pr_coord]
          move_src[V] = movf[:node_version]
          SpinAccessControl.copy_parent_acls move_sid, my_loc, node_type # => new_node = [x,y,prx,v,hashkey]
          retcploc = SpinLocationManager.move_location move_sid, move_src, my_loc
          if retcploc != my_loc
            ret_key = ''
            break
          else
            self.delete_node(move_sid, movf[:spin_node_hashkey], true)
            SpinLocationManager.remove_node_from_storage(move_sid, movf[:spin_node_hashkey], false)
          end
        else # => error
          ret_key = ''
          break
        end
      }
      #        SpinLocationManager.move_location move_sid, src, dst
    end # => end of if node_type == NODE_DIRECTORY
    #    end # => end of transaction
    return ret_key
  end

  # => end of self.move_node_location move_file_key, new_location, target_cont_location = LOCATION_A, node_type = NODE_FILE

  def self.xmove_node_location move_sid, move_file_key, vfile_name, new_dir_location, node_exists, target_cont_location = LOCATION_A, node_type = NODE_FILE, parent_dir_key = ''
    # rewrite location coordinates in file_key node
    loc = []
    loc[X] = ANY_VALUE
    loc[Y] = new_dir_location[Y] + 1
    loc[PRX] = new_dir_location[X]
    loc[V] = REQUEST_VERSION_NUMBER
    src = []
    dst = []
    ret_key = ''
    ids = SessionManager.get_uid_gid(move_sid)
    my_uid = ids[:uid]
    my_gid = ids[:gid]
    acls = {}
    #    self.transaction do
    moving_node = SpinNode.find_by_spin_node_hashkey move_file_key
    #      if node_type == NODE_DIRECTORY and new_location[V] < 0 # => is directory and already is at the target
    #        moving_node[:is_void] = true
    #        if moving_node.save
    #          return true
    #        else
    #          return false
    #        end 
    #      end
    src[X] = moving_node[:node_x_coord]
    src[Y] = moving_node[:node_y_coord]
    src[PRX] = moving_node[:node_x_pr_coord]
    src[V] = moving_node[:node_version]
    src[K] = moving_node[:spin_node_hashkey]
    vfile_name = moving_node[:node_name]

    if node_type == NODE_DIRECTORY
      if node_exists
        new_location = new_dir_location
        loc = self.update_spin_node_with_copy move_sid, moving_node, new_location[X], new_location[Y], new_location[PRX], my_uid, my_gid
        if loc[X..K] != [-1, -1, -1, -1, nil]
          new_location[K] = loc[K]
          SpinAccessControl.copy_parent_acls move_sid, new_location, node_type # => new_node = [x,y,prx,v,hashkey]
          dst_parent = self.find_by_node_x_coord_and_node_y_coord_and_node_type_and_node_version new_location[PRX], new_location[Y] - 1, NODE_DIRECTORY, INITIAL_VERSION_NUMBER
          self.has_updated move_sid, dst_parent[:spin_node_hashkey]
          #            self.delete_node move_sid, moving_node[:spin_node_hashkey], true
          ret_key = loc[K]
        else
          return ''
        end
      else
        #          loc = self.create_spin_node move_sid, new_location[X], new_location[Y], new_location[PRX], new_location[V], moving_node[:node_name], moving_node[:node_type]
        #          retbc = self.move_spin_node_attribiutes move_sid, movf, loc[X], loc[Y], loc[PRX], loc[V]
        #          my_new_location = self.create_virtual_file(move_sid, vfile_name, parent_dir_key)
        my_new_location = nil
        while my_new_location.blank?
          my_new_location = SpinNodeKeeper.test_and_set_xy(move_sid, loc, vfile_name, node_type)
        end
        #          my_loc = []
        if my_new_location[V] < 0
          my_new_location[V] *= (-1)
        end
        my_loc = self.create_spin_node_with_copy move_sid, moving_node, my_new_location[X], my_new_location[Y], my_new_location[PRX], my_uid, my_gid
        if my_loc != [-1, -1, -1, -1, nil]
          my_new_location[K] = my_loc[K]
          #            SpinAccessControl.move_parent_acls move_sid, my_new_location, node_type  # => new_node = [x,y,prx,v,hashkey]
          dst_parent = self.find_by_node_x_coord_and_node_y_coord_and_node_type_and_node_version loc[PRX], loc[Y] - 1, NODE_DIRECTORY, INITIAL_VERSION_NUMBER
          self.has_updated move_sid, dst_parent[:spin_node_hashkey]
          #            self.delete_node move_sid, moving_node[:spin_node_hashkey], true
          ret_key = my_loc[K]
        else
          return ''
        end
      end
      #        dst[X] = new_location[X]
      #        dst[Y] = new_location[Y]
      #        dst[PRX] = new_location[PRX]
      #        void_nodes = SpinNode.where(:node_x_coord => dst[X], :node_y_coord => dst[Y], :is_void => true)
      #        void_nodes.each {|vn|
      ##          if vn[:is_void]
      #            vn.destroy
      ##          end
      #        }
    else # => file
      moving_node_versions = SpinNode.where(["spin_tree_type = 0 AND node_x_coord = ? AND node_y_coord = ? AND is_void = false AND in_trash_flag = false", src[X], src[Y]]).order("node_version DESC")
      moving_node_versions.each_with_index {|movf, idx|
        #          loc = self.create_spin_node move_sid, new_location[X], new_location[Y], new_location[PRX], new_location[V], moving_node[:node_name], moving_node[:node_type]
        #          retbc = self.move_spin_node_attribiutes move_sid, movf, loc[X], loc[Y], loc[PRX], loc[V]
        loc[V] = movf[:node_version]
        vfile_name = movf[:node_name]
        #          my_new_location = self.create_virtual_file(move_sid, vfile_name, parent_dir_key, loc[V])
        my_new_location = nil
        while my_new_location.blank?
          my_new_location = SpinNodeKeeper.test_and_set_xy(move_sid, loc, vfile_name, node_type)
        end
        if my_new_location[V] < 0
          my_new_location[V] *= (-1)
        end
        #          my_new_location = new_location
        my_loc = self.create_spin_node_with_copy move_sid, movf, my_new_location[X], my_new_location[Y], my_new_location[PRX], my_uid, my_gid
        #          loc = self.create_spin_node_with_copy move_sid, movf, new_location[X], new_location[Y], new_location[PRX], my_uid, my_gid
        if my_loc != [-1, -1, -1, -1, nil]
          #            my_new_location[K] = my_loc[K]
          #            SpinAccessControl.move_parent_acls move_sid, my_new_location, node_type  # => new_node = [x,y,prx,v,hashkey]
          #            src_parent = self.find_by_node_x_coord_and_node_y_coord_and_node_type_and_node_version src[PRX],src[Y]-1,NODE_DIRECTORY,INITIAL_VERSION_NUMBER
          #            rmfiles = FileDatum.where :spin_node_hashkey => movf[:spin_node_hashkey], :folder_hash_key => src_parent[:spin_node_hashkey]
          #            rmfiles.each {|rmf|
          #              rmf.destroy
          #            }
          self.has_updated move_sid, movf[:spin_node_hashkey]
          #            self.delete_node move_sid, movf[:spin_node_hashkey], true
          ret_key = my_loc[K]
          move_src = []
          move_src[X] = movf[:node_x_coord]
          move_src[Y] = movf[:node_y_coord]
          move_src[PRX] = movf[:node_x_pr_coord]
          move_src[V] = movf[:node_version]
          retcploc = SpinLocationManager.move_location move_sid, move_src, my_loc
          if retcploc != my_loc
            ret_key = ''
            break
          end
        else # => error
          ret_key = ''
          break
        end
      }
      #        SpinLocationManager.move_location move_sid, src, dst
    end # => end of if node_type == NODE_DIRECTORY
    #    end # => end of transaction
    return ret_key
  end

  # => end of self.move_node_location move_file_key, new_location, target_cont_location = LOCATION_A, node_type = NODE_FILE

  #  def self.copy_node_location copy_sid, copy_file_key, new_location, target_cont_location = LOCATION_A, node_type = NODE_FILE
  #    # rewrite location coordinates in copy_file_key node
  #    src = []
  #    dst = []
  #    ret = false
  #    self.transaction do
  #      copyingnode = SpinNode.find_by_spin_node_hashkey copy_file_key
  #      src[X] = copyingnode[:node_x_coord]
  #      src[Y] = copyingnode[:node_y_coord]
  #      src[PRX] = copyingnode[:node_x_pr_coord]
  #      src[V] = copyingnode[:node_version]
  #      src[T] = copyingnode[:node_type]
  #      dst[X] = new_location[X]
  #      dst[Y] = new_location[Y]
  #      dst[PRX] = new_location[PRX]
  #      dst[V] = copyingnode[:node_version]
  #      dst[T] = copyingnode[:node_type]
  #      copyingnode_versions = SpinNode.where(["spin_tree_type = 0 AND node_x_coord = ? AND node_y_coord = ? AND node_x_pr_coord = ?",src[X],src[Y],src[PRX]])
  #      copyingnode_versions.each { |copyf|
  #        acls = {}
  #        acls[:user] = copyf[:spin_uid_access_right]
  #        acls[:group] = copyf[:spin_gid_access_right]
  #        acls[:world] = copyf[:spin_world_access_right]
  #        loc = self.create_spin_node copy_sid, new_location[X], new_location[Y], new_location[PRX], copyf[:node_version], copyf[:node_name], copyf[:node_type], copyf[:spin_uid], copyf[:spin_gid], acls, true, true
  #        if loc != [-1,-1,-1,-1,nil] and loc != [-1,-1,-1,-1,nil]
  #          dst_parent = self.find_by_node_x_coord_and_node_y_coord_and_node_type_and_node_version dst[PRX],dst[Y]-1,NODE_DIRECTORY,INITIAL_VERSION_NUMBER
  #          self.has_updated sid, dst_parent[:spin_node_hashkey]
  #          ret = true
  #        else
  #          ret = false
  #        end
  #      }
  #    end
  #    ret = SpinLocationManager.copy_location copy_sid, src, dst
  #    return ret
  #  end # => end of delete_node delete_file_key, trash_it

  def self.retrieve_node node_key
    #    ActiveRecord::Base.lock_optimistically = false
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      rn = nil
      rn = self.find_by_spin_node_hashkey node_key
      if rn.blank?
        return false
      end
      rn.in_trash_flag = false
      rn.is_pending = false
      if rn.save
        #          self.negative_coordinates rn
        return true
      else
        return false
      end
    end
  end

  # => end of self.retrieve_node

  def self.has_updated sid, node_key
    retb = false
    uid = SessionManager.get_uid(sid)
    #    ActiveRecord::Base.lock_optimistically = false
    catch(:has_updated_again) {
      self.transaction do
        begin
          # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
          n = nil
          n = self.find_by_spin_node_hashkey node_key
          if n.blank?
            return false
          end
          ctime = Time.now
          n[:spin_updated_at] = ctime
          n[:ctime] = ctime
          n[:changed_by] = uid
          if n.save
            retb = true
          end
          uid = SessionManager.get_uid(sid)
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :has_updated_again
        end
      end # => end of transaction
    }
    SpinDomain.set_domain_has_updated node_key
    return retb
  end

  # => end of self.has_updated sid, sid, folder_key

  def self.has_children key
    n = nil
    n = self.find_by_spin_node_hashkey key
    if n.blank?
      return false
    end
    cns = self.where(["spin_tree_type = ? AND node_x_pr_coord = ? AND node_y_coord = ?", SPIN_NODE_VTREE, n[:node_x_coord], (n[:node_y_coord] + 1)])
    if cns.length > 0
      return true
    else
      return false
    end
  end

  # => end of has_children

  def self.get_children key, type = NODE_DIRECTORY
    n = nil
    cns = []
    if type == ANY_TYPE
      n = self.find_by_spin_node_hashkey key
    else
      n = self.find_by_spin_node_hashkey_and_node_type key, type
    end
    if n.blank?
      return cns # => empty
    end
    cns = self.where(["spin_tree_type = ? AND node_x_pr_coord = ? AND node_y_coord = ? AND node_type = ?", SPIN_NODE_VTREE, n[:node_x_coord], n[:node_y_coord] + 1, type])
    return cns
  end

  # => end of has_children

  def self.get_parent key, type = ANY_TYPE
    n = nil
    if type == ANY_TYPE
      n = self.select("node_x_coord,node_y_coord,node_x_pr_coord").find_by_spin_node_hashkey(key)
    else
      n = self.select("node_x_coord,node_y_coord,node_x_pr_coord").find_by_spin_node_hashkey_and_node_type(key, type)
    end
    if n.blank?
      return nil
    end

    px = 0
    py = 0
    if n[:node_y_coord] != 0
      px = n[:node_x_pr_coord]
      py = n[:node_y_coord] - 1
    end
    pnode = nil
    pnode = self.select("spin_node_hashkey").find_by_node_x_coord_and_node_y_coord(px, py)
    if pnode.blank?
      return nil
    end
    return pnode[:spin_node_hashkey]
  end

  # => end of has_children

  def self.get_spin_node_vpath(px, py, spin_tree_type = 0)
    if py == 0
      return nil # => root
    end

    # get node record
    n = nil
    n = self.find_by_spin_tree_type_and_node_x_coord_and_node_y_coord(0, px, py)
    if n.blank?
      return nil
    end

    # Is it has valid virtual_path?
    if /\// =~ n[:virtual_path]
      return n[:virtual_path]
    end

    # travers tree
    #    ActiveRecord::Base.lock_optimistically = false
    self.transaction do
      if n[:virtual_path].blank?
        pvpath = self.get_spin_node_vpath(n[:node_x_pr_coord], n[:node_y_coord] - 1, spin_tree_type)
        if pvpath == nil
          return nil
        end
        vpath = pvpath + '/' + n[:node_name]
        n[:virtual_path] = vpath
        n.save
        pp vpath
        return vpath
      else
        return n[:virtual_path]
      end
    end # => end of transaction    
  end

  # => end of self.get_spin_node_vpath(node_vloc, node_name)

  def self.get_vpath(node_key)
    # get node record
    n = nil
    n = self.find_by_spin_node_hashkey(node_key)
    if n.blank?
      return nil
    end

    # Is it has valid virtual_path?
    if /\// =~ n[:virtual_path]
      return n[:virtual_path]
    else
      return nil
    end
  end

  # => end of self.get_spin_node_vpath(node_vloc, node_name)

  def self.get_active_children sid, key, type = ANY_TYPE, max_children = -1
    cns = []
    cns_can = []
    #    ids = SessionManager.get_uid_gid(sid, true)
    #    spin_uid = ids[:uid]
    #    spin_gid = ids[:gid]

    n = nil

    if type == ANY_TYPE
      n = self.readonly.select("node_x_coord,node_y_coord,node_x_pr_coord").find_by_spin_node_hashkey_and_in_trash_flag_and_is_void_and_is_pending(key, false, false, false)
    else
      n = self.readonly.select("node_x_coord,node_y_coord,node_x_pr_coord").find_by_spin_node_hashkey_and_node_type_and_in_trash_flag_and_is_void_and_is_pending(key, type, false, false, false)
    end
    if n.blank?
      return cns
    end

    nc = [0, 0, 0]
    #    if n[:node_y_coord] < 0
    #      nc[X] = n[:node_x_coord] * (-1)
    #      nc[Y] = n[:node_y_coord] * (-1)
    #      nc[PRX] = n[:node_x_pr_coord] * (-1)
    #    else
    nc[X] = n[:node_x_coord]
    nc[Y] = n[:node_y_coord]
    nc[PRX] = n[:node_x_pr_coord]
    #    end

    ActiveRecord::Base.transaction do
      if max_children > 0
        if type == ANY_TYPE
          cns_can_query = sprintf("SELECT id,spin_node_hashkey,node_type,node_name FROM spin_nodes WHERE spin_tree_type = 0 AND node_x_pr_coord = %d AND node_y_coord = %d AND is_void = false AND in_trash_flag = false AND is_pending = false LIMIT %d;", nc[X], nc[Y] + 1, max_children)
          cns_can = self.find_by_sql(cns_can_query)
          #          cns_can = self.where(["spin_tree_type = 0 AND node_x_pr_coord_and_node_y_coord_and_is_void = false AND in_trash_flag = false AND is_pending = false",nc[X],nc[Y]+1], :limit=>max_children)
        else
          #      cns = self.where :node_x_pr_coord => nc[X], :node_y_coord => nc[Y]+1, :node_type => type, :is_void => false, :in_trash_flag => false, :is_pending => false
          cns_can_query = sprintf("SELECT id,spin_node_hashkey,node_type,node_name FROM spin_nodes WHERE spin_tree_type = 0 AND node_x_pr_coord = %d AND node_y_coord = %d AND is_void = false AND in_trash_flag = false AND node_type = %d AND is_pending = false LIMIT %d;", nc[X], nc[Y] + 1, type, max_children)
          cns_can = self.find_by_sql(cns_can_query)
          #          cns_can = self.where(["spin_tree_type = 0 AND node_x_pr_coord_and_node_y_coord_and_node_type_and_is_void = false AND in_trash_flag = false AND is_pending = false",nc[X],nc[Y]+1,type], :limit=>max_children)
        end
      else # => no limit
        if type == ANY_TYPE
          cns_can_query = sprintf("SELECT id,spin_node_hashkey,node_type,node_name FROM spin_nodes WHERE spin_tree_type = 0 AND node_x_pr_coord = %d AND node_y_coord = %d AND is_void = false AND in_trash_flag = false AND is_pending = false;", nc[X], nc[Y] + 1)
          cns_can = self.find_by_sql(cns_can_query)
          #          cns_can = self.where(["spin_tree_type = 0 AND node_x_pr_coord_and_node_y_coord_and_is_void = false AND in_trash_flag = false AND is_pending = false",nc[X],nc[Y]+1])
        else
          #      cns = self.where :node_x_pr_coord => nc[X], :node_y_coord => nc[Y]+1, :node_type => type, :is_void => false, :in_trash_flag => false, :is_pending => false
          cns_can_query = sprintf("SELECT id,spin_node_hashkey,node_type,node_name FROM spin_nodes WHERE spin_tree_type = 0 AND node_x_pr_coord = %d AND node_y_coord = %d AND is_void = false AND in_trash_flag = false AND node_type = %d AND is_pending = false;", nc[X], nc[Y] + 1, type)
          cns_can = self.find_by_sql(cns_can_query)
          #          cns_can = self.where(["spin_tree_type = 0 AND node_x_pr_coord_and_node_y_coord_and_node_type_and_is_void = false AND in_trash_flag = false AND is_pending = false",nc[X],nc[Y]+1,type])
        end
      end

      # go through spin_access_controls
      cns_can.each {|ccan|
        if SpinAccessControl.is_accessible_node(sid, ccan['spin_node_hashkey'], ccan['node_type'].to_i)
          #      aclv = SpinAccessControl.has_acl_values(sid, ccan[:spin_node_hashkey], ccan[:node_type])
          #      if aclv[:user]&ACL_NODE_READ != 0 or aclv[:group]& ACL_NODE_READ != 0 or \
          #          aclv[:user]&ACL_NODE_WRITE != 0 or aclv[:group]& ACL_NODE_WRITE != 0 or \
          #          aclv[:world]&ACL_NODE_READ != 0 or aclv[:world]&ACL_NODE_WRITE != 0
          cns.push ccan
        end
      }
    end # => end of transaction

    return cns
  end

  # => end of has_children

  def self.get_active_children_for_trash sid, key, type = ANY_TYPE, max_children = -1
    cns = []
    cns_can = []
    #    ids = SessionManager.get_uid_gid(sid, true)
    #    spin_uid = ids[:uid]
    #    spin_gid = ids[:gid]

    n = nil

    if type == ANY_TYPE
      n = self.readonly.select("node_x_coord,node_y_coord,node_x_pr_coord").find_by_spin_node_hashkey_and_in_trash_flag_and_is_void(key, false, false)
    else
      n = self.readonly.select("node_x_coord,node_y_coord,node_x_pr_coord").find_by_spin_node_hashkey_and_node_type_and_in_trash_flag_and_is_void(key, type, false, false)
      #      n = self.readonly.select("node_x_coord,node_y_coord,node_x_pr_coord").find_by_spin_node_hashkey_and_node_type_and_in_trash_flag_and_is_void key, type, false, false
    end
    if n.blank?
      return cns
    end

    nc = [0, 0, 0]
    #    if n[:node_y_coord] < 0
    #      nc[X] = n[:node_x_coord] * (-1)
    #      nc[Y] = n[:node_y_coord] * (-1)
    #      nc[PRX] = n[:node_x_pr_coord] * (-1)
    #    else
    nc[X] = n[:node_x_coord]
    nc[Y] = n[:node_y_coord]
    nc[PRX] = n[:node_x_pr_coord]
    #    end

    ActiveRecord::Base.transaction do
      if max_children > 0
        if type == ANY_TYPE
          cns_can_query = sprintf("SELECT id,spin_node_hashkey,node_type,node_name FROM spin_nodes WHERE spin_tree_type = 0 AND node_x_pr_coord = %d AND node_y_coord = %d AND is_void = false AND in_trash_flag = false LIMIT %d;", nc[X], nc[Y] + 1, max_children)
          cns_can = self.find_by_sql(cns_can_query)
          #          cns_can = self.where(["spin_tree_type = 0 AND node_x_pr_coord_and_node_y_coord_and_is_void = false AND in_trash_flag = false AND is_pending = false",nc[X],nc[Y]+1], :limit=>max_children)
        else
          #      cns = self.where :node_x_pr_coord => nc[X], :node_y_coord => nc[Y]+1, :node_type => type, :is_void => false, :in_trash_flag => false, :is_pending => false
          cns_can_query = sprintf("SELECT id,spin_node_hashkey,node_type,node_name FROM spin_nodes WHERE spin_tree_type = 0 AND node_x_pr_coord = %d AND node_y_coord = %d AND is_void = false AND in_trash_flag = false AND node_type = %d LIMIT %d;", nc[X], nc[Y] + 1, type, max_children)
          cns_can = self.find_by_sql(cns_can_query)
          #          cns_can = self.where(["spin_tree_type = 0 AND node_x_pr_coord_and_node_y_coord_and_node_type_and_is_void = false AND in_trash_flag = false AND is_pending = false",nc[X],nc[Y]+1,type], :limit=>max_children)
        end
      else # => no limit
        if type == ANY_TYPE
          cns_can_query = sprintf("SELECT id,spin_node_hashkey,node_type,node_name FROM spin_nodes WHERE spin_tree_type = 0 AND node_x_pr_coord = %d AND node_y_coord = %d AND is_void = false AND in_trash_flag = false;", nc[X], nc[Y] + 1)
          cns_can = self.find_by_sql(cns_can_query)
          #          cns_can = self.where(["spin_tree_type = 0 AND node_x_pr_coord_and_node_y_coord_and_is_void = false AND in_trash_flag = false AND is_pending = false",nc[X],nc[Y]+1])
        else
          #      cns = self.where :node_x_pr_coord => nc[X], :node_y_coord => nc[Y]+1, :node_type => type, :is_void => false, :in_trash_flag => false, :is_pending => false
          cns_can_query = sprintf("SELECT id,spin_node_hashkey,node_type,node_name FROM spin_nodes WHERE spin_tree_type = 0 AND node_x_pr_coord = %d AND node_y_coord = %d AND is_void = false AND in_trash_flag = false AND node_type = %d;", nc[X], nc[Y] + 1, type)
          cns_can = self.find_by_sql(cns_can_query)
          #          cns_can = self.where(["spin_tree_type = 0 AND node_x_pr_coord_and_node_y_coord_and_node_type_and_is_void = false AND in_trash_flag = false AND is_pending = false",nc[X],nc[Y]+1,type])
        end
      end

      # go through spin_access_controls
      cns_can.each {|ccan|
        if SpinAccessControl.is_accessible_node(sid, ccan['spin_node_hashkey'], ccan['node_type'].to_i)
          #      aclv = SpinAccessControl.has_acl_values(sid, ccan[:spin_node_hashkey], ccan[:node_type])
          #      if aclv[:user]&ACL_NODE_READ != 0 or aclv[:group]& ACL_NODE_READ != 0 or \
          #          aclv[:user]&ACL_NODE_WRITE != 0 or aclv[:group]& ACL_NODE_WRITE != 0 or \
          #          aclv[:world]&ACL_NODE_READ != 0 or aclv[:world]&ACL_NODE_WRITE != 0
          cns.push ccan
        end
      }
    end # => end of transaction

    return cns
  end

  # => end of has_children

  def self.is_active_node node_hash_key, include_pending = false
    n = nil
    n = self.select("is_void,is_pending,in_trash_flag").find_by_spin_node_hashkey(node_hash_key)
    if n.blank?
      retun false
    end
    if include_pending
      if n[:is_void] or n[:in_trash_flag]
        return false
      else
        return true
      end
    else
      if n[:is_void] or n[:is_pending] or n[:in_trash_flag]
        return false
      else
        return true
      end
    end
  end

  # => end of self.is_active_node node_hash_key

  def self.is_active_dir_node_location node_loc, include_pending = false
    n = nil
    rethash = {:is_active => false, :hash_key => ''}

    n = self.select("is_void,is_pending,in_trash_flag,spin_node_hashkey").find_by_node_type_and_node_x_coord_and_node_y_coord_and_node_x_pr_coord(NODE_DIRECTORY, node_loc[X], node_loc[Y], node_loc[PRX])
    if n.blank?
      return rethash
    end
    if include_pending
      if n[:is_void] or n[:in_trash_flag]
        return rethash
      else
        rethash[:is_active] = true
        rethash[:hash_key] = n[:spin_node_hashkey]
        return rethash
      end
    else
      if n[:is_void] or n[:is_pending] or n[:in_trash_flag]
        return rethash
      else
        rethash[:is_active] = true
        rethash[:hash_key] = n[:spin_node_hashkey]
        return rethash
      end
    end

    return rethash
  end

  # => end of self.is_active_node node_hash_key

  def self.is_directory node
    n = nil
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      n = self.select("node_type").readonly.find_by_spin_node_hashkey(node)
      if n.blank?
        return false
      end
      if n[:node_type] == NODE_DIRECTORY
        return true
      else
        return false
      end
    end
    return false
  end

  # => end of is_directory node

  def self.is_existing_vpath vpath
    vps = self.readonly.select("id").where(["virtual_path = ?", vpath])
    if vps.length > 0
      return true
    else
      return false
    end
  end

  # => end of self.is_existing_vpath vpath

  def self.create_spin_node sid, x, y, prx, v, node_name, node_type, owner_uid = -1, owner_gid = -1, acls = nil, is_sticky = false, is_under_maintenance = true, is_pending = false
    ret = false
    node_description = ''
    created_by = -1
    created_date = nil
    node_hash_key = ''
    updated_file_only = false
    new_node_vloc = [-1, -1, -1, -1, nil]
    error_vloc = [-1, -1, -1, -1, nil]
    parent_max_versions = DEFAULT_MAX_VERSIONS

    #    ActiveRecord::Base.lock_optimistically = false

    retry1 = 20
    catch(:create_spin_node_again) {
      self.transaction do
        begin
          existing_nodes = self.where(["spin_tree_type = 0 AND node_x_coord = ? AND node_y_coord = ? AND node_x_pr_coord = ? AND node_version = ?", x, y, prx, v]).order("node_version DESC")
          if existing_nodes.length > 0
            node_vloc = []
            node_vloc[X] = x
            node_vloc[Y] = y
            node_vloc[PRX] = prx
            node_vloc[V] = v
            return node_vloc
          end
          new_node = nil

          # generate hsahkey for the new nodeF
          my_ids = Hash.new
          if sid == Vfs::INITIALIZE_SESSION
            my_ids = {uid: 0, gid: 0}
          else
            my_ids = SessionManager.get_uid_gid(sid)
          end
          if owner_uid == -1
            owner_uid = my_ids[:uid]
          end
          if owner_gid == -1
            owner_gid = my_ids[:gid]
          end

          if created_by == -1
            created_by = my_ids[:uid]
          end

          parent_acl = Hash.new
          if v == ANY_VERSION or v == CREATE_NEW
            v = 1
          end
          new_node_vloc = [-1, -1, -1, -1, nil]
          updated_file_only = false
          parent_max_versions = DEFAULT_MAX_VERSIONS

          #      self.find_by_sql('LOCK TABLE spin_nodes IN EXCLUSIVE MODE;')
          new_node = SpinNode.new {|new_node|
            hk = Security::hash_key x, y, prx, v
            new_node[:spin_node_hashkey] = hk
            node_hash_key = hk
            # pp "hashkey = ",new_node.spin_node_hashkey
            # set values
            new_node[:node_x_coord] = x
            new_node[:node_y_coord] = y
            new_node[:node_x_pr_coord] = prx
            new_node[:node_version] = v
            new_node[:node_name] = node_name
            new_node[:node_type] = node_type
            new_node[:node_content_type] = 'application/octet-stream'
            new_node[:in_trash_flag] = false
            new_node[:is_dirty_flag] = false
            new_node[:is_under_maintenance_flag] = is_under_maintenance
            new_node[:is_pending] = (node_type == NODE_DIRECTORY ? false : is_pending)

            new_node[:is_sticky] = is_sticky

            new_node[:in_use_uid] = 0
            #        new_node[:spin_storage_id] = 0 
            new_node[:spin_uid] = owner_uid
            new_node[:spin_gid] = owner_gid
            new_node[:latest] = true
            new_node[:updated_by] = my_ids[:uid]
            new_node[:created_by] = created_by
            new_node[:changed_by] = my_ids[:uid]
            new_node[:node_description] = node_description
            my_vpath = self.get_spin_node_vpath(prx, y - 1)
            new_node[:virtual_path] = (my_vpath.nil? ? '' : my_vpath + '/' + node_name)

            new_node_vloc = [x, y, prx, v, hk]
            new_node_vloc[VPATH] = new_node[:virtual_path]

            parent_acl = self.get_access_rights owner_uid, owner_gid, prx, (y >= 0 ? y - 1 : 0)
            if acls.present? # => acls are specified
              if acls[:user] == ACL_NO_VALUE or acls[:group] == ACL_NO_VALUE or acls[:world] == ACL_NO_VALUE
                new_node[:spin_uid_access_right] = (acls[:user] == ACL_NO_VALUE ? parent_acl[:spin_uid_access_right] : acls[:user])
                new_node[:spin_gid_access_right] = (acls[:group] == ACL_NO_VALUE ? parent_acl[:spin_gid_access_right] : acls[:group])
                new_node[:spin_world_access_right] = (acls[:world] == ACL_NO_VALUE ? parent_acl[:spin_world_access_right] : acls[:world])
              else
                new_node[:spin_uid_access_right] = acls[:user]
                new_node[:spin_gid_access_right] = acls[:group]
                new_node[:spin_world_access_right] = acls[:world]
              end
            else # => no acls are passed
              #          parent_acl = self.get_access_rights owner_uid, owner_gid, prx, (y>=0?y-1:0)
              if parent_acl
                new_node[:spin_uid_access_right] = parent_acl[:spin_uid_access_right]
                new_node[:spin_gid_access_right] = parent_acl[:spin_gid_access_right]
                new_node[:spin_world_access_right] = parent_acl[:spin_world_access_right]
              else
                new_node[:spin_uid_access_right] = ACL_DEFAULT_UID_ACCESS_RIGHT
                new_node[:spin_gid_access_right] = ACL_DEFAULT_GID_ACCESS_RIGHT
                new_node[:spin_world_access_right] = ACL_DEFAULT_WORLD_ACCESS_RIGHT
              end
            end # => end of if acls
            parent_node = SpinNode.find_by_spin_tree_type_and_node_x_coord_and_node_y_coord(0, prx, (y >= 0 ? y - 1 : 0))
            if parent_node.blank?
              return [-1, -1, -1, -1, nil]
            end
            parent_spin_node_tree = parent_node[:spin_node_tree]
            if parent_spin_node_tree
              new_node[:spin_node_tree] = parent_spin_node_tree
            else
              new_node[:spin_node_tree] = self.get_spin_node_tree 0, 0 # => get it from root
            end
            parent_max_versions = parent_node[:max_versions]
            if parent_max_versions
              new_node[:max_versions] = parent_max_versions
            else
              new_node[:max_versions] = self.get_max_versions 0, 0 # => get it from root
            end
            # set node attributes
            if node_type == NODE_DIRECTORY
              updated_file_only = false
              new_node[:node_attributes] = {:type => "folder"}.to_json
            else
              updated_file_only = true
              new_node[:node_attributes] = {:type => "file"}.to_json
            end
            new_node[:spin_vfs_id] = self.get_current_spin_vfs_id
            new_node[:node_attributes].to_json
            #        new_node[:created_at] = Time.now
            new_node[:mtime] = Time.now
            new_node[:spin_updated_at] = Time.now
            new_node[:ctime] = Time.now
            new_node[:spin_created_at] = (created_date == nil ? Time.now : created_date)
          }
          ret = new_node.save
        rescue ActiveRecord::StaleObjectError
          retry1 -= 1
          if retry1 > 0
            sleep(AR_RETRY_WAIT_MSEC)
            throw :create_spin_node_again
          else
            return error_vloc
          end
        end
      end # => end of self.transaction do
    }

    unless ret # => return error 
      case node_type
      when NODE_DIRECTORY
        return [-1, -1, -1, -1, nil]
      when NODE_FILE
        return [-1, -1, -1, -1, nil]
      else
        return [-1, -1, -1, -1, nil]
      end # => end of case
    else # => saved successfully
      # clear obsoleted versions
      #        ActiveRecord::Base.lock_optimistically = false
      node_versions = SpinNode.where(["node_x_coord = ? AND node_y_coord = ? AND node_version < ? AND spin_tree_type = ?", x, y, v, SPIN_NODE_VTREE]).order('node_version ASC')
      #        del_last_index = (parent_max_versions + 1)*(-1)
      fm_args = []
      last_version = node_versions.size > 0 ? node_versions[-1][:node_version] : -1;
      #      last_index = node_versions.length - 1
      del_last_version = last_version - parent_max_versions + 1
      FileManager.rails_logger("del_last_version = " + del_last_version.to_s)
      #        node_versions[IDX_FIRST_INDEX..del_last_index].each {|nv|
      retry2 = 20
      catch(:create_spin_node_again2) {
        self.transaction do
          begin
            if node_versions.length > 0
              node_versions.each {|nv|
                if nv[:node_version] <= del_last_version
                  #              self.delete_virtual_file sid, nv[:spin_node_hashkey], false
                  node_hash_key = nv[:spin_node_hashkey]
                  fm_args.push(node_hash_key)
                  FileManager.rails_logger("pushed key = " + node_hash_key)
                  #                  end
                elsif nv[:latest] == true
                  nv[:latest] = false
                  nv.save
                end # => end of if idx <= del_last_index
              }
            end
            #        ActiveRecord::Base.lock_optimistically = true
            if fm_args.length > 0 && sid != Vfs::INITIALIZE_SESSION
              fm_args.each {|rmnode|
                self.delete_node sid, rmnode, true
                SpinLocationMapping.delete_mapping_data rmnode
              }
            end
          rescue ActiveRecord::StaleObjectError
            retry2 -= 1
            if retry2 > 0
              sleep(AR_RETRY_WAIT_MSEC)
              throw :create_spin_node_again2
            else
              return error_vloc
            end
          end
        end # => end of self.transaction do
      }
    end # => end of unless ret

    # => set spin_updated_at of the parent node
    pnode = SpinLocationManager.location_to_key [prx, y - 1, ANY_PRX, ANY_VERSION]
    if sid != Vfs::INITIALIZE_SESSION
      self.has_updated sid, pnode
      FolderDatum.has_updated sid, pnode, updated_file_only
      if node_type == NODE_DIRECTORY
        DomainDatum.set_domains_dirty_by_key(pnode)
      end
    end

    #    SpinUrl.generate_public_url(sid, node_hash_key, node_name)

    return new_node_vloc
  end

  # => end of create_virtual_node

  def self.set_spin_node_vpath limit_y = -1, force_generate_vpath = false
    s = SpinNode.select("id").where(["id > 0"]).order("id ASC").limit(1)
    start_node_id = s[:id]
    next_node_id = start_node_id
    spin_tree_type = SPIN_NODE_VTREE
    #    ActiveRecord::Base.lock_optimistically = false
    self.transaction do
      if limit_y == -1 # => no limit
        snode = nil
        while true do
          if start_node_id == next_node_id
            snode = self.find(next_node_id)
            start_node_id = -1
          else
            snode_a = self.where(["id > ?", next_node_id]).order("id")
          end
          if snode_a.blank?
            break
          end
          snode = snode_a[0]

          if snode[:virtual_path].blank? or force_generate_vpath
            if snode[:node_y_coord] == 0 # => root
              snode[:virtual_path] = '/'
            else
              pvp = self.get_spin_node_vpath(snode[:node_x_pr_coord], snode[:node_y_coord] - 1, spin_tree_type)
              if pvp == nil # => snode is orphan
                snode[:orphan] = true
                snode.save
                next_node_id = snode[:id]
                next
              end
              snode[:virtual_path] = pvp + '/' + snode[:node_name]
            end
            snode.save
          end
          next_node_id = snode[:id]
        end
      else # => limit_y >= 0
        while true do
          if start_node_id == next_node_id
            snode = self.find(next_node_id)
            start_node_id = -1
          else
            snode_a = self.where(["id > ? AND node_y_coord <= ?", next_node_id, limit_y]).order("id")
          end
          if snode_a.blank?
            break
          end
          snode = snode_a[0]
          if snode[:virtual_path].blank? or force_generate_vpath
            if snode[:node_y_coord] == 0 # => root
              snode[:virtual_path] = '/'
            else
              pvp = self.get_spin_node_vpath(snode[:node_x_pr_coord], snode[:node_y_coord] - 1)
              if pvp == nil # => snode is orphan
                snode[:orphan] = true
                snode.save
                next_node_id = snode[:id]
                next
              end
              snode[:virtual_path] = pvp + '/' + snode[:node_name]
            end
            snode.save
          end
          next_node_id = snode[:id]
        end
      end
    end # => end of transaction
  end

  # => end of self.set_spin_node_vpath limit_y = -1

  def self.set_notified_at node_key, notification_type
    #    ActiveRecord::Base.lock_optimistically = false
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      n = nil
      n = self.find_by_spin_node_hashkey(node_key)
      if n.blank?
        return false
      end
      t = Time.now
      n[:notified_at] = t
      nf = notification_type
      unless n[:notify_type] < 0
        nf = n[:notify_type]
        nf |= notification_type
      end
      n[:notify_type] = nf
      case notification_type
      when UPLOAD_NOTIFICATION
        n[:notified_new_at] = t
      when MODIFY_NOTIFICATION
        n[:notified_modification_at] = t
      when DELETE_NOTIFICATION
        n[:notified_delete_at] = t
      end
      if n.save
        return true
      end
    end
    return false
  end

  def self.set_notified_at_vpath(trashed_vps, notification_type)
    #    ActiveRecord::Base.lock_optimistically = false
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      n = nil
      n = self.find_by_virtual_path(trashed_vps)
      if n.blank?
        return false
      end
      t = Time.now
      n[:notified_at] = t
      nf = notification_type
      unless n[:notify_type] < 0
        nf = n[:notify_type]
        nf |= notification_type
      end
      n[:notify_type] = nf
      case notification_type
      when UPLOAD_NOTIFICATION
        n[:notified_new_at] = t
      when MODIFY_NOTIFICATION
        n[:notified_modification_at] = t
      when DELETE_NOTIFICATION
        n[:notified_delete_at] = t
      end
      if n.save
        return true
      end
    end
    return false
  end

  def self.copy_spin_node_attribiutes sid, src_node, x, y, prx, v = ANY_VERSION
    owner_uid = -1
    owner_gid = -1
    v = src_node[:node_version]
    new_node = nil
    if v != ANY_VERSION
      new_node = self.find_by_spin_tree_type_and_node_x_coord_and_node_y_coord_and_node_x_pr_coord_and_node_version(SPIN_NODE_VTREE, x, y, prx, v)
      if new_node.blank?
        return false
      end
    else
      new_nodes = self.where(["spin_tree_type = ? AND node_x_coord = ? AND node_y_coord = ? AND node_x_pr_coord = ?", SPIN_NODE_VTREE, x, y, prx])
      #      new_nodes = self.where :node_x_coord => x, :nodex_y_coord => y, :node_x_pr_coord => prx
      if new_nodes.length > 0
        new_node = new_nodes[-1]
      else
        return false
      end
    end

    ret = false
    #    ActiveRecord::Base.lock_optimistically = false
    # new_acl = SpinAccessControl.new
    # generate hsahkey for the new node
    my_ids = SessionManager.get_uid_gid(sid)
    if owner_uid == -1
      owner_uid = my_ids[:uid]
    end
    if owner_gid == -1
      owner_gid = my_ids[:gid]
    end
    #    parent_acl = Hash.new
    #    if v == ANY_VERSION or v == CREATE_NEW
    #      v = 1
    #    end
    self.transaction do
      src_node.attributes.each {|key, value| # => copy src data
        next if key == 'id'
        next if key == 'spin_node_hashkey'
        next if key == 'node_x_coord'
        next if key == 'node_y_coord'
        next if key == 'node_x_pr_coord'
        next if key == 'node_name'
        next if key == 'node_version'
        next if key == 'created_at'
        next if key == 'updated_at'

        if key == 'spin_uid'
          new_node[:spin_uid] = owner_uid
        elsif key == 'spin_gid'
          new_node[:spin_gid] = owner_uid
        else
          new_node[key] = value
        end

      }
      if new_node.save
        ret = true
      else
        ret = false
      end
    end # => end of transaction
    return ret
    #  end # => end of unless new_node.save

    # => set spin_updated_at of the parent node
    pnode = SpinLocationManager.location_to_key [prx, y - 1, ANY_PRX, ANY_VERSION]
    self.has_updated sid, pnode
    FolderDatum.has_updated sid, pnode, updated_file_only
    if node_type == NODE_DIRECTORY
      DomainDatum.set_domains_dirty_by_key(pnode)
    end
    return new_node_vloc
  end

  # => end of create_virtual_node

  def self.create_virtual_file sid, vfile_name, dir_key, node_version = REQUEST_VERSION_NUMBER, acls = nil, is_under_maintenance = true, set_pending = false
    # create virtual file in the directory specified by dir_key
    # acls : acl hash for the new file if it isn't nil
    # => default : use acls of the parent directory
    # get uid and gid { :uid => id, :gid => id }
    uidgid = SessionManager.get_uid_gid sid
    # get location [x,y,prx,v] from dir_key
    ploc = SpinLocationManager.key_to_location dir_key, NODE_DIRECTORY

    # Are there nodes in the target directory?
    #    existing_nodes = self.where(["spin_tree_type = ? AND node_x_pr_coord = ? AND node_y_coord = ? AND is_void = false",SPIN_NODE_VTREE,ploc[X],ploc[Y] + 1])
    #    max_number = REQUEST_COORD_VALUE
    #    existing_nodes.each {|n|
    #      if n[:node_x_coord] > max_number
    #        max_number = n[:node_x_coord]
    #      end
    #    }
    # get full location [X,Y,P,V,K]
    loc = [-1, ploc[Y] + 1, ploc[X], node_version]
    vfile_loc = nil
    while vfile_loc.blank?
      vfile_loc = SpinNodeKeeper.test_and_set_xy sid, loc, vfile_name # parent node loc and new file name
    end
    # Is there a file that has the same name?
    #    ActiveRecord::Base.lock_optimistically = false
    #    self.transaction do
    #      same_locs = self.where(["spin_tree_type = ? AND node_x_coord = ? AND node_y_coord = ?",SPIN_NODE_VTREE, vfile_loc[X], vfile_loc[Y]])
    #      same_locs.each { |sl|
    #          if sl[:node_name] != vfile_name
    #            self.delete_node(sid, sl[:spin_node_hashkey], true)
    #          else
    #            if sl[:node_version] < vfile_loc[V]
    #              sl[:latest] = false
    #              sl.save
    #            end
    #          end
    #      }
    #    end # => end of transaction
    log_msg = ":create_virtual_file => test_and_set_xy returned = #{vfile_loc.to_s}"
    FileManager.logger(sid, log_msg)
    if vfile_loc[X..V] == NoXYPV
      FileManager.rails_logger("Error : test_and_set_xy returned error for " + loc.to_s)
      return vfile_loc
    end
    if vfile_loc[V] < 0
      vfile_loc[V] *= (-1)
    end
    vfile_loc = self.create_spin_node sid, vfile_loc[X], vfile_loc[Y], vfile_loc[PRX], vfile_loc[V], vfile_name, NODE_FILE, uidgid[:uid], uidgid[:gid], acls, false, is_under_maintenance, set_pending
    if vfile_loc[X..K] == [-1, -1, -1, -1, nil]
      FileManager.rails_logger("Error : create_spin_node returned error for " + vfile_name + vfile_loc.to_s)
      return NoXYPV
    end
    if acls == nil
      # vfile_loc = self.create_virtual_node 0, depth, prx, 0, NODE_DIRECTORY, get_uid, get_gid
      SpinAccessControl.copy_parent_acls sid, vfile_loc, NODE_FILE # => vfile_loc = [x,y,prx,v,hashkey]
    end
    return vfile_loc # => return location array
    #      return vfile_loc[K] # => return hash key
  end

  # => self.create_virtual_file sid, vfile_name, dir_key

  def self.create_spin_node_with_copy sid, src_node, x, y, prx, new_node_uid = -1, new_node_gid = -1, new_node_acls = {}, new_node_name = '', new_node_type = NODE_FILE
    owner_uid = new_node_uid
    owner_gid = new_node_gid
    v = src_node[:node_version]
    node_type = src_node[:node_type]
    latest = src_node[:latest]
    new_node = nil
    ret = false
    #    ActiveRecord::Base.lock_optimistically = false
    # new_acl = SpinAccessControl.new
    # generate hsahkey for the new node
    my_ids = SessionManager.get_uid_gid(sid)
    if owner_uid == -1
      owner_uid = my_ids[:uid]
    end
    if owner_gid == -1
      owner_gid = my_ids[:gid]
    end
    if v == ANY_VERSION or v == CREATE_NEW
      v = 1
    end
    new_node_vloc = [-1, -1, -1, -1, nil]
    updated_file_only = false
    parent_max_versions = DEFAULT_MAX_VERSIONS

    my_parent_node = Hash.new

    #    self.transaction do
    #      new_node = SpinNode.new
    # remove file which has the same x,y,v i target dir
    #    pf = self.find_by_node_x_coord_and_node_y_coord_and_node_x_pr_coord_and_node_version x, y, prx, v
    retry_count = ACTIVE_RECORD_RETRY_COUNT
    new_node_hash_key = nil

    catch(:create_spin_node_with_copy_again) {

      self.transaction do
        begin
          #      self.find_by_sql('LOCK TABLE spin_nodes IN EXCLUSIVE MODE;')
          #          pf = self.find_by_node_x_coord = ? AND node_y_coord = ? AND node_x_pr_coord = ? AND node_version = ? AND spin_tree_type = ?", x, y, prx, v, SPIN_NODE_VTREE])
          #          if pf.present?
          #            if node_type == NODE_FILE
          #              if pf.present?
          #                SpinNode.delete_node(sid, pf[:spin_node_hashkey])
          #              end
          #            elsif node_type == NODE_DIRECTORY
          #              new_node = pf
          #            end
          #          else
          new_node = self.new {|new_node|
            #          end

            src_node.attributes.each {|key, value| # => copy src data
              #            next if key == 'spin_node_hashkey'
              #            next if key == 'node_x_coord'
              #            next if key == 'node_y_coord'
              #            next if key == 'node_x_pr_coord'
              #            next if key == 'node_type'
              #            next if key == 'node_version'
              #            next if key == 'virtual_path'
              unless key == 'id'
                new_node[key] = value
              end
            }
            hk = Security::hash_key x, y, prx, v
            new_node[:spin_node_hashkey] = hk
            new_node_hash_key = hk
            # pp "hashkey = ",new_node.spin_node_hashkey
            # set values
            new_node[:node_x_coord] = x
            new_node[:node_y_coord] = y
            new_node[:node_x_pr_coord] = prx
            new_node[:node_version] = v
            new_node[:node_type] = node_type
            new_node[:is_void] = false
            new_node[:in_trash_flag] = false
            new_node[:is_pending] = false
            new_node[:is_sticky] = false
            new_node[:updated_by] = my_ids[:uid]
            new_node[:changed_by] = my_ids[:uid]
            new_node[:virtual_path] = self.get_spin_node_vpath(prx, y - 1) + '/' + src_node[:node_name]

            new_node_vloc = [x, y, prx, v, hk]
            new_node_vloc[VPATH] = new_node[:virtual_path]

            new_node[:spin_tree_type] = SPIN_NODE_VTREE
            new_node[:spin_vfs_id] = self.get_current_spin_vfs_id
            new_node[:latest] = latest
            begin
              parent_node = self.find_by_spin_tree_type_and_node_x_coord_and_node_y_coord(0, prx, (y >= 0 ? y - 1 : 0))
              if parent_node.blank?
                return [-1, -1, -1, -1, nil]
              end
              my_parent_node = parent_node
              parent_spin_node_tree = parent_node[:spin_node_tree]
              if parent_spin_node_tree
                new_node[:spin_node_tree] = parent_spin_node_tree
              else
                new_node[:spin_node_tree] = self.get_spin_node_tree 0, 0 # => get it from root
              end
              parent_max_versions = parent_node[:max_versions]
              if parent_max_versions
                new_node[:max_versions] = parent_max_versions
              else
                new_node[:max_versions] = self.get_max_versions 0, 0 # => get it from root
              end
            rescue ActiveRecord::RecordNotFound
              return [-1, -1, -1, -1, nil]
            end

            unless new_node_acls.blank?
              new_node[:spin_uid_access_right] = new_node_acls[:spin_uid_access_right]
              new_node[:spin_gid_access_right] = new_node_acls[:spin_gid_access_right]
              new_node[:spin_world_access_right] = new_node_acls[:spin_world_access_right]
            end
            new_node[:spin_uid] = new_node_uid unless new_node_uid == -1
            new_node[:spin_gid] = new_node_uid unless new_node_gid == -1
            new_node[:node_name] = new_node_name unless new_node_name.blank?
          }

          new_node.save
          log_msg = 'create_spin_node_with copy created a record for ' + new_node.to_s
          FileManager.logger(sid, log_msg)
          FileManager.rails_logger(log_msg, Vfs::LOG_INFO)
            #    end # => end of self.transaction do
            # clear obsoleted versions
            #        ActiveRecord::Base.lock_optimistically = false
        rescue ActiveRecord::StaleObjectError
          retry_count -= 1
          if retry_count > 0
            sleep(AR_RETRY_WAIT_MSEC)
            throw :create_spin_node_with_copy_again
          else
            log_msg = 'create_spin_node_with copy failed with StaleObjectError for ' + new_node.to_s
            FileManager.logger(sid, log_msg)
            Rails.logger(log_msg)
            case node_type
            when NODE_DIRECTORY
              return [-1, -1, -1, -1, nil]
            when NODE_FILE
              return [-1, -1, -1, -1, nil]
            else
              return [-1, -1, -1, -1, nil]
            end # => end of case
          end
        rescue => e
          log_msg = 'create_spin_node_with copy failed to ctreate a record with exception ' + e.backtrace + ' for ' + new_node.to_s
          FileManager.logger(sid, log_msg)
          FileManager.rails_logger(log_msg, Vfs::LOG_ERROR)
          case node_type
          when NODE_DIRECTORY
            return [-1, -1, -1, -1, nil]
          when NODE_FILE
            return [-1, -1, -1, -1, nil]
          else
            return [-1, -1, -1, -1, nil]
          end # => end of case
        end # => end of begin block
        #        unless ret # => return error 
        #        else # => saved successfully
        #        end # => end of unless new_node.save
      end # => end of transaction

    } # => end of catch block

    #    pnode = SpinLocationManager.location_to_key [ prx, y-1, ANY_PRX, ANY_VERSION ]
    self.has_updated sid, my_parent_node[:spin_node_hashkey]
    FolderDatum.has_updated sid, my_parent_node[:spin_node_hashkey], updated_file_only
    if node_type == NODE_DIRECTORY
      DomainDatum.set_domains_dirty_by_key(my_parent_node[:spin_node_hashkey])
    end
    return new_node_vloc
  end

  # => end of create_virtual_node

  def self.create_spin_thumbnail_node_with_copy sid, src_node, x, y, prx, new_node_uid = -1, new_node_gid = -1, new_node_acls = {}, new_node_name = '', new_node_type = NODE_FILE
    owner_uid = new_node_uid
    owner_gid = new_node_gid
    v = src_node[:node_version]
    node_type = src_node[:node_type]
    new_node = nil
    ret = false
    #    ActiveRecord::Base.lock_optimistically = false
    # new_acl = SpinAccessControl.new
    # generate hsahkey for the new node
    my_ids = SessionManager.get_uid_gid(sid)
    if owner_uid == -1
      owner_uid = my_ids[:uid]
    end
    if owner_gid == -1
      owner_gid = my_ids[:gid]
    end
    if v == ANY_VERSION or v == CREATE_NEW
      v = 1
    end
    new_node_vloc = [-1, -1, -1, -1, nil]
    updated_file_only = false
    parent_max_versions = DEFAULT_MAX_VERSIONS
    #    self.transaction do
    #      new_node = SpinNode.new
    # remove file which has the same x,y,v i target dir
    #    pf = self.find_by_node_x_coord_and_node_y_coord_and_node_x_pr_coord_and_node_version x, y, prx, v
    retry_count = ACTIVE_RECORD_RETRY_COUNT
    catch(:create_spin_thumbnail_node_with_copy) {

      self.transaction do
        begin
          pf = nil
          pf = self.find_by_node_x_coord_and_node_y_coord_and_node_x_pr_coord_and_node_version_and_spin_tree_type(x, y, prx, v, SPIN_THUMBNAIL_VTREE)

          if pf.present?
            if node_type == NODE_FILE
              SpinNode.delete_node(sid, pf[:spin_node_hashkey])
            elsif node_type == NODE_DIRECTORY
              new_node = pf
            end
          else
            new_node = SpinNode.new {|new_node|

              src_node.attributes.each {|key, value| # => copy src data
                next if key == 'id'
                next if key == 'spin_node_hashkey'
                new_node[key] = value
              }

              hk = Security::hash_key x, y, prx, v + 8
              new_node[:spin_node_hashkey] = hk
              # pp "hashkey = ",new_node.spin_node_hashkey
              new_node_vloc = [x, y, prx, v, hk]
              # set values
              new_node[:node_x_coord] = x
              new_node[:node_y_coord] = y
              new_node[:node_x_pr_coord] = prx
              new_node[:node_version] = v
              new_node[:is_void] = false
              new_node[:in_trash_flag] = false
              new_node[:is_pending] = false
              new_node[:is_sticky] = false
              new_node[:updated_by] = my_ids[:uid]
              new_node[:changed_by] = my_ids[:uid]
              new_node[:virtual_path] = self.get_spin_node_vpath(prx, y - 1) + '/' + src_node[:node_name]
              new_node[:spin_tree_type] = SPIN_THUMBNAIL_VTREE
              new_node[:spin_node_tree] = SPIN_THUMBNAIL_VTREE
              new_node[:spin_vfs_id] = self.get_current_spin_vfs_id
              parent_node = nil
              begin
                parent_node = SpinNode.find_by_spin_tree_type_and_node_x_coord_and_node_y_coord(0, prx, (y >= 0 ? y - 1 : 0))
                if parent_node.present?
                  parent_max_versions = parent_node[:max_versions]
                  if parent_max_versions
                    new_node[:max_versions] = parent_max_versions
                  else
                    new_node[:max_versions] = self.get_max_versions 0, 0 # => get it from root
                  end
                end
              rescue ActiveRecord::RecordNotFound
              end

              unless new_node_acls.blank?
                new_node[:spin_uid_access_right] = new_node_acls[:spin_uid_access_right]
                new_node[:spin_gid_access_right] = new_node_acls[:spin_gid_access_right]
                new_node[:spin_world_access_right] = new_node_acls[:spin_world_access_right]
              end
              new_node[:spin_uid] = new_node_uid unless new_node_uid == -1
              new_node[:spin_gid] = new_node_uid unless new_node_gid == -1
              new_node[:node_name] = new_node_name unless new_node_name.blank?
            }
            ret = new_node.save
          end
          #    end # => end of self.transaction do
          unless ret # => return error 
            case node_type
            when NODE_DIRECTORY
              return [-1, -1, -1, -1, nil]
            when NODE_FILE
              return [-1, -1, -1, -1, nil]
            else
              return [-1, -1, -1, -1, nil]
            end # => end of case
          end # => end of unless new_node.save
        rescue ActiveRecord::StaleObjectError
          retry_count -= 1
          if retry_count > 0
            sleep(AR_RETRY_WAIT_MSEC)
            throw :create_spin_thumbnail_node_with_copy
          else
            log_msg = 'create_spin_thumbnail_node_with_copy failed with StaleObjectError for ' + new_node.to_s
            FileManager.logger(sid, log_msg)
            Rails.logger(log_msg)
            case node_type
            when NODE_DIRECTORY
              return [-1, -1, -1, -1, nil]
            when NODE_FILE
              return [-1, -1, -1, -1, nil]
            else
              return [-1, -1, -1, -1, nil]
            end # => end of case
          end
        rescue => e
          log_msg = 'create_spin_thumbnail_node_with_copy failed to ctreate a record with exception ' + e.backtrace + ' for ' + new_node.to_s
          FileManager.logger(sid, log_msg)
          Rails.logger(log_msg)
          case node_type
          when NODE_DIRECTORY
            return [-1, -1, -1, -1, nil]
          when NODE_FILE
            return [-1, -1, -1, -1, nil]
          else
            return [-1, -1, -1, -1, nil]
          end # => end of case
        end
      end # => end of transaction
    } # => end of catch-block

    # => set spin_updated_at of the parent node
    pnode = SpinLocationManager.location_to_key [prx, y - 1, ANY_PRX, ANY_VERSION]
    self.has_updated sid, pnode
    FolderDatum.has_updated sid, pnode, updated_file_only
    if node_type == NODE_DIRECTORY
      DomainDatum.set_domains_dirty_by_key(pnode)
    end
    return new_node_vloc
  end

  # => end of create_virtual_node

  def self.update_spin_node_with_copy sid, src_node, x, y, prx, new_node_uid = -1, new_node_gid = -1, new_node_acls = {}, new_node_name = ''
    owner_uid = new_node_uid
    owner_gid = new_node_gid
    node_type = src_node[:node_type]
    v = src_node[:node_version]
    ret = false
    #    ActiveRecord::Base.lock_optimistically = false
    new_nodes = []
    if v == ANY_VERSION
      new_nodes = self.where(["node_x_coord = ? AND node_y_coord = ? AND node_x_pr_coord = ?", x, y, prx])
    else
      new_nodes = self.where(["node_x_coord = ? AND node_y_coord = ? AND node_x_pr_coord = ? AND node_version = ?", x, y, prx, v])
    end
    # new_acl = SpinAccessControl.new
    # generate hsahkey for the new node
    my_ids = SessionManager.get_uid_gid(sid)
    if owner_uid == -1
      owner_uid = my_ids[:uid]
    end
    if owner_gid == -1
      owner_gid = my_ids[:gid]
    end
    if v == ANY_VERSION or v == CREATE_NEW
      v = 1
    end
    new_node_vloc = [-1, -1, -1, -1, nil]
    updated_file_only = false
    parent_max_versions = DEFAULT_MAX_VERSIONS
    self.transaction do
      #      self.find_by_sql('LOCK TABLE spin_nodes IN EXCLUSIVE MODE;')
      new_nodes.each {|new_node|
        src_node.attributes.each {|key, value| # => copy src data
          next if key == 'id' or key == 'spin_node_hashkey'
          new_node[key] = value
        }
        #        hk = Security::hash_key x, y, prx, v
        #        new_node[:spin_node_hashkey]= hk
        # pp "hashkey = ",new_node.spin_node_hashkey
        # set values
        new_node[:node_x_coord] = x
        new_node[:node_y_coord] = y
        new_node[:node_x_pr_coord] = prx
        new_node[:node_version] = v
        new_node[:is_void] = false
        new_node[:in_trash_flag] = false
        new_node[:is_pending] = false
        new_node[:is_sticky] = false
        new_node[:virtual_path] = self.get_spin_node_vpath(prx, y - 1) + '/' + src_node[:node_name]
        new_node_vloc = [x, y, prx, v, new_node[:spin_node_hashkey]]
        new_node_vloc[VPATHJ] = new_node[:virtual_path]
        new_node[:spin_vfs_id] = self.get_current_spin_vfs_id
        parent_node = nil
        begin
          parent_node = SpinNode.find_by_spin_tree_type_and_node_x_coord_and_node_y_coord(0, prx, (y >= 0 ? y - 1 : 0))
          if parent_node.present?
            parent_spin_node_tree = parent_node[:spin_node_tree]
            if parent_spin_node_tree
              new_node[:spin_node_tree] = parent_spin_node_tree
            else
              new_node[:spin_node_tree] = self.get_spin_node_tree 0, 0 # => get it from root
            end
            parent_max_versions = parent_node[:max_versions]
            if parent_max_versions
              new_node[:max_versions] = parent_max_versions
            else
              new_node[:max_versions] = self.get_max_versions 0, 0 # => get it from root
            end
          end
        rescue ActiveRecord::RecordNotFound
        end

        unless new_node_acls.blank?
          new_node[:spin_uid_access_right] = new_node_acls[:spin_uid_access_right]
          new_node[:spin_gid_access_right] = new_node_acls[:spin_gid_access_right]
          new_node[:spin_world_access_right] = new_node_acls[:spin_world_access_right]
        end
        new_node[:spin_uid] = new_node_uid unless new_node_uid == -1
        new_node[:spin_gid] = new_node_uid unless new_node_gid == -1
        new_node[:node_name] = new_node_name unless new_node_name.blank?
        ret = new_node.save
      }
      #    end # => end of self.transaction do
      unless ret # => return error 
        case node_type
        when NODE_DIRECTORY
          return [-1, -1, -1, -1, nil]
        when NODE_FILE
          return [-1, -1, -1, -1, nil]
        else
          return [-1, -1, -1, -1, nil]
        end # => end of case
      else # => saved successfully
        # clear obsoleted versions
        #        ActiveRecord::Base.lock_optimistically = false
        fm_args = []
        if node_type == NODE_FILE
          node_versions = SpinNode.where(["spin_tree_type = 0 AND node_x_coord = ? AND node_y_coord = ?", x, y]).order('node_version')
          #        del_last_index = (parent_max_versions + 1)*(-1)
          last_index = node_versions.length - 1
          del_last_index = last_index - parent_max_versions
          #        node_versions[IDX_FIRST_INDEX..del_last_index].each {|nv|
          if last_index > 0
            node_versions.each_with_index {|nv, idx|
              if idx <= del_last_index
                begin
                  #              self.delete_virtual_file sid, nv[:spin_node_hashkey], false
                  node_hash_key = nv[:spin_node_hashkey]
                  nv[:latest] = false
                  nv.save
                  #                  if nv[:is_pending] != true
                  fm_args.push(node_hash_key)
                    #                  end
                rescue
                  #                  ActiveRecord::Base.lock_optimistically = true
                  log_msg = "create_virtual_node [" + (__FILE__).to_s + "," + (__LINE__).to_s + "] : Failed to delete obsoleted node = " + nv[:spin_node_hashkey]
                  FileManager.logger(sid, log_msg)
                end
              end # => end of if idx <= del_last_index
            }
          end
        end # => end of if node_type == NODE_FILE

        #        ActiveRecord::Base.lock_optimistically = true
        if fm_args.length > 0
          fm_args.each {|rmnode|
            self.delete_node sid, rmnode
            SpinLocationMapping.delete_mapping_data rmnode
            rparams = [rmnode]
            #            SpinFileManager.request sid, 'recopy_node', rparams
          }
        end
      end # => end of unless new_node.save
    end # => end of transaction
    # => set spin_updated_at of the parent node
    pnode = SpinLocationManager.location_to_key [prx, y - 1, ANY_PRX, ANY_VERSION]
    self.has_updated sid, pnode
    FolderDatum.has_updated sid, pnode, updated_file_only
    if node_type == NODE_DIRECTORY
      DomainDatum.set_domains_dirty_by_key(pnode)
    end
    return new_node_vloc
  end

  # => end of create_virtual_node

  # Should be called in a transaction!
  def self.get_access_rights uid, gid, x, y
    # get node(x,y)
    if x < 0
      x = 0
    end
    if y < 0
      y = 0
    end
    acl = Hash.new
    n = nil
    begin
      n = self.readonly.find_by_node_x_coord_and_node_y_coord x, y
      if n.blank?
        return nil
      end
      acl[:spin_uid_access_right] = (n[:spin_uid] == uid ? n[:spin_uid_access_right] : ACL_NODE_NO_ACCESS)
      acl[:spin_gid_access_right] = (n[:spin_gid] == gid ? n[:spin_gid_access_right] : ACL_NODE_NO_ACCESS)
      acl[:spin_world_access_right] = n[:spin_world_access_right]
    rescue ActiveRecord::RecordNotFound
      return nil
    end

    # does this user has superuser priviledge?
    owner_id = n[:spin_uid]
    if uid == owner_id
      acl[:spin_uid_access_right] = ACL_DEFAULT_UID_ACCESS_RIGHT
      acl[:spin_gid_access_right] = (n[:spin_gid] == gid ? n[:spin_gid_access_right] : ACL_NODE_NO_ACCESS)
      acl[:spin_world_access_right] = n[:spin_world_access_right]
      return acl
    end # => end of if su check block

    # pp "n = ",n
    # 
    # retreive access rights fr4om spin_access_controls
    u_acls = SpinAccessControl.readonly.where :managed_node_hashkey => n[:spin_node_hashkey], :spin_uid => uid
    if u_acls.length > 0
      u_acls.each {|ua|
        acl[:spin_uid_access_right] |= ua[:spin_uid_access_right]
      }
    end

    # get parent gid's
    #    spin_user_obj = SpinUser.find_by_spin_uid uid
    #    my_gid = spin_user_obj[:spin_gid]

    gids = SpinGroupMember.get_parent_gids(gid)
    #    gids += [ gid ]

    gids.each {|g|
      g_acls = SpinAccessControl.readonly.where :managed_node_hashkey => n[:spin_node_hashkey], :spin_gid => g
      if g_acls.length > 0
        g_acls.each {|ga|
          acl[:spin_gid_access_right] |= ga[:spin_gid_access_right]
        }
      end
    }

    # return access rights      
    return acl
  end

  # Sould be called in a transaction!
  def self.get_spin_vfs_id x, y
    # get node(x,y)
    n = nil
    if x < 0
      x = 0
    end
    if y < 0
      y = 0
    end
    acl = Hash.new
    n = nil
    begin
      n = self.readonly.find_by_node_x_coord_and_node_y_coord(x, y)
      if n.blank?
        return nil
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    end
    return n[:spin_vfs_id]
  end

  # Sould be called in a transaction!
  def self.get_spin_storage_id x, y
    # get node(x,y)
    n = nil
    if x < 0
      x = 0
    end
    if y < 0
      y = 0
    end
    acl = Hash.new
    #      n = self.readonly.find_by_node_x_coord_and_node_y_coord x, y
    n = nil
    begin
      n = self.readonly.find_by_node_x_coord_and_node_y_coord(x, y)
      if n.blank?
        return nil
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    end
    return n[:spin_storage_id]
  end

  # Sould be called in a transaction!
  def self.get_current_spin_storage_id vfs_id
    n = nil
    begin
      n = SpinVfsStorageMapping.readonly.find_by_spin_vfs(vfs_id)
      if n.blank?
        return nil
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    end
    return n[:spin_storage]
  end

  def self.get_current_spin_vfs_id
    n = nil
    begin
      n = SpinVirtualFileSystem.readonly.find_by_is_default true
      if n.blank?
        return nil
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    end
    return n[:spin_vfs_id]
  end

  # Sould be called in a transaction!
  def self.get_spin_node_tree x, y
    # get node(x,y)
    n = nil
    if x < 0
      x = 0
    end
    if y < 0
      y = 0
    end
    begin
      n = self.readonly.find_by_node_x_coord_and_node_y_coord_and_is_pending_and_in_trash_flag_and_is_void(x, y, false, false, false)
      if n.blank?
        return nil
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    end
    return n[:spin_node_tree]
  end

  def self.get_thumbnail_key node_key
    n = nil
    begin
      n = self.readonly.find_by_spin_node_hashkey(node_key)
      if n.blank?
        return nil
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    end
    nt = nil
    begin
      nt = self.readonly.find_by_spin_tree_type_and_node_x_coord_and_node_y_coord_and_node_version(SPIN_THUMBNAIL_VTREE, n[:node_x_coord], n[:node_y_coord], n[:node_version])
      if nt.blank?
        return nil
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    end
    return nt[:spin_node_hashkey]
  end

  def self.get_spin_tree_type node_key
    n = nil
    begin
      n = self.readonly.find_by_spin_node_hashkey(node_key)
      if n.blank?
        return nil
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    end
    return n[:spin_tree_type]
  end

  def self.get_thumbnail_node node_key
    n = nil
    begin
      n = self.readonly.find_by_spin_node_hashkey(node_key)
    rescue ActiveRecord::RecordNotFound
      return nil
    end
    if n.blank?
      return nil
    end
    nt = nil
    begin
      nt = self.readonly.find_by_spin_tree_type_and_node_x_coord_and_node_y_coord_and_node_version(SPIN_THUMBNAIL_VTREE, n[:node_x_coord], n[:node_y_coord], n[:node_version])
    rescue ActiveRecord::RecordNotFound
      return nil
    end
    if nt.blank?
      return nil
    end

    return nt
  end

  # Sould be called in a transaction!
  def self.get_max_versions x, y
    # get node(x,y)
    n = nil
    if x < 0
      x = 0
    end
    if y < 0
      y = 0
    end
    begin
      n = self.readonly.select("max_versions").find_by_node_x_coord_and_node_y_coord(x, y)
      if n.blank?
        return nil
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    end
    return n[:max_versions]
  end

  def self.get_virtual_path node_key
    begin
      nk = self.readonly.select("virtual_path").find_by_spin_node_hashkey(node_key)
      if nk.blank?
        return nil
      end
      return nk[:virtual_path]
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  def self.get_virtual_path_by_location node_loc
    begin
      nk = self.readonly.select("virtual_path").find_by_node_x_coord_and_node_y_coord_and_node_x_pr_coord_and_node_version(node_loc[:X], node_loc[:Y], node_loc[:PRX], node_loc[:V])
      if nk.blank?
        return nil
      end
      return nk[:virtual_path]
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  def self.rename_node sid, node_key, new_name
    retb = false
    #    ActiveRecord::Base.lock_optimistically = false
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      target_node = nil
      begin
        target_node = self.find_by_spin_node_hashkey node_key
        if target_node.blank?
          return false
        end
        target_node[:node_name] = new_name
        vp = target_node[:virtual_path]
        fnindex = vp.rindex('/')
        newvp = vp[0..fnindex] + new_name
        target_node[:virtual_path] = newvp
        #      ctime = Time.now
        #      target_node[:spin_updated_at] = ctime
        #      target_node[:ctime] = ctime
        if target_node.save
          SpinNode.has_updated(sid, node_key)
          # => set spin_updated_at of the parent node
          pnode = SpinLocationManager.location_to_key [target_node[:node_x_pr_coord], target_node[:node_y_coord] - 1, ANY_PRX, ANY_VERSION]
          self.has_updated sid, pnode
          fnodes = FolderDatum.where :session_id => sid, :spin_node_hashkey => node_key
          fnodes.each {|fn|
            fn[:text] = new_name
            fn[:folder_name] = new_name
            fn.save
          }
          locations = CONT_LOCATIONS_LIST
          locations.each {|location|
            if location == locations[0]
              reth = FolderDatum.fill_folders(sid, location, nil, nil, PROCESS_FOR_UNIVERSAL_REQUEST, false, 1)
            else
              reth = FolderDatum.copy_folder_data_from_location_to_location sid, locations[0], location
            end
          }
          #        FolderDatum.has_updated sid, pnode, true
          DomainDatum.set_domains_dirty_by_key(node_key)
          retb = true
        else
          retb = false
        end
      rescue ActiveRecord::RecordNotFound
        return false
      end
    end
  end

  # => end of self.rename_node node_key, new_name

  def self.set_node_in_trash(sid, target_node)
    #    ActiveRecord::Base.lock_optimistically = false
    catch(:set_node_in_trash_again) {
      self.transaction do
        begin
          uid = SessionManager.get_uid(sid, true)
          target_node[:in_trash_flag] = true
          target_node[:is_pending] = false
          target_node[:changed_by] = uid
          if target_node.save
            return true
          end
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :set_node_in_trash_again
        end
      end # => end of transsaction
    }
  end

  def self.set_node_is_void vn
    #    ActiveRecord::Base.lock_optimistically = false
    catch(:set_node_is_void_again) {
      self.transaction do
        begin
          vn[:is_void] = true
          vn[:spin_updated_at] = Time.now
          vn.save
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :set_node_is_void_again
        end
      end # => end of transaction
    }
    retk = SpinNodeKeeper.delete_node_keeper_record(vn[:node_x_coord], vn[:node_y_coord], vn[:node_version])
    return retk
  end

  # => end of self.set_void node_key

  def self.set_void node_key
    #    ActiveRecord::Base.lock_optimistically = false
    vn = nil
    catch(:set_void_again) {
      self.transaction do
        begin
          vn = self.find_by_spin_node_hashkey node_key
          if vn.blank?
            return false
          end
          vn[:is_void] = true
          vn[:spin_updated_at] = Time.now
          vn.save
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :set_void_again
        end
      end # => end of transaction
    }
    retk = SpinNodeKeeper.delete_node_keeper_record(vn[:node_x_coord], vn[:node_y_coord], vn[:node_version])
    return retk
  end

  # => end of self.set_void node_key

  def self.set_pending node_key, bval = true
    vn = nil
    begin
      vn = self.find_by_spin_node_hashkey node_key
      if vn.blank?
        return false
      end
      #      ActiveRecord::Base.lock_optimistically = false
      self.transaction do
        begin
          vn[:is_pending] = bval
          if vn.save
            # delete from folder_data
            if vn[:node_type] == NODE_DIRECTORY
              delquery = sprintf("DELETE FROM folder_data WHERE spin_node_hashkey = \'%s\';", node_key)
              FolderDatum.find_by_sql(delquery)
            else
              delquery = sprintf("DELETE FROM file_data WHERE spin_node_hashkey = \'%s\';", node_key)
              FileDatum.find_by_sql(delquery)
            end
            Rails.logger.warn(">> thread_delete_folder : call set_pending 1 ok")
            return true
          end
        rescue ActiveRecord::StaleObjectError
          Rails.logger.warn(">> thread_delete_folder : ActiveRecord::StaleObjectError")
          return true
        end
      end # => end of transaction
    rescue ActiveRecord::RecordNotFound
      return false
    end
    Rails.logger.warn(">> thread_delete_folder : call set_pending 1 NG")
    return false
  end

  # => end of self.set_void node_key

  def self.set_pending_all node_key, bval = true, transaction_size = DEFAULT_TRANSACTION_UNIT_NUMBER
    vn = self.find_by_spin_node_hashkey node_key
    if vn.blank?
      return -1
    end
    vp = vn[:virtual_path]
    bval_s = (bval == true ? "true" : "false")
    cquery0 = sprintf("SELECT count(*) FROM spin_nodes WHERE (virtual_path = \'%s\' OR left(virtual_path,%d) = \'%s/\') AND spin_tree_type = %d AND in_trash_flag = false AND is_void = false AND orphan = false;", vp.gsub(/\'/, '\'\''), vp.length + 1, vp.gsub(/\'/, '\'\''), SPIN_NODE_VTREE)
    ret_count = self.find_by_sql(cquery0)
    target_count = -1
    if ret_count.length > 0
      target_count = ret_count[0]['count'].to_i
    end

    vpquery = ""
    loops = target_count.div(transaction_size)
    rem_loops = target_count.modulo(transaction_size)
    if rem_loops > 0
      loops += 1
    end

    #    ActiveRecord::Base.lock_optimistically = false
    self.transaction do
      1.upto(loops) {|i|

        begin
          vpquery_u = sprintf("UPDATE spin_nodes SET is_pending = %s WHERE id IN (SELECT id FROM spin_nodes WHERE is_pending <> %s AND (virtual_path = \'%s\' OR left(virtual_path,%d) = \'%s/\') AND spin_tree_type = %d AND in_trash_flag = false AND is_void = false AND orphan = false LIMIT %d);", bval_s, bval_s, vp.gsub(/\'/, '\'\''), vp.length + 1, vp.gsub(/\'/, '\'\''), SPIN_NODE_VTREE, transaction_size)
          self.find_by_sql(vpquery_u)
        rescue ActiveRecord::StaleObjectError
        end

      }

    end # => end of transaction

    return target_count
  end

  # => end of self.set_void node_key

  def self.set_active node_key
    #    ActiveRecord::Base.lock_optimistically = false
    catch(:set_active_again) {
      self.transaction do
        begin
          vn = nil
          begin
            vn = self.find_by_spin_node_hashkey node_key
            if vn.present?
              vn[:is_pending] = false
              vn[:in_trash_flag] = false
              vn[:is_void] = false
              vn.save
            end
          rescue ActiveRecord::StaleObjectError
            sleep(AR_RETRY_WAIT_MSEC)
            throw :set_active_again
          end
        rescue ActiveRecord::RecordNotFound
          return nil
        end
      end # => end of transaction
    }
  end

  # => end of self.set_void node_key

  def self.set_sticky sid, node_hash_key, uid = ANY_UID
    my_uid = SessionManager.get_uid(sid, true)

    # Are you superuser or owner?
    unless uid == ANY_UID # => ANY_UID means that it isn't specified  by the caller
      unless uid == my_uid or my_uid == ROOT_USER_ID
        return false
      end
    end

    ret = true
    #    ActiveRecord::Base.lock_optimistically = false
    catch(:set_sticky_again) {

      self.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')

        begin
          n = nil
          begin
            n = self.find_by_spin_node_hashkey node_hash_key
            if n.blank?
              return false
            end
          rescue ActiveRecord::RecordNotFound
            return false
          end

          unless n[:spin_uid] == uid or n[:spin_uid] == ROOT_USER_ID
            return false
          end

          # make it stick!
          n[:is_sticky] = true
          if n.save
            ret = true
          end
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :set_sticky_again
        end

      end
    }

    return ret
  end

  # => end of set_sticky my_session_id, user_record[:spin_uid], u[:spin_login_directory]

  def self.reset_sticky sid, node_hash_key, uid = ANY_UID
    my_uid = SessionManager.get_uid(sid, true)

    # Are you superuser or owner?
    unless uid == ANY_UID # => ANY_UID means that it isn't specified  by the caller
      unless uid == my_uid or my_uid == ROOT_USER_ID
        return false
      end
    end

    ret = false
    #    ActiveRecord::Base.lock_optimistically = false
    catch(:reset_sticky_again) {

      self.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        begin
          n = nil
          begin
            n = self.find_by_spin_node_hashkey node_hash_key
            if n.blank?
              return false
            end
          rescue ActiveRecord::RecordNotFound
            return false
          end

          unless n[:spin_uid] == uid or n[:spin_uid] == ROOT_USER_ID
            return false
          end

          # make it stick!
          n[:is_sticky] = false
          if n.save
            ret = true
          end
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :reset_sticky_again
        end
      end
    }

    return ret
  end

  # => end of set_sticky my_session_id, user_record[:spin_uid], u[:spin_login_directory]

  def self.set_sticky_gid_bit sid, gid, node_hash_key
    ids = SessionManager.get_uid_gid(sid, true)
    my_uid = ids[:uid]
    my_gid = ids[:gid]

    # Are you superuser or owner?
    if gid != my_gid or my_gid != 0
      return false
    end

    catch(:set_sticky_gid_bit_again) {

      #    ActiveRecord::Base.lock_optimistically = false
      self.transaction do

        begin
          n = nil
          begin
            n = self.find_by_spin_node_hashkey node_hash_key
            if n.blank?
              return false
            end
          rescue ActiveRecord::RecordNotFound
            return false
          end

          # make it sticky!
          n[:is_stick] = true
          if n.save
            return true
          else
            return false
          end
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :set_sticky_gid_bit_again
        end
      end # => end of transaction
    }
  end

  # => end of set_sticky my_session_id, user_record[:spin_uid], u[:spin_login_directory]

  def self.set_sticky_uid_bit sid, uid, node_hash_key
    my_uid = SessionManager.get_uid(sid, true)

    # Are you superuser or owner?
    if uid != my_uid or my_uid != 0
      return false
    end
    catch(:set_sticky_gid_bit_again) {
      self.transaction do
        begin
          n = nil
          begin
            n = self.find_by_spin_node_hashkey node_hash_key
            if n.blank?
              return false
            end
          rescue ActiveRecord::RecordNotFound
            return false
          end

          #    ActiveRecord::Base.lock_optimistically = false
          # make it stick!
          n[:is_stick] = true
          if n.save
            return true
          else
            return false
          end
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :set_sticky_gid_bit_again
        end
      end # => end of transaction
    }
  end

  # => end of set_sticky my_session_id, user_record[:spin_uid], u[:spin_login_directory]

  def self.set_lock user_id, folder_hash_key, file_name, session_id, spin_node_upd
    catch(:set_lock_again) {
      self.transaction do
        begin
          nodes = DatabaseUtility::VirtualFileSystemUtility.search_virtual_file session_id, file_name, folder_hash_key, ANY_VALUE, ANY_VALUE, SEARCH_EXISTING_VFILE
          if nodes.blank?
            return false
          end
          node = nodes[0]
          lock_uid = node[:lock_uid]
          if !(lock_uid != -1 && lock_uid != user_id)
            # 第三老E��ロチE��されてぁE��ぁE��合�Eみ更新
            node[:lock_uid] = spin_node_upd[:upd_lock_uid]
            node[:lock_status] = spin_node_upd[:upd_lock_status]
            node[:lock_mode] = spin_node_upd[:upd_lock_mode]
            if node.save
              return true
            end
          end
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :set_lock_again
        end
      end # => end of transaction
    }
    return false
  end

  # =>  end of set_lock user_id, folder_hash_key, file_name, session_id, spin_node_upd

  def self.set_lock2 session_id, node_key, spin_node_upd
    #       lock_ret = SpinNode.set_lock2 my_session_id, lock_file_hash_key, spin_node_upd
    user_id = SessionManager.get_uid session_id
    catch(:set_lock_again) {
      self.transaction do
        begin
          node = nil
          begin
            node = self.find_by_spin_node_hashkey node_key
            if node.blank?
              return false
            end
          rescue ActiveRecord::RecordNotFound
            return false
          end
          lock_uid = node[:lock_uid]
          if !(lock_uid != -1 && lock_uid != user_id)
            # 第三老E��ロチE��されてぁE��ぁE��合�Eみ更新
            node[:lock_uid] = user_id
            node[:lock_status] = spin_node_upd[:upd_lock_status]
            node[:lock_mode] = spin_node_upd[:upd_lock_mode]
            if node.save
              return true
            end
          end
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :set_lock_again
        end
      end # => end of transaction
    }
    return false
  end

  # =>  end of set_lock user_id, folder_hash_key, file_name, session_id, spin_node_upd
  # 追加 ↁE
  def self.clear_lock node_hash_key
    # clear lock to node
    #    ActiveRecord::Base.lock_optimistically = false
    catch(:clear_lock_again) {
      self.transaction do
        begin
          node = nil
          begin
            node = self.find_by_spin_node_hashkey node_hash_key
            if node.blank?
              return false
            end
          rescue ActiveRecord::RecordNotFound
            return false
          end
          # ロチE��状態を初期値に更新
          node[:lock_uid] = -1
          node[:lock_status] = 0
          node[:lock_mode] = 0
          if node.save
            return true
          end
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :clear_lock_again
        end
      end # => end of transaction
    }
    return false
  end

  # =>  end of clear_lock node_hash_key
  # 追加 ↁE

  def self.get_archived_folder offset, limit
    if offset != 0 && limit != 'total'
      archived_folder_list = self.limit(limit).offset(offset).where(["is_archive = true AND in_trash_flag => false"]).order("node_name ASC")
    else
      archived_folder_list = self.where(["is_archive = true AND in_trash_flag = false"]).order("node_name ASC")
    end
    return archived_folder_list
  end

  #アーカイブ済みフォルダ取得

  def self.get_synced_folder offset, limit
    if offset != 0 && limit != 'total'
      synced_folder_list = self.limit(limit).offset(offset).where(:is_synchronized => true, :in_trash_flag => false).order("node_name ASC")
      synced_folder_list = self.limit(limit).offset(offset).where(["is_synchronized = true AND in_trash_flag = false"]).order("node_name ASC")
    else
      synced_folder_list = self.where(["is_synchronized = true AND in_trash_flag = false"]).order("node_name ASC")
    end
    return synced_folder_list
  end #同期済みフォルダ取得

end # => end of SpinNode

