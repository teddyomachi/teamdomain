# coding: utf-8
require 'const/vfs_const'
require 'const/acl_const'
require 'const/spin_types'
require 'utilities/set_utilities'

class SpinAccessControl < ActiveRecord::Base
  include Vfs
  include Acl
  include Types

  ID_NOT_SET = -1
  # # constants internal
  # X = 0         # => position of X coordinate value 
  # Y = 1         # => position of Y coordinate value
  # PRX = 2       # => position of prX coordinate value
  # V = 3         # => position of V coordinate value
  # HASHKEY = 4   # => spin_node_hashkey
  #     
  # # node value indicates no directory
  # [-1,-1,-1,-1,nil] = [-1,-1,-1,-1,nil]

  # for test
  # ADMIN_SESSION_ID = "_special_administrator_session"

  # # flag to indicate that it is a hard link
  # LINKED_NODE_FLAG = 32768      # => 17th bit is 1 
  #   
  # attr_accessor :title, :body
  attr_accessor :spin_node_hashkey, :spin_uid, :spin_uid_access_right, :spin_gid, :managed_node_hashkey, :created_at, :updated_at, :spin_node_type

  def self.set_folder_privilege sid, privileges, groups, target_node_key = nil
    #      privileges[:folder_name] = paramshash[:text]
    #      privileges[:folder_hashkey] = paramshash[:hash_key]
    #      privileges[:target] = paramshash[:target]
    #      privileges[:range] = paramshash[:range]
    #      privileges[:owner] = paramshash[:owner]
    #      privileges[:owner_right] = paramshash[:data][:owner_right]
    #      privileges[:other_writable] = paramshash[:other_writable] # => boolean
    #      privileges[:other_readable] = paramshash[:other_readable] # => boolean
    #      privileges[:group_writable] = paramshash[:group_writable] # => boolean
    #      privileges[:group_readable] = paramshash[:group_readable] # => boolean
    #      privileges[:control_right] = paramshash[:control_right] # => boolean
    # set privilege to nodes and access controls for each group
    #     groups == members from JS
    #groups[0][:member_id] = uid ? gidのどちらか・・・

    recs = 0
    node = {}
    node_key = nil
    uacl = ACL_DEFAULT_UID_ACCESS_RIGHT
    gacl = ACL_DEFAULT_GID_ACCESS_RIGHT
    wacl = ACL_DEFAULT_WORLD_ACCESS_RIGHT
    spin_uid_access_right = ACL_DEFAULT_UID_ACCESS_RIGHT
    spin_gid_access_right = ACL_DEFAULT_GID_ACCESS_RIGHT
    spin_world_access_right = ACL_DEFAULT_WORLD_ACCESS_RIGHT

    if target_node_key == nil # => call from request broker
      node_key = privileges[:folder_hashkey]
    else # => recursive call
      node_key = target_node_key
    end

    retry_save = ACTIVE_RECORD_RETRY_COUNT

    catch(:set_folder_privilege_again) {

      SpinNode.transaction do
        begin
          uacl = (privileges[:owner_right] == 'full' ? ACL_NODE_FULL_ACCESS : ACL_NODE_READ)
          gacl = ((privileges[:group_readable] ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (privileges[:group_writable] ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS) | (privileges[:control_right] ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
          wacl = ((privileges[:other_readable] ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (privileges[:other_writable] ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS))
          nrecs = 0
          if self.is_controlable sid, node_key, NODE_DIRECTORY
            nrecs = SpinNode.where(spin_node_hashkey: node_key).update_all(spin_uid_access_right: uacl, spin_gid_access_right: gacl, spin_world_access_right: wacl)
          else
            nrecs = SpinNode.where(spin_node_hashkey: node_key).update_all(spin_uid_access_right: uacl, spin_world_access_right: wacl)
          end
          if nrecs != 1
            return -1
          end
        rescue ActiveRecord::StaleObjectError
          if retry_save > 0
            retry_save -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :set_folder_privilege_again
          else
            return -1
          end
        end
      end
    }

    #    return 1
    #  end

    self.set_groups_access_control gacl, node_key, groups, privileges
    # check range
    my_file_list = []

    case privileges[:range]
    when 'all_folders' # => this and sub folders
      case privileges[:target]
      when 'file'
        retry_save = ACTIVE_RECORD_RETRY_COUNT
        catch(:target_all_folders_file_again) {
          my_file_list = SpinNode.get_active_children sid, node_key, NODE_FILE
          SpinNode.transaction do
            begin
              my_file_list.each {|f|
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                nrecs = SpinNode.where(spin_node_hashkey: f['spin_node_hashkey']).update_all(spin_uid_access_right: uacl, spin_gid_access_right: gacl, spin_world_access_right: wacl)
                if nrecs != 1
                  next
                end
                recs += self.set_groups_access_control gacl, f['spin_node_hashkey'], groups, privileges
              }
            rescue ActiveRecord::StaleObjectError
              if retry_save > 0
                retry_save -= 1
                throw :target_all_folders_file_again
              else
                next
              end
            end
          end
        }
      when 'folder'
        my_file_list = SpinNode.get_active_children sid, node_key, NODE_DIRECTORY
        my_file_list.each {|f|
          next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
          recs += self.set_folder_privilege sid, privileges, groups, f['spin_node_hashkey']
        }
      when 'folder_file'
        my_file_list = SpinNode.get_active_children sid, node_key, ANY_TYPE
        retry_save = ACTIVE_RECORD_RETRY_COUNT
        catch(:target_all_folders_folder_file_again) {
          SpinNode.transaction do
            begin
              my_file_list.each {|f|
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                if f['node_type'].to_i == NODE_FILE
                  fn = SpinNode.find_by(spin_node_hashkey: f['spin_node_hashkey'])
                  if fn.blank?
                    next
                  end
                  nrecs = SpinNode.where(spin_node_hashkey: f['spin_node_hashkey']).update_all(spin_uid_access_right: uacl, spin_gid_access_right: gacl, spin_world_access_right: wacl)
                  if nrecs != 1
                    next
                  end
                  #定義との差異があったため、privilegesを追加 2015/11/16
                  recs += self.set_groups_access_control gacl, f['spin_node_hashkey'], groups, privileges
                else
                  recs += self.set_folder_privilege sid, privileges, groups, f['spin_node_hashkey']
                end
              }
            rescue ActiveRecord::StaleObjectError
              if retry_save > 0
                retry_save -= 1
                throw :target_all_folders_folder_file_again
              else
                next
              end
            end
          end # => end of transaction
        }
      end # => end of case : target

    when 'folder'
      case privileges[:target]
      when 'file'
        my_file_list = SpinNode.get_active_children sid, node_key, NODE_FILE
        retry_save = ACTIVE_RECORD_RETRY_COUNT
        catch(:target_folder_file_again) {
          SpinNode.transaction do
            begin
              my_file_list.each {|f|
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                nrecs = SpinNode.where(spin_node_hashkey: f['spin_node_hashkey']).update_all(spin_uid_access_right: uacl, spin_gid_access_right: gacl, spin_world_access_right: wacl)
                if nrecs != 1
                  next
                end
                recs += self.set_groups_access_control gacl, f['spin_node_hashkey'], groups, privileges
              }
            rescue ActiveRecord::StaleObjectError
              if retry_save > 0
                retry_save -= 1
                throw :target_folder_file_again
              else
                next
              end
            end
          end # => end of transaction
        }
      when 'folder'
        pp 'NOP'
      when 'folder_file'
        my_file_list = SpinNode.get_active_children sid, node_key, ANY_TYPE
        retry_save = ACTIVE_RECORD_RETRY_COUNT
        catch(:target_folder_folder_file_again) {
          SpinNode.transaction do
            begin
              my_file_list.each {|f|
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                nrecs = SpinNode.where(spin_node_hashkey: f['spin_node_hashkey']).update_all(spin_uid_access_right: uacl, spin_gid_access_right: gacl, spin_world_access_right: wacl)
                if nrecs != 1
                  next
                end
                recs += self.set_groups_access_control gacl, f['spin_node_hashkey'], groups, privileges
              }
            rescue ActiveRecord::StaleObjectError
              if retry_save > 0
                retry_save -= 1
                throw :target_folder_folder_file_again
              else
                next
              end
            end
          end # => end of transaction
        }
      end # => end of case : target

    end # => end of case : range

    node = SpinNode.find_by(spin_node_hashkey: node_key)
    pn = SpinLocationManager.get_parent_node(node)
    pkey = pn[:spin_node_hashkey]
    SpinNode.has_updated(sid, pkey)
    return recs
  end

  # =>  end of set_privilege privileges

  def self.set_file_privilege sid, privileges, groups
    #      privileges[:folder_name] = paramshash[:text]
    #      privileges[:folder_hashkey] = paramshash[:hash_key]
    #      privileges[:target] = paramshash[:target]
    #      privileges[:range] = paramshash[:range]
    #      privileges[:owner] = paramshash[:owner]
    #      privileges[:other_writable] = paramshash[:other_writable] # => boolean
    #      privileges[:other_readable] = paramshash[:other_readable] # => boolean
    #      privileges[:group_writable] = paramshash[:group_writable] # => boolean
    #      privileges[:group_readable] = paramshash[:group_readable] # => boolean
    #      privileges[:control_right] = paramshash[:control_right] # => boolean
    # set privilege to nodes and access controls for each group
    recs = 0
    uacl = ACL_DEFAULT_UID_ACCESS_RIGHT
    gacl = ACL_DEFAULT_GID_ACCESS_RIGHT
    wacl = ACL_DEFAULT_WORLD_ACCESS_RIGHT
    FileDatum.set_selected(sid, privileges[:file_hashkey], privileges[:cont_location])

    retry_save = ACTIVE_RECORD_RETRY_COUNT

    catch(:set_file_privileges_again) {

      self.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        begin
          node = SpinNode.find_by_spin_node_hashkey privileges[:file_hashkey]
          if node.blank?
            return recs
          end
          uacl = ((privileges[:owner_right].present? && privileges[:owner_right] == 'full') ? ACL_NODE_FULL_ACCESS : ACL_NODE_READ)
          gacl = (((privileges[:group_readable].present? && privileges[:group_readable]) ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | ((privileges[:group_writable].present? && privileges[:group_writable]) ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS) | ((privileges[:control_right].present? && privileges[:control_right]) ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
          wacl = (((privileges[:other_readable].present? && privileges[:other_readable]) ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | ((privileges[:other_writable].present? & privileges[:other_writable]) ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS))
          node[:spin_uid_access_right] = uacl
          node[:spin_world_access_right] = wacl
          if self.is_controlable sid, node[:spin_node_hashkey], NODE_DIRECTORY
            node[:spin_gid_access_right] = gacl
          end
          node.save
        rescue ActiveRecord::StaleObjectError
          if retry_save > 0
            eretry_save -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :set_file_privileges_again
          end
        end
      end
    }
    recs += 1
    recs += self.set_groups_access_control gacl, privileges[:file_hashkey], groups, privileges
    FolderDatum.has_updated_to_parent(sid, privileges[:file_hashkey], NEW_CHILD, false)
    SpinNode.has_updated(sid, SpinLocationManager.get_parent_key(privileges[:file_hashkey], ANY_TYPE))
    return recs

  end

  # =>  end of set_privilege privileges

  def self.add_user_access_control node_hashkey, user_acl, spin_uid
    # first : get record which has spin_uid value
    my_acl = SpinAccessControl.where :spin_uid => spin_uid
    if my_acl.count > 0
      catch(:add_user_access_control_again) {
        self.transaction do
          # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
          my_acl.each {|a|
            begin
              a[:spin_uid_access_right] = user_acl
              a.save
            rescue ActiveRecord::StaleObjectError
              sleep(AR_RETRY_WAIT_MSEC)
              throw :add_user_access_control_again
            end
          }
        end
      }
      return true
    end

    # get records which has not used spin_uid(-1) field
    no_user_acl = SpinAccessControl.where :spin_uid => ID_NOT_SET
    if no_user_acl.count > 0
      catch(:add_user_access_control_again2) {

        self.transaction do
          # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
          no_user_acl.each {|a|
            begin
              a[:spin_uid] = spin_uid
              a[:spin_uid_access_right] = user_acl
              a[:updated_at] = Time.now
              a.save
              break
            rescue ActiveRecord::StaleObjectError
              sleep(AR_RETRY_WAIT_MSEC)
              throw :add_user_access_control_again2
            end
          }
        end
      }
      return true
    end

    # create new record
    # set spin_access_contrtol
    catch(:add_user_access_control_again3) {

      self.transaction do
        begin
          # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
          new_acl = SpinAccessControl.new
          new_acl[:spin_uid] = spin_uid
          new_acl[:spin_uid_access_right] = user_acl
          new_acl[:spin_world_access_right] = ACL_NODE_NO_ACCESS
          r = Random.new
          new_acl[:spin_node_hashkey] = Security.hash_key_s node_hashkey + r.rand.to_s
          new_acl[:managed_node_hashkey] = node_hashkey
          new_acl[:created_at] = Time.now
          new_acl[:updated_at] = Time.now
          new_acl.save
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :add_user_access_control_again3
        end
      end
    }
    return true
  end

  def self.add_groups_access_control sid, node_hashkey, gacl, groups, managed_node_type
    # first : get record which has spin_gid values
    acl_records = 0

    catch(:add_groups_access_control_again) {
      self.transaction do
        #        domain_hashkey = ""  #20161111 T2L ADD
        #        if (managed_node_type == 32768)
        #          domain_hashkey = node_hashkey
        #          spin_domain_rec = SpinDomain.readonly.find_by_hash_key node_hashkey
        #          node_hashkey = spin_domain_rec[:domain_root_node_hashkey]
        #        end #20161111 T2L ADD
        managed_node = SpinNode.find_by_spin_node_hashkey node_hashkey
        if managed_node.blank?
          return acl_records
        end
        px = managed_node[:node_x_coord]
        py = managed_node[:node_y_coord]
        ppx = managed_node[:node_x_pr_coord]
        node_type = (managed_node_type.present? ? managed_node_type : managed_node[:node_type])
        # for groups in array 'groups'
        groups.each {|g|
          begin
            # analyze group
            # it may be a member of the group
            # we use member's primary group ( group assigned at user registration ) if it is
            my_acl_local = nil
            my_group = nil
            primary_group = -1
            if g[:member_id].present?
              primary_group = SpinUser.get_primary_group g[:member_id]
              self.transaction do
                # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
                sql = "SELECT * FROM spin_access_controls WHERE spin_gid = " + primary_group.to_s + " AND managed_node_hashkey = '" + node_hashkey + "' limit 1;";
                temp = SpinAccessControl.find_by_sql(sql);
                if temp.present?
                  my_acl_local = temp[0];
                end
                #my_acl_local = SpinAccessControl.where( :spin_gid => primary_group,:managed_node_hashkey => node_hashkey ).first
              end
            else
              self.transaction do
                # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
                my_group = SpinGroup.select("spin_gid").where(["spin_group_name = ?", g[:group_name]]).first
                #                my_group = SpinGroup.select("spin_gid").where(:spin_group_name => g[:group_name]).first
                my_acl_local = SpinAccessControl.where(["spin_gid = ? AND managed_node_hashkey = ?", my_group[:spin_gid], node_hashkey]).first
              end
            end
            #if my_acl_local and my_acl_local.size() > 0
            if (my_acl_local.present?)
              #エラー発生のためコメントアウト
              #              gacl_str = g[:group_privilege]
              #              gacl = ((gacl_str[0] == 'r' ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (gacl_str[1] == 'w' ? ACL_NODE_WRITE : ACL_NODE_NO_ACCESS) | (gacl_str[2] == 'a' ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
              my_acl_local.each {|ma|
                gacl |= ma[:spin_gid_access_right]
                ma[:px] = px
                ma[:py] = py
                ma[:ppx] = ppx
                ma.save
              }
              my_acl_local[:spin_gid_access_right] |= gacl

              #              #一時的な動作確保のためのコード
              #              #ここから
              #              my_acl_local[:spin_gid_access_right] = gacl
              #              my_acl_local[:spin_gid] = (my_group == nil ? primary_group : my_group[:spin_gid])
              #              my_acl_local[:spin_uid] = ID_NOT_SET
              #              my_acl_local[:px] = px
              #              my_acl_local[:py] = py
              #              my_acl_local[:ppx] = ppx
              #              my_acl_local[:spin_uid_access_right] = ACL_NODE_NO_ACCESS
              #              my_acl_local[:spin_world_access_right] = ACL_NODE_NO_ACCESS
              #              r = Random.new
              #              my_acl_local[:spin_node_hashkey] = Security.hash_key_s node_hashkey + r.rand.to_s
              #              my_acl_local[:managed_node_hashkey] = node_hashkey
              #              my_acl_local[:spin_node_type] = node_type
              #              my_acl_local[:created_at] = Time.now
              #              my_acl_local[:root_node_hashkey] = domain_hashkey #20161111 T2L ADD
              #              if my_acl_local.save
              #                acl_records += 1
              #              end
              #              #ここまで
            else
              # get records which has not used spin_gid(-1) field
              self.transaction do
                # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
                my_acl_local = SpinAccessControl.where(["managed_node_hashkey = ? AND spin_gid = ?", node_hashkey, ID_NOT_SET]).first
                if my_acl_local.present?
                  #                  gacl_str = g[:group_privilege]
                  #                  gacl = ((gacl_str[0] == 'r' ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (gacl_str[1] == 'w' ? ACL_NODE_WRITE : ACL_NODE_NO_ACCESS) | (gacl_str[2] == 'a' ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
                  my_acl_local[:spin_gid_access_right] = gacl
                  my_acl_local[:spin_gid] = my_group[:spin_gid]
                else
                  # create new record
                  my_acl_local = SpinAccessControl.new
                  # set spin_access_contrtol
                  #          gacl_str = g[:group_privilege]
                  #          gacl = ((gacl_str[0] == 'r' ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (gacl_str[1] == 'w' ? ACL_NODE_WRITE : ACL_NODE_NO_ACCESS) | (gacl_str[2] == 'a' ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
                  my_acl_local[:spin_gid_access_right] = gacl
                  my_acl_local[:spin_gid] = (my_group == nil ? primary_group : my_group[:spin_gid])
                  my_acl_local[:spin_uid] = ID_NOT_SET
                  my_acl_local[:px] = px
                  my_acl_local[:py] = py
                  my_acl_local[:ppx] = ppx
                  my_acl_local[:spin_uid_access_right] = ACL_NODE_NO_ACCESS
                  my_acl_local[:spin_world_access_right] = ACL_NODE_NO_ACCESS
                  r = Random.new
                  my_acl_local[:spin_node_hashkey] = Security.hash_key_s node_hashkey + r.rand.to_s
                  my_acl_local[:managed_node_hashkey] = node_hashkey
                  my_acl_local[:spin_node_type] = node_type
                  my_acl_local[:created_at] = Time.now
                  my_acl_local[:updated_at] = Time.now
                  #                  my_acl_local[:root_node_hashkey] = domain_hashkey #20161111 T2L ADD
                end
                if my_acl_local.save
                  acl_records += 1
                end
              end
            end
          rescue ActiveRecord::StaleObjectError
            sleep(AR_RETRY_WAIT_MSEC)
            throw :add_groups_access_control_again
          rescue ActiveRecord::RecordNotFound
            Rails.logger('add_groups_access_control : domain_data record or acl is not found')
          rescue
            Rails.logger('add_groups_access_control : exception')
          end
        } # => end of group   
      end
    }

    FolderDatum.has_updated(sid, node_hashkey, NEW_CHILD, false)
    return acl_records
  end

  # => end of add_groups_access_control node_hashkey, groups

  #  def self.add_groups_access_control gacl, node_hashkey, groups
  #    # first : get record which has spin_gid values
  #    acl_records = 0
  #    # for groups in array 'groups'
  #    groups.each {|g|
  #      # analyze group
  #      # it may be a member of the group
  #      # we use member's primary group ( group assigned at user registration ) if it is
  #      my_acl = nil
  #      my_group = nil
  #      primary_group = -1
  #      if g[:member_id] != nil
  #        primary_group = SpinUser.get_primary_group g[:member_id]
  #        my_acl = SpinAccessControl.where( :spin_gid => primary_group,:managed_node_hashkey => node_hashkey ).first
  #      else
  #        my_group = SpinGroup.select("spin_gid").where(:spin_group_name => g[:group_name]).first
  #        my_acl = SpinAccessControl.where( :spin_gid => my_group[:spin_gid],:managed_node_hashkey => node_hashkey ).first
  #      end
  #      if my_acl
  #        gacl_str = g[:group_privilege]
  #        gacl = ((gacl_str[0] == 'r' ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (gacl_str[1] == 'w' ? ACL_NODE_WRITE : ACL_NODE_NO_ACCESS) | (gacl_str[2] == 'a' ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
  #        my_acl[:spin_gid_access_right] |= gacl
  #      else
  #        # get records which has not used spin_gid(-1) field
  #        my_acl = SpinAccessControl.where( :managed_node_hashkey => node_hashkey, :spin_gid => ID_NOT_SET ).first
  #        if my_acl
  #          gacl_str = g[:group_privilege]
  #          gacl = ((gacl_str[0] == 'r' ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (gacl_str[1] == 'w' ? ACL_NODE_WRITE : ACL_NODE_NO_ACCESS) | (gacl_str[2] == 'a' ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
  #          my_acl[:spin_gid_access_right] = gacl
  #          my_acl[:spin_gid] = my_group[:spin_gid]
  #        else
  #          # create new record
  #          my_acl = SpinAccessControl.new
  #          # set spin_access_contrtol
  ##          gacl_str = g[:group_privilege]
  ##          gacl = ((gacl_str[0] == 'r' ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (gacl_str[1] == 'w' ? ACL_NODE_WRITE : ACL_NODE_NO_ACCESS) | (gacl_str[2] == 'a' ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
  #          my_acl[:spin_gid_access_right] = gacl
  #          my_acl[:spin_gid] = (my_group == nil ? primary_group : my_group[:spin_gid])
  #          my_acl[:spin_uid] = ID_NOT_SET
  #          my_acl[:spin_uid_access_right] = ACL_NODE_NO_ACCESS
  #          my_acl[:spin_world_access_right] = ACL_NODE_NO_ACCESS
  #          my_acl[:spin_node_hashkey] = Security.hash_key_s node_hashkey + r.rand.to_s
  #          my_acl[:managed_node_hashkey] = node_hashkey
  #          my_acl[:created_at] = Time.now
  ##          my_acl[:updated_at] = Time.now
  #        end
  #      end
  #      if my_acl.save
  #        acl_records += 1
  #      end
  #    } # => end of group   
  #    return acl_records
  #  end # => end of add_groups_access_control node_hashkey, groups

  def self.set_groups_access_control gacl, node_hashkey, groups, privileges
    # first : get record which has spin_gid values
    acl_records = 0

    if groups.blank?
      return acl_records
    end

    # get node location
    mnode = SpinNode.find_by(spin_node_hashkey: node_hashkey)
    if mnode.blank?
      return acl_records
    end
    px = mnode[:node_x_coord]
    py = mnode[:node_y_coord]
    ppx = mnode[:node_x_pr_coord]
    node_type = mnode[:node_type]

    retry_set_groups_access_control = ACTIVE_RECORD_RETRY_COUNT
    catch(:set_groups_access_control_again) {
      SpinAccessControl.transaction do
        begin
          # for groups in array 'groups'
          groups.each {|g|
            # analyze group
            # it may be a member of the group
            # we use member's primary group ( group assigned at user registration ) if it is
            my_acl = nil
            my_group = {}
            primary_group = -1
            my_acl_recs = 0
            unless g[:member_id].blank?
              primary_group = g[:member_id].to_i
              my_group[:spin_gid] = primary_group
              my_acl_recs = SpinAccessControl.where(["spin_gid = ? AND managed_node_hashkey = ?", primary_group, node_hashkey]).update_all(
                  spin_gid_access_right: gacl,
                  spin_gid: my_group[:spin_gid],
                  spin_uid_access_right: privileges[:spin_uid_access_right],
                  spin_world_access_right: privileges[:spin_world_access_right]
              )
            else
              my_group = SpinGroup.select("spin_gid").where(["spin_group_name = ?", g[:group_name]]).first
              my_acl_recs = SpinAccessControl.where(["spin_gid = ? AND managed_node_hashkey = ?", my_group[:spin_gid], node_hashkey]).update_all(
                  spin_gid_access_right: gacl,
                  spin_gid: my_group[:spin_gid],
                  spin_uid_access_right: privileges[:spin_uid_access_right],
                  spin_world_access_right: privileges[:spin_world_access_right]
              )
            end

            if my_acl_recs != 1 # no record
              # create new record
              my_new_acl = SpinAccessControl.create {|my_acl|
                my_acl[:spin_gid_access_right] = gacl
                my_acl[:spin_gid] = (my_group == nil ? primary_group : my_group[:spin_gid])
                my_acl[:spin_uid] = ID_NOT_SET
                my_acl[:spin_uid_access_right] = ACL_NODE_NO_ACCESS
                my_acl[:spin_world_access_right] = ACL_NODE_NO_ACCESS
                r = Random.new
                my_acl[:spin_node_hashkey] = Security.hash_key_s node_hashkey + r.rand.to_s
                my_acl[:managed_node_hashkey] = node_hashkey
                my_acl[:spin_node_type] = node_type
                my_acl[:created_at] = Time.now
                my_acl[:px] = px
                my_acl[:py] = py
                my_acl[:ppx] = ppx
              }
            end

            # if my_acl.present?
            #   my_acl[:spin_gid_access_right] = gacl
            #   my_acl[:spin_gid] = my_group[:spin_gid]
            #   my_acl[:spin_uid_access_right] = privileges[:spin_uid_access_right]
            #   my_acl[:spin_world_access_right] = privileges[:spin_world_access_right]
            # else
            #   # create new record
            #   my_acl = SpinAccessControl.new
            #   # set spin_access_contrtol
            #   #          gacl_str = g[:group_privilege]
            #   #          gacl = ((gacl_str[0] == 'r' ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (gacl_str[1] == 'w' ? ACL_NODE_WRITE : ACL_NODE_NO_ACCESS) | (gacl_str[2] == 'a' ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
            #
            #
            #   my_acl[:spin_gid_access_right] = gacl
            #   my_acl[:spin_gid] = (my_group == nil ? primary_group : my_group[:spin_gid])
            #   my_acl[:spin_uid] = ID_NOT_SET
            #   my_acl[:spin_uid_access_right] = ACL_NODE_NO_ACCESS
            #   my_acl[:spin_world_access_right] = ACL_NODE_NO_ACCESS
            #   r = Random.new
            #   my_acl[:spin_node_hashkey] = Security.hash_key_s node_hashkey + r.rand.to_s
            #   my_acl[:managed_node_hashkey] = node_hashkey
            #   my_acl[:spin_node_type] = node_type
            #   my_acl[:created_at] = Time.now
            #   my_acl[:px] = px
            #   my_acl[:py] = py
            #   my_acl[:ppx] = ppx
            #   #          my_acl[:updated_at] = Time.now
            # end
            acl_records += 1
          } # => end of group
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :set_groups_access_control_again
        end
      end
    }
    return acl_records
  end

  # => end of set_groups_access_control node_hashkey, groups

  def self.set_group_access_control node_hashkey, gid, priv
    # first : get record which has spin_gid values
    retry_save = ACTIVE_RECORD_RETRY_COUNT
    catch(:set_group_access_control_again) {

      self.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        my_acl = SpinAccessControl.find_by(spin_gid: gid)
        if my_acl.blank?
          # get records which has not used spin_gid(-1) field
          my_acl = SpinAccessControl.where(["spin_gid = ?", ID_NOT_SET]).first
          if my_acl.blank?
            # create new record
            self.transaction do
              my_acl_rec = SpinAccessControl.create {|my_acl|
                # set spin_access_contrtol
                my_acl[:spin_uid] = ID_NOT_SET
                my_acl[:spin_uid_access_right] = ACL_NODE_NO_ACCESS
                my_acl[:spin_world_access_right] = ACL_NODE_NO_ACCESS
                r = Random.new
                my_acl[:spin_node_hashkey] = Security.hash_key_s node_hashkey + r.rand.to_s
                my_acl[:managed_node_hashkey] = node_hashkey
                my_acl[:created_at] = Time.now
                my_acl[:updated_at] = Time.now
                my_acl[:spin_gid_access_right] = priv
              }
            end
            return true
          else
            begin
              retb = my_acl.update_attribute(spin_gid_access_right: priv)
              unless retb
                return false
              end
            rescue ActiveRecord::StaleObjectError
              if retry_save > 0
                retry_save -= 1
                sleep(AR_RETRY_WAIT_MSEC)
                throw :set_group_access_control_again
              end
            end
          end
        else
          begin
            retb = my_acl.update_attribute(spin_gid_access_right: priv)
            unless retb
              return false
            end
          rescue ActiveRecord::StaleObjectError
            if retry_save > 0
              retry_save -= 1
              sleep(AR_RETRY_WAIT_MSEC)
              throw :set_group_access_control_again
            end
          end
        end
      end
    }
  end

  # => end of set_group_access_control node_hashkey, group

  def self.remove_groups_access_control gacl, node_hashkey, groups
    # first : get record which has spin_gid values
    acl_records = 0
    # for groups in array 'groups'

    retry_remove_groups = ACTIVE_RECORD_RETRY_COUNT
    catch(:remove_groups_access_control_again) {
      SpinAccessControl.transaction do
        begin
          groups.each {|g|
            # analyze group
            # it may be a member of the group
            # we use member's primary group ( group assigned at user registration ) if it is
            my_acls = nil
            my_acls = SpinAccessControl.where(spin_gid: g[:member_id], managed_node_hashkey: node_hashkey)

            my_acls.each {|my_acl|
              if my_acl[:spin_uid] == -1
                my_acl.destroy
                acl_records += 1
              else
                retb = my_acl.update_attribute(spin_gid: -1)
                # my_acls_recs = SpinAccessControl.where(spin_gid: g[:member_id], managed_node_hashkey: node_hashkey).update_all(spin_gid: -1)
                if retb
                  acl_records += 1
                end
              end
            }
            retry_remove_groups = ACTIVE_RECORD_RETRY_COUNT
          } # => end of group
        rescue ActiveRecord::StaleObjectError
          if retry_remove_groups > 0
            retry_remove_groups -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :remove_groups_access_control_again
          end
        end
      end # end of transaction
    }
    return acl_records
  end

  # => end of add_groups_access_control node_hashkey, groups

  def self.remove_folder_privilege sid, privileges, groups, target_node_key = nil
    #      privileges[:folder_name] = paramshash[:text]
    #      privileges[:folder_hashkey] = paramshash[:folder_hashkey]
    #      privileges[:target] = paramshash[:target]
    #      privileges[:range] = paramshash[:range]
    #      privileges[:owner] = paramshash[:owner]
    #      privileges[:other_writable] = paramshash[:other_writable] # => boolean
    #      privileges[:other_readable] = paramshash[:other_readable] # => boolean
    #      privileges[:group_writable] = paramshash[:group_writable] # => boolean
    #      privileges[:group_readable] = paramshash[:group_readable] # => boolean
    #      privileges[:control_right] = paramshash[:control_right] # => boolean
    # set privilege to nodes and access controls for each group
    recs = 0
    node = {}
    gacl = 0
    wacl = 0

    retry_save = ACTIVE_RECORD_RETRY_COUNT
    catch(:remove_folder_privilege_again) {
      SpinAccessControl.transaction do
        begin
          # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
          node = SpinNode.find_by(spin_node_hashkey: privileges[:folder_hashkey])
          if node.blank?
            return recs
          end
          gacl = ((privileges[:group_readable] ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (privileges[:group_writable] ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS) | (privileges[:control_right] ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
          wacl = ((privileges[:other_readable] ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (privileges[:other_writable] ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS))
          node[:spin_world_access_right] = wacl
          rrecs = 0
          if self.is_controlable sid, node[:spin_node_hashkey], NODE_DIRECTORY
            rrecs = SpinNode.where(spin_node_hashkey: privileges[:folder_hashkey]).update_all(spin_gid_access_right: gacl, spin_world_access_right: wacl)
          else
            rrecs = SpinNode.where(spin_node_hashkey: privileges[:folder_hashkey]).update_all(spin_world_access_right: wacl)
          end
          unless rrecs == 1
            if retry_save > 0
              retry_save -= 1
              sleep(AR_RETRY_WAIT_MSEC)
              throw :remove_folder_privilege_again
            end
          end
        rescue ActiveRecord::StaleObjectError
          if retry_save > 0
            retry_save -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :remove_folder_privilege_again
          end
        end
      end
    }

    if target_node_key == nil # => call from request broker
      node_key = privileges[:folder_hashkey]
    else # => recursive call
      node_key = target_node_key
    end

    removed_recs = self.remove_groups_access_control gacl, privileges[:folder_hashkey], groups
    unless removed_recs > 0
      return removed_recs
    end
    FolderDatum.has_updated_to_parent(sid, privileges[:folder_hashkey], DISMISS_CHILD, false)
    #    FolderDatum.remove_folder_rec(sid, LOCATION_ANY, privileges[:folder_hashkey])
    # check range
    my_file_list = Array.new

    case privileges[:range]
    when 'all_folders' # => this and sub folders
      case privileges[:target]
      when 'file'
        my_file_list = SpinNode.get_active_children sid, node_key, NODE_FILE
        retry_save = ACTIVE_RECORD_RETRY_COUNT
        catch(:remove_all_folders_file_again) {
          SpinAccessControl.transaction do
            begin
              my_file_list.each {|f|
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                nrecs = SpinNode.where(spin_node_hashkey: f['spin_node_hashkey']).update_all(spin_world_access_right: wacl, spin_gid_access_right: gacl)
                unless nrecs == 1
                  next
                end
                recs += self.remove_groups_access_control gacl, f['spin_node_hashkey'], groups
              }
            rescue ActiveRecord::StaleObjectError
              if retry_save > 0
                retry_save -= 1
                throw :remove_all_folders_file_again
              end
            end # end of begin-rescue
          end # end of transaction
        }
      when 'folder'
        my_file_list = SpinNode.get_active_children sid, node_key, NODE_DIRECTORY
        my_file_list.each {|f|
          next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
          self.remove_folder_privilege sid, privileges, groups, f['spin_node_hashkey']
        }
      when 'folder_file'
        my_file_list = SpinNode.get_active_children sid, node_key, ANY_TYPE
        retry_save = ACTIVE_RECORD_RETRY_COUNT
        catch(:remove_all_folders_folder_file_again) {
          SpinAccessControl.transaction do
            begin
              my_file_list.each {|f|
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                if f['node_type'] == NODE_FILE
                  fn = SpinNode.find_by(spin_node_hashkey: f['spin_node_hashkey'])
                  if fn.blank?
                    return recs
                  end
                  fn[:spin_world_access_right] = wacl
                  fn[:spin_gid_access_right] = gacl
                  recs += self.remove_groups_access_control gacl, f['spin_node_hashkey'], groups
                else
                  self.remove_folder_privilege sid, privileges, groups, f['spin_node_hashkey']
                end
              }
            rescue ActiveRecord::StaleObjectError
              if retry_save > 0
                retry_save -= 1
                throw :remove_all_folders_folder_file_again
              end
            end # end of begin-rescue
          end # end of transaction
        }
      end # => end of case : target

    when 'folder'
      case privileges[:target]
      when 'file'
        my_file_list = SpinNode.get_active_children sid, node_key, NODE_FILE
        retry_save = ACTIVE_RECORD_RETRY_COUNT
        catch(:remove_folder_file_again) {
          SpinAccessControl.transaction do
            begin
              my_file_list.each {|f|
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                fn = SpinNode.find_by(spin_node_hashkey: f['spin_node_hashkey'])
                if fn.blank?
                  return recs
                end
                retb = fn.update(spin_world_access_right: wacl, spin_gid_access_right: gacl)
                unless retb
                  return recs
                end
                recs += self.remove_groups_access_control gacl, f['spin_node_hashkey'], groups
              }
            rescue ActiveRecord::StaleObjectError
              if retry_save > 0
                retry_save -= 1
                throw :remove_folder_file_again
              end
            end # end of begin-rescue
          end # end of transaction
        }
      when 'folder'
        pp 'NOP'
      when 'folder_file'
        my_file_list = SpinNode.get_active_children sid, node_key, ANY_TYPE
        retry_save = ACTIVE_RECORD_RETRY_COUNT
        catch(:remove_folder_folder_file_again) {
          SpinAccessControl.transaction do
            begin
              my_file_list.each {|f|
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                fn = SpinNode.find_by_spin_node_hashkey f['spin_node_hashkey']
                if fn.blank?
                  return recs
                end
                retb = fn.update(spin_world_access_right: wacl, spin_gid_access_right: gacl)
                unless retb
                  return recs
                end
                recs += self.remove_groups_access_control gacl, f['spin_node_hashkey'], groups
              }
            rescue ActiveRecord::StaleObjectError
              if retry_save > 0
                retry_save -= 1
                throw :remove_folder_folder_file_again
              end
            end # end of begin-rescue
          end # end of transaction
        }
      end # => end of case : target

    end # => end of case : range

    pn = SpinLocationManager.get_parent_node(node)
    pkey = pn[:spin_node_hashkey]
    SpinNode.has_updated(sid, pkey)
    GroupDatum.reset_folder_group_access_list sid, GROUP_LIST_FOLDER
    return recs

  end

  # =>  end of  remove_folder_privilege

  def self.remove_file_privilege sid, privileges, groups
    recs = 0
    node = {}
    gacl = 0
    wacl = 0

    retry_save = ACTIVE_RECORD_RETRY_COUNT

    catch(:remove_file_privilege_again) {

      self.transaction do
        begin
          # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
          node = SpinNode.find_by(spin_node_hashkey: privileges[:file_hashkey])
          if node.blank?
            return recs
          end
          gacl = ((privileges[:group_readable] ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (privileges[:group_writable] ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS) | (privileges[:control_right] ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
          wacl = ((privileges[:other_readable] ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (privileges[:other_writable] ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS))
          node[:spin_world_access_right] = wacl
          if self.is_controlable sid, node[:spin_node_hashkey], NODE_DIRECTORY
            node[:spin_gid_access_right] = gacl
          end
          node.save
        rescue ActiveRecord::StaleObjectError
          if retry_save > 0
            retry_save -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :remove_file_privilege_again
          end
        end
      end
    }

    recs = self.remove_groups_access_control gacl, privileges[:file_hashkey], groups
    FileDatum.set_selected(sid, privileges[:file_hashkey], privileges[:cont_location])
    FolderDatum.has_updated_to_parent(sid, privileges[:file_hashkey], DISMISS_CHILD, false)
    pn = SpinLocationManager.get_parent_node(node)
    pkey = pn[:spin_node_hashkey]
    SpinNode.has_updated(sid, pkey)
    GroupDatum.reset_folder_group_access_list sid, GROUP_LIST_FILE
    return recs

  end

  # =>  end of set_privilege privileges

  def self.get_group_acl_string gid, tf

  end

  # => end of self.get_group_acl_string sid, tf

  # get accseible brother nodes i.e. nodes which share the same parent directory
  def self.get_accessible_brother_nodes ssid, current_root_node, node_type = ANY_TYPE
    # initialize
    acl_nodes = []

    # get root node
    rn = nil
    ppx = -1
    py = -1
    rn = SpinNode.readonly.select("node_name,node_x_coord,node_y_coord").find_by_spin_node_hashkey_and_is_void_and_is_pending_and_in_trash_flag(current_root_node, false, false, false)

    if rn.present?
      # get coordinate values
      ppx = rn[:node_x_coord]
      py = rn[:node_y_coord]
      # py = rn[:node_y_coord] + 1
    else
      return nil
    end

    # get id's
    ids = SessionManager.get_uid_gid(ssid, false)
    spin_uid = ids[:uid]
    spin_gid = ids[:gid]
    gids = ids[:gids]


    #    gids = [ spin_gid]
    #    gids += SpinGroupMember.get_parent_gids spin_gid

    acl_node_keys = []

    # get accessible nodes from spin_nodes
    if spin_uid == 0 or spin_gid == 0
      if node_type == ANY_TYPE
        #        ns_query = sprintf("SELECT spin_node_hashkey FROM spin_nodes WHERE spin_tree_type = 0 AND node_x_pr_coord = %d AND node_y_coord = %d AND is_void = false AND is_pending = false AND in_trash_flag = false FOR share;",ppx,py)
        #        ns = SpinNode.connection.select_all(ns_query)
        ns = SpinNode.readonly.select("spin_node_hashkey").where(["spin_tree_type = 0 AND node_x_pr_coord = ? AND node_y_coord = ? AND is_void = false AND is_pending = false AND in_trash_flag = false", ppx, py])
        ns.each {|n|
          acl_node_keys.push(n['spin_node_hashkey'])
        }
      else
        #        ns_query = sprintf("SELECT spin_node_hashkey FROM spin_nodes WHERE spin_tree_type = 0 AND node_x_pr_coord = %d AND node_y_coord = %d AND node_type = %d AND is_void = false AND is_pending = false AND in_trash_flag = false FOR share;",ppx,py,node_type)
        #        ns = SpinNode.connection.select_all(ns_query)
        ns = SpinNode.readonly.select("spin_node_hashkey").where(["spin_tree_type = 0 AND node_x_pr_coord = ? AND node_y_coord = ? AND node_type = ? AND is_void = false AND is_pending = false AND in_trash_flag = false", ppx, py, node_type])
        ns.each {|n|
          acl_node_keys.push(n['spin_node_hashkey'])
        }
      end
    else
      if node_type == ANY_TYPE
        #        ns_query = sprintf("SELECT spin_node_hashkey FROM spin_nodes WHERE spin_tree_type = 0 AND node_x_pr_coord = %d AND node_y_coord = %d AND ((spin_gid = %d AND spin_gid_access_right > %d) OR (spin_uid = %d AND spin_uid_access_right > %d)) AND is_void = false AND is_pending = false AND in_trash_flag = false FOR share;",ppx,py,spin_gid,ACL_NODE_NO_ACCESS,spin_uid,ACL_NODE_NO_ACCESS)
        #        ns = SpinNode.connection.select_all(ns_query)
        ns = SpinNode.readonly.select("spin_node_hashkey").where(["spin_tree_type = 0 AND node_x_pr_coord = ? AND node_y_coord = ? AND ((spin_gid = ? AND spin_gid_access_right > ?) OR (spin_uid = ? AND spin_uid_access_right > ?)) AND is_void = false AND is_pending = false AND in_trash_flag = false", ppx, py, spin_gid, ACL_NODE_NO_ACCESS, spin_uid, ACL_NODE_NO_ACCESS])
        ns.each {|n|
          acl_node_keys.push(n['spin_node_hashkey'])
        }
      else
        #        ns_query = sprintf("SELECT spin_node_hashkey FROM spin_nodes WHERE spin_tree_type = 0 AND node_x_pr_coord = %d AND node_y_coord = %d AND node_type = %d AND ((spin_gid = %d AND spin_gid_access_right > %d) OR (spin_uid = %d AND spin_uid_access_right > %d)) AND is_void = false AND is_pending = false AND in_trash_flag = false FOR share;",ppx,py,node_type,spin_gid,ACL_NODE_NO_ACCESS,spin_uid,ACL_NODE_NO_ACCESS)
        #        ns = SpinNode.connection.select_all(ns_query)
        ns = SpinNode.readonly.select("spin_node_hashkey").where(["spin_tree_type = 0 AND node_x_pr_coord = ? AND node_y_coord = ? AND node_type = ? AND ((spin_gid = ? AND spin_gid_access_right > ?) OR (spin_uid = ? AND spin_uid_access_right > ?)) AND is_void = false AND in_trash_flag = false", ppx, py, node_type, spin_gid, ACL_NODE_NO_ACCESS, spin_uid, ACL_NODE_NO_ACCESS])
        ns.each {|n|
          acl_node_keys.push(n['spin_node_hashkey'])
        }
      end
    end

    #    gids += self.get_parent_node
    # go through spin_access_controls table
    gid_set = ''
    gids.each {|gid|
      if gid_set.empty?
        gid_set = gid.to_s
      else
        gid_set += (',' + gid.to_s)
      end
    }
    query = sprintf("ppx = %d AND py = %d AND spin_gid IN (%s) AND spin_gid_access_right > %d AND is_void = false", ppx, py, gid_set, ACL_NODE_NO_ACCESS)
    #    acl_nodes = SpinAccessControl.connection.select_all(query)
    acl_nodes = SpinAccessControl.readonly.select("managed_node_hashkey").where("#{query}")
    acl_nodes.each {|acl_node|
      acl_node_keys.push(acl_node['managed_node_hashkey'])
    }


    acl_node_keys.uniq!

    # returns acl_nodes
    return acl_node_keys

  end

  # => end of self.get_accessible_brother_nodes ssid, current_root_node

  def self.is_accessible_thumbnail_node sid, node_key, node_type = NODE_FILE # => always TRUE now
    return true
  end

  def self.is_accessible_node sid, node_key, node_type = ANY_TYPE
    # get acl from the node which has hashkey 'node_key'
    acls_hash = self.has_acl_values sid, node_key, node_type

    u_acl = acls_hash[:user]
    g_acl = acls_hash[:group]
    w_acl = acls_hash[:world]

    if (u_acl | g_acl | w_acl) > ACL_NODE_NO_ACCESS
      return true
    else
      return false
    end
  end

  # => end of is_accessible_node

  def self.is_readable sid, node_key, node_type = ANY_TYPE
    # # returns union of acls for uid and gids
    # return { :user => u_acl, :group => g_acl, :world => w_acl }
    # get uid and gid
    ids = SessionManager.get_uid_gid(sid, true)
    if ids[:uid] == 0 or ids[:gid] == 0
      return true
    end

    #    gids = ids[:gids]
    #    gids += SpinGroupMember.get_parent_gids ids[:gid]

    acls_hash = self.has_acl_values sid, node_key, node_type
    u_acl = acls_hash[:user]
    g_acl = acls_hash[:group]
    w_acl = acls_hash[:world]

    if (u_acl | g_acl | w_acl) & ACL_NODE_READ != 0
      return true
    end

    return false
  end

  # => end of is_readable

  def self.is_parent_readable sid, child_node_key, node_type = ANY_TYPE
    node_key = SpinLocationManager.get_parent_key(child_node_key, node_type)
    # # returns union of acls for uid and gids
    # return { :user => u_acl, :group => g_acl, :world => w_acl }
    # get uid and gid
    ids = SessionManager.get_uid_gid(sid, true)
    if ids[:uid] == 0 or ids[:gid] == 0
      return true
    end

    #    gids = ids[:gids]
    #    gids += SpinGroupMember.get_parent_gids ids[:gid]

    acls_hash = self.has_acl_values sid, node_key, node_type
    u_acl = acls_hash[:user]
    g_acl = acls_hash[:group]
    w_acl = acls_hash[:world]

    if (u_acl | g_acl | w_acl) & ACL_NODE_READ != 0
      return true
    end

    return false
  end

  # => end of is_readable

  def self.is_writable sid, node_key, node_type = ANY_TYPE
    # get uid and gid
    ids = SessionManager.get_uid_gid(sid, true)
    if ids[:uid] == 0 or ids[:gid] == 0
      return true
    end
    # acl.values.each { |a|
    # if (a & ACL_NODE_WRITE) != 0
    # return true
    # end
    # }
    # return false
    acls_hash = self.has_acl_values sid, node_key, node_type
    if acls_hash == nil
      return false
    end
    u_acl = acls_hash[:user]
    g_acl = acls_hash[:group]
    w_acl = acls_hash[:world]

    if (u_acl | g_acl | w_acl) & ACL_NODE_WRITE != 0
      return true
    end

    return false
  end

  # => end of self.is_writable sid, node_key, node_type = ANY_TYPE

  def self.is_write_only sid, node_key, node_type = ANY_TYPE
    # get uid and gid
    ids = SessionManager.get_uid_gid(sid, true)
    if ids[:uid] == 0 or ids[:gid] == 0
      return true
    end
    # acl.values.each { |a|
    # if (a & ACL_NODE_WRITE) != 0
    # return true
    # end
    # }
    # return false
    acls_hash = self.has_acl_values sid, node_key, node_type
    if acls_hash == nil
      return false
    end
    u_acl = acls_hash[:user]
    g_acl = acls_hash[:group]
    w_acl = acls_hash[:world]

    if (((u_acl | g_acl | w_acl) & ACL_NODE_WRITE != 0) & ((u_acl | g_acl | w_acl) & ACL_NODE_READ == 0))
      return true
    end

    return false
  end

  def self.is_deletable sid, node_key, node_type = ANY_TYPE
    # get uid and gid
    ids = SessionManager.get_uid_gid(sid, true)
    if ids[:uid] == 0 or ids[:gid] == 0
      return true
    end

    # is stick if sticky bit is set
    sn = SpinNode.select("is_sticky").find_by(spin_node_hashkey: node_key)
    if sn.blank?
      return false
    end
    if sn[:is_sticky]
      return false
    end

    acls_hash = self.has_acl_values sid, node_key, node_type
    if acls_hash == nil
      return false
    end

    u_acl = acls_hash[:user]
    g_acl = acls_hash[:group]
    w_acl = acls_hash[:world]

    if (u_acl | g_acl | w_acl) & ACL_NODE_DELETE != 0
      return true
    end

    return false
  end

  # => end of is_writable

  def self.is_deletable_node sid, node_rec, node_type = ANY_TYPE
    # get uid and gid
    ids = SessionManager.get_uid_gid(sid, true)
    if ids[:uid] == 0 or ids[:gid] == 0
      return true
    end

    # is stick if sticky bit is set
    #    sn = SpinNode.select("is_sticky").find(["spin_node_hashkey = ?",node_key])
    if node_rec[:is_sticky]
      return false
    end

    acls_hash = self.has_acl_values sid, node_rec[:spin_node_hashkey], node_type
    if acls_hash == nil
      return false
    end

    u_acl = acls_hash[:user]
    g_acl = acls_hash[:group]
    w_acl = acls_hash[:world]

    if (u_acl | g_acl | w_acl) & ACL_NODE_DELETE != 0
      return true
    end

    return false
  end

  # => end of is_writable

  def self.is_other_readable sid, node_key, node_type = ANY_TYPE
    # # returns union of acls for uid and gids
    # return { :user => u_acl, :group => g_acl, :world => w_acl }
    #    ids = SessionManager.get_uid_gid(sid)
    acls_hash = self.has_acl_values sid, node_key, node_type
    w_acl = acls_hash[:world]

    if w_acl & ACL_NODE_READ != 0
      return true
    end

    #    # check access control table
    #    aclnodes = []
    #    self.transaction do
    #      aclnodes = self.readonly.where(["managed_node_hashkey = ? AND spin_world_access_right&? <> 0", node_key,ACL_NODE_READ])
    #    end
    #    if aclnodes.length > 0
    #          return true
    #    else
    #      return false
    #    end # => end of if aclnodes
    return false
  end

  # => end of is_readable

  def self.is_other_writable sid, node_key, node_type = ANY_TYPE
    acls_hash = self.has_acl_values sid, node_key, node_type
    w_acl = acls_hash[:world]

    if w_acl & ACL_NODE_WRITE != 0
      return true
    end

    #    # check access control table
    #    aclnodes = []
    #    self.transaction do
    #      aclnodes = self.readonly.where(["managed_node_hashkey = ? AND spin_world_access_right&? <> 0", node_key,ACL_NODE_WRITE])
    #    end
    #    if aclnodes.length > 0
    #          return true
    #    else
    #      return false
    #    end # => end of if aclnodes
    return false
  end

  # => end of is_writable

  def self.is_controlable sid, node_key, node_type = ANY_TYPE
    # get uid and gid
    ids = SessionManager.get_uid_gid(sid, true)
    if ids[:uid] == 0 or ids[:gid] == 0
      return true
    end
    # acl.values.each { |a|
    # if (a & ACL_NODE_WRITE) != 0
    # return true
    # end
    # }
    # return false
    n = {}
    my_uid = ids[:uid]
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      n = SpinNode.readonly.select("spin_uid").find_by_spin_node_hashkey_and_is_void_and_in_trash_flag(node_key, false, false)
    end
    if n.blank?
      return false
    end

    if n[:spin_uid] == my_uid
      return true
    end
    acls_hash = self.has_acl_values sid, node_key, node_type
    u_acl = acls_hash[:user]
    g_acl = acls_hash[:group]
    w_acl = acls_hash[:world]

    if (u_acl | g_acl | w_acl) & ACL_NODE_CONTROL != 0
      return true
    end

    return false
  end

  # => end of is_writable

  def self.remove_node_acls sid, managed_node_hashkey
    ids = SessionManager.get_uid_gid(sid, true)
    unless ids[:uid] == 0 or ids[:gid] == 0
      return -1
    end
    rm_count = 0
    catch(:remove_node_acls_again) {
      self.transaction do

        recs = self.where(["managed_node_hashkey = ?", managed_node_hashkey])
        recs.each {|aclrec|
          begin
            aclrec.destroy
            rm_count += 1
          rescue ActiveRecord::StaleObjectError
            sleep(AR_RETRY_WAIT_MSEC)
            throw :remove_node_acls_again
          rescue ActiveRecord::RecordNotFound
          end
        }
      end
    }
    return rm_count
  end

  def self.has_acl sid, node_key, node_type = ANY_TYPE
    # get acl from the node which has hashkey 'node_key'
    anode = {}
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      if node_type == ANY_TYPE
        #        anode = SpinNode.readonly.find_by_spin_node_hashkey node_key
        anode = SpinNode.readonly.find_by_spin_node_hashkey_and_is_void_and_in_trash_flag(node_key, false, false)
      else
        #        anode = SpinNode.readonly.find_by_spin_node_hashkey_and_node_type node_key, node_type
        anode = SpinNode.readonly.find_by_spin_node_hashkey_and_node_type_and_is_void_and_in_trash_flag(node_key, node_type, false, false)
      end
      if anode.blank?
        return nil
      end
    end
    # get uid and gid
    ids = SessionManager.get_uid_gid(sid, false)
    if ids[:uid] == ACL_SUPERUSER_UID or ids[:gid] == ACL_SUPERUSER_GID
      return ACL_NODE_SUPERUSER_ACCESS
    end
    if SetUtility::SetOp.is_in_set ACL_SUPERUSER_GID, ids[:gids]
      return ACL_NODE_SUPERUSER_ACCESS
    end

    # does this user has superuser priviledge?
    owner_id = anode[:spin_uid]
    if ids[:uid] == owner_id
      u_acl = ACL_NODE_SUPERUSER_ACCESS
      return u_acl
    end # => end of if su check block

    # get parent gid's
    my_gids = ids[:gids]
    #    ids[:gids].each {|g|
    #      pgids = SpinGroupMember.get_parent_gids g
    #      my_gids += pgids
    #    }
    #    my_gids.uniq!

    # initialize object
    #    u_acls = Hash.new
    #    g_acls = Hash.new
    #    w_acls = Hash.new
    u_acl = ACL_NODE_NO_ACCESS
    g_acl = ACL_NODE_NO_ACCESS
    w_acl = ACL_NODE_NO_ACCESS

    # Does ids has access rights in the node record?
    if anode
      if anode[:spin_world_access_right] > ACL_NODE_NO_ACCESS
        w_acl = anode[:spin_world_access_right]
      end
      if anode[:spin_gid] == ids[:gid] and anode[:spin_gid_access_right] > ACL_NODE_NO_ACCESS
        g_acl = anode[:spin_gid_access_right]
      end
      if anode[:spin_uid] == ids[:uid] and anode[:spin_uid_access_right] > ACL_NODE_NO_ACCESS
        u_acl = anode[:spin_uid_access_right]
      end
    else
      return nil
    end

    # search spin_acces_contorols for ACL related with these ID's
    # are there records which have my uid or gid?
    node_acls = Array.new
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      if node_type == ANY_TYPE
        #        node_acls = self.readonly.where(:managed_node_hashkey =>  node_key)
        node_acls = self.readonly.where(["managed_node_hashkey = ? AND ((spin_uid = ? AND spin_uid_access_right > ?) OR spin_world_access_right > ?) AND is_void = false", node_key, ids[:uid], ACL_NODE_NO_ACCESS, ACL_NODE_NO_ACCESS]).order("id DESC")
      else # => node type specified
        #        node_acls = self.readonly.where(:managed_node_hashkey => node_key, :spin_node_type => node_type)
        node_acls = self.readonly.where(["spin_node_type = ? AND managed_node_hashkey = ? AND ((spin_uid = ? AND spin_uid_access_right > ?) OR spin_world_access_right > ?) AND is_void = false", node_type, node_key, ids[:uid], ACL_NODE_NO_ACCESS, ACL_NODE_NO_ACCESS]).order("id DESC")
      end
      node_acls.each {|na|
        w_acl |= na[:spin_world_access_right]
        if na[:spin_gid] == ids[:uid]
          u_acl |= na[:spin_uid_access_right]
        end
        my_gids.each {|g|
          if na[:spin_gid] == g
            g_acl |= na[:spin_gid_access_right]
          end
        }
      }
    end
    # returns union of acls for uid and gids
    return (u_acl | g_acl | w_acl)
  end

  # => end of has_acl

  def self.has_acl_values sid, node_key, node_type = ANY_TYPE
    # get acl from the node which has hashkey 'node_key'
    # for DEBUG
    # if node_key == '64ad4d6cc914f1738a0325086a3e79282231d2d3'
    # pp 'Yes'
    # end
    # get uid and gid
    ids = SessionManager.get_uid_gid(sid, false)

    # get parent gid's
    my_gids = ids[:gids]
    #    ids[:gids].each {|g|
    #      pgids = SpinGroupMember.get_parent_gids g
    #      my_gids += pgids
    #    }
    #    my_gids.uniq!

    # initialize object
    u_acl = ACL_NODE_NO_ACCESS
    g_acl = ACL_NODE_NO_ACCESS
    w_acl = ACL_NODE_NO_ACCESS

    if ids[:uid] == ACL_SUPERUSER_UID
      return {:user => ACL_NODE_SUPERUSER_ACCESS, :group => ACL_NODE_SUPERUSER_ACCESS, :world => ACL_NODE_SUPERUSER_ACCESS}
    end

    owner_id = ACL_WORLD_GID

    anode = nil
    #    SpinAccessControl.transaction do
    #      SpinAccessControl.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
    #      if node_type == ANY_TYPE
    anode_query = sprintf("SELECT spin_uid,spin_gid,spin_uid_access_right,spin_gid_access_right,spin_world_access_right FROM spin_nodes WHERE spin_node_hashkey = \'%s\' AND is_void = false", node_key)
    anodes = SpinNode.connection.select_all(anode_query)
    #      anode = SpinNode.select("spin_uid,spin_gid,spin_uid_access_right,spin_gid_access_right,spin_world_access_right").readonly.find(["spin_node_hashkey = ? AND is_void = false", node_key])
    if anodes.empty?
      return {:user => u_acl, :group => g_acl, :world => w_acl}
    end
    anode = anodes[0]
    owner_id = anode['spin_uid'].to_i
    #    end # => end of transaction

    # does this user has superuser priviledge?
    if ids[:uid] == ACL_SUPERUSER_UID or ids[:gid] == ACL_SUPERUSER_GID or SetUtility::SetOp.is_in_set(ACL_SUPERUSER_GID, ids[:gids])
      if ids[:uid] == ACL_SUPERUSER_UID
        u_acl = ACL_NODE_SUPERUSER_ACCESS
      end
      if ids[:gid] == ACL_SUPERUSER_GID or SetUtility::SetOp.is_in_set(ACL_SUPERUSER_GID, ids[:gids])
        g_acl = ACL_NODE_SUPERUSER_ACCESS
      end
      # => teddy 20180817
      return {:user => u_acl, :group => g_acl, :world => w_acl}
    end # => end of if su check block

    # does this user has superuser priviledge?
    if ids[:uid] == owner_id
      u_acl = ACL_NODE_SUPERUSER_ACCESS
    end # => end of if su check block

    # Does ids has access rights in the node record?
    if anode['spin_world_access_right'].to_i > ACL_NODE_NO_ACCESS
      w_acl |= anode['spin_world_access_right'].to_i
    end
    if anode['spin_gid'].to_i == ids[:gid] and anode['spin_gid_access_right'].to_i > ACL_NODE_NO_ACCESS
      g_acl |= anode['spin_gid_access_right'].to_i
    end
    if anode['spin_uid'].to_i == ids[:uid] and anode['spin_uid_access_right'].to_i > ACL_NODE_NO_ACCESS
      u_acl |= anode['spin_uid_access_right'].to_i
    end

    # search spin_acces_contorols for ACL related with these ID's
    # are there records which have my uid or gid?
    node_acls = Array.new
    SpinAccessControl.transaction do
      #      SpinAccessControl.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      if node_type == ANY_TYPE
        node_acls_query = sprintf("SELECT spin_uid,spin_uid_access_right,spin_world_access_right FROM spin_access_controls WHERE managed_node_hashkey = \'%s\' AND ((spin_uid = %d AND spin_uid_access_right > %d) OR (spin_gid = %d AND spin_gid_access_right > %d) OR spin_world_access_right > %d) AND is_void = false ORDER BY id DESC;", node_key, ids[:uid], ACL_NODE_NO_ACCESS, ids[:gid], ACL_NODE_NO_ACCESS, ACL_NODE_NO_ACCESS)
        node_acls = self.connection.select_all(node_acls_query)
        #        node_acls = self.readonly.select("spin_uid,spin_uid_access_right,spin_world_access_right").where(["managed_node_hashkey = ? AND ((spin_uid = ? AND spin_uid_access_right > ?) OR (spin_gid = ? AND spin_gid_access_right > ?) OR spin_world_access_right > ?) AND is_void = false", node_key,ids[:uid],ACL_NODE_NO_ACCESS,ids[:gid],ACL_NODE_NO_ACCESS,ACL_NODE_NO_ACCESS]).order("id DESC")
        #        node_acls = self.readonly.where(:managed_node_hashkey =>  node_key)
      else # => node type specified
        node_acls_query = sprintf("SELECT spin_uid,spin_uid_access_right,spin_world_access_right FROM spin_access_controls WHERE spin_node_type = %d AND managed_node_hashkey = \'%s\' AND ((spin_uid = %d AND spin_uid_access_right > %d) OR (spin_gid = %d AND spin_gid_access_right > %d) OR spin_world_access_right > %d) AND is_void = false ORDER BY id DESC;", node_type, node_key, ids[:uid], ACL_NODE_NO_ACCESS, ids[:gid], ACL_NODE_NO_ACCESS, ACL_NODE_NO_ACCESS)
        node_acls = self.connection.select_all(node_acls_query)
        #        node_acls = self.readonly.select("spin_uid,spin_uid_access_right,spin_world_access_right").where(["spin_node_type = ? AND managed_node_hashkey = ? AND ((spin_uid = ? AND spin_uid_access_right > ?) OR spin_world_access_right > ?) AND is_void = false", node_type,node_key,ids[:uid],ACL_NODE_NO_ACCESS,ACL_NODE_NO_ACCESS]).order("id DESC")
        #        node_acls = self.readonly.where(:managed_node_hashkey => node_key, :spin_node_type => node_type)
      end
      node_acls.each {|na|
        w_acl |= na['spin_world_access_right'].to_i
        if na['spin_uid'].to_i == ids[:uid]
          u_acl |= na['spin_uid_access_right'].to_i
        end
        break
      }
    end # => end of transactoin

    gid_list = ''
    my_gids.each {|g|
      if gid_list.empty?
        gid_list = g.to_s
      else
        gid_list += (',' + g.to_s)
      end
    }
    gid_query = sprintf("SELECT spin_gid_access_right FROM spin_access_controls WHERE managed_node_hashkey = \'%s\' AND spin_gid IN (%s) AND spin_gid_access_right > %d AND is_void = false ORDER BY id DESC;", node_key, gid_list, ACL_NODE_NO_ACCESS)
    #    gid_query = "managed_node_hashkey = \'#{node_key}\' AND spin_gid IN (#{gid_list}) AND spin_gid_access_right > #{ACL_NODE_NO_ACCESS} AND is_void = false"

    SpinAccessControl.transaction do
      #      SpinAccessControl.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      node_group_acls = self.connection.select_all(gid_query)
      #      node_group_acls = self.readonly.select("spin_gid_access_right").where("#{gid_query}").order("id DESC")
      node_group_acls.each {|group_acl|
        g_acl |= group_acl['spin_gid_access_right'].to_i
        break
      }
    end # => end of transaction
    # returns hash of acls for uid and gids
    return {:user => u_acl, :group => g_acl, :world => w_acl}
  end

  # => end of has_acl

  def self.copy_parent_acls sid, new_node, type = ANY_TYPE, pkey = '', uid = ANY_UID # => new_node = [x,y,prx,v,hashkey]
    # get acls
    parent_key = pkey
    if parent_key.empty?
      parent_key = SpinLocationManager.get_parent_key new_node[K], type # => pass hashkey
    end
    acl_recs = []
    group_acls = Array.new
    user_acls = Array.new
    world_acl = ACL_NODE_NO_ACCESS

    catch(:copy_parent_acls_again) {

      self.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        acl_recs_query = sprintf("SELECT * FROM spin_access_controls WHERE managed_node_hashkey = \'%s\' AND is_void = false;", parent_key)
        acl_recs = self.connection.select_all(acl_recs_query)
        #      acl_recs = self.where(:managed_node_hashkey => parent_key, :is_void => false)
        # group_acls = [ {:gid => n,:acl => N},{:gid => n,acl :N},...,{:gid => -1,:acl => N}] where ":gid => -1" is for WORLD ACCESS RIGHT
        # user_acls = [ {:uid => n,:acl => N},{:uid => n,acl :N},...,{:uid => n,:acl => N}]
        my_uid = uid
        if my_uid == ANY_UID
          my_uid = SessionManager.get_uid(sid)
        end
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        #      self.find_by_sql('LOCK TABLE spin_access_controls IN EXCLUSIVE MODE;')
        acl_recs.each {|a|
          # duplicate it for new_node
          # create new record
          # set spin_access_contrtol
          new_node_acl = SpinAccessControl.new

          begin
            new_node_acl[:spin_uid] = my_uid
            #        new_node_acl[:spin_uid] = a['spin_uid']
            new_node_acl[:spin_gid] = a['spin_gid'].to_i
            new_node_acl[:spin_node_type] = type
            new_node_acl[:spin_domain_flag] = (a['spin_domain_flag'] == 't' ? true : false)
            new_node_acl[:user_level_x] = a['user_level_x'].to_i
            new_node_acl[:user_level_y] = a['user_level_y'].to_i
            new_node_acl[:notify_upload] = a['notify_upload'].to_i
            new_node_acl[:notify_modify] = a['notify_modify'].to_i
            new_node_acl[:notify_delete] = a['notify_delete'].to_i
            if a['spin_gid_access_right'].to_i > ACL_NODE_NO_ACCESS
              new_node_acl[:spin_gid_access_right] = a['spin_gid_access_right'].to_i
              gx = {:gid => a['spin_gid'].to_i, :acl => a['spin_gid_access_right'].to_i}
              group_acls.append gx
            end
            if a['spin_world_access_right'].to_i > ACL_NODE_NO_ACCESS
              new_node_acl[:spin_world_access_right] = a['spin_world_access_right'].to_i
              world_acl |= a['spin_world_access_right'].to_i
            end
            if a['spin_uid_access_right'].to_i > ACL_NODE_NO_ACCESS
              new_node_acl[:spin_uid_access_right] = a['spin_uid_access_right'].to_i
              ux = {:uid => my_uid, :acl => a['spin_uid_access_right'].to_i}
              user_acls.append ux
            end
            r = Random.new
            new_node_acl[:spin_node_hashkey] = Security.hash_key_s ACL_PREFIX + a['spin_node_hashkey'] + r.rand.to_s
            new_node_acl[:managed_node_hashkey] = new_node[K] # => node_hashkey from caller
            new_node_acl[:created_at] = Time.now
            new_node_acl[:updated_at] = Time.now
            new_node_acl[:px] = new_node[X]
            new_node_acl[:py] = new_node[Y]
            new_node_acl[:ppx] = new_node[PRX]
            new_node_acl.save
              #        logger.debug new_node_acl
              # new_node_acl = new
              # new_node_acl = a
              # new_node_acl[:managed_node_hashkey] = new_node[4] # => node_hashkey from caller
              # new_node_acl.save
          rescue ActiveRecord::StaleObjectError
            sleep(AR_RETRY_WAIT_MSEC)
            throw :copy_parent_acls_again
          end
        }
      end
    }
    wgx = {:gid => ACL_WORLD_GID, :acl => world_acl}
    group_acls.append wgx
    # return acls set
    return {:user_acl => user_acls, :group_acl => group_acls}
  end

  # => end of copy_parent_acls new_node # => new_node = [x,y,prx,v,hashkey]

  def self.copy_node_acls sid, src_node, new_node # => new_node = [x,y,prx,v,hashkey]
    # get acls
    source_key = src_node[K]
    acl_recs = []
    group_acls = Array.new
    user_acls = Array.new
    world_acl = ACL_NODE_NO_ACCESS

    catch(:copy_node_acls_again) {

      self.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        acl_recs = self.where(["managed_node_hashkey = ? AND is_void => false", source_key])
        # group_acls = [ {:gid => n,:acl => N},{:gid => n,acl :N},...,{:gid => -1,:acl => N}] where ":gid => -1" is for WORLD ACCESS RIGHT
        # user_acls = [ {:uid => n,:acl => N},{:uid => n,acl :N},...,{:uid => n,:acl => N}]
        my_uid = SessionManager.get_uid(sid)
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        #      self.find_by_sql('LOCK TABLE spin_access_controls IN EXCLUSIVE MODE;')
        acl_recs.each {|a|
          # duplicate it for new_node
          # create new record
          # set spin_access_contrtol
          new_node_acl = SpinAccessControl.new

          begin
            new_node_acl[:spin_uid] = my_uid
            #        new_node_acl[:spin_uid] = a[:spin_uid]
            new_node_acl[:spin_gid] = a[:spin_gid]
            new_node_acl[:spin_node_type] = a[:spin_node_type]
            new_node_acl[:spin_domain_flag] = a[:spin_domain_flag]
            new_node_acl[:user_level_x] = a[:user_level_x]
            new_node_acl[:user_level_y] = a[:user_level_y]
            if a[:spin_gid_access_right] > ACL_NODE_NO_ACCESS
              new_node_acl[:spin_gid_access_right] = a[:spin_gid_access_right]
              gx = {:gid => a[:spin_gid], :acl => a[:spin_gid_access_right]}
              group_acls.append gx
            end
            if a[:spin_world_access_right] > ACL_NODE_NO_ACCESS
              new_node_acl[:spin_world_access_right] = a[:spin_world_access_right]
              world_acl |= a[:spin_world_access_right]
            end
            if a[:spin_uid_access_right] > ACL_NODE_NO_ACCESS
              new_node_acl[:spin_uid_access_right] = a[:spin_uid_access_right]
              ux = {:uid => my_uid, :acl => a[:spin_uid_access_right]}
              user_acls.append ux
            end
            r = Random.new
            new_node_acl[:spin_node_hashkey] = Security.hash_key_s ACL_PREFIX + a[:spin_node_hashkey] + r.rand.to_s
            new_node_acl[:managed_node_hashkey] = new_node[K] # => node_hashkey from caller
            new_node_acl[:created_at] = Time.now
            new_node_acl[:updated_at] = Time.now
            new_node_acl[:px] = new_node[X]
            new_node_acl[:py] = new_node[Y]
            new_node_acl[:ppx] = new_node[PRX]
            new_node_acl.save
            logger.debug new_node_acl
              # new_node_acl = new
              # new_node_acl = a
              # new_node_acl[:managed_node_hashkey] = new_node[4] # => node_hashkey from caller
              # new_node_acl.save
          rescue ActiveRecord::StaleObjectError
            sleep(AR_RETRY_WAIT_MSEC)
            throw :copy_node_acls_again
          end
        }
      end
    }
    wgx = {:gid => ACL_WORLD_GID, :acl => world_acl}
    group_acls.append wgx
    # return acls set
    return {:user_acl => user_acls, :group_acl => group_acls}
  end

  # => end of copy_node_acls new_node # => new_node = [x,y,prx,v,hashkey]

  def self.move_node_acls sid, new_node, type = ANY_TYPE # => new_node = [x,y,prx,v,hashkey]
    # get acls
    pn = SpinLocationManager.get_parent_node(new_node)
    pkey = pn[:spin_node_hashkey]
    parent_key = SpinLocationManager.get_parent_key pkey, type # => pass hashkey
    acl_recs = []
    group_acls = Array.new
    user_acls = Array.new
    world_acl = ACL_NODE_NO_ACCESS

    catch(:move_node_acls_again) {

      self.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        acl_recs = self.where(["managed_node_hashkey = ? AND is_void = false", parent_key])
        # group_acls = [ {:gid => n,:acl => N},{:gid => n,acl :N},...,{:gid => -1,:acl => N}] where ":gid => -1" is for WORLD ACCESS RIGHT
        # user_acls = [ {:uid => n,:acl => N},{:uid => n,acl :N},...,{:uid => n,:acl => N}]
        my_uid = SessionManager.get_uid(sid)
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        #      self.find_by_sql('LOCK TABLE spin_access_controls IN EXCLUSIVE MODE;')
        acl_recs.each {|a|
          # duplicate it for new_node
          # create new record
          # set spin_access_contrtol
          new_node_acl = SpinAccessControl.new

          begin
            new_node_acl[:spin_uid] = my_uid
            #        new_node_acl[:spin_uid] = a[:spin_uid]
            new_node_acl[:spin_gid] = a[:spin_gid]
            new_node_acl[:spin_node_type] = type
            new_node_acl[:spin_domain_flag] = a[:spin_domain_flag]
            new_node_acl[:user_level_x] = a[:user_level_x]
            new_node_acl[:user_level_y] = a[:user_level_y]
            if a[:spin_gid_access_right] > ACL_NODE_NO_ACCESS
              new_node_acl[:spin_gid_access_right] = a[:spin_gid_access_right]
              gx = {:gid => a[:spin_gid], :acl => a[:spin_gid_access_right]}
              group_acls.append gx
            end
            if a[:spin_world_access_right] > ACL_NODE_NO_ACCESS
              new_node_acl[:spin_world_access_right] = a[:spin_world_access_right]
              world_acl |= a[:spin_world_access_right]
            end
            if a[:spin_uid_access_right] > ACL_NODE_NO_ACCESS
              new_node_acl[:spin_uid_access_right] = a[:spin_uid_access_right]
              ux = {:uid => my_uid, :acl => a[:spin_uid_access_right]}
              user_acls.append ux
            end
            r = Random.new
            new_node_acl[:spin_node_hashkey] = Security.hash_key_s ACL_PREFIX + a[:spin_node_hashkey] + r.rand.to_s
            new_node_acl[:managed_node_hashkey] = new_node[K] # => node_hashkey from caller
            new_node_acl[:created_at] = Time.now
            new_node_acl[:updated_at] = Time.now
            new_node_acl[:px] = new_node[X]
            new_node_acl[:py] = new_node[Y]
            new_node_acl[:ppx] = new_node[PRX]
            new_node_acl.save
            logger.debug new_node_acl
              # new_node_acl = new
              # new_node_acl = a
              # new_node_acl[:managed_node_hashkey] = new_node[4] # => node_hashkey from caller
              # new_node_acl.save
          rescue ActiveRecord::StaleObjectError
            sleep(AR_RETRY_WAIT_MSEC)
            throw :move_node_acls_again
          end
        }
      end
    }
    wgx = {:gid => ACL_WORLD_GID, :acl => world_acl}
    group_acls.append wgx
    # return acls set
    return {:user_acl => user_acls, :group_acl => group_acls}
  end

  # => end of copy_parent_acls new_node # => new_node = [x,y,prx,v,hashkey]

  def self.inq_node_access_right sid, node_key
    return self.has_acl_values sid, node_key
  end

  # => end of inq_node_access_right

  def self.is_sticky node_key
    # is sticky if it is nil
    n = SpinNode.readonly.select("is_sticky,spin_uid_access_right,spin_gid_access_right").find_by_spin_node_hashkey_and_is_void(node_key, false)

    if n.blank?
      return false
    end
    # is stick if stock bit is set
    if n[:is_sticky] == true
      return true
    end

    # is stick if the owner or owner group is ROOT
    if (n[:spin_uid_access_right] & ACL_NODE_STICKY) != 0 or (n[:spin_gid_access_right] & ACL_NODE_STICKY) != 0
      return true
    end

    return false
  end

  # => end of self.is_stick node_key

  def self.secret_files_set_folder_privilege sid, privileges, groups, target_node_key = nil
    #      privileges[:folder_name] = paramshash[:text]
    #      privileges[:folder_hashkey] = paramshash[:hash_key]
    #      privileges[:target] = paramshash[:target]
    #      privileges[:range] = paramshash[:range]
    #      privileges[:owner] = paramshash[:owner]
    #      privileges[:owner_right] = paramshash[:data][:owner_right]
    #      privileges[:other_writable] = paramshash[:other_writable] # => boolean
    #      privileges[:other_readable] = paramshash[:other_readable] # => boolean
    #      privileges[:group_writable] = paramshash[:group_writable] # => boolean
    #      privileges[:group_readable] = paramshash[:group_readable] # => boolean
    #      privileges[:control_right] = paramshash[:control_right] # => boolean
    # set privilege to nodes and access controls for each group
    #groups[0][:member_id] = uid ? gidのどちらか・・・

    recs = 0
    node = {}
    node_key = nil
    uacl = ACL_DEFAULT_UID_ACCESS_RIGHT
    gacl = ACL_DEFAULT_GID_ACCESS_RIGHT
    wacl = ACL_DEFAULT_WORLD_ACCESS_RIGHT

    if target_node_key == nil # => call from request broker
      node_key = privileges[:folder_hashkey]
    else # => recursive call
      node_key = target_node_key
    end

    catch(:secret_files_set_folder_privilege_again) {

      self.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        begin
          node = SpinNode.find_by_spin_node_hashkey node_key
          if node.blank?
            return recs
          end
          uacl = (privileges[:owner_right] == 'full' ? ACL_NODE_FULL_ACCESS : ACL_NODE_READ)
          gacl = ((privileges[:group_readable] ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (privileges[:group_writable] ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS) | (privileges[:control_right] ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
          wacl = ((privileges[:other_readable] ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (privileges[:other_writable] ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS))
          node[:spin_uid_access_right] = uacl
          node[:spin_world_access_right] = wacl
          if self.is_controlable sid, node[:spin_node_hashkey], NODE_DIRECTORY
            node[:spin_gid_access_right] = gacl
          end
          node.save
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :secret_files_set_folder_privilege_again
        end

        self.secret_files_set_groups_access_control gacl, node_key, groups, privileges, domain_hashkey
        #FolderDatum.has_updated_to_parent(sid, node_key, NEW_CHILD, false) #2015/11/18 COMMENT
        # check range
        my_file_list = []

        case privileges[:range]
        when 'all_folders' # => this and sub folders
          case privileges[:target]
          when 'file'
            my_file_list = SpinNode.get_active_children sid, node_key, NODE_FILE
            # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            my_file_list.each {|f|
              begin
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                fn = SpinNode.find_by_spin_node_hashkey f['spin_node_hashkey']
                if fn.blank?
                  return recs
                end
                fn[:spin_uid_access_right] = uacl
                fn[:spin_world_access_right] = wacl
                #                if self.is_controlable sid, fn[:spin_node_hashkey], NODE_FILE
                fn[:spin_gid_access_right] = gacl
                #                end
                fn.save
              rescue ActiveRecord::StaleObjectError
                sleep(AR_RETRY_WAIT_MSEC)
                throw :secret_files_set_folder_privilege_again
              end
              recs += self.secret_files_set_groups_access_control gacl, f['spin_node_hashkey'], groups, privileges, domain_hashkey
            }
          when 'folder'
            my_file_list = SpinNode.get_active_children sid, node_key, NODE_DIRECTORY
            # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            my_file_list.each {|f|
              next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
              recs += self.secret_files_set_folder_privilege sid, privileges, groups, f['spin_node_hashkey']
            }
            pp 'NOP'
          when 'folder_file'
            my_file_list = SpinNode.get_active_children sid, node_key, ANY_TYPE
            # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            my_file_list.each {|f|
              begin
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                if f['node_type'].to_i == NODE_FILE
                  fn = SpinNode.find_by_spin_node_hashkey f['spin_node_hashkey']
                  if fn.blank?
                    return recs
                  end
                  fn[:spin_uid_access_right] = uacl
                  fn[:spin_world_access_right] = wacl
                  #                if self.is_controlable sid, fn[:spin_node_hashkey], NODE_FILE
                  fn[:spin_gid_access_right] = gacl
                  #                end
                  fn.save
                  recs += self.set_groups_access_control gacl, f['spin_node_hashkey'], groups, privileges
                else
                  recs += self.secret_files_set_folder_privilege sid, privileges, groups, f['spin_node_hashkey']
                end
              rescue ActiveRecord::StaleObjectError
                sleep(AR_RETRY_WAIT_MSEC)
                throw :secret_files_set_folder_privilege_again
              end
            }
          end # => end of case : target

        when 'folder'
          case privileges[:target]
          when 'file'
            my_file_list = SpinNode.get_active_children sid, node_key, NODE_FILE
            # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            my_file_list.each {|f|
              begin
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                fn = SpinNode.find_by_spin_node_hashkey f['spin_node_hashkey']
                if fn.blank?
                  return recs
                end
                fn[:spin_uid_access_right] = uacl
                fn[:spin_world_access_right] = wacl
                #                if self.is_controlable sid, fn[:spin_node_hashkey], NODE_FILE
                fn[:spin_gid_access_right] = gacl
                #                end
                fn.save
              rescue ActiveRecord::StaleObjectError
                sleep(AR_RETRY_WAIT_MSEC)
                throw :secret_files_set_folder_privilege_again
              end
              recs += self.set_groups_access_control gacl, f['spin_node_hashkey'], groups, privileges
            }
          when 'folder'
            pp 'NOP'
          when 'folder_file'
            my_file_list = SpinNode.get_active_children sid, node_key, ANY_TYPE
            # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            my_file_list.each {|f|
              begin
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                fn = SpinNode.find_by_spin_node_hashkey f['spin_node_hashkey']
                if fn.blank?
                  return recs
                end
                fn[:spin_uid_access_right] = uacl
                fn[:spin_world_access_right] = wacl
                #                if self.is_controlable sid, fn[:spin_node_hashkey], NODE_FILE
                fn[:spin_gid_access_right] = gacl
                #                end
                fn.save
              rescue ActiveRecord::StaleObjectError
                sleep(AR_RETRY_WAIT_MSEC)
                throw :secret_files_set_folder_privilege_again
              end
              recs += self.set_groups_access_control gacl, f['spin_node_hashkey'], groups, privileges
            }
          end # => end of case : target

        end # => end of case : range
      end # => end of transaction
    } # => end of catch block

    pn = SpinLocationManager.get_parent_node(node)
    pkey = pn[:spin_node_hashkey]
    SpinNode.has_updated(sid, pkey)
    return recs

  end

  # =>  end of set_privilege privileges

  def self.secret_files_set_domain_privilege sid, privileges, groups, target_node_key = nil, domain_hashkey
    #      privileges[:folder_name] = paramshash[:text]
    #      privileges[:folder_hashkey] = paramshash[:hash_key]
    #      privileges[:target] = paramshash[:target]
    #      privileges[:range] = paramshash[:range]
    #      privileges[:owner] = paramshash[:owner]
    #      privileges[:owner_right] = paramshash[:data][:owner_right]
    #      privileges[:other_writable] = paramshash[:other_writable] # => boolean
    #      privileges[:other_readable] = paramshash[:other_readable] # => boolean
    #      privileges[:group_writable] = paramshash[:group_writable] # => boolean
    #      privileges[:group_readable] = paramshash[:group_readable] # => boolean
    #      privileges[:control_right] = paramshash[:control_right] # => boolean
    # set privilege to nodes and access controls for each group
    #groups[0][:member_id] = uid ? gidのどちらか・・・

    recs = 0
    node = {}
    node_key = nil
    uacl = ACL_DEFAULT_UID_ACCESS_RIGHT
    gacl = ACL_DEFAULT_GID_ACCESS_RIGHT
    wacl = ACL_DEFAULT_WORLD_ACCESS_RIGHT

    if target_node_key == nil # => call from request broker
      node_key = privileges[:folder_hashkey]
    else # => recursive call
      node_key = target_node_key
    end

    catch(:secret_files_set_domain_privilege_again) {

      self.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        begin
          node = SpinNode.find_by_spin_node_hashkey node_key
          if node.blank?
            return recs
          end
          uacl = (privileges[:owner_right] == 'full' ? ACL_NODE_FULL_ACCESS : ACL_NODE_READ)
          gacl = ((privileges[:group_readable] ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (privileges[:group_writable] ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS) | (privileges[:control_right] ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
          wacl = ((privileges[:other_readable] ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (privileges[:other_writable] ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS))
          node[:spin_uid_access_right] = uacl
          node[:spin_world_access_right] = wacl
          if self.is_controlable sid, node[:spin_node_hashkey], NODE_DIRECTORY
            node[:spin_gid_access_right] = gacl
          end
          node.save
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :secret_files_set_domain_privilege_again
        end

        self.secret_files_set_groups_access_control gacl, node_key, groups, privileges, domain_hashkey

        #FolderDatum.has_updated_to_parent(sid, node_key, NEW_CHILD, false) #2015/11/18 COMMENT
        # check range
        my_file_list = []

        case privileges[:range]
        when 'all_folders' # => this and sub folders
          case privileges[:target]
          when 'file'
            my_file_list = SpinNode.get_active_children sid, node_key, NODE_FILE
            # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            my_file_list.each {|f|
              begin
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                fn = SpinNode.find_by_spin_node_hashkey f['spin_node_hashkey']
                if fn.blank?
                  return recs
                end
                fn[:spin_uid_access_right] = uacl
                fn[:spin_world_access_right] = wacl
                #                if self.is_controlable sid, fn[:spin_node_hashkey], NODE_FILE
                fn[:spin_gid_access_right] = gacl
                #                end
                fn.save
              rescue ActiveRecord::StaleObjectError
                sleep(AR_RETRY_WAIT_MSEC)
                throw :secret_files_set_domain_privilege_again
              end
              recs += self.secret_files_set_groups_access_control gacl, f['spin_node_hashkey'], groups, privileges, domain_hashkey
            }
          when 'folder'
            my_file_list = SpinNode.get_active_children sid, node_key, NODE_DIRECTORY
            # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            my_file_list.each {|f|
              next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
              recs += self.secret_files_set_domain_privilege sid, privileges, groups, f['spin_node_hashkey'], domain_hashkey
            }
            pp 'NOP'
          when 'folder_file'
            my_file_list = SpinNode.get_active_children sid, node_key, ANY_TYPE
            # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            my_file_list.each {|f|
              begin
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                if f['node_type'].to_i == NODE_FILE
                  fn = SpinNode.find_by_spin_node_hashkey f['spin_node_hashkey']
                  if fn.blank?
                    return recs
                  end
                  fn[:spin_uid_access_right] = uacl
                  fn[:spin_world_access_right] = wacl
                  #                if self.is_controlable sid, fn[:spin_node_hashkey], NODE_FILE
                  fn[:spin_gid_access_right] = gacl
                  #                end
                  fn.save
                  recs += self.secret_files_set_groups_access_control gacl, f['spin_node_hashkey'], groups, privileges, domain_hashkey
                else
                  recs += self.secret_files_set_domain_privilege sid, privileges, groups, f['spin_node_hashkey'], domain_hashkey
                end
              rescue ActiveRecord::StaleObjectError
                sleep(AR_RETRY_WAIT_MSEC)
                throw :secret_files_set_domain_privilege_again
              end
            }
          end # => end of case : target

        when 'folder'
          case privileges[:target]
          when 'file'
            my_file_list = SpinNode.get_active_children sid, node_key, NODE_FILE
            # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            my_file_list.each {|f|
              begin
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                fn = SpinNode.find_by_spin_node_hashkey f['spin_node_hashkey']
                if fn.blank?
                  return recs
                end
                fn[:spin_uid_access_right] = uacl
                fn[:spin_world_access_right] = wacl
                #                if self.is_controlable sid, fn[:spin_node_hashkey], NODE_FILE
                fn[:spin_gid_access_right] = gacl
                #                end
                fn.save
              rescue ActiveRecord::StaleObjectError
                sleep(AR_RETRY_WAIT_MSEC)
                throw :secret_files_set_domain_privilege_again
              end
              recs += self.secret_files_set_groups_access_control gacl, f['spin_node_hashkey'], groups, privileges, domain_hashkey
            }
          when 'folder'
            pp 'NOP'
          when 'folder_file'
            my_file_list = SpinNode.get_active_children sid, node_key, ANY_TYPE
            # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            my_file_list.each {|f|
              begin
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                fn = SpinNode.find_by_spin_node_hashkey f['spin_node_hashkey']
                if fn.blank?
                  return recs
                end
                fn[:spin_uid_access_right] = uacl
                fn[:spin_world_access_right] = wacl
                #                if self.is_controlable sid, fn[:spin_node_hashkey], NODE_FILE
                fn[:spin_gid_access_right] = gacl
                #                end
                fn.save
              rescue ActiveRecord::StaleObjectError
                sleep(AR_RETRY_WAIT_MSEC)
                throw :secret_files_set_domain_privilege_again
              end
              recs += self.secret_files_set_groups_access_control gacl, f['spin_node_hashkey'], groups, privileges, domain_hashkey
            }
          end # => end of case : target

        end # => end of case : range
      end # => end of transaction

    } # => end of catch block

    pn = SpinLocationManager.get_parent_node(node)
    pkey = pn[:spin_node_hashkey]
    SpinNode.has_updated(sid, pkey)
    return recs
  end

  # =>  end of set_privilege privileges

  def self.secret_files_add_domain_access_control sid, node_hashkey, gacl, groups, managed_node_type, domain_hashkey
    # first : get record which has spin_gid values
    acl_records = 0
    managed_node = SpinNode.find_by(spin_node_hashkey: node_hashkey)
    if managed_node.blank?
      return acl_records
    end
    px = managed_node[:node_x_coord]
    py = managed_node[:node_y_coord]
    ppx = managed_node[:node_x_pr_coord]
    node_type = (managed_node_type.present? ? managed_node_type : managed_node[:node_type])
    # for groups in array 'groups'

    catch(:secret_files_add_domain_access_control_again) {
      self.transaction do
        groups.each {|g|
          # analyze group
          # it may be a member of the group
          # we use member's primary group ( group assigned at user registration ) if it is
          my_acl_local = nil
          my_group = nil
          primary_group = -1
          if g[:member_id].present?
            primary_group = SpinUser.get_primary_group g[:member_id]
            # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            sql = "SELECT * FROM spin_access_controls WHERE spin_gid = " + primary_group.to_s + "AND managed_node_hashkey = '" + node_hashkey + "' limit 1;";
            temp = SpinAccessControl.find_by_sql(sql);
            my_acl_local = temp[0];
            #my_acl_local = SpinAccessControl.where( :spin_gid => primary_group,:managed_node_hashkey => node_hashkey ).first
          else
            # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            my_group = SpinGroup.select("spin_gid").where(["spin_group_name = ?", g[:group_name]]).first
            my_acl_local = SpinAccessControl.where(["spin_gid = ? AND managed_node_hashkey = ?", my_group[:spin_gid], node_hashkey]).first
          end
          #if my_acl_local and my_acl_local.size() > 0
          if (my_acl_local != nil)
            #エラー発生のためコメントアウト
            #gacl_str = g[:group_privilege]
            #gacl = ((gacl_str[0] == 'r' ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (gacl_str[1] == 'w' ? ACL_NODE_WRITE : ACL_NODE_NO_ACCESS) | (gacl_str[2] == 'a' ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
            #my_acl_local.each {|ma|
            #  gacl |= ma[:spin_gid_access_right]
            #  ma[:px] = px
            #  ma[:py] = py
            #  ma[:ppx] = ppx
            #  ma.save
            #}
            #        my_acl[:spin_gid_access_right] |= gacl

            #一時的な動作確保のためのコード
            #ここから
            begin
              my_acl_local[:spin_gid_access_right] = gacl
              my_acl_local[:spin_gid] = (my_group == nil ? primary_group : my_group[:spin_gid])
              my_acl_local[:spin_uid] = ID_NOT_SET
              my_acl_local[:px] = px
              my_acl_local[:py] = py
              my_acl_local[:ppx] = ppx
              my_acl_local[:spin_uid_access_right] = ACL_NODE_NO_ACCESS
              my_acl_local[:spin_world_access_right] = ACL_NODE_NO_ACCESS
              r = Random.new
              my_acl_local[:spin_node_hashkey] = Security.hash_key_s node_hashkey + r.rand.to_s
              my_acl_local[:managed_node_hashkey] = node_hashkey
              my_acl_local[:spin_node_type] = node_type
              my_acl_local[:created_at] = Time.now
              my_acl_local[:root_node_hashkey] = domain_hashkey
              if my_acl_local.save
                acl_records += 1
              end
            rescue ActiveRecord::StaleObjectError
              sleep(AR_RETRY_WAIT_MSEC)
              throw :secret_files_add_domain_access_control_again
            end
            #ここまで
          else
            # get records which has not used spin_gid(-1) field
            # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            my_acl_local = SpinAccessControl.where(["managed_node_hashkey = ? AND spin_gid = ?", node_hashkey, ID_NOT_SET]).first

            begin
              if my_acl_local
                gacl_str = g[:group_privilege]
                gacl = ((gacl_str[0] == 'r' ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (gacl_str[1] == 'w' ? ACL_NODE_WRITE : ACL_NODE_NO_ACCESS) | (gacl_str[2] == 'a' ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
                my_acl_local[:spin_gid_access_right] = gacl
                my_acl_local[:spin_gid] = my_group[:spin_gid]
              else
                # create new record
                my_acl_local = SpinAccessControl.new
                # set spin_access_contrtol
                #          gacl_str = g[:group_privilege]
                #          gacl = ((gacl_str[0] == 'r' ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (gacl_str[1] == 'w' ? ACL_NODE_WRITE : ACL_NODE_NO_ACCESS) | (gacl_str[2] == 'a' ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
                my_acl_local[:spin_gid_access_right] = gacl
                my_acl_local[:spin_gid] = (my_group == nil ? primary_group : my_group[:spin_gid])
                my_acl_local[:spin_uid] = ID_NOT_SET
                my_acl_local[:px] = px
                my_acl_local[:py] = py
                my_acl_local[:ppx] = ppx
                my_acl_local[:spin_uid_access_right] = ACL_NODE_NO_ACCESS
                my_acl_local[:spin_world_access_right] = ACL_NODE_NO_ACCESS
                r = Random.new
                my_acl_local[:spin_node_hashkey] = Security.hash_key_s node_hashkey + r.rand.to_s
                my_acl_local[:managed_node_hashkey] = node_hashkey
                my_acl_local[:spin_node_type] = node_type
                my_acl_local[:created_at] = Time.now
                my_acl_local[:root_node_hashkey] = domain_hashkey
                #          my_acl[:updated_at] = Time.now
              end
              if my_acl_local.save
                acl_records += 1
              end
            rescue ActiveRecord::StaleObjectError
              sleep(AR_RETRY_WAIT_MSEC)
              throw :secret_files_add_domain_access_control_again
            end
          end
        } # => end of group
      end # => end of transaction
    } # => end of cathc block

    #FolderDatum.has_updated(sid, node_hashkey, NEW_CHILD, false) #2015/11/24
    return acl_records
  end

  # => end of add_groups_access_control node_hashkey, groups

  def self.secret_files_set_groups_access_control gacl, node_hashkey, groups, privileges = 7, domain_hashkey
    # first : get record which has spin_gid values
    acl_records = 0
    # get node location
    mnode = SpinNode.find_by_spin_node_hashkey node_hashkey
    if mnode.blank?
      return acl_records
    end
    px = mnode[:node_x_coord]
    py = mnode[:node_y_coord]
    ppx = mnode[:node_x_pr_coord]
    node_type = mnode[:node_type]
    # for groups in array 'groups'

    catch(:secret_files_set_groups_access_control_again) {
      self.transaction do

        if groups.present?
          groups.each {|g|
            # analyze group
            # it may be a member of the group
            # we use member's primary group ( group assigned at user registration ) if it is
            begin
              my_acl = nil
              my_group = {}
              primary_group = -1
              if g[:member_id] != ""
                #primary_group = SpinUser.get_primary_group g[:member_id]
                primary_group = g[:member_id];
                my_group[:spin_gid] = primary_group
                # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
                my_acl = SpinAccessControl.where(["spin_gid = ? AND managed_node_hashkey = ?", primary_group, node_hashkey]).first
              else
                # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
                my_group = SpinGroup.select("spin_gid").where(["spin_group_name = ?", g[:group_name]]).first
                my_acl = SpinAccessControl.where(["spin_gid = ? AND managed_node_hashkey = ?", my_group[:spin_gid], node_hashkey]).first
              end
              # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
              if my_acl
                my_acl[:spin_gid_access_right] = gacl
                my_acl[:spin_gid] = my_group[:spin_gid]
                my_acl[:spin_uid_access_right] = privileges[:spin_uid_access_right]
                my_acl[:spin_world_access_right] = privileges[:spin_world_access_right]
                #my_acl[:spin_uid_access_right] = ACL_NODE_NO_ACCESS
                #my_acl[:spin_world_access_right] = ACL_NODE_NO_ACCESS
              else
                # create new record
                my_acl = SpinAccessControl.new
                # set spin_access_contrtol
                #          gacl_str = g[:group_privilege]
                #          gacl = ((gacl_str[0] == 'r' ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (gacl_str[1] == 'w' ? ACL_NODE_WRITE : ACL_NODE_NO_ACCESS) | (gacl_str[2] == 'a' ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
                my_acl[:spin_gid_access_right] = gacl
                my_acl[:spin_gid] = (my_group == nil ? primary_group : my_group[:spin_gid])
                my_acl[:spin_uid] = ID_NOT_SET
                my_acl[:spin_uid_access_right] = ACL_NODE_NO_ACCESS
                my_acl[:spin_world_access_right] = ACL_NODE_NO_ACCESS
                r = Random.new
                my_acl[:spin_node_hashkey] = Security.hash_key_s node_hashkey + r.rand.to_s
                my_acl[:managed_node_hashkey] = node_hashkey
                my_acl[:spin_node_type] = node_type
                my_acl[:created_at] = Time.now
                my_acl[:px] = px
                my_acl[:py] = py
                my_acl[:ppx] = ppx
                my_acl[:root_node_hashkey] = domain_hashkey
                #          my_acl[:updated_at] = Time.now
              end
              if my_acl.save
                acl_records += 1
              end
            rescue ActiveRecord::StaleObjectError
              sleep(AR_RETRY_WAIT_MSEC)
              throw :secret_files_set_groups_access_control_again
            end
          } # => end of group
        end # => end of if groups != nil
      end # => end of transaction
    } # => end of catch block

    return acl_records
  end

  # => end of set_groups_access_control node_hashkey, groups

  def self.secret_files_remove_domain_privilege sid, privileges, groups, target_node_key = nil, domain_hashkey
    #      privileges[:folder_name] = paramshash[:text]
    #      privileges[:folder_hashkey] = paramshash[:folder_hashkey]
    #      privileges[:target] = paramshash[:target]
    #      privileges[:range] = paramshash[:range]
    #      privileges[:owner] = paramshash[:owner]
    #      privileges[:other_writable] = paramshash[:other_writable] # => boolean
    #      privileges[:other_readable] = paramshash[:other_readable] # => boolean
    #      privileges[:group_writable] = paramshash[:group_writable] # => boolean
    #      privileges[:group_readable] = paramshash[:group_readable] # => boolean
    #      privileges[:control_right] = paramshash[:control_right] # => boolean
    # set privilege to nodes and access controls for each group
    recs = 0
    node = {}
    gacl = 0
    wacl = 0

    catch(:secret_files_remove_domain_privilege_again) {

      self.transaction do
        # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        begin
          node = SpinNode.find_by_spin_node_hashkey privileges[:folder_hashkey]
          if node.blank?
            return recs
          end
          gacl = ((privileges[:group_readable] ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (privileges[:group_writable] ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS) | (privileges[:control_right] ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
          wacl = ((privileges[:other_readable] ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (privileges[:other_writable] ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS))
          node[:spin_world_access_right] = wacl
          if self.is_controlable sid, node[:spin_node_hashkey], NODE_DIRECTORY
            node[:spin_gid_access_right] = gacl
          end
          node.save
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :secret_files_remove_domain_privilege_again
        end

        if target_node_key == nil # => call from request broker
          node_key = privileges[:folder_hashkey]
        else # => recursive call
          node_key = target_node_key
        end

        self.remove_groups_access_control gacl, privileges[:folder_hashkey], groups
        #FolderDatum.has_updated_to_parent(sid, privileges[:folder_hashkey], DISMISS_CHILD, false)
        #    FolderDatum.remove_folder_rec(sid, LOCATION_ANY, privileges[:folder_hashkey])
        # check range
        my_file_list = Array.new

        case privileges[:range]
        when 'all_folders' # => this and sub folders
          case privileges[:target]
          when 'file'
            my_file_list = SpinNode.get_active_children sid, node_key, NODE_FILE
            # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            my_file_list.each {|f|
              begin
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                fn = SpinNode.find_by_spin_node_hashkey f['spin_node_hashkey']
                if fn.blank?
                  return recs
                end
                #            fn[:spin_uid_access_right] = uacl
                fn[:spin_world_access_right] = wacl
                #                if self.is_controlable sid, fn[:spin_node_hashkey], NODE_FILE
                fn[:spin_gid_access_right] = gacl
                #                end
                fn.save
              rescue ActiveRecord::StaleObjectError
                sleep(AR_RETRY_WAIT_MSEC)
                throw :secret_files_remove_domain_privilege_again
              end
              recs += self.remove_groups_access_control gacl, f['spin_node_hashkey'], groups
            }
          when 'folder'
            my_file_list = SpinNode.get_active_children sid, node_key, NODE_DIRECTORY
            # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            my_file_list.each {|f|
              next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
              self.remove_folder_privilege sid, privileges, groups, f['spin_node_hashkey']
            }
            pp 'NOP'
          when 'folder_file'
            my_file_list = SpinNode.get_active_children sid, node_key, ANY_TYPE
            # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            my_file_list.each {|f|
              begin
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                if f['node_type'] == NODE_FILE
                  fn = SpinNode.find_by_spin_node_hashkey f['spin_node_hashkey']
                  if fn.blank?
                    return recs
                  end
                  #              fn[:spin_uid_access_right] = uacl
                  fn[:spin_world_access_right] = wacl
                  #                if self.is_controlable sid, fn[:spin_node_hashkey], NODE_FILE
                  fn[:spin_gid_access_right] = gacl
                  #                end
                  fn.save
                  recs += self.remove_groups_access_control gacl, f['spin_node_hashkey'], groups
                else
                  self.secret_files_remove_domain_privilege sid, privileges, groups, f['spin_node_hashkey'], domain_hashkey
                end
              rescue ActiveRecord::StaleObjectError
                sleep(AR_RETRY_WAIT_MSEC)
                throw :secret_files_remove_domain_privilege_again
              end
            }
          end # => end of case : target

        when 'folder'
          case privileges[:target]
          when 'file'
            my_file_list = SpinNode.get_active_children sid, node_key, NODE_FILE
            # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            my_file_list.each {|f|
              begin
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                fn = SpinNode.find_by_spin_node_hashkey f['spin_node_hashkey']
                if fn.blank?
                  return recs
                end
                #            fn[:spin_uid_access_right] = uacl
                fn[:spin_world_access_right] = wacl
                #                if self.is_controlable sid, fn[:spin_node_hashkey], NODE_FILE
                fn[:spin_gid_access_right] = gacl
                #                end
                fn.save
              rescue ActiveRecord::StaleObjectError
                sleep(AR_RETRY_WAIT_MSEC)
                throw :secret_files_remove_domain_privilege_again
              end
              recs += self.remove_groups_access_control gacl, f['spin_node_hashkey'], groups
            }
          when 'folder'
            pp 'NOP'
          when 'folder_file'
            my_file_list = SpinNode.get_active_children sid, node_key, ANY_TYPE
            # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            my_file_list.each {|f|
              begin
                next unless SpinAccessControl.is_controlable(sid, f['spin_node_hashkey'], f['node_type'].to_i)
                fn = SpinNode.find_by_spin_node_hashkey f['spin_node_hashkey']
                if fn.blank?
                  return recs
                end
                #            fn[:spin_uid_access_right] = uacl
                fn[:spin_world_access_right] = wacl
                #                if self.is_controlable sid, fn[:spin_node_hashkey], NODE_FILE
                fn[:spin_gid_access_right] = gacl
                #                end
                fn.save
              rescue ActiveRecord::StaleObjectError
                sleep(AR_RETRY_WAIT_MSEC)
                throw :secret_files_remove_domain_privilege_again
              end
              recs += self.remove_groups_access_control gacl, f['spin_node_hashkey'], groups
            }
          end # => end of case : target

        end # => end of case : range
      end # => end of transaction
    } # => end of catch block

    pn = SpinLocationManager.get_parent_node(node)
    pkey = pn[:spin_node_hashkey]
    SpinNode.has_updated(sid, pkey)
    #GroupDatum.reset_folder_group_access_list sid, GROUP_LIST_FOLDER
    return recs
  end

  # =>  end of set_privilege privileges

  def self.secret_files_remove_groups_access_control gacl, node_hashkey, groups, domain_hashkey
    # first : get record which has spin_gid values
    acl_records = 0
    # for groups in array 'groups'
    catch(:secret_files_remove_groups_access_control_again) {

      self.transaction do

        groups.each {|g|
          # analyze group
          # it may be a member of the group
          # we use member's primary group ( group assigned at user registration ) if it is
          my_acls = nil
          #group_id = SpinGroup.get_group_id_by_group_name(g[:group_name])
          # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
          #        my_group = SpinGroup.select("spin_gid").where(:spin_group_name => g[:group_name]).first
          my_acls = SpinAccessControl.where(:spin_gid => g[:member_id], :managed_node_hashkey => node_hashkey)
          my_acls = SpinAccessControl.where(["spin_gid = ? AND managed_node_hashkey = ?", g[:member_id], node_hashkey])
          #      r = my_acls.length
          #      if r > 0
          # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
          my_acls.each {|my_acl|
            if my_acl[:spin_uid] == -1
              my_acl.destroy
              acl_records += 1
            else
              my_acl[:spin_gid] = -1
              if my_acl.save
                acl_records += 1
              end
            end
          }
          #      end
        } # => end of group
      end # => end of transaction
    } # => end of catch block

    return acl_records
  end # => end of add_groups_access_control node_hashkey, groups

end

