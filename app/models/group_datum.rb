# coding: utf-8
require 'const/vfs_const'
require 'const/acl_const'
require 'const/stat_const'
require 'const/spin_types'
require 'tasks/session_management'
require 'tasks/security'

class GroupDatum < ActiveRecord::Base
  include Vfs
  include Acl
  include Stat
  include Types

  attr_accessor :editable_status, :group_description, :group_name, :group_privilege, :hash_key, :id, :member_description, :member_id, :member_name, :session_id, :target_hash_key

  def self.search_all_groups sid, qstr
    # search group and it's members
    # search groups
    unless qstr and qstr.length > 0
      return nil
    end

    # remove '%' from qstr
    qstr.gsub!(/%/, '')

    delquery = sprintf("DELETE FROM group_data")
    self.connection.select_all(delquery)
    #    srecs = self.where(["id > 0"])
    #    srecs.each {|srec|
    #      srec.destroy
    #    }
    #    group_ids = []
    #    if qstr == nil or qstr.length == 0
    #      group_ids = SpinGroup.select("spin_gid").where("spin_group_name LIKE \'%\'")
    #    else
    #      group_ids = SpinGroup.select("spin_gid").where("spin_group_name LIKE \'%#{qstr}%\'")
    #    end
    group_ids = []
    if qstr == nil or qstr.empty? or qstr.length == 0
      group_ids = SpinGroup.where("spin_group_name LIKE \'\'")
    else
      group_ids = SpinGroup.where("spin_group_name LIKE \'%#{qstr}%\'")
    end

    # generate activated-user-only group list
    activated_group_ids = []
    group_ids.each {|gi|
      uid = SpinUser.get_uid_from_gid(gi[:spin_gid])
      next if gi[:id_type] == GROUP_MEMBER_ID_TYPE_USER_PRIMARY_GROUP and SpinUser.get_user_activation_status(uid) != INFO_USER_ACOUNT_ACTIVATED
      activated_group_ids.push(gi)
    }

    # get group name and user name
    activated_group_ids.each {|agi|
      gn = SpinGroup.get_group_name agi[:spin_gid]
      member_uids = SpinGroupMember.get_member_uids agi[:spin_gid]
      gnr = self.new
      gnr[:session_id] = sid
      gnr[:group_name] = gn
      gnr[:group_description] = SpinGroup.get_group_description(gn)
      #      gnr[:member_name] = GROUP_LIST_DATA_GROUP_IDENTIFIER_STRING
      gnr[:member_name] = SpinGroupMember.get_brief_member_name_list agi[:spin_gid]
      gnr[:list_type] = GROUP_LIST_ALL
      gnr[:data_class] = GROUP_LIST_DATA_GROUP
      gnr.save
      # Is it a primary group or not?
      next if agi[:id_type] == GROUP_LIST_DATA_USER_PRIMARY_GROUP or agi[:id_type] == GROUP_LIST_DATA_GROUP
      member_uids.each {|mi|
        #        if idx == 0
        #          ggd = self.new
        #          ggd[:session_id] = sid
        #          ggd[:member_name] = 'GROUP:' + gn + 'グループを選択'
        #          ggd[:group_name] = gn
        #          ggd[:member_id] = gi[:spin_gid]
        #          ggd[:list_type] = GROUP_LIST_ALL
        #          ggd[:data_class] = GROUP_LIST_DATA_GROUP
        #          ggd.save
        #        end
        gd = self.new
        gd[:session_id] = sid
        if mi[:id_type] == GROUP_MEMBER_ID_TYPE_USER
          gd[:member_name] = SpinUserAttribute.get_user_display_name(mi['spin_uid'].to_i)
        else
          gd[:member_name] = SpinGroup.get_group_name(mi['spin_uid'].to_i)
        end
        gd[:group_name] = gn
        gd[:member_id] = mi['spin_gid']
        gd[:list_type] = GROUP_LIST_ALL
        gd[:data_class] = mi['id_type'].to_i
        gd.save
      }
    }
    return activated_group_ids
  end

  # => end of search_all_groups

  def self.get_children_data index, id, id_list, group_list, children_data
    children = children_data[:children];
    children_index = children_data[:children_index];
    for j in 0..id_list.length() - 1 do
      member = Hash.new;
      case id
      when 'gid'
        sql = "select spin_uid,spin_gid,spin_uname from spin_users where spin_gid=" + id_list[j]["spin_gid"].to_s
      when 'uid'
        sql = "select spin_uid,spin_gid,spin_uname from spin_users where spin_uid=" + id_list[j]["spin_uid"].to_s
      end
      su = SpinUser.find_by_sql(sql);
      if (su.length() > 0)
        member[:leaf] = true;
        member[:text] = su[0]["spin_uname"];
        member[:member_name] = su[0]["spin_uname"];
        member[:member_id] = su[0]["spin_uid"];
        member[:group_id] = su[0]["spin_gid"];
        member[:group_name] = group_list[index]['spin_group_name'];
        member[:checked] = false;
        member[:iconCls] = 'x-tree-icon-member'
        children[children_index] = member;
        children_index += 1;
      end
    end
    children_data[:children] = children;
    children_data[:children_index] = children_index;
    return children_data;
  end

  def self.select_group_member_display_tree group_name
    if (group_name != nil)
      rethash = Hash.new;
      sql1 = "select distinct spin_group_name from spin_groups where spin_group_name LIKE '" + group_name.to_s + "%' order by spin_group_name;";
      group_list = SpinGroup.find_by_sql(sql1);
      if (group_list.length() <= 0)
        rethash[:display_data] = Array.new;
        rethash[:success] = true;
      else
        member_list = Array.new;
        group_index = 0;
        for i in 0..group_list.length() - 1 do
          children_data = Hash.new;
          children_data[:children] = Array.new;
          children_data[:children_index] = 0;
          group = Hash.new;
          sql2 = "select spin_gid from spin_groups where (id_type = #{GROUP_MEMBER_ID_TYPE_USER_PRIMARY_GROUP} or id_type = #{GROUP_MEMBER_ID_TYPE_GROUP}) and spin_group_name='" + group_list[i]['spin_group_name'] + "' order by spin_gid;";
          gid_list = SpinGroup.find_by_sql(sql2);
          if (gid_list.length() > 0)
            children_data = get_children_data i, "gid", gid_list, group_list, children_data;
            for j in 0..gid_list.length() - 1
              sql3 = "select spin_uid from spin_group_members where (id_type = #{GROUP_MEMBER_ID_TYPE_USER_PRIMARY_GROUP} or id_type = #{GROUP_MEMBER_ID_TYPE_GROUP}) and spin_gid=" + gid_list[j]["spin_gid"].to_s + " order by spin_uid;";
              uid_list = SpinUser.find_by_sql(sql3);
              if (uid_list.length() > 0)
                children_data = get_children_data i, "uid", uid_list, group_list, children_data;
              end
            end
          end
          if (children_data[:children].length() > 0)
            sql4 = "select * from spin_groups where spin_group_name='" + group_list[i]['spin_group_name'] + "' limit 1;";
            sg = SpinGroup.find_by_sql(sql4);
            if (sg[0]['id_type'] === 2)
              group[:owner_id] = -1;
            else
              group[:owner_id] = sg[0]['owner_id'];
            end
            group[:leaf] = false;
            group[:text] = group_list[i]['spin_group_name'];
            group[:group_name] = group_list[i]['spin_group_name'];
            group[:children] = children_data[:children];
            group[:iconCls] = 'x-tree-icon-group'
            group[:checked] = false;
            member_list[group_index] = group;
            group_index += 1;
          end
        end
        rethash[:display_data] = member_list;
        rethash[:success] = true;
      end
      return rethash
    end
  end

  def self.select_group_member_display_data group_name, offset, limit
    rethash = Hash.new;
    sql1 = "select spin_gid from spin_groups where spin_group_name='" + group_name + "' offset " + offset.to_s + " limit " + limit.to_s;
    sg = SpinGroup.find_by_sql(sql1);
    if (sg.length() == 0)
      rethash[:display_data] = Array.new;
      rethash[:success] = true;
    else
      gid_list = '';
      for i in 0..sg.length - 1 do
        if (i == 0)
          gid_list = "(spin_gid=" + sg[i]["spin_gid"].to_s + ")";
        else
          gid_list = gid_list + " or (spin_gid=" + sg[i]["spin_gid"].to_s + ")"
        end
      end
      sql2 = "select * from spin_users where " + gid_list;
      su = SpinUser.find_by_sql(sql2);
      data_array = Array.new
      for i in 0..su.length - 1 do
        temp = Hash.new
        temp[:member_name] = su[i][:spin_uname];
        temp[:group_id] = su[i][:spin_gid];
        temp[:member_id] = su[i][:spin_uid];
        data_array[i] = temp;
      end
      rethash[:display_data] = data_array;
      rethash[:success] = true;
    end
    return rethash
  end

  # => end of get_file_list_display_data

  def self.get_group_list_display_data sid, list_type, offset, limit
    rethash = Hash.new
    group_list = Array.new
    #    nrecs = self.select("id").where(:session_id => sid)
    #    rethash[:total] = nrecs.length
    rethash[:start] = offset
    rethash[:limit] = limit
    rethash[:members] = []
    uid = SessionManager.get_uid(sid)
    case list_type
    when GROUP_LIST_ALL
      uid_list = SpinGroupMember.limit(limit).offset(offset).where(["id_type = ? OR id_type = ?", GROUP_MEMBER_ID_TYPE_USER_PRIMARY_GROUP, GROUP_MEMBER_ID_TYPE_GROUP]).order("spin_uid")
      #group_member_list = SpinGroup.limit(limit).offset(offset).where(["spin_group_name = ? AND id_type = ?", gname ,2]).order("spin_gid")
      if uid_list.length < 0
        rethash[:success] = false
        rethash[:status] = ERROR_NO_GROUPS
        rethash[:errors] = '該当するメンバー・グループが有りません'
        return rethash
      else
        group_member_list = Array.new;
        for i in 0..uid_list.length() - 1 do
          #group_member_list[i] = SpinUser.limit(limit).offset(offset).where(["spin_uid = ?", uid_list[i]['spin_uid']]).order("spin_uid")
          group_member_list[i] = SpinUser.limit(limit).where(["spin_uid = ?", uid_list[i]['spin_uid']]).order("spin_uid")
        end
        rethash[:success] = true
        rethash[:status] = INFO_GET_GROUP_MEMBER_LIST_SUCCESS
        rethash[:members] = group_member_list
        nrs = SpinGroupMember.select("id").where(["id_type = ? OR id_type = ?", GROUP_MEMBER_ID_TYPE_USER_PRIMARY_GROUP, GROUP_MEMBER_ID_TYPE_GROUP]).order("spin_uid")
        rethash[:total] = nrs.length
      end
      work_group_list = self.limit(limit).offset(offset).where(["session_id = ? AND list_type = ?", sid, list_type]).order("group_name ASC")
      work_group_list.each {|wgl|
        if wgl[:member_id].present?
          group_list.push wgl
        end
      }
      rethash[:success] = true
      rethash[:status] = INFO_GET_GROUP_LIST_SUCCESS
      rethash[:members] = group_list
      nrs = self.select("id").where(["session_id = ? AND list_type = ? AND member_id is not null", sid, list_type]).order("group_name ASC")
      rethash[:total] = nrs.length
      #    when X_GROUP_LIST_ALL
      #      work_group_list = self.limit(limit).offset(offset).where(:session_id => sid, :list_type => list_type).order("group_name ASC")
      #      work_group_list.each {|wgl|
      #        if nil != wgl[:member_id]
      #          group_list.push wgl
      #        end
      #      }
      #      rethash[:success] = true
      #      rethash[:status] = INFO_GET_GROUP_LIST_SUCCESS
      #      rethash[:members] = group_list
      #      nrs = self.select("id").where(["session_id = ? AND list_type = ? AND member_id is not null", sid, list_type]).order("group_name ASC")
      #      rethash[:total] = nrs.length
    when GROUP_LIST_FOLDER, GROUP_LIST_FILE
      rethash[:groups] = group_list
    when GROUP_LIST_CREATED
      uid = SessionManager.get_uid(sid, true)
      group_list = SpinGroup.limit(limit).offset(offset).where(["owner_id = ? AND id_type = ?", uid, GROUP_LIST_DATA_GROUP]).order("spin_group_name ASC")
      rethash[:success] = true
      rethash[:status] = INFO_GET_GROUP_LIST_SUCCESS
      rethash[:groups] = group_list
      nrs = SpinGroup.select("id").where(["owner_id = ? AND id_type = ?", uid, GROUP_LIST_DATA_GROUP]).order("spin_group_name ASC")
      rethash[:total] = nrs.length
    when GROUP_MEMBER_LIST_SELECTED
      delquery = sprintf("DELETE FROM group_data")
      self.connection.select_all(delquery)
      #      current_data = self.where(["id > 0"])
      #      current_data.each {|c|
      #        c.destroy
      #      }
      gname = SessionManager.get_current_selected_group_name(sid)
      if gname == nil
        rethash[:success] = true
        rethash[:status] = ERROR_NO_GROUPS

        rethash[:erros] = '該当するメンバー・グループが有りません'
        rethash[:members] = []

        rethash[:errors] = '該当するメンバー・グループが有りません'

        return rethash
      end
      gid = SpinGroup.get_group_id_by_group_name(gname)
      uid_list = SpinGroupMember.limit(limit).offset(offset).where(["spin_gid = ? AND (id_type = ? OR id_type = ?)", gid, GROUP_MEMBER_ID_TYPE_USER_PRIMARY_GROUP, GROUP_MEMBER_ID_TYPE_GROUP]).order("spin_uid")
      #group_member_list = SpinGroup.limit(limit).offset(offset).where(["spin_group_name = ? AND id_type = ?", gname ,2]).order("spin_gid")
      if uid_list.length < 0
        rethash[:success] = false
        rethash[:status] = ERROR_NO_GROUPS
        rethash[:errors] = '該当するメンバー・グループが有りません'
        return rethash
      else
        group_member_list = Array.new;
        for i in 0..uid_list.length() - 1 do
          #group_member_list[i] = SpinUser.limit(limit).offset(offset).where(["spin_uid = ?", uid_list[i]['spin_uid']]).order("spin_uid")
          group_member_list[i] = SpinUser.limit(limit).where(["spin_uid = ?", uid_list[i]['spin_uid']]).order("spin_uid")
        end
        rethash[:success] = true
        rethash[:status] = INFO_GET_GROUP_MEMBER_LIST_SUCCESS
        rethash[:members] = group_member_list
        nrs = SpinGroupMember.select("id").where(["spin_gid = ? AND (id_type = ? OR id_type = ?)", gid, GROUP_MEMBER_ID_TYPE_USER_PRIMARY_GROUP, GROUP_MEMBER_ID_TYPE_GROUP]).order("spin_uid")
        rethash[:total] = nrs.length
      end
      #    else # =>  I don't know
      #      rethash[:success] = false
      #      rethash[:status] = ERROR_NO_GROUPS
      #      rethash[:erros] = '該当するメンバー・グループが有りません'
      #      return rethash
    end
    return rethash
  end

  # => end of get_file_list_display_data

  def self.reset_folder_group_access_list sid, list_type
    listd = self.where :session_id => sid, :list_type => list_type
    if listd.length > 0
      listd.each {|ld|
        ld.destroy
      }
    end
  end

  # => end of self.reset_folder_group_access_list sid, list_type

  def self.get_folder_node_data sid, list_type, offset, limit, add_flag, target_hashkey
    pwd = target_hashkey
    acl_str = '---'
    notify_str = '---'
    recs = 0
    if add_flag == 0
      # clear data
      # cdsql="select * from group_data where session_id='"+sid+"' and list_type="+list_type.to_s+" and target_hash_key='"+pwd+"';";
      last_data = GroupDatum.where(session_id: sid, list_type: list_type, target_hash_key: pwd)
      # last_data=self.find_by_sql(cdsql);
      last_data.each {|ld|
        #if ld[:data_class] != GROUP_INITIAL_MEMBER_ID_TYPE
        ld.destroy
        #end
      }
    end

    ss = SpinSession.find_by(spin_session_id: sid)
    if ss.blank?
      return 0
    end

    # sql2="select * from spin_nodes where spin_uid="+ss[0]['spin_uid'].to_s+" and spin_node_hashkey='"+ss[0]["spin_current_directory"]+"';"
    sn = SpinNode.find_by(spin_uid: ss[:spin_uid], spin_node_hashkey: ss[:spin_current_directory])
    sg = SpinGroup.find_by(owner_id: ss['spin_uid'])

    grecs = self.where(session_id: sid, list_type: list_type, target_hash_key: pwd)
    # unless ags.count > 0
    #   return 0
    # end

    already_flag = 0
    grecs.each {|grec|
      if grec[:member_id] == sg[:spin_gid]
        already_flag = 1
        break
      end
    }
    # already_flag = 0
    # for i in 0..ags.length-1 do
    #   if (ags[i][:member_id].to_i==sg[:spin_gid].to_i)
    #     already_flag=1;
    #   end
    # end

    retry_new_rec = ACTIVE_RECORD_RETRY_COUNT
    catch(:get_folder_node_data_again) {
      GroupDatum.transaction do
        begin
          if already_flag == 0 and sn.present?
            new_group_rec = GroupDatum.create {|ag|
              ag[:session_id] = sid
              r = Random.new
              new_hash_key = Security.hash_key_s(pwd + sid + r.rand.to_s)
              ag[:hash_key] = new_hash_key
              ag[:group_name] = sg[:spin_group_name]
              ag[:group_description] = sg[:group_descr]
              ag[:target_hash_key] = pwd
              ag[:member_name] = sn[:node_name]
              ag[:member_id] = sn[:spin_gid]
              acl_value = sn[:spin_gid_access_right]
              acl_str[0] = (acl_value & ACL_NODE_READ != 0 ? 'r' : '-')
              acl_str[1] = (acl_value & ACL_NODE_WRITE != 0 ? 'w' : '-')
              acl_str[2] = (acl_value & ACL_NODE_CONTROL != 0 ? 'a' : '-')
              ag[:group_privilege] = acl_str
              notify_str[0] = (sn[:notify_upload] == 1 ? 'u' : '-') # => upload
              notify_str[1] = (sn[:notify_modify] == 1 ? 'm' : '-') # => modify
              notify_str[2] = (sn[:notify_delete] == 1 ? 'd' : '-') # => delete
              ag[:group_notification] = notify_str
              ag[:list_type] = list_type
              ag[:data_class] = list_type
            }
            recs += 1
          end
        rescue ActiveRecord::StaleObjectError
          if retry_new_rec > 0
            retry_new_rec -= 1
            throw :get_folder_node_data_again
          else
            return recs
          end
        end
      end # end of transaction
    }
    return recs
  end

  def self.get_folder_group_access_list sid, list_type, offset, limit, add_flag, target_hashkey
    rethash = Hash.new
    recs = 0
    # get gid
    ids = SessionManager.get_uid_gid(sid)
    #pwd = DatabaseUtility::SessionUtility.get_current_directory(sid)

    group_access_list = Array.new

    pwd = target_hashkey;

    rethash[:start] = offset
    rethash[:limit] = limit

    current_group_access_list = self.where(list_type: list_type, target_hash_key: pwd, is_void: false).order("data_class DESC").offset(offset).limit(limit)
    group_access_control_list = SpinAccessControl.where(managed_node_hashkey: pwd)

    group_access_control_list.each {|gacl|
      sg = SpinGroup.find_by(spin_gid: gacl[:spin_gid])
      next if sg.blank? or gacl[:spin_gid] < 0

      acl_value = gacl[:spin_gid_access_right]
      acl_str = '---'
      acl_str[0] = (acl_value & ACL_NODE_READ != 0 ? 'r' : '-')
      acl_str[1] = (acl_value & ACL_NODE_WRITE != 0 ? 'w' : '-')
      acl_str[2] = (acl_value & ACL_NODE_CONTROL != 0 ? 'a' : '-')
      notify_str = '---'
      notify_str[0] = (gacl[:notify_upload] == 1 ? 'u' : '-') # => upload
      notify_str[1] = (gacl[:notify_modify] == 1 ? 'm' : '-') # => modify
      notify_str[2] = (gacl[:notify_delete] == 1 ? 'd' : '-') # => delete

      if current_group_access_list.size <= 0
        new_acl = self.create {|ag|
          ag[:session_id] = sid
          r = Random.new
          new_hash_key = Security.hash_key_s(pwd + sid + r.rand.to_s)
          ag[:hash_key] = new_hash_key
          ag[:group_name] = sg[:spin_group_name]
          ag[:group_description] = sg[:group_descr]
          ag[:target_hash_key] = pwd
          ag[:member_id] = sg[:spin_gid]
          ag[:group_privilege] = acl_str
          ag[:group_notification] = notify_str
          ag[:list_type] = list_type
          ag[:data_class] = sg[:id_type]
        }
      else
        already_flag = 0;
        index = 0;
        current_group_access_list.each_with_index {|galrec, i|
          if galrec[:member_id] == sg[:spin_gid]
            already_flag = 1
            index = i
          end
        }
        if already_flag == 0
          new_rec = self.create {|ag|
            ag[:session_id] = sid
            r = Random.new
            new_hash_key = Security.hash_key_s(pwd + sid + r.rand.to_s)
            ag[:hash_key] = new_hash_key
            ag[:group_name] = sg[:spin_group_name]
            ag[:group_description] = sg[:group_descr]
            ag[:target_hash_key] = pwd
            ag[:member_id] = sg[:spin_gid]
            ag[:group_privilege] = acl_str
            ag[:list_type] = list_type
            ag[:data_class] = sg[:id_type]
            ag[:group_notification] = notify_str
          }
        else
          retry_update = ACTIVE_RECORD_RETRY_COUNT
          catch(:update_folder_group_access_list_again) {
            GroupDatum.transaction do
              begin
                nrecs = GroupDatum.where(hash_key: current_group_access_list[index][:hash_key], is_void: false).update_all(
                    session_id: sid,
                    group_name: sg[:spin_group_name],
                    group_description: sg[:group_descr],
                    target_hash_key: pwd,
                    member_id: sg[:spin_gid],
                    group_privilege: acl_str,
                    list_type: list_type,
                    data_class: sg[:id_type],
                    group_notification: notify_str
                )
              rescue ActiveRecord::StaleObjectError
                if retry_update > 0
                  retry_update -= 1
                  throw :update_folder_group_access_list_again
                end
              end
            end # end of transaction
          } # end of catch-block
        end
        recs += 1
      end
    }

    group_access_list = self.where(session_id: sid, list_type: list_type, target_hash_key: pwd, is_void: false).order("data_class DESC").offset(offset).limit(limit)

    rethash[:success] = true
    rethash[:status] = INFO_GET_GROUP_LIST_SUCCESS
    rethash[:total] = group_access_list.size
    rethash[:groups] = group_access_list
    return rethash
  end

  # => end of get_file_list_display_data

  def self.get_file_group_access_list sid, list_type, offset, limit
    rethash = Hash.new
    group_access_list = []
    recs = 0
    # get gid
    #    ids = SessionManager.get_uid_gid(sid)
    pwd = DatabaseUtility::SessionUtility.get_current_directory(sid)
    # get selected file
    firec = FileDatum.find_by(session_id: sid, folder_hash_key: pwd, selected: true)
    if firec.blank?
      printf ">> firec is nil!\n"
      rethash[:total] = 0
      rethash[:start] = offset
      rethash[:limit] = limit
      rethash[:success] = true
      rethash[:status] = INFO_GET_GROUP_LIST_SUCCESS
      rethash[:groups] = group_access_list
      return rethash
    end
    file_node_key = firec[:spin_node_hashkey]
    FileDatum.reset_selected(sid, file_node_key)

    # clear data
    self.transaction do
      last_data = self.where("session_id = ? AND list_type = ? AND target_hash_key = ? ", sid, list_type, file_node_key)
      if last_data.length > 0
        last_data.each {|ld|
          if ld[:data_class] != GROUP_INITIAL_MEMBER_ID_TYPE
            ld.destroy
          end
        }
      end
    end

    rethash[:start] = offset
    rethash[:limit] = limit
    #    group_access_control_list = SpinAccessControl.select("max(spin_gid_access_right), spin_gid").group("spin_gid").where(managed_node_hashkey: pwd)
    group_access_control_list = SpinAccessControl.where(["managed_node_hashkey = ?", file_node_key])
    #    group_access_control_list = SpinAccessControl.where(spin_gid: ids[:gid],managed_node_hashkey: pwd)
    #    unless group_access_control_list.length > 0
    #      rethash[:total] = 0
    #      rethash[:start] = offset
    #      rethash[:limit] = limit
    #      rethash[:success] = false
    #      rethash[:status] = ERROR_NO_GROUPS
    #      rethash[:erros] = '該当するグループが有りません'
    #      return rethash
    #    end

    ags = Array.new
    self.transaction do
      ags = self.where("session_id = ? AND list_type = ? AND target_hash_key = ?", sid, list_type, file_node_key)
    end

    group_access_control_list.each {|gacl|
      sg = SpinGroup.find_by(spin_gid: gacl[:spin_gid])
      next if sg == nil
      next if gacl[:spin_gid] < 0
      if ags.length <= 0
        ag = self.new
        ag[:session_id] = sid
        ag[:group_name] = sg[:spin_group_name]
        ag[:group_description] = sg[:group_descr]
        ag[:target_hash_key] = file_node_key
        acl_value = gacl[:spin_gid_access_right]
        acl_str = '---'
        acl_str[0] = (acl_value & ACL_NODE_READ != 0 ? 'r' : '-')
        acl_str[1] = (acl_value & ACL_NODE_WRITE != 0 ? 'w' : '-')
        acl_str[2] = (acl_value & ACL_NODE_CONTROL != 0 ? 'a' : '-')
        #      acl_str[0] = (gacl[:spin_gid_access_right]&ACL_NODE_READ != 0 ? 'r' : '-')
        #      acl_str[1] = (gacl[:spin_gid_access_right]&ACL_NODE_WRITE != 0 ? 'w' : '-')
        #      acl_str[2] = (gacl[:spin_gid_access_right]&ACL_NODE_CONTROL != 0 ? 'a' : '-')
        ag[:group_privilege] = acl_str
        ag[:list_type] = list_type
        if ag.save
          recs += 1
        end
      else
        ags.each {|nag|
          ag = {}
          if nag[:group_name] == sg[:spin_group_name]
            ag = nag
          else
            ag = self.new
          end
          ag[:session_id] = sid
          ag[:group_name] = sg[:spin_group_name]
          ag[:group_description] = sg[:group_descr]
          ag[:target_hash_key] = file_node_key
          acl_value = gacl[:spin_gid_access_right]
          acl_str = '---'
          acl_str[0] = (acl_value & ACL_NODE_READ != 0 ? 'r' : '-')
          acl_str[1] = (acl_value & ACL_NODE_WRITE != 0 ? 'w' : '-')
          acl_str[2] = (acl_value & ACL_NODE_CONTROL != 0 ? 'a' : '-')
          #      acl_str[0] = (gacl[:spin_gid_access_right]&ACL_NODE_READ != 0 ? 'r' : '-')
          #      acl_str[1] = (gacl[:spin_gid_access_right]&ACL_NODE_WRITE != 0 ? 'w' : '-')
          #      acl_str[2] = (gacl[:spin_gid_access_right]&ACL_NODE_CONTROL != 0 ? 'a' : '-')
          ag[:group_privilege] = acl_str
          ag[:list_type] = list_type
          ag[:data_class] = sg[:id_type]
          if ag.save
            recs += 1
          end
        }
      end
    }

    # then make list again
    group_access_list = Array.new
    self.transaction do
      group_access_list = self.where :session_id => sid, :list_type => list_type, :target_hash_key => file_node_key
      group_access_list.uniq!
      #    group_access_list = []
      rethash[:success] = true
      rethash[:status] = INFO_GET_GROUP_LIST_SUCCESS
      rethash[:total] = group_access_list.length
      rethash[:groups] = group_access_list
    end
    return rethash
  end

  # => end of get_file_list_display_data

  def self.append_group_to_privilege_list sid, folder_cont_location, groups, target_hash_key, list_type = GROUP_LIST_FOLDER
    # get the target folder to add groups
    target = ''
    extended_groups = []

    case list_type
    when GROUP_LIST_FOLDER
      unless target_hash_key.empty?
        target = target_hash_key
      else
        target = DatabaseUtility::SessionUtility.get_location_current_directory(sid, folder_cont_location)
      end
    when GROUP_LIST_FILE
      unless target_hash_key.empty?
        target = target_hash_key
      else
        tf = DatabaseUtility::SessionUtility.get_location_current_directory(sid, folder_cont_location)
        target_recs = FileDatum.where(["session_id = ? AND folder_hash_key = ? AND cont_location = ?", sid, tf, folder_cont_location])
        target = target_recs[0][:spin_node_hashkey]
      end
      FileDatum.set_selected(sid, target, folder_cont_location)
    end

    #    ids = SessionManager.get_uid_gid(sid)
    recs = 0

    groups.each {|g|
      # check group data
      gname = g[:group_name]

      acl_str = '---'
      ntf_str = '---'
      data_class = GROUP_INITIAL_MEMBER_ID_TYPE
      ople = nil

      if g[:leaf] == true
        ople = self.find_by(group_name: gname, list_type: list_type, target_hash_key: target)
        if g[:owner_id] == -1
          group_list = SpinGroup.where(spin_group_name: gname)
          group_list.each {|gl|
            data_class = gl[:id_type]
            retry_update_or_create1 = ACTIVE_RECORD_RETRY_COUNT
            catch(:update_or_create_again1) {
              GroupDatum.transaction do
                begin
                  new_group_datum = GroupDatum.find_or_create_by(session_id: sid, group_name: gname, list_type: list_type, target_hash_key: target, member_name: g[:member_name]) {|primary_group|
                    primary_group[:session_id] = sid
                    if primary_group[:hash_key].blank?
                      r = Random.new
                      new_hash_key = Security.hash_key_s(target_hash_key + sid + r.rand.to_s)
                      primary_group[:hash_key] = new_hash_key
                    end
                    primary_group[:target_hash_key] = target
                    if primary_group[:group_privilege].blank?
                      primary_group[:group_privilege] = acl_str
                    end
                    if primary_group[:group_notification].blank?
                      primary_group[:group_notification] = ntf_str
                    end
                    # if primary_group[:data_class] == GROUP_INITIAL_MEMBER_ID_TYPE
                    #   primary_group[:data_class] = data_class
                    # end
                    primary_group[:list_type] = list_type
                    primary_group[:data_class] = data_class
                    primary_group[:group_name] = gname
                    primary_group[:member_id] = gl["spin_gid"]
                    primary_group[:group_description] = gl["group_descr"]
                  }
                rescue ActiveRecord::StaleObjectError
                  if retry_update_or_create1 > 0
                    retry_update_or_create1 -= 1
                    throw :update_or_create_again1
                  end
                end
              end
            }
            recs += 1
          }
        else
          sg = SpinGroup.select("spin_gid, id_type").find_by(id_type: 1, spin_group_name: g[:group_name], owner_id: g[:owner_id])
          secondary_gid = 0
          if sg.present?
            secondary_gid = sg[:spin_gid]
            data_class = sg[:id_type]
          end
          retry_update_or_create2 = ACTIVE_RECORD_RETRY_COUNT
          catch(:update_or_create_again2) {
            GroupDatum.transaction do
              begin
                new_group_datum = GroupDatum.find_or_create_by(session_id: sid, group_name: gname, list_type: list_type, target_hash_key: target, member_name: g[:member_name]) {|secondary_group|
                  secondary_group[:session_id] = sid
                  if secondary_group[:hash_key].blank?
                    r = Random.new
                    new_hash_key = Security.hash_key_s(target_hash_key + sid + r.rand.to_s)
                    secondary_group[:hash_key] = new_hash_key
                  end
                  secondary_group[:target_hash_key] = target
                  if secondary_group[:group_privilege].blank?
                    secondary_group[:group_privilege] = acl_str
                  end
                  if secondary_group[:group_notification].blank?
                    secondary_group[:group_notification] = ntf_str
                  end
                  # if secondary_group[:data_class] == GROUP_UNINITIALIZED_MEMBER_ID_TYPE
                  #   secondary_group[:data_class] = data_class
                  # end
                  secondary_group[:list_type] = list_type
                  secondary_group[:data_class] = data_class
                  secondary_group[:group_name] = g[:group_name]
                  secondary_group[:member_id] = secondary_gid
                }
              rescue ActiveRecord::StaleObjectError
                if retry_update_or_create2 > 0
                  retry_update_or_create2 -= 1
                  throw :update_or_create_again2
                end
              end
            end
          }
          recs += 1
        end
      else
        ople = self.find_by(group_name: g[:group_name], list_type: list_type, target_hash_key: target)
        if g[:owner_id] == -1
          group_list = SpinGroup.where(spin_group_name: g[:group_name])
          group_list.each {|gl|
            data_class = gl[:id_type]
            retry_update_or_create1 = ACTIVE_RECORD_RETRY_COUNT
            catch(:update_or_create_again1) {
              GroupDatum.transaction do
                begin
                  new_group_datum = GroupDatum.find_or_create_by(session_id: sid, group_name: g[:group_name], list_type: list_type, target_hash_key: target) {|primary_group|
                    primary_group[:session_id] = sid
                    if primary_group[:hash_key].blank?
                      r = Random.new
                      new_hash_key = Security.hash_key_s(target_hash_key + sid + r.rand.to_s)
                      primary_group[:hash_key] = new_hash_key
                    end
                    primary_group[:target_hash_key] = target
                    if primary_group[:group_privilege].blank?
                      primary_group[:group_privilege] = acl_str
                    end
                    if primary_group[:group_notification].blank?
                      primary_group[:group_notification] = ntf_str
                    end
                    if primary_group[:data_class] == GROUP_UNINITIALIZED_MEMBER_ID_TYPE
                      primary_group[:data_class] = data_class
                    end
                    primary_group[:list_type] = list_type
                    primary_group[:data_class] = data_class
                    primary_group[:group_name] = g[:group_name]
                    primary_group[:member_id] = gl["spin_gid"]
                    primary_group[:group_description] = gl["group_descr"]
                  }
                rescue ActiveRecord::StaleObjectError
                  if retry_update_or_create1 > 0
                    retry_update_or_create1 -= 1
                    throw :update_or_create_again1
                  end
                end
              end
            }
            recs += 1
          }
        else
          sg = SpinGroup.select("spin_gid, id_type").find_by(id_type: 1, spin_group_name: g[:group_name], owner_id: g[:owner_id])
          secondary_gid = 0
          if sg.present?
            secondary_gid = sg[:spin_gid]
            data_class = sg[:id_type]
          end
          retry_update_or_create2 = ACTIVE_RECORD_RETRY_COUNT
          catch(:update_or_create_again2) {
            GroupDatum.transaction do
              begin
                new_group_datum = GroupDatum.find_or_create_by(group_name: g[:group_name], list_type: list_type, target_hash_key: target) {|secondary_group|
                  secondary_group[:session_id] = sid
                  if secondary_group[:hash_key].blank?
                    r = Random.new
                    new_hash_key = Security.hash_key_s(target_hash_key + sid + r.rand.to_s)
                    secondary_group[:hash_key] = new_hash_key
                  end
                  secondary_group[:target_hash_key] = target
                  if secondary_group[:group_privilege].blank?
                    secondary_group[:group_privilege] = acl_str
                  end
                  if secondary_group[:group_notification].blank?
                    secondary_group[:group_notification] = ntf_str
                  end
                  if secondary_group[:data_class] == GROUP_UNINITIALIZED_MEMBER_ID_TYPE
                    secondary_group[:data_class] = data_class
                  end
                  secondary_group[:list_type] = list_type
                  secondary_group[:data_class] = data_class
                  secondary_group[:group_name] = g[:group_name]
                  secondary_group[:member_id] = secondary_gid
                }
              rescue ActiveRecord::StaleObjectError
                if retry_update_or_create2 > 0
                  retry_update_or_create2 -= 1
                  throw :update_or_create_again2
                end
              end
            end
          }
          recs += 1
        end
      end

      ple = nil
      acl_str = '---'
      ntf_str = '---'
      data_class = GROUP_INITIAL_MEMBER_ID_TYPE

      if ople.present? #  modify data
        ple = ople
        acl_str = ople[:group_privilege]
        ntf_str = ople[:group_notification]
        data_class = ople[:data_class]
        group_descr = SpinGroup.select("group_descr, id_type").find_by(spin_group_name: ple[:group_name], spin_gid: g[:group_id])
        if group_descr.present?
          data_class = group_descr[:id_type]
        end
        if g[:leaf] == true
          retry_update_or_create0 = ACTIVE_RECORD_RETRY_COUNT
          catch(:update_or_create_again0) {
            GroupDatum.transaction do
              begin
                nrecs = GroupDatum.where(group_name: gname, list_type: list_type, target_hash_key: target).update_all(
                    session_id: sid,
                    target_hash_key: target,
                    group_privilege: acl_str,
                    list_type: list_type,
                    data_class: data_class,
                    group_name: gname,
                    member_id: g[:group_id],
                    member_name: ple[:data_class] == GROUP_LIST_DATA_USER_PRIMARY_GROUP ? (g[:member_name].present? ? g[:member_name] : SpinUserAttribute.get_user_display_name(g[:member_id])) : g[:member_name],
                    group_description: group_descr
                )
              rescue ActiveRecord::StaleObjectError
                if retry_update_or_create0 > 0
                  retry_update_or_create0 -= 1
                  throw :update_or_create_again0
                end
              end
            end
          }
          recs += 1
        else
        end
      else # add new data

      end

    }
    return recs
  end

  # =>  end of append_group_to_privilege_list

  def self.remove_group_from_privilege_list sid, groups, list_type = GROUP_LIST_FOLDER
    # get the target folder to add groups
    recs = 0

    group_names = Array.new
    groups.each {|g|
      group_names.push(g[:group_name])
    }
    # retry_remove = ACTIVE_RECORD_RETRY_COUNT
    # catch(:remove_group_from_privilege_list_again) {
    #   self.transaction do
    #     remove_groups = self.where(group_name: group_names)
    #     begin
    #       remove_groups.each {|g|
    #         g.update(is_void: true)
    #         recs += 1
    #       }
    #     rescue ActiveRecord::StaleObjectError
    #       if retry_remove > 0
    #         retry_remove -= 1
    #         sleep(AR_RETRY_WAIT_MSEC)
    #         throw :remove_group_from_privilege_list_again
    #       end
    #     end
    #   end
    # }

    self.transaction do
      recs = GroupDatum.where(group_name: group_names).update_all(is_void: true)
    end

    return recs
  end

  # =>  end of append_group_to_privilege_list

  def self.secret_files_get_domain_access_list sid, list_type, offset, limit, target_hashkey, domain_hashkey
    rethash = Hash.new
    recs = 0
    # get gid
    #    ids = SessionManager.get_uid_gid(sid)
    #pwd = DatabaseUtility::SessionUtility.get_current_directory(sid)

    pwd = target_hashkey;

    # clear data
    #last_data = self.where( "session_id = ? AND list_type = ? AND target_hash_key = ? ", sid, list_type, pwd)
    #    last_data = self.where( "session_id = ? AND list_type = ? AND target_hash_key = ?", sid, list_type, pwd )
    #if last_data.length > 0
    #  last_data.each {|ld|
    #    if ld[:data_class] != GROUP_INITIAL_MEMBER_ID_TYPE
    #      ld.destroy
    #    end
    #  }
    #end
    rethash[:start] = offset
    rethash[:limit] = limit
    begin
      #    group_access_control_list = SpinAccessControl.select("max(spin_gid_access_right), spin_gid").group("spin_gid").where(managed_node_hashkey: pwd)
      group_access_control_list = SpinAccessControl.where(["root_node_hashkey = ?", domain_hashkey])
      if (group_access_control_list.blank?) #WebUIには :root_node_hashkeyがNULLのため・・・・
        group_access_control_list = SpinAccessControl.where(["managed_node_hashkey = ?", pwd])
      end
      #ags = self.where( "session_id = ? AND list_type = ? AND target_hash_key = ?", sid, list_type, pwd )
      ag = Array.new
      group_access_control_list.each_with_index {|gacl, index|
        sg = SpinGroup.find_by(spin_gid: gacl[:spin_gid])
        next if sg == nil
        next if gacl[:spin_gid] < 0
        ag[index] = {}
        ag[index][:session_id] = sid
        ag[index][:group_name] = sg[:spin_group_name]
        ag[index][:group_description] = sg[:group_descr]
        ag[index][:target_hash_key] = pwd
        ag[index][:member_id] = sg[:spin_gid]
        acl_value = gacl[:spin_gid_access_right]
        #acl_str = '---'
        ag[index][:group_privilege_read] = (acl_value & ACL_NODE_READ != 0 ? true : false)
        ag[index][:group_privilege_write] = (acl_value & ACL_NODE_WRITE != 0 ? true : false)
        ag[index][:group_privilege_control] = (acl_value & ACL_NODE_CONTROL != 0 ? true : false)
        #ag[index][:spin_gid_access_right] = gacl[:spin_gid_access_right]
        #ag[index][:group_privilege] = acl_str
        #notify_str = '---'
        ag[index][:group_notification_upload] = (gacl[:notify_upload] == 1 ? true : false) # => upload
        ag[index][:group_notification_modify] = (gacl[:notify_modify] == 1 ? true : false) # => modify
        ag[index][:group_notification_delete] = (gacl[:notify_delete] == 1 ? true : false) # => delete
        #ag[index][:group_notification] = notify_str
        ag[index][:list_type] = list_type
        ag[index][:data_class] = sg[:id_type]
      }
      rethash[:success] = true
      rethash[:status] = INFO_GET_GROUP_LIST_SUCCESS
      rethash[:total] = ag.length
      rethash[:groups] = ag
      return rethash
    rescue => e
      rethash[:success] = false
      rethash[:status] = INFO_GET_GROUP_LIST_SUCCESS
      rethash[:errors] = e.message
      return rethash
    end
  end


end

