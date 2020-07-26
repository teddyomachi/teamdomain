# coding: utf-8
require 'const/vfs_const'
require 'const/stat_const'
require 'const/acl_const'

class SpinUserAttribute < ActiveRecord::Base
  include Vfs
  include Stat
  include Acl

  attr_accessor :mail_addr, :mail_addr2, :organization1, :organization2, :organization3, :organization4, :organization5, :organization6, :organization7, :organization8, :real_uname1, :real_uname2, :real_unameM, :spin_uid, :spin_uname, :tel_area_code_1, :tel_country_code_1, :tel_ext_1, :tel_number_1, :tel_pid_code_1, :user_attributes

  def self.get_user_name uid
    begin
      u = self.readonly.select("spin_uname").find_by_spin_uid(uid)
      if u.present?
        return u[:spin_uname]
      else
        return ACL_SUPER_USER_NAME
      end
    rescue ActiveRecord::RecordNotFound
      return ACL_SUPER_USER_NAME
    end
  end

  # => end of get_user_name

  def self.get_user_real_name uid
    u = nil
    begin
      u = self.find_by_spin_uid(uid)
      if u.blank?
        return nil
      end
      return [u[:real_name1], u[:real_nameM], u[:real_name2]]
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  # => end of get_user_name

  def self.get_user_display_name uid
    u = nil
    begin
      u = self.find_by_spin_uid(uid)
      if u.blank?
        return nil
      end
      return u[:real_uname1]
    rescue ActiveRecord::RecordNotFound
      uname = SpinUser.get_uname uid
      return uname
    end
  end

  # => end of get_user_name

  def self.add_user_attribute sid, user_attributes
    # Am I an administrator?
    rethash = {}
    ids = SessionManager.get_uid_gid(sid, false)
    if ids[:uid] == 0 or ids[:gid] == 0
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_CREATE_USER_ATTRIBUTE
      rethash[:errors] = "Failed to create user attribute record : ERROR_SYSADMIN_FAILED_TO_CREATE_USER_ATTRIBUTE"
      return rethash
    end

    # add attributes
    # into user attributes
    ua = nil
    ua = self.find_by_spin_uid_and_spin_uname(user_attributes[:user_id], user_attributes[:user_name])
    if ua.blank?
      ua = self.new
    end

    begin
      ua[:spin_uid] = user_attributes[:user_id]
      ua[:spin_uname] = user_attributes[:user_name]
      ua[:real_uname1] = user_attributes[:real_uname]

      # mail
      ua[:mail_addr] = user_attributes[:mail_addr]
      #    ua[:tel_number] = user_attributes[:tel_number]
      ua[:organization1] = user_attributes[:company_name]
      ua[:organization2] = user_attributes[:user_post]
      ua[:organization3] = user_attributes[:employee_number]
      # JSON attributes
      #    ua_json = usr_attr[:user_attributes]
      usr_attr = {}
      usr_attr[:real_uname1] = user_attributes[:real_uname]
      usr_attr[:organization1] = user_attributes[:company_name]
      usr_attr[:organization2] = user_attributes[:user_post]
      usr_attr[:organization3] = user_attributes[:employee_number]
      usr_attr[:user_directory] = user_attributes[:user_directory]
      ua[:user_attributes] = usr_attr.to_json
      ua.save
      rethash[:success] = true
      rethash[:status] = INFO_SYSADMIN_CREATE_CREATE_USER_ATTRIBUTE_SUCCESS
      rethash[:result] = user_attributes
    rescue ActiveRecord::RecordNotSaved
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_CREATE_USER_ATTRIBUTE
      rethash[:errors] = "Failed to create user attribute record at save : ERROR_SYSADMIN_FAILED_TO_CREATE_USER_ATTRIBUTE"
    end
    return rethash

  end

  # => end of self.add_user_attribute sid, user_attr

  def self.add_options sid, user_attributes
    # Am I an administrator?
    rethash = {}
    ids = SessionManager.get_uid_gid(sid, false)
    if ids[:uid] == 0 or ids[:gid] == 0 or ids[:uid] == user_attributes[:uid]
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_CREATE_USER_ATTRIBUTE
      rethash[:errors] = "Failed to create user attribute record : ERROR_SYSADMIN_FAILED_TO_CREATE_USER_ATTRIBUTE"
      return rethash
    end

    # add attributes
    # into user attributes
    ua = self.find_by_spin_uid user_attributes[:uid]
    if ua.blank?
      ua = self.new
    end

    begin
      ua[:spin_uid] = user_attributes[:uid]
      usr_attr = {}
      usr_attr[:auto_save] = user_attributes[:auto_save]
      usr_attr[:disp_ext] = user_attributes[:disp_ext]
      usr_attr[:disp_tree] = user_attributes[:disp_tree]
      usr_attr[:rule_created_date] = user_attributes[:rule_created_date]
      ua[:user_attributes] = usr_attr.to_json
      ua.save
      rethash[:success] = true
      rethash[:status] = INFO_SYSADMIN_CREATE_CREATE_USER_ATTRIBUTE_SUCCESS
      rethash[:result] = user_attributes
    rescue ActiveRecord::RecordNotSaved
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_CREATE_USER_ATTRIBUTE
      rethash[:errors] = "Failed to create user attribute record at save : ERROR_SYSADMIN_FAILED_TO_CREATE_USER_ATTRIBUTE"
      return rethash
    end

  end

  # => end of self.add_user_attribute sid, user_attr

  def self.delete_user_attribute sid, spin_uid
    # Am I an administrator?
    rethash = {}
    ids = SessionManager.get_uid_gid(sid, false)
    if ids[:uid] == 0 or ids[:gid] == 0
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_DELETE_USER_ATTRIBUTE
      rethash[:errors] = "Failed to delete user attribute record : ERROR_SYSADMIN_FAILED_TO_DELETE_USER_ATTRIBUTE"
      return rethash
    end

    # add attributes
    # into user attributes
    ua = nil
    ua = self.find_by_spin_uid spin_uid
    if ua.blank?
      rethash[:success] = true
      rethash[:status] = INFO_SYSADMIN_DELETE_NO_USER_ATTRIBUTE_SUCCESS
      rethash[:result] = "No usdr attribute record is found but there is no problem anyway"
      return rethash
    end

    ua.destroy
    rethash[:success] = true
    rethash[:status] = INFO_SYSADMIN_DELETE_USER_ATTRIBUTE_SUCCESS
    rethash[:result] = {:spin_uid => spin_uid}
    return rethash

  end

  # => end of self.add_user_attribute sid, user_attr

  def self.modify_user_attribute sid, current_uname, user_attributes
    # Am I an administrator?
    rethash = {}
    ids = SessionManager.get_uid_gid(sid, false)
    if ids[:uid] == 0 or ids[:gid] == 0 or ids[:uid] == user_attributes[:user_id]
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_MODIFY_USER_ATTRIBUTE
      rethash[:errors] = "Failed to modify user attribute record : ERROR_SYSADMIN_FAILED_TO_MODIFY_USER_ATTRIBUTE"
      return rethash
    end

    # add attributes
    # into user attributes
    ua = nil
    ua = self.find_by_spin_uid_and_spin_uname user_attributes[:user_id], current_uname
    if ua.blank?
      rethash = self.add_user_attribute sid, user_attributes
      return rethash
    end

    begin
      ua[:spin_uid] = user_attributes[:user_id]
      ua[:spin_uname] = user_attributes[:user_name]
      ua[:real_uname1] = user_attributes[:real_uname]

      # mail
      ua[:mail_addr] = user_attributes[:mail_addr]
      #    ua[:tel_number] = user_attributes[:tel_number]
      ua[:organization1] = user_attributes[:company_name]
      ua[:organization2] = user_attributes[:user_post]
      ua[:organization3] = user_attributes[:employee_number]
      # JSON attributes
      #    ua_json = usr_attr[:user_attributes]
      usr_attr = JSON.parse ua[:user_attributes]
      usr_attr[:real_uname] = user_attributes[:real_uname]
      usr_attr[:organization1] = user_attributes[:company_name]
      usr_attr[:organization2] = user_attributes[:user_post]
      usr_attr[:organization3] = user_attributes[:employee_number]
      usr_attr[:user_directory] = user_attributes[:user_directory]
      ua[:user_attributes] = usr_attr.to_json
      ua.save

      rethash[:success] = true
      rethash[:status] = INFO_SYSADMIN_CREATE_CREATE_USER_ATTRIBUTE_SUCCESS
      rethash[:result] = user_attributes
    rescue ActiveRecord::RecordNotSaved
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_CREATE_USER_ATTRIBUTE
      rethash[:errors] = "Failed to create user attribute record at save : ERROR_SYSADMIN_FAILED_TO_CREATE_USER_ATTRIBUTE"
    end

    return rethash

  end

  # => end of self.add_user_attribute sid, user_attr

  def self.change_options sid, user_attributes
    #    change_option_params = { :uid => paramshash[:operator_id].to_i, :auto_save => paramshash[:auto_save],
    #      :disp_ext => paramshash[:disp_ext],:disp_tree => paramshash[:disp_tree], :rule_created_date => paramshash[:rule_created_date]
    #    }
    #    rethash = SpinUserAttribute.change_options my_session_id, change_option_params
    # Am I an administrator?
    rethash = {}
    ids = SessionManager.get_uid_gid(sid, false)
    if ids[:uid] == 0 or ids[:gid] == 0 or ids[:uid] == user_attributes[:uid]
      # => do it!
    else
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_MODIFY_USER_ATTRIBUTE
      rethash[:errors] = "Failed to modify user attribute record : ERROR_SYSADMIN_FAILED_TO_MODIFY_USER_ATTRIBUTE"
      return rethash
    end

    # add attributes
    # into user attributes
    ua = nil
    ua = self.find_by_spin_uid user_attributes[:uid]
    if ua.blank?
      return rethash
    end

    begin
      usr_attr = {}
      if ua[:user_attributes] == nil or ua[:user_attributes].empty?
        usr_attr['auto_save'] = "auto_noncog"
        usr_attr['disp_ext'] = "hide"
        usr_attr['disp_tree'] = "hide"
        usr_attr['rule_created_date'] = "local_date"
      else
        usr_attr = JSON.parse ua[:user_attributes]
        usr_attr['auto_save'] = user_attributes[:auto_save]
        usr_attr['disp_ext'] = user_attributes[:disp_ext]
        usr_attr['disp_tree'] = user_attributes[:disp_tree]
        usr_attr['rule_created_date'] = user_attributes[:rule_created_date]
      end
      # JSON attributes
      #    ua_json = usr_attr[:user_attributes]
      ua[:user_attributes] = usr_attr.to_json

      ua.save
      rethash[:success] = true
      rethash[:status] = INFO_SYSADMIN_MODIFY_USER_ATTRIBUTE_SUCCESS
      rethash[:result] = user_attributes
    rescue ActiveRecord::RecordNotSaved
      rethash[:success] = false
      rethash[:status] = ERROR_SYSADMIN_FAILED_TO_MODIFY_USER_ATTRIBUTE
      rethash[:errors] = "Failed to modify user attribute record at save : ERROR_SYSADMIN_FAILED_TO_MODIFY_USER_ATTRIBUTE"
    end
    return rethash

  end

  # => end of self.change_options my_session_id, change_option_params

  def self.get_active_operator sid
    # uid = SessionManager.get_uid sid
    ids = SessionManager.get_uid_gid sid
    uid = ids[:uid]
    gid = ids[:gid]
    usr_attr = {}
    operator = {}

    ur = SpinUser.readonly.find_by(spin_uid: uid)
    if ur.blank?
      return nil
    end
    ua = self.readonly.find_by(spin_uid: uid)
    if ua.blank?
      return nil
    end

    active_user = Hash.new

    retry_get_active_operator = ACTIVE_RECORD_RETRY_COUNT
    catch(:get_active_operator_again) {
      OperatorDatum.transaction do
        begin
          active_user = OperatorDatum.find_or_create_by(active_operator_id: uid, session_id: sid) {|operator_rec|
            operator_rec[:session_id] = sid
            operator_rec[:active_operator_id] = uid
            operator_rec[:active_operator_spin_uname] = ur[:spin_uname]
            operator_rec[:active_operator_name] = (ua[:real_uname2].blank? ? ur[:spin_uname] : (ua[:real_uname2] + ' ' + ua[:real_uname1]))
            operator_rec[:operator_group_editable] = ur[:is_group_editor] ? "f" : "t"
            operator_rec[:operator_control_editable] = ((uid == 0 or gid == 0 or SpinGroupMember.is_administrator(uid)) ? "t" : "f")
          }
        rescue ActiveRecord::StaleObjectError
          if retry_get_active_operator > 0
            retry_get_active_operator -= 1
            throw :get_active_operator_again
          else
            return nil
          end
        rescue
          pp exception_details
        end # enmd of begin-rescue block
      end # end of transaction
    } # end of catch-throw block

    active_operator = Hash.new

    active_user.attributes.each {|key, value|
      active_operator[key] = value
    }
    active_operator["operator_name"] = active_user[:active_operator_name]
    active_operator["operator_id"] = active_user[:active_operator_id]
    active_operator["rule_created_date"] = "local_date"
    active_operator["disp_ext"] = "hide"
    active_operator["auto_save"] = "auto_noncog"
    active_operator["disp_tree"] = "hide"
    active_operator["real_uname"] = ua[:real_uname1]
    active_operator["user_mail"] = ua[:mail_addr]
    active_operator["company_name"] = ua[:organization1] # =>  student id  number
    active_operator["user_post"] = ua[:organization7]
    active_operator["employee_number"] = ua[:organization8]

    usr_attr_rec = (ua[:user_attributes].present? ? ua[:user_attributes] : "{}")
    usr_attr = JSON.parse usr_attr_rec
    usr_attr.each {|key, value|
      active_operator[key] = value # add or replace with user_attributes
    }

    id_s = active_operator["active_operator_id"].to_s
    active_operator["active_operator_id"] = id_s
    # oce_s = active_operator["operator_control_editable"] == true ? "t" : "f"
    # active_operator["operator_control_editable"] = oce_s
    # active_operator["operator_control_editable"] = ((uid == 0 or gid == 0) ? "t" : "f")

    return active_operator

  end # => end of self.get_active_operator sid

end
