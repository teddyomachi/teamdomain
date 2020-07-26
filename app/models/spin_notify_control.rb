# coding: utf-8
require 'const/vfs_const'
require 'const/acl_const'
require 'const/spin_types'
require 'utilities/set_utilities'

# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class SpinNotifyControl < SpinAccessControl
  include Vfs
  include Acl
  include Types
  
  def initialize
    
  end
  
  def self.set_folder_notification sid, privileges, groups, target_node_key = nil
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
    
    recs = 0
    node = {}
    node_key = target_node_key
    notification = {}
    notification[:notify_upload] = privileges[:notify_upload] ? ACL_NOTIFY_DEFAULT : ACL_NOTIFY_NONE
    notification[:notify_modify] = privileges[:notify_modify] ? ACL_NOTIFY_DEFAULT : ACL_NOTIFY_NONE
    notification[:notify_delete] = privileges[:notify_delete] ? ACL_NOTIFY_DEFAULT : ACL_NOTIFY_NONE

    if target_node_key == nil # => call from request broker
      node_key = privileges[:folder_hashkey]
    else # => recursive call
      node_key = target_node_key
    end

    self.set_groups_notify_control notification, node_key, groups
    FolderDatum.has_updated_to_parent(sid, node_key, NEW_CHILD, false)
    # check range
    my_file_list = []
    
    case privileges[:range]
    when 'all_folders' # => this and sub folders
      case privileges[:target]
      when 'file'
        my_file_list = SpinNode.get_active_children  sid, node_key, NODE_FILE
#        self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        self.transaction do
          my_file_list.each {|f|
            next unless self.is_controlable(sid, f['spin_node_hashkey'], f['node_type'])
            recs += self.set_groups_notify_control notification, node_key, groups
            #            recs += self.set_groups_access_control notify_modify, f['spin_node_hashkey'], groups
          }
        end
      when 'folder'
        my_file_list = SpinNode.get_active_children  sid, node_key, NODE_DIRECTORY
#        self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        self.transaction do
          my_file_list.each {|f|
            next unless self.is_controlable(sid, f['spin_node_hashkey'], f['node_type'])
            recs += self.set_folder_notification sid, privileges, groups, f['spin_node_hashkey']
          }
        end # => end of transaction
        pp 'NOP'
      when 'folder_file'
        my_file_list = SpinNode.get_active_children  sid, node_key, ANY_TYPE
#        self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        self.transaction do
          my_file_list.each {|f|
            next unless self.is_controlable(sid, f['spin_node_hashkey'], f['node_type'])
            if f['node_type'] == NODE_FILE
              recs += self.set_groups_notify_control notification, node_key, groups
              #              recs += self.set_groups_access_control notify_modify, f['spin_node_hashkey'], groups
            else
              recs += self.set_folder_notification sid, privileges, groups, f['spin_node_hashkey']
            end
          }
        end # => end of transaction
      end # => end of case : target
      
    when 'folder'
      case privileges[:target]
      when 'file'
        my_file_list = SpinNode.get_active_children  sid, node_key, NODE_FILE
#        self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        self.transaction do
          my_file_list.each {|f|
            next unless self.is_controlable(sid, f['spin_node_hashkey'], f['node_type'])
            recs += self.set_groups_notify_control notification, node_key, groups
            #          recs += self.set_groups_access_control notify_modify, f['spin_node_hashkey'], groups
          }
        end
      when 'folder'
        pp 'NOP'
      when 'folder_file'
        my_file_list = SpinNode.get_active_children  sid, node_key, ANY_TYPE
#        self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
        self.transaction do
          my_file_list.each {|f|
            next unless self.is_controlable(sid, f['spin_node_hashkey'], f['node_type'])
            recs += self.set_groups_notify_control notification, node_key, groups
            #            recs += self.set_groups_access_control notify_modify, f['spin_node_hashkey'], groups
          }
        end # => end of transaction
      end # => end of case : target

    end # => end of case : range
    
    node =SpinNode.find_by_spin_node_hashkey(node_key)
    pn = SpinLocationManager.get_parent_node(node)
    pkey = pn[:spin_node_hashkey]
    SpinNode.has_updated( sid, pkey )
    return recs
    
  end # =>  end of set_privilege privileges

  def self.notify_new(sid,current_folder_key,new_file_key,new_file_url,domain_hash_key)
    FileManager.rails_logger(">> Start notify_new")
    #    notify_flag = self.has_notification(sid,current_folder_key,NODE_DIRECTORY)
    #    FileManager.rails_logger(">> notify_new : notify_flag = " + notify_flag.to_s)
    #    if (notify_flag&UPLOAD_NOTIFICATION) == 0 # => not new
    #      return 0
    #    end
    
    sn = SpinNode.find_by_spin_node_hashkey(new_file_key)
    vpath = sn[:virtual_path]
    fsize = sn[:node_size_upper] * MAX_INTEGER + sn[:node_size]
    fsize_u = SystemTools::Numeric.size_with_unit(fsize)
    domain_root_vpath = SpinDomain.get_domain_root_vpath(domain_hash_key)
    
    # generate vpath's
    new_file_relative_vpath = vpath[domain_root_vpath.length+1..-1]
    last_sep_pos = new_file_relative_vpath.rindex('/')
    folder_relative_vpath = new_file_relative_vpath[0..(last_sep_pos-1)] 
    FileManager.rails_logger(">> notify_new : folder_relative_vpath = " + folder_relative_vpath)
    
    # make list for notification
    target_groups = SpinAccessControl.select("spin_gid").where(["managed_node_hashkey = ? AND notify_upload = 1",current_folder_key])
    target_users = []
    target_groups.each {|tg|
      group_members = SpinGroupMember.where(["spin_gid = ?",tg[:spin_gid]])
      group_members.each {|gm|
        target_users.push(gm[:spin_uid])
      }
    }
    
    target_users.uniq!
    mail_list = []
    user_list = []
    target_users.each {|target_user|
      ml = SpinUserAttribute.select("mail_addr,user_attributes").find_by_spin_uid(target_user)
      if ml.present?
        mail_list.push(ml[:mail_addr])
        user_attr = JSON.parse(ml[:user_attributes])
        user_list.push(user_attr['user_description'])
      end
    }
    FileManager.rails_logger(">> notify_new : mail_list = " + mail_list.to_s)
    
    thumbnail_info = {}
    thumbnail_info = SpinLocationManager.get_thumbnail_info(sid,new_file_key)
    FileManager.rails_logger(">> notify_new : thumbnail_info = " + thumbnail_info[:thumbnail_path])

    # mail
    sent_mail = nil
    mail_list.each_with_index {|ml,idx|
      #      boombox_notify = BoomboxNotifier
      
      # deliver mail
      if thumbnail_info[:thumbnail_size] > 0 # => can send mail with inline thumbnail
        notify_mail = BoomboxNotifier.upload_info(sid,ml,folder_relative_vpath,new_file_relative_vpath,fsize_u,user_list[idx],new_file_url,thumbnail_info[:thumbnail_path])
        sent_mail = notify_mail.deliver
      else # => send mail without thumbnail
        notify_mail = BoomboxNotifier.upload_info(sid,ml,folder_relative_vpath,new_file_relative_vpath,fsize_u,user_list[idx],new_file_url)
        sent_mail = notify_mail.deliver
      end
    }
    SpinNode.set_notified_at(new_file_key,UPLOAD_NOTIFICATION)
    
    return sent_mail
  end # => end of self.notify_new

  def self.notify_modification(sid,current_folder_key,new_file_key,new_file_url,domain_hash_key)
    FileManager.rails_logger(">> Start notify_modification")
    #    notify_flag = self.has_notification(sid,current_folder_key,NODE_DIRECTORY)
    #    FileManager.rails_logger(">> notify_modification : notify_flag = " + notify_flag.to_s)
    #    if (notify_flag&MODIFY_NOTIFICATION) == 0 # => not modified
    #      return 0
    #    end
    
    sn = SpinNode.find_by_spin_node_hashkey(new_file_key)
    vpath = sn[:virtual_path]
    fsize = sn[:node_size_upper] * MAX_INTEGER + sn[:node_size]
    fsize_u = SystemTools::Numeric.size_with_unit(fsize)
    domain_root_vpath = SpinDomain.get_domain_root_vpath(domain_hash_key)
    
    # generate vpath's
    new_file_relative_vpath = vpath[domain_root_vpath.length+1..-1]
    last_sep_pos = new_file_relative_vpath.rindex('/')
    folder_relative_vpath = new_file_relative_vpath[0..(last_sep_pos-1)] 
    FileManager.rails_logger(">> notify_modification : folder_relative_vpath = " + folder_relative_vpath)
    
    # make list for notification
    target_groups = SpinAccessControl.select("spin_gid").where(["managed_node_hashkey = ? AND notify_upload = 1",current_folder_key])
    target_users = []
    target_groups.each {|tg|
      group_members = SpinGroupMember.where(["spin_gid = ?",tg[:spin_gid]])
      group_members.each {|gm|
        target_users.push(gm[:spin_uid])
      }
    }
    
    target_users.uniq!
    mail_list = []
    user_list = []
    target_users.each {|target_user|
      ml = SpinUserAttribute.select("mail_addr,user_attributes").find_by_spin_uid(target_user)
      if ml.present?
        mail_list.push(ml[:mail_addr])
        user_attr = JSON.parse(ml[:user_attributes])
        user_list.push(user_attr['user_description'])
      end
    }
    FileManager.rails_logger(">> notify_modification : mail_list = " + mail_list.to_s)
    
    thumbnail_info = {}
    thumbnail_info = SpinLocationManager.get_thumbnail_info(sid,new_file_key)
    FileManager.rails_logger(">> notify_modification : thumbnail_info = " + thumbnail_info[:thumbnail_path])

    # mail
    sent_mail = nil
    mail_list.each_with_index {|ml,idx|
      #      boombox_notify = BoomboxNotifier
      
      # deliver mail
      if thumbnail_info[:thumbnail_size] > 0 # => can send mail with inline thumbnail
        notify_mail = BoomboxNotifier.modification_info(sid,ml,folder_relative_vpath,new_file_relative_vpath,fsize_u,user_list[idx],new_file_url,thumbnail_info[:thumbnail_path])
        sent_mail = notify_mail.deliver
      else # => send mail without thumbnail
        notify_mail = BoomboxNotifier.modification_info(sid,ml,folder_relative_vpath,new_file_relative_vpath,fsize_u,user_list[idx],new_file_url)
        sent_mail = notify_mail.deliver
      end
    }
    SpinNode.set_notified_at(new_file_key,MODIFY_NOTIFICATION)
    
    return sent_mail
  end # => end of self.notify_modification

  def self.notify_delete(sid,trashed_vps,current_folder_key)
    FileManager.rails_logger(">> Start notify_delete")
    
    # make list for notification
    target_groups = SpinAccessControl.select("spin_gid").where(["managed_node_hashkey = ? AND notify_upload = 1",current_folder_key])
    target_users = []
    target_groups.each {|tg|
      group_members = SpinGroupMember.where(["spin_gid = ?",tg[:spin_gid]])
      group_members.each {|gm|
        target_users.push(gm[:spin_uid])
      }
    }
    
    target_users.uniq!
    mail_list = []
    user_list = []
    target_users.each {|target_user|
      ml = SpinUserAttribute.select("mail_addr,user_attributes").find_by_spin_uid(target_user)
      if ml.present?
        mail_list.push(ml[:mail_addr])
        user_attr = JSON.parse(ml[:user_attributes])
        user_list.push(user_attr['user_description'])
      end
    }
    FileManager.rails_logger(">> notify_delete : mail_list = " + mail_list.to_s)
    
    folder_vps = SpinLocationManager.get_key_vpath(sid, current_folder_key, NODE_DIRECTORY)
    
    # mail
    sent_mail = nil
    mail_list.each_with_index {|ml,idx|
      notify_mail = BoomboxNotifier.delete_info(sid,ml,folder_vps,trashed_vps,user_list[idx])
      sent_mail = notify_mail.deliver
    }
    SpinNode.set_notified_at_vpath(trashed_vps,DELETE_NOTIFICATION)
    
    return sent_mail
  end # => end of self.notify_delete(delete_sid,trashed_vps)

  def self.set_groups_notify_control notification, node_hashkey, groups
    # first : get record which has spin_gid values
    acl_records = 0
    # get node location
    mnode = SpinNode.find_by_spin_node_hashkey node_hashkey
    px = mnode[:node_x_coord]
    py = mnode[:node_y_coord]
    ppx = mnode[:node_x_pr_coord]
    node_type = mnode[:node_type]
    # for groups in array 'groups'
    if groups != nil
      groups.each {|g|
        # analyze group
        # it may be a member of the group
        # we use member's primary group ( group assigned at user registration ) if it is
        my_acl = nil
        my_group = {}
        primary_group = -1
        if g[:member_id] != ""
          #primary_group = SpinUser.get_primary_group g[:member_id]
          #my_group[:spin_gid] = primary_group
          my_group=g[:member_id]
          SpinAccessControl.transaction do
            #             SpinAccessControl.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            #            my_acl = SpinAccessControl.where( :spin_gid => primary_group,:managed_node_hashkey => node_hashkey ).first
            my_acl = SpinAccessControl.find_by_spin_gid_and_managed_node_hashkey(g[:member_id], node_hashkey)
            if my_acl.blank?
              return acl_records
            end
          end
        else
          SpinAccessControl.transaction do
            #             SpinAccessControl.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
            my_group = SpinGroup.select("spin_gid").find_by_spin_group_name(g[:group_name])
            if my_group.blank?
              return acl_records
            end
            my_acl = SpinAccessControl.find_by_spin_gid_and_managed_node_hashkey(my_group[:spin_gid], node_hashkey)
            if my_acl.blank?
              return acl_records
            end
            #            my_group = SpinGroup.select("spin_gid").where(:spin_group_name => g[:group_name]).first
            #            my_acl = SpinAccessControl.where( :spin_gid => my_group[:spin_gid],:managed_node_hashkey => node_hashkey ).first
          end
        end
        SpinAccessControl.transaction do
          #           SpinAccessControl.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
          if my_acl != nil
            my_acl[:notify_upload] = notification[:notify_upload]
            my_acl[:notify_modify] = notification[:notify_modify]
            my_acl[:notify_delete] = notification[:notify_delete]
          else
            # create new record
            my_acl = SpinAccessControl.new
            # set spin_access_contrtol
            #          gacl_str = g[:group_privilege]
            #          gacl = ((gacl_str[0] == 'r' ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (gacl_str[1] == 'w' ? ACL_NODE_WRITE : ACL_NODE_NO_ACCESS) | (gacl_str[2] == 'a' ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
            my_acl[:notify_upload] = notification[:notify_upload]
            my_acl[:notify_modify] = notification[:notify_modify]
            my_acl[:notify_delete] = notification[:notify_delete]
            #my_acl[:spin_gid] = (my_group == nil ? primary_group : my_group[:spin_gid])
            my_acl[:spin_gid] = g[:member_id]
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
            #          my_acl[:updated_at] = Time.now
          end
          if my_acl.save
            acl_records += 1
          end
        end
      } # => end of group   
    end # => end of if groups != nil
    return acl_records
  end # => end of set_groups_access_control node_hashkey, groups

  def self.remove_groups_notify_control gacl, node_hashkey, groups
    # first : get record which has spin_gid values
    acl_records = 0
    # for groups in array 'groups'
    groups.each {|g|
      # analyze group
      # it may be a member of the group
      # we use member's primary group ( group assigned at user registration ) if it is
      my_acls = nil
      group_id = SpinGroup.get_group_id_by_group_name(g[:group_name])
#      self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      self.transaction do
        #        my_group = SpinGroup.select("spin_gid").where(:spin_group_name => g[:group_name]).first
        my_acls = self.where(["spin_gid = ? AND managed_node_hashkey = ?", group_id, node_hashkey ])
      end
      #      r = my_acls.length
      #      if r > 0
#      self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      self.transaction do
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
      end
      #      end
    } # => end of group
    return acl_records
  end # => end of add_groups_access_control node_hashkey, groups
 
  def self.has_notification sid, node_key, node_type = ANY_TYPE
    # use has_acl to know it is accessible node or not before call this
    # because this method doesn't check access right.
    
    # get uid and gid
    ids = SessionManager.get_uid_gid(sid, false)
    if ids[:uid] == ACL_SUPERUSER_UID or ids[:gid] == ACL_SUPERUSER_GID
      return ACL_NODE_SUPERUSER_ACCESS
    end
    if SetUtility::SetOp.is_in_set ACL_SUPERUSER_GID, ids[:gids]
      return ACL_NODE_SUPERUSER_ACCESS
    end
    my_gids = ids[:gids]
    uid = ids[:uid]

    notify_upload = ACL_NOTIFY_NONE
    notify_modify = ACL_NOTIFY_NONE
    notify_delete = ACL_NOTIFY_NONE
    
    # search spin_acces_contorols for ACL related with these ID's
    # are there records which have my uid or gid?
    node_acls = Array.new
#    self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
    self.transaction do
      my_gids.each {|gid|
        if node_type == ANY_TYPE
          acls_query = sprintf("SELECT notify_upload,notify_modify,notify_delete FROM spin_access_controls WHERE managed_node_hashkey = \'%s\' AND (spin_uid = %d  OR (spin_gid = %d AND spin_gid_access_right > %d) OR spin_world_access_right > %d) AND is_void = false ORDER BY id DESC FOR share;",node_key,uid,gid,ACL_NODE_NO_ACCESS,ACL_NODE_NO_ACCESS)
          acls = self.connection.select_all(acls_query)
          #          acls = self.readonly.select("notify_upload,notify_modify,notify_delete").where(["managed_node_hashkey = ? AND (spin_uid = ?  OR (spin_gid = ? AND spin_gid_access_right > ?) OR spin_world_access_right > ?) AND is_void = false", node_key,uid,gid,ACL_NODE_NO_ACCESS,ACL_NODE_NO_ACCESS]).order("id DESC")
        else # => node type specified
          acls_query = sprintf("SELECT notify_upload,notify_modify,notify_delete FROM spin_access_controls WHERE spin_node_type = %d AND managed_node_hashkey = \'%s\' AND (spin_uid = %d  OR (spin_gid = %d AND spin_gid_access_right > %d) OR spin_world_access_right > %d) AND is_void = false ORDER BY id DESC FOR share;",node_type,node_key,uid,gid,ACL_NODE_NO_ACCESS,ACL_NODE_NO_ACCESS)
          acls = self.connection.select_all(acls_query)
          #          acls = self.readonly.select("notify_upload,notify_modify,notify_delete").where(["spin_node_type = ? AND managed_node_hashkey = ? AND (spin_uid = ? OR (spin_gid = ? AND spin_gid_access_right > ?) OR spin_world_access_right > ?) AND is_void = false", node_type,node_key,uid,gid,ACL_NODE_NO_ACCESS,ACL_NODE_NO_ACCESS]).order("id DESC")
        end
        if acls.length > 0
          node_acls += acls
        end
      }

      node_acls.each {|na|
        notify_upload = na['notify_upload'].to_i
        notify_modify = na['notify_modify'].to_i
        notify_delete = na['notify_delete'].to_i
      }
    end
    # returns union of acls for uid and gids
    retv = notify_upload + (notify_modify * 2) + (notify_delete * 4)
    return ( retv )
  end # => end of has_acl
  
end
