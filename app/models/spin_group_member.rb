# coding: utf-8
require 'const/vfs_const'
require 'const/stat_const'
require 'const/acl_const'

class SpinGroupMember < ActiveRecord::Base
  include Vfs
  include Stat
  include Acl

  attr_accessor :spin_gid, :spin_uid

  def self.get_user_groups uid
    gids = Array.new
    #    groups_query = sprintf("SELECT spin_gid FROM spin_group_members WHERE spin_uid = %d", uid)
    #    groups = self.connection.select_all(groups_query)
    begin
      groups = self.select("spin_gid").where(["spin_uid = ?", uid])
      groups.each {|g|
        gids.push(g['spin_gid'].to_i)
      }
      return gids
    rescue ActiveRecord::RecordNotFound
      return gids
    end
    #    groups = self.select(:spin_gid).where(["spin_uid = ?", uid])
  end

  def self.get_member_uids gid
    uids = Array.new
    begin
      uids = self.where(["spin_gid = ?", gid])
      return uids
    rescue ActiveRecord::RecordNotFound
      return uids
    end
  end

  def self.get_parent_gids gid, id_type = GROUP_MEMBER_ID_TYPE_USER_PRIMARY_GROUP
    my_gids = []
    my_gids.push gid
    # get groups for primary group id
    #    direct_parent_groups_query = sprintf("SELECT spin_gid FROM spin_group_members WHERE id_type = %d AND spin_uid = %d",id_type,gid)
    #    direct_parent_groups = self.connection.select_all(direct_parent_groups_query)
    begin
      direct_parent_groups = self.select("spin_gid").where(["id_type = ? AND spin_uid = ?", id_type, gid])
      direct_parent_groups.each {|dpg|
        next if dpg['spin_gid'].to_i == gid # => skip myself
        my_gids.push dpg['spin_gid'].to_i
        my_gids += self.get_parent_gids dpg['spin_gid'].to_i, GROUP_MEMBER_ID_TYPE_GROUP
      }
      return my_gids
    rescue ActiveRecord::RecordNotFound
      return my_gids
    end
  end

  def self.get_brief_member_name_list gid
    uids = []
    begin
      uids = self.select("spin_uid").where(["spin_gid = ?", gid])
      namelist = String.new('')
      uids.each {|ui|
        n1, nm, n2 = SpinUserAttribute.get_user_real_name ui[:spin_uid]
        if namelist.length < 20
          if n1
            namelist << ',' << n1
          end
        else
          namelist << '...'
          break
        end
      }
    rescue ActiveRecord::RecordNotFound
      return namelist
    end
  end

  def self.is_administrator uid
    # start
    if uid == Vfs::ROOT_USER_ID
      return true
    end

    gm = self.readonly.where(spin_uid: uid)
    if gm.blank? # => spin_uid user is already a member
      return false
    else
      gm.each do |gr|
        if gr[:spin_gid] == Vfs::ROOT_GROUP_ID
          return true
        end
      end
    end
    return false
  end

  # => end of self.add_member sid, spin_uid, spin_gid
  def self.add_member sid, spin_uid, spin_gid, id_type = GROUP_MEMBER_ID_TYPE_GROUP
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

    # start
    # gm = self.readonly.find_by_spin_uid_and_spin_gid spin_uid, spin_gid
    new_member_rec = nil
    new_member_rec = self.find_or_create_by(spin_uid: spin_uid, spin_gid: spin_gid) do |new_member|
      # add member
      new_member[:spin_uid] = spin_uid
      new_member[:spin_gid] = spin_gid
      new_member[:id_type] = id_type
    end
    if new_member_rec.present? # => spin_uid user is already a member
      rethash[:success] = true
      rethash[:status] = INFO_SYSADMIN_ADD_GROUP_MEMBER_ALREADY_A_MEMBER
      rethash[:result] = {:uid => spin_uid, :gid => spin_gid}
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_ADD_GROUP_MEMBER
      rethash[:errors] = "Failed to add group member : ERROR_SYSADMIN_FAILED_TO_ADD_GROUP_MEMBER"
    end
    return rethash
  end

  # => end of self.add_member sid, spin_uid, spin_gid

  def self.delete_member sid, spin_uid, spin_gid, delete_all = false
    # simply create group record
    rethash = {}
    # Am I an administrator?
    ids = SessionManager.get_uid_gid(sid, false)
    if ids[:uid] == 0 or ids[:gid] == 0 or SpinUser.is_group_editable(ids[:uid])
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE
      rethash[:errors] = "Failed to delete group member record : ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE"
      return rethash
    end

    # start
    gm = self.find_by_spin_uid_and_spin_gid spin_uid, spin_gid
    if gm == nil # => spin_uid user is already a member
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_DELETE_GROUP_MEMBER
      rethash[:result] = "No such user in the specified group but it\'s OK"
    else
      gm.destroy
      rethash[:success] = true
      rethash[:status] = INFO_SYSADMIN_DELETE_GROUP_MEMBER_SUCCESS
      rethash[:result] = {:spin_gid => spin_gid, :spin_uid => spin_uid}
    end

    if delete_all
      members = self.where(["spin_uid = ?", spin_uid])
      members.each {|m|
        m.destroy
      }
    end
    rethash[:success] = true
    rethash[:status] = INFO_SYSADMIN_DELETE_GROUP_MEMBER_SUCCESS
    rethash[:result] = {:spin_gid => spin_gid, :spin_uid => spin_uid}
    return rethash
  end

  # => end of self.add_member sid, spin_uid, spin_gid

  def self.delete_group_members sid, spin_gid
    # simply create group record
    rethash = {}
    # Am I an administrator?
    ids = SessionManager.get_uid_gid(sid, false)
    if ids[:uid] == 0 or ids[:gid] == 0 or SpinUser.is_group_editable(ids[:uid])
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE
      rethash[:errors] = "Failed to delete group member record : ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE"
      return rethash
    end

    # start
    gms = self.where(["spin_gid = ?", spin_gid])
    if gms.length == 0 # => spin_uid user is already a member
      rethash[:success] = true
      rethash[:status] = INFO_DELETE_GROUP_MEMBER_WITH_NO_MEMBER_SUCCESS
      rethash[:result] = "No such member in the specified group but it\'s OK"
    else
      del_recs = 0
      gms.each {|gm|
        gm.destroy
        del_recs += 1
      }
      rethash[:success] = true
      rethash[:status] = INFO_DELETE_GROUP_MEMBER_SUCCESS
      rethash[:result] = del_recs
    end

    return rethash
  end

  # => end of self.add_member sid, spin_uid, spin_gid

  def self.modify_member sid, spin_uid, current_gid, spin_gid
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

    # start
    gm = self.readonly.find_by_spin_uid_and_spin_gid spin_uid, current_gid
    if gm == nil # => spin_uid user is already a member
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_MODIFY_GROUP_MEMBER
      rethash[:result] = {:uid => spin_uid, :gid => spin_gid}
    end
    # add member
    mod_member = self.find_by_spin_gid_and_spin_uid spin_uid, current_gid
    if mod_member != nil
      mod_member[:spin_uid] = spin_uid
      mod_member[:spin_gid] = spin_gid
      if mod_member.save
        rethash[:success] = true
        rethash[:status] = INFO_SYSADMIN_MODIFY_GROUP_MEMBER_SUCCESS
        rethash[:result] = {:uid => spin_uid, :gid => spin_gid}
        return rethash
      else
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_FAILED_TO_MODIFY_GROUP_MEMBER
        rethash[:errors] = "Failed to modify group member : ERROR_SYSADMIN_FAILED_TO_MODIFY_GROUP_MEMBER"
        return rethash
      end
    end
    rethash[:success] = true
    rethash[:status] = INFO_SYSADMIN_MODIFY_GROUP_MEMBER_SUCCESS
    rethash[:result] = {:uid => spin_uid, :gid => spin_gid}
    return rethash
  end

  # => end of self.add_member sid, spin_uid, spin_gid

  def self.append_group_members_to_current_selected_group session_id, groups, params, gid
    reth = {}
    appended_members = 0
    #extended_groups = []

    #groups.each {|gr|
    #  mem_gid = SpinGroup.get_group_id_by_group_name(gr[:group_name])
    #  gmembers = self.get_member_uids(mem_gid)
    #  gmembers.each {|gm|
    #    id_type = gm[:id_type]
    #    case id_type
    #    when GROUP_MEMBER_ID_TYPE_USER # => primary group
    #      group_name = SpinGroup.get_group_name(gm[:spin_gid])
    #      extended_groups.push(group_name)
    #    when GROUP_MEMBER_ID_TYPE_USER_PRIMARY_GROUP,GROUP_MEMBER_ID_TYPE_GROUP # => member is group
    #      group_name = SpinGroup.get_group_name(gm[:spin_uid])
    #      extended_groups.push(group_name)
    #    else
    #      group_name = SpinGroup.get_group_name(gm[:spin_uid])
    #      extended_groups.push(group_name)
    #    end
    #    extended_groups.push(gm[:group_name])
    #  }
    #}

    #extended_groups.uniq!

    #extended_groups.each { |gr|
    #  target_group_name = SessionManager.get_current_selected_group_name session_id
    #  target_gid = SpinGroup.get_group_id_by_group_name(target_group_name)
    #  member_gid = SpinGroup.get_group_id_by_group_name(gr)
    #  next if target_gid == member_gid
    #      member_gid = gr[:group_id]
    #  reth = self.add_member session_id, member_gid, target_gid, SpinGroup.get_id_type_by_group_name(gr)
    #  if reth[:success] == false
    #    return reth
    #  end
    #  appended_members += 1
    #}
    groups.each {|gr|
      #target_group_name = SessionManager.get_current_selected_group_name session_id
      #target_gid = SpinGroup.get_group_id_by_group_name(target_group_name)
      #target_gid = gr[:group_id]
      target_gid = gid;
      member_gid = gr[:member_id];

      next if target_gid == member_gid
      #      member_gid = gr[:group_id]
      reth = self.add_member session_id, member_gid, target_gid
      if reth[:success] == false
        return reth
      end
      appended_members += 1
    }
    reth[:result] = appended_members
    return reth
  end

  # => end of append_group_members_to_current_selected_group my_session_id, list_groups, hash_params

  def self.remove_group_members_from_group session_id, group_id, members
    # remove members from group with id_type != GROUP_MEMBER_ID_TYPE_USER
    reth = {}
    removed_members = 0
    members.each {|member|
      reth = self.delete_member session_id, member[:member_id].to_i, group_id
      if reth[:success] == false
        return reth
      end
      removed_members += 1
    }
    reth[:result] = removed_members
    return reth
  end # => end of remove_group_members_from_current_selected_group my_session_id, my_group_id, list_members

end
