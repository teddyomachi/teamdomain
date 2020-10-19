# coding: utf-8
require 'const/vfs_const'
require 'const/stat_const'
require 'const/acl_const'

class SpinGroup < ActiveRecord::Base
  include Vfs
  include Stat
  include Acl
  
  attr_accessor :group_atrtributes, :group_descr, :spin_gid, :spin_group_name

  def self.create_group sid, group_name, group_id, group_description
    # get uid
    ids = SessionManager.get_uid_gid(sid)
    uid = ids[:uid]
    
    # generate new gid if grop_id is ANY_GID : -1
    current_gid = MIN_GID
    if group_id == ANY_GID
      gid_rec = self.find_by_sql("SELECT spin_gid FROM spin_groups ORDER BY spin_gid DESC LIMIT 1")
      if gid_rec.length > 0
        current_gid = gid_rec[0][:spin_gid] + 1
      end
    else
      if group_id > MAX_GID
        return { :success => false, :status => ERROR_GID_EXCEEDS_MAX_GID, :errors => 'Given GID is out of range. gid > MAX_GID'}
      end
    end
    
    # Is the group_id unique?
    if self.find_by_spin_gid(group_id) != nil
      return { :success => false, :status => ERROR_GID_IS_NOT_UNIQUE, :errors => 'Given GID is already used'}
    end
    
    # Is the group_name unique?
    if self.find_by_spin_group_name(group_name) != nil
      return { :success => false, :status => ERROR_GROUP_NAME_IS_NOT_UNIQUE, :errors => 'Given group name is already used'}
    end
    
    reth = self.add_group(sid, uid, current_gid, group_name, group_description, GROUP_LIST_DATA_GROUP)    
    if reth[:success] == false  # => failed to add new group
      return reth
    end
    
    return { :success => true, :status => INFO_SYSADMIN_ADD_GROUP_RECORD_SUCCESS }
  end # => end of self.create_group my_session_id, my_new_group_name, my_new_group_id, my_new_group_decription

  def self.get_group_name gid
    g = self.find_by_spin_gid gid
    if g != nil
      return g[:spin_group_name]
    else
      return ''
    end
  end
  
  def self.get_group_description group_name
    g = self.find_by_spin_group_name group_name
    if g == nil
      return nil
    end
    return g[:group_descr]
  end
  
  def self.add_group sid, spin_uid, spin_gid, spin_group_name, group_descr, id_type = GROUP_LIST_DATA_GROUP
    # simply create group record
    rethash = {}
    # Am I an administrator?
    ids = SessionManager.get_uid_gid(sid, false)
    if ids[:uid] == 0 or ids[:gid] == 0 or SpinUser.is_group_editable(spin_uid) == true
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE
      rethash[:errors] = "Failed to create group record : ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE"
      return rethash
    end
    new_group_rec = self.new
    new_group_rec[:spin_gid] = spin_gid
    new_group_rec[:spin_group_name] = spin_group_name
    new_group_rec[:group_descr] = group_descr
    new_group_rec[:owner_id] = spin_uid
    new_group_rec[:id_type] = id_type
    if new_group_rec.save
      rethash[:success] = true
      rethash[:status] = INFO_SYSADMIN_ADD_GROUP_RECORD_SUCCESS
      rethash[:result] = { :gid => spin_gid, :spin_group_name => spin_group_name }
      
      # add group member
      if spin_uid != nil and id_type == GROUP_LIST_DATA_USER_PRIMARY_GROUP
        reth = SpinGroupMember.add_member sid, spin_uid, spin_gid, (id_type == GROUP_LIST_DATA_USER_PRIMARY_GROUP ? GROUP_MEMBER_ID_TYPE_USER : id_type)
        if reth[:success] == false
          return reth
        end
      end
    else # => failed tyo save new_group_rec
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_ADD_GROUP_RECORD
      rethash[:errors] = "Failed to add group record : ERROR_SYSADMIN_FAILED_TO_ADD_GROUP_RECORD"
      return rethash
    end # => end of if new_group_rec.save

    return rethash

  end # => end of self.add_group sid, spin_gid, spin_group_name, group_descr

  def self.delete_group sid, spin_gid
    # simply create group record
    rethash = {}
    # Am I an administrator?
    ids = SessionManager.get_uid_gid(sid, false)
    if ids[:uid] == 0 or ids[:gid] == 0 or SpinUser.is_group_editable(ids[:uid]) == true
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE
      rethash[:errors] = "Failed to create group record : ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE"
      return rethash
    end

    del_group_rec = self.find_by_spin_gid spin_gid
    if del_group_rec == nil
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_DELETE_GROUP_RECORD
      rethash[:errors] = "Failed to delete group record : ERROR_SYSADMIN_FAILED_TO_DELETE_GROUP_RECORD"
      return rethash
    end
    del_group_rec.destroy
    
    reth = SpinGroupMember.delete_group_members(sid, spin_gid)
    rethash[:success] = true
    rethash[:status] = INFO_SYSADMIN_DELETE_GROUP_RECORD_SUCCESS
    rethash[:result] = { :gid => spin_gid }
    return rethash
  end # => end of if mod_group_rec.save
  
  def self.modify_group sid, spin_uid, current_gid, spin_gid, spin_group_name, group_descr
    # simply create group record
    rethash = {}
    # Am I an administrator?
    ids = SessionManager.get_uid_gid(sid, false)
    if ids[:uid] == 0 or ids[:gid] == 0
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE
      rethash[:errors] = "Failed to create group record : ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE"
      return rethash
    end
    mod_group_rec = self.find_by_spin_gid current_gid
    mod_group_rec[:spin_gid] = spin_gid
    mod_group_rec[:spin_group_name] = spin_group_name
    mod_group_rec[:group_descr] = group_descr
    if mod_group_rec.save
      rethash[:success] = true
      rethash[:status] = INFO_SYSADMIN_MODIFY_GROUP_RECORD_SUCCESS
      rethash[:result] = { :gid => spin_gid, :spin_group_name => spin_group_name }
      
      # add group member
      if spin_uid != nil
        reth = SpinGroupMember.modify_member sid, spin_uid, current_gid, spin_gid
        if reth[:success] == false
          return reth
        end
      end
    else # => failed tyo save mod_group_rec
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_ADD_GROUP_RECORD
      rethash[:errors] = "Failed to modify group record : ERROR_SYSADMIN_FAILED_TO_ADD_GROUP_RECORD"
      return rethash
    end # => end of if mod_group_rec.save

    return rethash

  end # => end of self.add_group sid, spin_gid, spin_group_name, group_descr
  
  def self.get_id_type_by_group_id gid
    sql="select id_type from spin_groups where spin_gid="+gid;
    gr = self.find_by_sql(sql);
    if gr != nil
      return gr[0][:id_type]
    else
      return GROUP_INITIAL_MEMBER_ID_TYPE
    end
  end
  
  def self.get_id_type_by_group_id gname
    gr = self.find_by_spin_group_name gname
    if gr != nil
      return gr[:id_type]
    else
      return GROUP_INITIAL_MEMBER_ID_TYPE
    end
  end # => end of self.get_id_type_by_group_name gname
  
  def self.get_group_id_by_group_name gname
    gr = self.find_by_spin_group_name gname
    if gr != nil
      return gr[:spin_gid]
    else
      return -1
    end
  end # => end of self.get_group_id_by_group_name gname
  
  def self.select_group session_id, selected_group_name
    ses = SpinSession.find_by_spin_session_id session_id
    ses[:current_selected_group_name] = selected_group_name
    if ses.save
      return self.get_group_id_by_group_name selected_group_name
    else
      return -1
    end
  end # => end of self.select_group my_session_id, my_selected_group_name
  
  def self.modify_group_info group_id, new_group_name, new_group_description
    grp = self.find_by_spin_gid group_id
    rethash = {}
    if grp == nil
      rethash[:success] = false
      rethash[:status] = ERROR_FAILED_TO_GET_GROUP_INFO
      rethash[:errors] = "Failed to get group info record : ERROR_FAILED_TO_GET_GROUP_INFO"
      return rethash
    end
    if new_group_name.length == 0 and new_group_description.length == 0
      rethash[:success] = true
      rethash[:status] = INFO_MODIFY_GROUP_INFO_WITH_NO_CHANGE_SUCCESS
      rethash[:result] = group_id
    end
    
    # modify each
    if new_group_name.length > 0
      grp[:spin_group_name] = new_group_name
    end
    if new_group_description.length > 0
      grp[:group_descr] = new_group_description
    end
    if grp.save
      rethash[:success] = true
      rethash[:status] = INFO_MODIFY_GROUP_INFO_SUCCESS
      rethash[:result] = group_id
    else # => error
      rethash[:success] = false
      rethash[:status] = ERROR_FAILED_TO_MODIFY_GROUP_INFO
      rethash[:errors] = "Failed to modify group info record : ERROR_FAILED_TO_MODIFY_GROUP_INFO"
    end
    
    return rethash
  end # => end of modify_group_info my_group_id, my_group_description, my_new_group_name, my_new_group_description
  
end
