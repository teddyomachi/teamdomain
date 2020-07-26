# coding: utf-8
require 'const/vfs_const'
require 'const/stat_const'
require 'const/acl_const'

class SpinUser < ActiveRecord::Base
  include Vfs
  include Stat
  include Acl

  attr_accessor :spin_login_directory, :spin_default_domain, :spin_default_server, :spin_gid, :spin_passwd, :spin_projid, :spin_uid, :spin_uname, :user_level_x, :user_level_y

  def self.get_working_directory uid
    begin
      w = self.find_by_spin_uid uid
      if w.blank?
        return nil
      end
      return w[:spin_login_directory]
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  # => end of get_working_directory

  def self.get_login_directory uid
    begin
      l = self.find_by_spin_uid uid
      if l.blank?
        return nil
      end
      return l[:spin_login_directory]
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  # => end of get_login_directory

  def self.get_default_domain sid
    ids = SessionManager.get_uid_gid(sid, true)
    uid = ids[:uid]
    gids = ids[:gids]
    begin
      l = self.find_by_spin_uid uid
      if l.blank?
        return nil
      end
      if l[:spin_default_domain]
        return l[:spin_default_domain]
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  # => end of get_default_domain

  def self.get_primary_group uid
    begin
      g = self.readonly.select("spin_gid").find_by_spin_uid uid
      if g.blank?
        return nil
      end
      return g[:spin_gid]
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  # => end of get_primary_group

  def self.is_group_editable uid
    if uid == 0
      return true
    end
    begin
      ge = self.readonly.select("is_group_editor").find_by_spin_uid uid
      if ge.blank?
        return false
      end
      return ge[:is_group_editor]
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  def self.get_uname uid
    begin
      u = self.readonly.select("spin_uname").find_by_spin_uid uid
      if u.blank?
        return u[:spin_uname]
      else
        return nil
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  def self.get_member_name gid
    begin
      u = self.readonly.select("spin_uname").find_by_spin_gid gid
      if u.blank?
        return u[:spin_uname]
      else
        return nil
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  def self.get_uid uname
    begin
      u = self.readonly.select("spin_uid").find_by_spin_uname uname
      if u.present?
        return u[:spin_uid]
      else
        return ANY_UID
      end
    rescue ActiveRecord::RecordNotFound
      return ANY_UID
    end
  end

  def self.select_user_from_form sid, form_data_hash
    rethash = {}
    # Am I an administrator?
    ids = SessionManager.get_uid_gid(sid, true)
    if ids[:uid] == 0 or ids[:gid] == 0
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE
      rethash[:errors] = "Failed to create user record : ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE"
      return rethash
    end

    sql = "select
           A.spin_uid,A.spin_uname,A.spin_passwd,A.spin_login_directory,B.real_uname1,B.organization1,B.organization2,B.organization3,B.mail_addr,C.spin_gid,C.spin_group_name,C.group_descr
           from
           spin_users A,spin_user_attributes B,spin_groups C
           where
           A.spin_uid=B.spin_uid
           and
           A.spin_gid=C.spin_gid
           and 
           A.spin_uname
           like '" + form_data_hash[:user_name].to_s + "%'"

    user_list = self.find_by_sql(sql)

    disp_user_list = []

    rethash[:success] = true
    rethash[:status] = INFO_SYSADMIN_CREATE_USER_SUCCESS
    rethash[:result] = 200

    user_list.each {|usr|
      next if /template-*/ =~ usr[:spin_uname]

      ur = {}
      ur[:hash_key] = "N/A"
      ur[:user_id] = usr[:spin_uid]
      ur[:user_name] = usr[:spin_uname]
      ur[:real_uname] = usr[:real_uname1]
      ur[:company_name] = usr[:organization1]
      ur[:user_post] = usr[:organization2]
      ur[:employee_number] = usr[:organization3]
      login_directory = DatabaseUtility::VirtualFileSystemUtility.key_to_path(usr[:spin_login_directory])
      ur[:user_directory] = login_directory
      #          ur[:user_directory] = ua['user_directory']
      ur[:user_mail] = usr[:mail_addr]
      ur[:user_pw] = usr[:spin_passwd]
      ur[:p_group_id] = usr[:spin_gid]
      ur[:p_group_name] = usr[:spin_group_name]
      ur[:p_group_description] = usr[:group_descr]

      disp_user_list.push(ur)
    }
    rethash[:display_data] = disp_user_list

    #    rethash[:total] = disp_user_list.length

    return rethash
  end

  def self.create_user_from_form sid, form_data_hash, is_sticky = false, is_group_editor = true, is_activated = true
    rethash = {}
    # user id
    spin_uid = form_data_hash['user_id']
    # user name
    spin_uname = form_data_hash['user_name']

    #    current_uid = ANY_UID
    if spin_uid == nil or spin_uid == ''
      begin
        urec = self.find_by_sql("SELECT spin_uid FROM spin_users ORDER BY spin_uid DESC LIMIT 1;")
        if urec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_SYSADMIN_DUPLICATE_UID
          rethash[:errors] = "Duplicate user id"
          return rethash
        else
          spin_uid = (urec[0][:spin_uid] >= MIN_UID ? urec[0][:spin_uid] + 1 : MIN_UID)
        end
      rescue ActiveRecord::RecordNotFound
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_DUPLICATE_UID
        rethash[:errors] = "Duplicate user id"
        return rethash
      end
    end

    # Is it unique?]
    begin
      u = self.readonly.find_by_spin_uname spin_uname
      if u.present? # => uid already used!
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_DUPLICATE_UID
        rethash[:errors] = "Duplicate user id"
        return rethash
      end
    rescue ActiveRecord::RecordNotFound
    end

    # user password
    spin_password = form_data_hash['user_pw']
    if self.is_valid_password(spin_password) == false
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INVALID_PASSWORD
      rethash[:errors] = "Specified password is invalid."
      return rethash
    end

    # user group
    spin_gid = form_data_hash['p_group_id']
    if spin_gid.empty?
      begin
        grec = SpinGroup.find_by_spin_gid spin_uid
        if grec.blank?
          spin_gid = spin_uid
        else
          grec = self.find_by_sql("SELECT spin_gid FROM spin_groups ORDER BY spin_gid DESC LIMIT 1;")
          if urec.blank?
            spin_gid = spin_uid
          else
            spin_gid = (grec[0][:spin_gid] >= MIN_UID ? grec[0][:spin_gid] + 1 : MIN_GID)
          end
        end
      rescue ActiveRecord::RecordNotFound
        spin_gid = spin_uid
      end
    end
    spin_group_name = form_data_hash['p_group_name']
    group_descr = form_data_hash['p_group_description']

    # Is it unique?
    begin
      g = SpinGroup.readonly.find_by_spin_gid spin_gid
      if g.present? # => gid already used!
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_DUPLICATE_GID
        rethash[:errors] = "Duplicate group id"
        return rethash
        #    else # => create it
      end
    rescue ActiveRecord::RecordNotFound
    end

    # create user and group
    reth = self.add_user sid, spin_uid, spin_gid, spin_uname, spin_password, is_group_editor, is_activated
    if reth[:success] == false
      return reth
    end

    reth = SpinGroup.add_group sid, spin_uid, spin_gid, spin_group_name, group_descr, GROUP_LIST_DATA_USER_PRIMARY_GROUP
    if reth[:success] == false
      return reth
    end

    # into user attributes
    user_attributes = {}
    user_attributes[:real_uname] = form_data_hash['real_uname']
    user_attributes[:user_id] = spin_uid
    user_attributes[:user_name] = spin_uname
    user_attributes[:user_post] = form_data_hash['user_post']

    # mail
    user_attributes[:mail_addr] = form_data_hash['user_mail']
    user_attributes[:company_name] = form_data_hash['company_name']
    user_attributes[:employee_number] = form_data_hash['employee_number']
    user_attributes[:user_directory] = form_data_hash['user_directory']
    reth = SpinUserAttribute.add_user_attribute sid, user_attributes
    if reth[:success] == false
      return reth
    end

    # login directory
    spin_login_directory = ''
    if form_data_hash['user_directory'].blank?
      spin_login_directory = spin_uname
    else
      spin_login_directory = form_data_hash['user_directory']
    end
    if spin_login_directory.empty?
      spin_login_directory = self.get_user_template DEFAULT_USER_LEVEL_X, DEFAULT_USER_LEVEL_Y, DEFAULT_LOGIN_DIRECTORY, form_data_hash['p_group_name']
    elsif spin_login_directory[0, 1] != '/' # => relative
      spin_login_directory = SYSTEM_DEFAULT_LOGIN_DIRECTORY + '/' + spin_login_directory
    end
    vp = spin_login_directory # =>  + spin_uname
    reth = self.create_directory sid, vp, true, spin_uid, spin_gid, ACL_DEFAULT_UID_ACCESS_RIGHT, ACL_DEFAULT_GID_ACCESS_RIGHT, ACL_DEFAULT_WORLD_ACCESS_RIGHT, is_sticky
    if reth[:success] == false
      return reth
    end
    spin_login_directory_key = reth[:result]
    reth = self.add_login_directory sid, spin_uid, spin_login_directory_key
    if reth[:success] == false
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_CREATE_USER_LOGIN_DIRECTORY
      rethash[:errors] = "Failed to create user login directory"
      return rethash
    end

    rethash[:success] = true
    rethash[:status] = INFO_SYSADMIN_CREATE_USER_SUCCESS
    rethash[:result] = spin_uid

    return rethash
  end

  # => end of create_user_from_form  sid, form_data_hash

  def self.update_user_from_form sid, form_data_hash
    rethash = {}
    # user id
    spin_uid = form_data_hash['user_id']
    current_user = {}

    #    current_uid = ANY_UID
    if spin_uid == nil or spin_uid.empty?
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INVALID_UID
      rethash[:errors] = "Invalid user id"
      return rethash
    else
      # Is it unique?
      begin
        current_user = self.readonly.find_by_spin_uid spin_uid
        if current_user.blank? # => uid isn't there!
          rethash[:success] = false
          rethash[:status] = ERROR_SYSADMIN_NO_SUCH_USER_UID
          rethash[:errors] = "No such user id"
          return rethash
        end
      rescue ActiveRecord::RecordNotFound
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_NO_SUCH_USER_UID
        rethash[:errors] = "No such user id"
        return rethash
      end
    end

    # user password
    spin_password = form_data_hash['user_pw']
    if self.is_valid_password(spin_password) == false
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INVALID_PASSWORD
      rethash[:errors] = "Specified password is invalid."
      return rethash
    end

    # is_group_editor
    group_editor_flag = nil
    if form_data_hash['is_group_editor'].present?
      group_editor_flag = form_data_hash['is_group_editor']
    end

    # is_activated
    activated_flag = nil
    if form_data_hash['is_activated'].present?
      activated_flag = form_data_hash['is_activated']
    end

    # user name
    spin_uname = form_data_hash['user_name']
    begin
      uname = self.find_by_spin_uname spin_uname
      if uname.blank? and uname[:spin_uid] != spin_uid.to_i # => already is!
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_INVALID_UID
        rethash[:errors] = "既に" + spin_uname + "は使われています"
        return rethash
      end
    rescue ActiveRecord::RecordNotFound
    end

    # user group
    current_gid = current_user[:spin_gid]
    spin_gid = form_data_hash['p_group_id']
    if spin_gid.empty?
      spin_gid = spin_uid
    end
    spin_group_name = form_data_hash['p_group_name']
    group_descr = form_data_hash['p_group_description']

    # Is it there?
    g = SpinGroup.readonly.find_by_spin_gid spin_gid
    if g.blank? # => gid is new!
      reth = SpinGroup.add_group sid, spin_uid, spin_gid, spin_group_name, group_descr, GROUP_LIST_DATA_USER_PRIMARY_GROUP
      if reth[:success] == false
        return reth
      end
    else
      reth = SpinGroup.modify_group sid, spin_uid, current_gid, spin_gid, spin_group_name, group_descr
      if reth[:success] == false
        return reth
      end
    end

    # modify user and group
    reth = self.modify_user sid, spin_uid, spin_gid, spin_uname, spin_password, group_editor_flag, activated_flag
    if reth[:success] == false
      return reth
    end


    # into user attributes
    user_attributes = {}
    user_attributes[:real_uname] = form_data_hash['real_uname']
    user_attributes[:user_id] = spin_uid
    user_attributes[:user_name] = spin_uname

    # mail
    user_attributes[:mail_addr] = form_data_hash['user_mail']
    user_attributes[:company_name] = form_data_hash['company_name']
    user_attributes[:user_post] = form_data_hash['user_post']
    user_attributes[:employee_number] = form_data_hash['employee_number']
    user_attributes[:user_directory] = form_data_hash['user_directory']
    reth = SpinUserAttribute.modify_user_attribute sid, current_user[:spin_uname], user_attributes
    if reth[:success] == false
      return reth
    end

    # login directory
    spin_login_directory = form_data_hash['user_directory']
    if spin_login_directory.empty?
      spin_login_directory = self.get_user_template DEFAULT_USER_LEVEL_X, DEFAULT_USER_LEVEL_Y, DEFAULT_LOGIN_DIRECTORY, form_data_hash['p_group_name']
    end
    # ユーザー名が変更されてぁE��場合�EログインチE��レクトリ新規作�E
    if spin_uname != current_user[:spin_uname]
      dir_path = spin_login_directory.split(/\//)
      dir_path.pop # => pop user
      spin_login_directory = ''
      dir_path.each {|dp|
        spin_login_directory += dp + '/'
      }
      vp = spin_login_directory + spin_uname
    else
      vp = spin_login_directory
    end

    reth = self.modify_directory sid, vp, true, spin_uid, spin_gid, ACL_DEFAULT_UID_ACCESS_RIGHT, ACL_DEFAULT_GID_ACCESS_RIGHT, ACL_DEFAULT_WORLD_ACCESS_RIGHT
    if reth[:success] == false
      return reth
    end
    spin_login_directory_key = reth[:result]
    reth = self.modify_login_directory sid, spin_uid, spin_login_directory_key
    if reth[:success] == false
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_CREATE_USER_LOGIN_DIRECTORY
      rethash[:errors] = "Failed to create user login directory"
      return rethash
    end

    rethash[:success] = true
    rethash[:status] = INFO_SYSADMIN_CREATE_USER_SUCCESS
    rethash[:result] = spin_uid

    return rethash
  end

  # => end of create_user_from_form  sid, form_data_hash

  def self.delete_user_from_form sid, form_data_hash
    rethash = {}
    # user id
    spin_uid = form_data_hash['user_id']

    #    current_uid = ANY_UID
    if spin_uid == nil or spin_uid == ''
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INVALID_UID
      rethash[:errors] = "Specified spin_uid is invalid."
      return rethash
    end

    # user group
    spin_gid = form_data_hash['p_group_id']

    # create user and group
    reth = self.delete_user sid, spin_uid
    if reth[:success] == false
      return reth
    end

    # into user attributes
    reth = SpinUserAttribute.delete_user_attribute sid, spin_uid
    if reth[:success] == false
      return reth
    end

    reth = SpinGroup.delete_group sid, spin_gid
    if reth[:success] == false
      return reth
    end

    reth = SpinGroupMember.delete_member(sid, spin_uid, spin_gid, true)
    if reth[:success] == false
      return reth
    end

    return rethash
  end

  # => end of create_user_from_form  sid, form_data_hash

  def self.add_user sid, spin_uid, spin_gid, spin_uname, spin_password, is_group_editor, is_activated
    # simply create user and group record
    rethash = {}
    # Am I an administrator?
    ids = SessionManager.get_uid_gid(sid, true)
    if ids[:uid] == 0 or ids[:gid] == 0
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE
      rethash[:errors] = "Failed to create user record : ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE"
      return rethash
    end
    new_user_rec = self.new
    new_user_rec[:spin_uid] = spin_uid
    new_user_rec[:spin_gid] = spin_gid
    new_user_rec[:spin_uname] = spin_uname
    new_user_rec[:spin_passwd] = spin_password
    new_user_rec[:is_group_editor] = is_group_editor
    new_user_rec[:activated] = is_activated
    if new_user_rec.save
      rethash[:success] = true
      rethash[:status] = INFO_SYSADMIN_ADD_USER_RECORD_SUCCESS
      rethash[:result] = {:uid => spin_uid, :gid => spin_gid}
      return rethash
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_ADD_USER_RECORD
      rethash[:errors] = "Failed to add user record : ERROR_SYSADMIN_FAILED_TO_ADD_USER_RECORD"
      return rethash
    end
  end

  # =>  end of add_user sid, spin_uid, spin_gid, spin_password

  def self.delete_user sid, spin_uid
    # simply create user and group record
    rethash = {}

    if spin_uid.to_s != '0'
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE
      rethash[:errors] = "Can't Delete Administator: ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE"
      return rethash
    end

    # Am I an administrator?
    ids = SessionManager.get_uid_gid(sid, true)
    if ids[:uid] == 0 or ids[:gid] == 0
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE
      rethash[:errors] = "Failed to create user record : ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE"
      return rethash
    end

    del_user_rec = self.find_by_spin_uid spin_uid
    if del_user_rec.blank?
      return rethash
    end
    uid = del_user_rec[:spin_uid]
    #uname = del_user_rec[:spin_uname]
    if del_user_rec == nil
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_DELETE_USER
      rethash[:errors] = "Failed to delete user record : no such user"
      return rethash
    elsif uid == 0
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_DELETE_USER
      rethash[:errors] = "Failed to delete user record : root user"
      return rethash
    end

    del_user_rec.destroy

    rethash[:success] = true
    rethash[:status] = INFO_SYSADMIN_DELETE_USER_SUCCESS
    rethash[:result] = {:uid => spin_uid}
    return rethash

  end

  # =>  end of add_user sid, spin_uid, spin_gid, spin_password

  def self.modify_user sid, spin_uid, spin_gid, spin_uname, spin_password, is_group_editor = nil, activated = nil
    # simply create user and group record
    rethash = {}
    # Am I an administrator?
    ids = SessionManager.get_uid_gid(sid, true)
    if ids[:uid] == 0 or ids[:gid] == 0 or spin_uid == ids[:uid]
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE
      rethash[:errors] = "Failed to create user record : ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE"
      return rethash
    end
    begin
      mod_user_rec = self.find_by_spin_uid spin_uid
      if mod_user_rec.blank?
        return rethash
      end
      mod_user_rec[:spin_uid] = spin_uid
      mod_user_rec[:spin_gid] = spin_gid
      mod_user_rec[:spin_uname] = spin_uname
      mod_user_rec[:spin_passwd] = spin_password
      if is_group_editor.present?
        if is_group_editor == true or is_group_editor == 'true' or is_group_editor == 't'
          mod_user_rec[:is_group_editor] = true
        else
          mod_user_rec[:is_group_editor] = false
        end
      end
      if activated.present?
        if activated == true or activated == 'true' or activated == 't'
          mod_user_rec[:activated] = true
        else
          mod_user_rec[:activated] = false
        end
      end

      if mod_user_rec.save
        rethash[:success] = true
        rethash[:status] = INFO_SYSADMIN_MODIFY_USER_RECORD_SUCCESS
        rethash[:result] = {:uid => spin_uid, :gid => spin_gid}
        return rethash
      else
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_FAILED_TO_MODIFY_USER_RECORD
        rethash[:errors] = "Failed to modify user record : ERROR_SYSADMIN_FAILED_TO_ADD_USER_RECORD"
        return rethash
      end
    rescue ActiveRecord::RecordNotFound
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_MODIFY_USER_RECORD
      rethash[:errors] = "Failed to modify user record : ERROR_SYSADMIN_FAILED_TO_ADD_USER_RECORD"
      return rethash
    end
  end

  # =>  end of add_user sid, spin_uid, spin_gid, spin_password

  def self.modify_user_name sid, spin_uid, spin_gid, spin_uname
    # simply create user and group record
    rethash = {}

    # Is spin_uname unique?
    begin
      existing_user_rec = self.where(["spin_uname = ? AND spin_uid <> ?", spin_uname, spin_uid])
      if existing_user_rec.length > 0
        rethash[:success] = false
        rethash[:status] = ERROR_USER_NAME_USED_ALREADY
        rethash[:errors] = 'User name \'' + spin_uname + '\' is already used by another user.'
        return rethash
      end
    rescue ActiveRecord::RecordNotFound
    end

    # Am I an administrator?
    ids = SessionManager.get_uid_gid(sid, true)
    if ids[:uid] == 0 or ids[:gid] == 0 or spin_uid == ids[:uid]
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE
      rethash[:errors] = "Failed to create user record : ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE"
      return rethash
    end
    begin
      mod_user_rec = self.find_by_spin_uid spin_uid
      if mod_user_rec.blank?
        return rethash
      end
      mod_user_rec[:spin_uname] = spin_uname
      if mod_user_rec.save
        rethash[:success] = true
        rethash[:status] = INFO_SYSADMIN_MODIFY_USER_RECORD_SUCCESS
        rethash[:result] = {:uid => spin_uid, :gid => spin_gid}
        return rethash
      else
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_FAILED_TO_MODIFY_USER_RECORD
        rethash[:errors] = "Failed to modify user record : ERROR_SYSADMIN_FAILED_TO_ADD_USER_RECORD"
        return rethash
      end
    rescue ActiveRecord::RecordNotFound
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_MODIFY_USER_RECORD
      rethash[:errors] = "Failed to modify user record : ERROR_SYSADMIN_FAILED_TO_ADD_USER_RECORD"
      return rethash
    end
  end

  # =>  end of add_user sid, spin_uid, spin_gid, spin_password

  def self.add_login_directory sid, spin_uid, spin_login_directory_key
    # Am I an administrator?
    rethash = {}
    ids = SessionManager.get_uid_gid(sid, false)
    if ids[:uid] == 0 or ids[:gid] == 0
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE
      rethash[:errors] = "Failed to create user record : ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE"
      return rethash
    end

    # create login directory if it isn't.
    #    reth = self.create_directory sid, spin_login_directory, true, spin_uid, ids[:gid], ACL_DEFAULT_UID_ACCESS_RIGHT, ACL_DEFAULT_GID_ACCESS_RIGHT, ACL_DEFAULT_WORLD_ACCESS_RIGHT

    # modify user record
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      begin
        user_rec = self.find_by_spin_uid spin_uid
        if user_rec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_SYSADMIN_NO_SUCH_USER
          rethash[:errors] = "Failed to add login directory to the user record : ERROR_SYSADMIN_NO_SUCH_USER"
          return rethash
        end
        user_rec[:spin_login_directory] = spin_login_directory_key
        # get domain of spin_login_directory
        doms = SpinNode.get_domains spin_login_directory_key
        if doms.length > 0
          user_rec[:spin_default_domain] = doms[0]
        else
          rethash[:success] = false
          rethash[:status] = ERROR_SYSADMIN_FAILED_TO_CREATE_USER_LOGIN_DIRECTORY
          rethash[:errors] = "Failed to add login directory to the user record due to missing default domain : ERROR_SYSADMIN_FAILED_TO_CREATE_USER_LOGIN_DIRECTORY"
          return rethash
        end
        if user_rec.save
          rethash[:success] = true
          rethash[:status] = INFO_SYSADMIN_CREATE_LOGIN_DIRECTORY_SUCCESS
          rethash[:result] = spin_login_directory_key
          return rethash
        else
          rethash[:success] = false
          rethash[:status] = ERROR_SYSADMIN_FAILED_TO_CREATE_USER_LOGIN_DIRECTORY
          rethash[:errors] = "Failed to add login directory to the user record : ERROR_SYSADMIN_FAILED_TO_CREATE_USER_LOGIN_DIRECTORY"
          return rethash
        end
      rescue ActiveRecord::RecordNotFound
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_FAILED_TO_CREATE_USER_LOGIN_DIRECTORY
        rethash[:errors] = "Failed to add login directory to the user record : ERROR_SYSADMIN_FAILED_TO_CREATE_USER_LOGIN_DIRECTORY"
        return rethash
      end
    end # => end of transaction

  end

  # => end of self.add_login_directory sid, spin_uid, spin_uname

  def self.modify_login_directory sid, spin_uid, spin_login_directory_key
    # Am I an administrator?
    rethash = {}
    ids = SessionManager.get_uid_gid(sid, true)
    if ids[:uid] == 0 or ids[:gid] == 0
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE
      rethash[:errors] = "Failed to create user record : ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE"
      return rethash
    end

    # create login directory if it isn't.
    #    reth = self.create_directory sid, spin_login_directory, true, spin_uid, ids[:gid], ACL_DEFAULT_UID_ACCESS_RIGHT, ACL_DEFAULT_GID_ACCESS_RIGHT, ACL_DEFAULT_WORLD_ACCESS_RIGHT

    # modify user record
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      begin
        user_rec = self.find_by_spin_uid spin_uid
        if user_rec.blank?
          rethash[:success] = false
          rethash[:status] = ERROR_SYSADMIN_NO_SUCH_USER
          rethash[:errors] = "Failed to change login directory to the user record : ERROR_SYSADMIN_NO_SUCH_USER"
          return rethash
        end
        user_rec[:spin_login_directory] = spin_login_directory_key
        # get domain of spin_login_directory
        doms = SpinNode.get_domains spin_login_directory_key
        if doms.length > 0
          user_rec[:spin_default_domain] = doms[0]
        else
          rethash[:success] = false
          rethash[:status] = ERROR_SYSADMIN_FAILED_TO_CHANGE_USER_LOGIN_DIRECTORY
          rethash[:errors] = "Failed to change login directory to the user record due to missing default domain : ERROR_SYSADMIN_FAILED_TO_CHANGE_USER_LOGIN_DIRECTORY"
          return rethash
        end
        if user_rec.save
          rethash[:success] = true
          rethash[:status] = INFO_SYSADMIN_CREATE_LOGIN_DIRECTORY_SUCCESS
          rethash[:result] = spin_login_directory_key
          return rethash
        else
          rethash[:success] = false
          rethash[:status] = ERROR_SYSADMIN_FAILED_TO_CREATE_USER_LOGIN_DIRECTORY
          rethash[:errors] = "Failed to add logij directory to the user record : ERROR_SYSADMIN_NO_SUCH_USER"
          return rethash
        end
      rescue ActiveRecord::RecordNotFound
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_FAILED_TO_CREATE_USER_LOGIN_DIRECTORY
        rethash[:errors] = "Failed to add logij directory to the user record : ERROR_SYSADMIN_NO_SUCH_USER"
        return rethash
      end
    end # => end of transaction

  end

  # => end of self.add_login_directory sid, spin_uid, spin_uname

  def self.create_directory sid, vp, mkdirf, owner_uid, owner_gid, u_acl, g_acl, w_acl, is_sticky = false
    rethash = {}
    loc = SpinLocationManager.get_location_coordinates sid, 'folder_a', vp, mkdirf, owner_uid, owner_gid, u_acl, g_acl, w_acl, is_sticky
    pp loc
    if loc[X..V] == [-1, -1, -1, -1]
      if mkdirf == false
        rethash[:success] = true
        rethash[:status] = INFO_NO_VPATH
        rethash[:errors] = "Specified vpath dosen\'t exist"
        rethash[:info] = "Specified vpath dosen\'t exist"
        rethash[:result] = 0
      else
        rethash[:success] = false
        rethash[:status] = ERROR_CREATE_VPATH_FAILED
        rethash[:errors] = "Failed to create specified vpath"
        rethash[:result] = -1
      end
    else # => valid loc
      key = nil
      if loc.size >= (K + 1)
        key = loc[K]
      end
      if key == nil
        if mkdirf == false
          rethash[:success] = true
          rethash[:errors] = "Specified vpath dosen\'t exist"
          rethash[:info] = "Specified vpath dosen\'t exist"
          rethash[:result] = 0
        else # => mkdirf is set true
          rethash[:success] = false
          rethash[:status] = ERROR_CREATE_VPATH_FAILED
          rethash[:errors] = "Failed to create specified vpath"
          rethash[:result] = -1
        end
      else
        rethash[:success] = true
        rethash[:status] = INFO_SYSADMIN_CREATE_LOGIN_DIRECTORY_SUCCESS
        rethash[:result] = key
      end
    end
    return rethash
  end

  # => end of self.create_directory

  def self.modify_directory sid, vp, mkdirf, owner_uid, owner_gid, u_acl, g_acl, w_acl
    rethash = {}
    loc = SpinLocationManager.get_location_coordinates sid, 'folder_a', vp, mkdirf, owner_uid, owner_gid, u_acl, g_acl, w_acl
    pp loc
    if loc[X..V] == [-1, -1, -1, -1]
      if mkdirf == false
        rethash[:success] = true
        rethash[:status] = INFO_NO_VPATH
        rethash[:errors] = "Specified vpath dosen\'t exist"
        rethash[:info] = "Specified vpath dosen\'t exist"
        rethash[:result] = 0
      else
        rethash[:success] = false
        rethash[:status] = ERROR_CREATE_VPATH_FAILED
        rethash[:errors] = "Failed to create specified vpath"
        rethash[:result] = -1
      end
    else # => valid loc
      key = loc[K]
      #          key = SpinLocationManager.location_to_key loc, NODE_DIRECTORY       
      if key == nil
        if mkdirf == false
          rethash[:success] = true
          rethash[:errors] = "Specified vpath dosen\'t exist"
          rethash[:info] = "Specified vpath dosen\'t exist"
          rethash[:result] = 0
        else # => mkdirf is set true
          rethash[:success] = false
          rethash[:status] = ERROR_CREATE_VPATH_FAILED
          rethash[:errors] = "Failed to create specified vpath"
          rethash[:result] = -1
        end
      else
        rethash[:success] = true
        rethash[:status] = INFO_SYSADMIN_CREATE_LOGIN_DIRECTORY_SUCCESS
        rethash[:result] = key
      end
    end
    return rethash
  end

  # => end of self.create_directory

  def self.get_user_template user_level_x, user_level_y, param_spec, p_group_name
    # get user template reord from spin_user
    rets = nil
    begin
      tmpl = self.find_by_spin_uname('template-user-' + p_group_name)
      if tmpl.blank?
        tmpl = self.find_by_user_level_x_and_user_level_y(user_level_x, user_level_y)
        if tmpl.blank? or tmpl[:spin_login_directory] == nil or tmpl[:spin_login_directory].empty?
          case param_spec
          when DEFAULT_LOGIN_DIRECTORY
            return SYSTEM_DEFAULT_LOGIN_DIRECTORY
          else
            return SYSTEM_DEFAULT_LOGIN_DIRECTORY
          end
        end
      else # => template is
        case param_spec
        when DEFAULT_LOGIN_DIRECTORY
          dir_path_work = ''
          if tmpl[:spin_login_directory] == nil or tmpl[:spin_login_directory].empty?
            dir_path_work = Vfs::SYSTEM_DEFAULT_LOGIN_DIRECTORY
          else
            dir_path_key_work = tmpl[:spin_login_directory]
            dir_path_work_loc = SpinLocationManager.key_to_location(dir_path_key_work, NODE_DIRECTORY)
            dir_path_work = SpinLocationManager.get_location_vpath(dir_path_work_loc)
          end
          login_path = dir_path_work + '/'
          rets = login_path
        else
          rets = '/'
        end
      end # => end of template == nil
    rescue ActiveRecord::RecordNotFound
      case param_spec
      when DEFAULT_LOGIN_DIRECTORY
        return SYSTEM_DEFAULT_LOGIN_DIRECTORY
      else
        return SYSTEM_DEFAULT_LOGIN_DIRECTORY
      end
    end

    return rets
  end

  # => end of self.get_user_template DEFAULT_USER_LEVEL_X, DEFAULT_USER_LEVEL_Y, DEFAULT_LOGIN_DIRECTORY

  def self.is_valid_password spin_password
    return true
  end

  # => end of self.is_valid_password spin_password

  def self.get_user_list_display_data sid, offset, limit
    rethash = {}
    # Am I an administrator?
    ids = SessionManager.get_uid_gid(sid, true)
    if ids[:uid] == 0 or ids[:gid] == 0
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE
      rethash[:errors] = "Failed to create user record : ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE"
      return rethash
    end

    all_users = self.where(["id > 0"])
    total = all_users.length

    disp_user_list = []

    rethash = {:success => true, :total => total, :start => offset, :limit => limit, :users => disp_user_list}

    user_list = Array.new
    begin
      user_list = self.limit(limit).offset(offset).where(["id > 0"]).order("updated_at DESC")
    rescue ActiveRecord::RecordNotFound
      return rethash
    end

    user_list.each {|usr|
      next if usr[:spin_uname] =~ /template-*/

      usr_attr = SpinUserAttribute.find_by_spin_uid usr[:spin_uid]
      # if usr_attr.blank?
      #   return rethash
      # end
      grp_attr = SpinGroup.find_by_spin_gid usr[:spin_gid]
      next if grp_attr.blank?
      ur = {}
      ur[:hash_key] = "N/A"
      ur[:user_id] = usr[:spin_uid]
      ur[:user_name] = usr[:spin_uname]
      if usr_attr.present?
        ua_json = usr_attr[:user_attributes]
        if ua_json.length > 0
          ua = JSON.parse ua_json
          ur[:real_uname] = usr_attr[:real_uname1]
          ur[:company_name] = usr_attr[:organization1]
          ur[:user_post] = usr_attr[:organization2]
          ur[:employee_number] = usr_attr[:organization3]
          login_directory = DatabaseUtility::VirtualFileSystemUtility.key_to_path(usr[:spin_login_directory])
          ur[:user_directory] = login_directory
          #          ur[:user_directory] = ua['user_directory']
        end
        ur[:user_mail] = usr_attr[:mail_addr]
      end
      ur[:user_pw] = usr[:spin_passwd]
      ur[:p_group_id] = usr[:spin_gid]
      if grp_attr.present?
        ur[:p_group_name] = grp_attr[:spin_group_name]
        ur[:p_group_description] = grp_attr[:group_descr]
      end

      disp_user_list.push(ur)
    }

    #    rethash[:total] = disp_user_list.length

    return rethash
  end

  # => end of get_file_list_display_data

  def self.select_user_list_display_data sid, offset, limit, form_data_hash
    rethash = {}
    # Am I an administrator?
    ids = SessionManager.get_uid_gid(sid, true)
    if ids[:uid] == 0 or ids[:gid] == 0
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE
      rethash[:errors] = "Failed to create user record : ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE"
      return rethash
    end

    sql = "select
           A.spin_uid,A.spin_uname,A.spin_passwd,A.spin_login_directory,B.real_uname1,B.organization1,B.organization2,B.organization3,B.mail_addr,C.spin_gid,C.spin_group_name,C.group_descr
           from
           spin_users A,spin_user_attributes B,spin_groups C
           where
           A.spin_uid=B.spin_uid
           and
           A.spin_gid=C.spin_gid
           and 
           A.spin_uname
           like '" + form_data_hash[:user_name].to_s + "%'"
    if ((form_data_hash[:real_uname] != "") && (form_data_hash[:real_uname] != nil))
      sql = sql + " and B.real_uname1 like '" + form_data_hash[:real_uname].to_s + "%'"
    end
    if ((form_data_hash[:user_post] != "") && (form_data_hash[:user_post] != nil))
      sql = sql + " and B.organization2 like '" + form_data_hash[:user_post].to_s + "%'"
    end
    if ((form_data_hash[:user_mail] != "") && (form_data_hash[:user_mail] != nil))
      sql = sql + " and B.mail_addr like '" + form_data_hash[:user_mail].to_s + "%'"
    end
    if ((form_data_hash[:company_name] != "") && (form_data_hash[:company_name] != nil))
      sql = sql + " and B.organization1 like '" + form_data_hash[:company_name].to_s + "%'"
    end
    if ((form_data_hash[:employee_number] != "") && (form_data_hash[:employee_number] != nil))
      sql = sql + " and B.organization3 like '" + form_data_hash[:employee_number].to_s + "%'"
    end
    if ((form_data_hash[:p_group_name] != "") && (form_data_hash[:p_group_name] != nil))
      sql = sql + " and C.spin_group_name like '" + form_data_hash[:p_group_name].to_s + "%'"
    end
    if ((form_data_hash[:p_group_description] != "") && (form_data_hash[:p_group_description] != nil))
      sql = sql + " and C.group_descr like '" + form_data_hash[:p_group_description].to_s + "%'"
    end

    disp_user_list = []

    rethash = {:success => true, :total => total, :start => offset, :limit => limit, :users => disp_user_list}

    all_users = []
    total = 0
    begin
      all_users = self.find_by_sql(sql)
    rescue ActiveRecord::RecordNotFound
      return rethash
    end

    sql = sql + " order by A.spin_uid desc offset " + offset + " limit " + limit

    if all_users.present?
      total = all_users.length
    end

    user_list = []
    begin
      user_list = self.find_by_sql(sql)
    rescue ActiveRecord::RecordNotFound
      return rethash
    end

    user_list.each {|usr|
      next if /template-*/ =~ usr[:spin_uname]

      ur = {}
      ur[:hash_key] = "N/A"
      ur[:user_id] = usr[:spin_uid]
      ur[:user_name] = usr[:spin_uname]
      ur[:real_uname] = usr[:real_uname1]
      ur[:company_name] = usr[:organization1]
      ur[:user_post] = usr[:organization2]
      ur[:employee_number] = usr[:organization3]
      login_directory = DatabaseUtility::VirtualFileSystemUtility.key_to_path(usr[:spin_login_directory])
      ur[:user_directory] = login_directory
      #          ur[:user_directory] = ua['user_directory']
      ur[:user_mail] = usr[:mail_addr]
      ur[:user_pw] = usr[:spin_passwd]
      ur[:p_group_id] = usr[:spin_gid]
      ur[:p_group_name] = usr[:spin_group_name]
      ur[:p_group_description] = usr[:group_descr]

      disp_user_list.push(ur)
    }

    rethash[:total] = disp_user_list.length
    rethash[:users] = disp_user_list
    return rethash
  end


  def self.activate_user my_session_id, user_record
    #      user_record[:spin_uid] = paramshash[:user_id]
    #      user_record[:new_user_login_name] = paramshash[:user_name]
    #      user_record[:new_user_description] = paramshash[:user_description]
    #      user_record[:new_user_mail_address] = paramshash[:user_mail]
    #      user_record[:student_id_number] = paramshash[:user_tel]
    #      user_record[:student_major] = paramshash[:user_major]
    #      user_record[:student_laboratory] = paramshash[:user_org]
    reth = {}
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      u = self.find_by_spin_uid user_record[:spin_uid]
      if u.blank? # => fatal error! it should not be nil!
        reth[:success] = false
        reth[:status] = ERROR_USER_RECORD_NOT_FOUND
        reth[:errors] = 'Fatl error : user record not found'
        return reth
      end # => end of error

      un = self.find_by_spin_uname user_record[:new_user_login_name]
      if un.present? # => fatal error! user name is already used
        reth[:success] = false
        reth[:status] = ERROR_USER_NAME_USED_ALREADY
        reth[:errors] = 'Fatl error :  user name is used already'
        return reth
      end # => end of error

      # get primary group
      # assume primary gourp id == spin_uid
      pg = SpinGroup.find_by_spin_gid user_record[:spin_uid]
      if pg.blank? # => fatal error! it should not be nil!
        reth[:success] = false
        reth[:status] = ERROR_USER_PRIMARY_GROUP_NOT_FOUND
        reth[:errors] = 'Fatl error : user primary group not found'
        return reth
      else
        pg[:spin_group_name] = user_record[:new_user_login_name]
        if pg.save == false
          reth[:success] = false
          reth[:status] = ERROR_FAILED_TO_UPDATE_USER_PRIMARY_GROUP
          reth[:errors] = 'Fatl error : failed to update user attributes during activation'
          return reth
        end # => end of error
      end # => end of error

      ua = SpinUserAttribute.find_by_spin_uid user_record[:spin_uid]
      if ua.blank?
        ua = SpinUserAttribute.new
      end
      ua[:spin_uid] = user_record[:spin_uid]
      ua[:spin_uname] = user_record[:new_user_login_name]
      ua[:mail_addr] = user_record[:new_user_mail_address]
      ua[:tel_ext_1] = user_record[:student_id_number]
      ua[:organization1] = user_record[:student_major]
      ua[:organization2] = user_record[:student_laboratory]
      ua[:real_uname1] = user_record[:new_user_description]
      if ua.save == false
        reth[:success] = false
        reth[:status] = ERROR_FAILED_TO_UPDATE_USER_ATTRIBUTES
        reth[:errors] = 'Fatl error : failed to update user attributes during activation'
        return reth
      end # => end of error

      u[:spin_uname] = user_record[:new_user_login_name]
      retb = SpinNode.rename_node my_session_id, u[:spin_login_directory], user_record[:new_user_login_name]
      if retb == false
        reth[:success] = false
        reth[:status] = ERROR_FAILED_TO_RENAME_USER_LOGIN_DIRECTORY
        reth[:errors] = 'Fatl error : failed to rename user login directory during activation'
        return reth
      else
        retb = SpinNode.set_sticky my_session_id, u[:spin_login_directory], user_record[:spin_uid].to_i
      end # => end of error

      u[:activated] = true
      if u.save == false
        reth[:success] = false
        reth[:status] = ERROR_FAILED_TO_UPDATE_USER_MANAGEMENT_TABLE
        reth[:errors] = 'Fatl error : failed to update user management table during activation'
        return reth
      end # => end of error

    end # => end of transaction

    reth[:success] = true
    reth[:status] = INFO_USER_ACOUNT_ACTIVATION_SUCCESS
    reth[:result] = user_record[:spin_uid]

    return reth

  end

  # => end of self.activate_user my_session_id,  user_record

  def self.change_user_info sid, user_record
    #      user_record[:spin_uid] = paramshash[:user_id]
    #      user_record[:new_user_login_name] = paramshash[:user_name]
    #      user_record[:new_user_description] = paramshash[:user_description]
    #      user_record[:new_user_mail_address] = paramshash[:user_mail]
    #      user_record[:student_id_number] = paramshash[:user_tel]
    #      user_record[:student_major] = paramshash[:user_major]
    #      user_record[:student_laboratory] = paramshash[:user_org]
    reth = {}
    ids = SessionManager.get_uid_gid(sid, true)
    uid = ids[:uid]
    gid = ids[:gid]
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      u = self.find_by_spin_uid user_record[:spin_uid]
      if u.blank? # => fatal error! it should not be nil!
        reth[:success] = false
        reth[:status] = ERROR_USER_RECORD_NOT_FOUND
        reth[:errors] = 'Fatl error : user record not found'
        return reth
      end # => end of error

      ua = nil
      begin
        ua = SpinUserAttribute.find_by_spin_uid user_record[:spin_uid]
        if ua.blank?
          ua = SpinUserAttribute.new
        end
      rescue ActiveRecord::RecordNotFound
        ua = SpinUserAttribute.new
      end
      ua[:spin_uname] = user_record[:new_user_login_name]
      ua[:mail_addr] = user_record[:new_user_mail_address]
      ua[:tel_ext_1] = user_record[:student_id_number]
      ua[:organization1] = user_record[:student_major]
      ua[:organization2] = user_record[:student_laboratory]
      ua[:real_uname1] = user_record[:new_user_description]
      if ua.save == false
        reth[:success] = false
        reth[:status] = ERROR_FAILED_TO_UPDATE_USER_ATTRIBUTES
        reth[:errors] = 'Fatl error : failed to update user attributes during activation'
        return reth
      end # => end of error

    end # => end of transaction

    reth_m = self.modify_user_name sid, uid, gid, user_record[:new_user_login_name]
    if reth_m[:success] == false
      return reth_m
    else
      reth[:success] = true
      reth[:status] = INFO_CHANGE_USER_INFO_SUCCESS
    end

    # change primary group name
    primary_gid = self.get_primary_group(uid)
    ret_pg = SpinGroup.modify_group_info(primary_gid, user_record[:new_user_login_name], '')
    if ret_pg[:success] == false
      return ret_pg
    else
      reth[:success] = true
      reth[:status] = INFO_CHANGE_USER_INFO_SUCCESS
      reth[:result] = user_record[:new_user_login_name]
      return reth
    end

  end

  # => end of self.activate_user my_session_id,  user_record

  def self.get_uid_from_gid gid
    begin
      u = self.find_by_spin_gid(gid)
      if u.present?
        return u[:spin_uid]
      else
        return -1
      end
    rescue ActiveRecord::RecordNotFound
      return -1
    end
  end

  def self.get_user_activation_status spin_uid
    begin
      u = self.find_by_spin_uid spin_uid
      if u.present?
        if u[:activated] == true
          return INFO_USER_ACOUNT_ACTIVATED
        else
          return INFO_USER_ACOUNT_IS_NOT_ACTIVATED
        end
      else
        return (INFO_USER_ACOUNT_ACTIVATED * (-1))
      end
    rescue ActiveRecord::RecordNotFound
      return INFO_USER_ACOUNT_IS_NOT_ACTIVATED
    end
  end

  # => end of self.get_user_activation_status res[:uid]

  def self.change_password sid, params
    # simply create user and group record
    rethash = {}
    # Am I an administrator?
    ids = SessionManager.get_uid_gid(sid, true)
    if ids[:uid] == 0 or ids[:gid] == 0 or ids[:uid] == params[:uid]
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE
      rethash[:errors] = "Failed to change user password : ERROR_SYSADMIN_INSUFFICIENT_USER_PRIVILEGE"
      return rethash
    end
    begin
      mod_user_rec = self.find_by_spin_uid ids[:uid]
      if mod_user_rec.blank?
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_INVALID_PASSWORD
        rethash[:errors] = "Failed to change user password due to invalid password: ERROR_SYSADMIN_INVALID_PASSWORD"
        return rethash
      end
      if mod_user_rec[:spin_passwd] == params[:current_password] # => password matches!
        # => do it!
      else # => given current password is invalid
        rethash[:success] = false
        rethash[:status] = ERROR_SYSADMIN_INVALID_PASSWORD
        rethash[:errors] = "Failed to change user password due to invalid password: ERROR_SYSADMIN_INVALID_PASSWORD"
        return rethash
      end
    rescue ActiveRecord::RecordNotFound
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_INVALID_PASSWORD
      rethash[:errors] = "Failed to change user password due to invalid password: ERROR_SYSADMIN_INVALID_PASSWORD"
      return rethash
    end

    mod_user_rec[:spin_passwd] = params[:new_password]
    if mod_user_rec.save
      rethash[:success] = true
      rethash[:status] = INFO_SYSADMIN_CHANGE_USER_PASSWORD_SUCCESS
      rethash[:result] = {:uid => params[:uid]}
      return rethash
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_CHANGE_USER_PASSWORD
      rethash[:errors] = "Failed to change user password : ERROR_SYSADMIN_FAILED_TO_CHANGE_USER_PASSWORD"
      return rethash
    end
  end

# => end of change_password my_session_id, change_password_params

end

