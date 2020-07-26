# :coding => utf-8
require 'const/vfs_const'
require 'const/acl_const'
require 'const/stat_const'
require 'tasks/spin_location_manager'
require 'tasks/session_management'
require 'tasks/security'
require 'utilities/set_utilities'
require 'multi_json'

class FolderDatum < ActiveRecord::Base
  include Vfs
  include Acl
  include Stat
  attr_accessor :selected, :capacity, :cls, :cont_location, :control_right, :created_at, :updated_at, :created_date, :spin_updated_at, :creator, :expanded, :fileNumber, :folder_name, :folder_readable_status, :folder_writable_status, :hash_key, :id, :img, :leaf, :owner, :ownership, :parent_readable_status, :parent_writable_status, :restSpace, :session_id, :subFolders, :text, :updated_date, :updater, :usedRate, :usedSpace, :workingFolder


  TREE_NOT_INCLUDE_ROOT = false
  TREE_INCLUDE_ROOT = true

  def self.get_accessible_folders ssid, current_root_node
    ids = SessionManager.get_uid_gid(ssid, false)
    uid = ids[:uid]
    gid = ids[:gid]
    gids = ids[:gids]
    #    gids += SpinGroupMember.get_parent_gids ids[:gid]

    accessible_nodes = []

    rnode = SpinNode.find_by_spin_node_hashkey current_root_node
    rx = rnode[:node_x_coord]
    ry = rnode[:node_y_coord]

    if uid == 0 or ids[:gid] == 0
      begin
        accessible_nodes = SpinNode.where(["spin_tree_type = 0 AND node_x_pr_coord = ? AND node_y_coord = ? AND node_type = ?)", rx, ry, NODE_DIRECTORY])
      rescue ActiveRecord::RecordNotFound
        # => do nothing
      end
    end

    begin
      accessible_nodes = SpinNode.where(["spin_tree_type = 0 AND node_x_pr_coord = ? AND node_y_coord = ? AND node_type = ? AND \
      ((spin_uid = ? AND spin_uid_access_right > 0) OR (spin_gid = ? AND spin_gid_access_right > 0) OR spin_world_access_right > 0)", \
            rx, ry, NODE_DIRECTORY, uid, gid])
    rescue ActiveRecord::RecordNotFound
      # => do nothing
    end

    aanodes = []
    gids.each {|grp|
      begin
        aanodes += SpinAccessControl.where(["ppx = ? AND py = ? AND spin_node_type = ? AND \
        ((spin_uid = ? AND spin_uid_access_right > 0) OR (spin_gid = ? AND spin_gid_access_right > 0) OR spin_world_access_right > 0)", \
              rx, ry, NODE_DIRECTORY, uid, grp])
      rescue ActiveRecord::RecordNotFound
        next
      end
    }

    #    ActiveRecord::Base.transaction do
    aanodes.each {|an|
      begin
        sn = SpinNode.find_by_spin_node_hashkey an[:managed_node_hashkey]
        accessible_nodes += [sn]
      rescue ActiveRecord::RecordNotFound
        next
      end
    }
    #    end

    # make it unique array
    accessible_nodes.uniq!

    return accessible_nodes
  end

  # => end of self.get_accessible_folders ssid, location, current_root_node

  def self.fill_folder_data_table ssid, last_ssid, my_uid, location, current_domain_key, partial_root_node = nil, process_request = PROCESS_FOR_UNIVERSAL_REQUEST, force_make_it = false, load_layers = 2, initial_load = false
    # get current domain for the session 'ssid'
    # current_domain_key = SpinSession.find_by_spin_session_id ssid

    #    ActiveRecord::Base::lock_optimistically = false

    if current_domain_key.blank? || current_domain_key == "0"
      #      logger.debug ">>> get_default_domain"
      current_domain_key = DatabaseUtility::SessionUtility.get_default_domain ssid
    end

    folder_tree_nodes = []
    folder_tree_node_keys = []

    root_user_access = (my_uid == 0 ? true : false)

    dom_location = ''
    case location
    when 'folder_a', 'folder_at', 'folder_a', 'folder_atfi'
      dom_location = 'folder_a'
    when 'folder_b', 'folder_bt', 'folder_b', 'folder_btfi'
      dom_location = 'folder_b'
    end

    partial_view = false

    #    # Is it dirty?
    #    fs = self.where session_id: ssid, cont_location: location, domain_hash_key: current_domain_key
    #    if force_make_it == false and fs.length > 0 and SessionManager.is_dirty_location(ssid, location, current_domain_key) == false
    #      return {success: true, status: STAT_DATA_ALREADY_LOADED, result: fs.length }
    #    end

    # => fix current_root_node
    current_domain_data = nil
    current_domain_root_obj = nil
    if partial_root_node.present?
      current_root_node = partial_root_node
    else
      self.transaction do
        current_domain_root_obj = SpinDomain.get_domain_root_node(current_domain_key)
        if current_domain_root_obj.blank?
          return folder_tree_nodes
        else
          current_root_node = current_domain_root_obj[:domain_root_node_hashkey]
        end

        begin
          current_domain_data = DomainDatum.readonly.find_by(spin_domain_hash_key: current_domain_key, cont_location: dom_location)
          if current_domain_data.blank?
            return folder_tree_nodes
          end
        rescue ActiveRecord::RecordNotFound
          # => do nothing
          return folder_tree_nodes
        end
      end
    end

    # => get root node location[x,y,prx,..]
    d_root_loc = SpinLocationManager.key_to_location current_root_node, NODE_DIRECTORY
    root_y = d_root_loc.present? ? d_root_loc[Y] : 0; # => exclude nodes which have y =< root_y

    # => Is it a partial root?
    if partial_root_node.blank? # => not a partial root

      # => remove not-accessible node
      begin
        current_frecs = self.where(["session_id = ? AND cont_location = ? AND domain_hash_key = ? AND py >= ?", ssid, location, current_domain_key, root_y])
        if current_frecs.present?
          current_frecs.each {|cfr|
            if SpinAccessControl.is_accessible_node(ssid, cfr[:spin_node_hashkey], NODE_DIRECTORY)
              if SpinNode.get_pending_flag(cfr[:spin_node_hashkey]) or SpinNode.get_in_trash_flag(cfr[:spin_node_hashkey])
                self.remove_folder_rec ssid, location, cfr[:spin_node_hashkey]
              end
            else
              self.remove_folder_rec ssid, location, cfr[:spin_node_hashkey]
            end
          }
        end
      rescue ActiveRecord::RecordNotFound
        # => do nothing
      end
    end

    # => get children of the current_root_node
    folder_tree_node_keys = SpinAccessControl.get_accessible_brother_nodes ssid, current_root_node, NODE_DIRECTORY
    folder_tree_length = folder_tree_node_keys.present? ? folder_tree_node_keys.length : 0
    key_query = nil
    key_count = 0
    # => go through children
    if folder_tree_node_keys.present?
      folder_tree_node_keys.each_with_index {|node_key, idx|
        key_count = idx + 1
        if key_query.blank?
          key_query = '\'' + node_key + '\''
        else
          key_query += (',' + '\'' + node_key + '\'')
        end
        if key_count % 100 == 0 or key_count == folder_tree_length
          tree_query = "spin_node_hashkey IN (#{key_query})"
          folder_tree_nodes += SpinNode.select("spin_node_hashkey,in_trash_flag,is_pending,spin_updated_at").where("#{tree_query}")
          key_query = nil
        end
      }
    end

    # if root_y == 0
    #   pp "root \'/\'"
    # end

    unless folder_tree_nodes.present? && folder_tree_nodes.length > 0 # => no children
      return {:success => true, :status => true, :result => 0}
    end

    # clear or set "is_partial_view flag
    if process_request == PROCESS_FOR_EXPAND_FOLDER and current_domain_data[:is_dirty] != true
      partial_view = true
    else
      partial_view = false
    end

    # build FolderData
    saved_records = 0
    #    self.transaction do
    if folder_tree_nodes.present?
      folder_tree_nodes.each {|tn|
        #        d = SpinNode.readonly.find_by_spin_node_hashkey_and_node_type tn[:spin_node_hashkey], NODE_DIRECTORY
        next if tn[:in_trash_flag]
        next if tn[:is_pending]
        # acls = SpinAccessControl.has_acl_values ssid, tn[:spin_node_hashkey]
        # if acls[:user] > ACL_NODE_NO_ACCESS or acls[:group] > ACL_NODE_NO_ACCESS  or acls[:world] > ACL_NODE_NO_ACCESS # => match!
        folder_rec = nil
        my_children = Array.new

        catch(:fill_folder_data_table_again) {

          self.transaction do

            begin
              folder_rec = self.find_by(spin_node_hashkey: tn[:spin_node_hashkey], session_id: ssid, cont_location: location, domain_hash_key: current_domain_key)

              if folder_rec.present? # => there is folder data
                retry_fill = ACTIVE_RECORD_RETRY_COUNT
                ActiveRecord::Base.lock_optimistically = true

                # Is there a new child?
                v_notify_new_child = 0
                if folder_rec[:notify_new_child] == 1
                  v_notify_new_child = 0
                end

                #          self.load_folder_recs(ssid, tn[:spin_node_hashkey], current_domain_key, location, load_layers)
                if folder_rec[:spin_updated_at] < tn[:spin_updated_at] or folder_rec[:is_dirty] # => node is newer
                  update_key = update_folder_rec(ssid, location, folder_rec, current_domain_key, -1, nil, nil, root_user_access, initial_load)
                  #            update_key = self.update_folder_rec(ssid, location, tn[:spin_node_hashkey], current_domain_key, -1, nil, nil, root_user_access, initial_load)
                  if update_key.present?
                    saved_records += 1
                  end
                else
                  FolderDatum.where(spin_node_hashkey: tn[:spin_node_hashkey], session_id: ssid, cont_location: location, domain_hash_key: current_domain_key).update_all(notify_new_child: v_notify_new_child)
                end # => if folder_rec.updated_at < tn[:updated_at]

                # Are there children?
                if folder_rec[:children].present?
                  my_children = MultiJson.load(folder_rec[:children])
                end
                # folder_rec.save
                if my_children.present?
                  if folder_rec[:expanded]
                    load_layers = DEPTH_TO_TRAVERSE
                  end
                  my_children.each {|cnid|
                    ckey = SpinNode.get_key_from_id(cnid)
                    unless (ckey.blank? or SpinNode.get_pending_flag_by_id(cnid) or SpinNode.get_in_trash_flag_used_id(cnid))
                      self.load_folder_recs(ssid, ckey, current_domain_key, folder_rec[:parent_hash_key], location, load_layers)
                    end
                  }
                end
              else # => no folder rec's for the session
                new_key = self.create_new_folder_rec(ssid, location, tn[:spin_node_hashkey], tn[:parent_hash_key], current_domain_key, root_y, current_root_node, partial_view, root_user_access, last_ssid)
                unless new_key.blank?
                  pfkey = self.get_parent_folder(ssid, new_key)
                  self.add_child_to_parent(new_key, pfkey, ssid, location)
                  # get new_rec
                  nrecs = self.load_folder_recs(ssid, new_key, current_domain_key, tn[:parent_hash_key], location, load_layers)
                  saved_records += nrecs
                end

              end # => end of if folder_rec.present?
            rescue ActiveRecord::StaleObjectError
              retry_fill -= 1
              if retry_fill > 0
                sleep(AR_RETRY_WAIT_MSEC)
                throw :fill_folder_data_table_again
              else
                return {:success => false, :status => false, :errors => 'Failed to fill folder tree table'}
              end
            end # => end of begin-rescue
          end # => end of transaction
        }

      } # =>  end of folder_tree_nodes.each
    end
    #    end # => end of tansaction
    # printf ">> number of records saved : "
    # pp saved_records
    SessionManager.set_location_clean(ssid, location) # => clean my folder tree's dirty flag which might be set by file loist obj.
    DomainDatum.unset_domain_dirty(ssid, dom_location, current_domain_key)
    return {:success => true, :status => true, :result => saved_records}
  end

  def self.add_child_to_parent child_key, parent_key, session_id, location = 'folder_a'
    # => get parent
    if parent_key.present? and child_key == parent_key
      return true # => root node!
    end

    retry_save = ACTIVE_RECORD_RETRY_COUNT

    catch(:add_child_to_parent_again) {

      FolderDatum.transaction do
        begin
          if parent_key.blank?
            parent_key = SpinLocationManager.get_parent_key(child_key, NODE_DIRECTORY)
          end
          if parent_key.blank?
            return false
          end
          parent_rec = self.find_by(spin_node_hashkey: parent_key, cont_location: location, session_id: session_id)
          if parent_rec.blank? # => It is domain root
            return true
          end

          ActiveRecord::Base.lock_optimistically = false
          if parent_rec[:children].blank?
            pchildren = Array.new
            child_id = SpinNode.get_id_from_key(child_key)
            if child_id > 0
              pchildren.push(child_id)
              parent_rec.update(children: MultiJson.dump(pchildren))
              #              parent_rec[:children] = MultiJson.dump(pchildren)
              #              parent_rec.save
            end
          else
            pchildren = MultiJson.load(parent_rec[:children])
            child_id = SpinNode.get_id_from_key(child_key)
            if child_id > 0
              pchildren.push(child_id)
              pchildren.uniq
              parent_rec.update(children: MultiJson.dump(pchildren))
              #              parent_rec[:children] = MultiJson.dump(pchildren)
              #              parent_rec.save
            end
          end
          ActiveRecord::Base.lock_optimistically = true
        rescue ActiveRecord::StaleObjectError
          if retry_save > 0
            retry_save -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :add_child_to_parent_again
          else
            return false
          end
        end
      end # => end of transaction
    }
    return true
  end

  # => end of self.add_child child_rec

  def self.remove_child_from_parent child_key, parent_key, session_id, location = 'folder_a'
    # => get parent
    if child_key == parent_key
      return true # => root node!
    end

    #    ActiveRecord::Base::lock_optimistically = false
    retry_save = ACTIVE_RECORD_RETRY_COUNT

    ActiveRecord::Base.lock_optimistically = true
    catch(:remove_child_from_parent) {
      self.transaction do

        begin
          parent_rec = self.find_by_spin_node_hashkey_and_cont_location_and_session_id(parent_key, location, session_id)
          #    parent_rec = self.find_by_spin_node_hashkey pkey
          return false if parent_rec.blank?
          Rails.logger.warn(">> remove_child_from_parent : critical part start")
          if parent_rec[:children] == '' or parent_rec[:children].blank? or parent_rec[:children] == '[]'
            return true
            #      pchildren = []
            #      pchildren.push(SpinNode.get_id_from_key(child_rec[:spin_node_hashkey]))
            #      parent_rec[:children] = pchildren.to_json
          else
            pchildren = MultiJson.load(parent_rec[:children])
            cid = SpinNode.get_id_from_key(child_key)
            pchildren -= [cid]
            #      unless SetUtility::SetOp.is_in_set(cid, pchildren)
            #        pchildren.push(SpinNode.get_id_from_key(child_rec[:spin_node_hashkey]))
            #      end
            if pchildren.length == 0
              parent_rec[:children] = ''
            else
              parent_rec[:children] = pchildren.to_json
            end
          end
          parent_rec.save
        rescue ActiveRecord::StaleObjectError
          if retry_save > 0
            retry_save -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :remove_child_from_parent
          end
        rescue
          Rails.logger.warn(">> remove_child_from_parent : exception!")
          return false
        end
      end # => end of transaction
    }
    return true
  end

  # => end of self.add_child child_rec

  def self.add_child parent_rec, child_id
    return false if parent_rec.blank?
    retry_save = ACTIVE_RECORD_RETRY_COUNT

    ActiveRecord::Base.lock_optimistically = true
    catch(:add_child_again) {

      self.transaction do
        begin
          if parent_rec[:children] == ''
            pchildren = Array.new
            pchildren.push(child_id)
          else
            pchildren = MultiJson.load(parent_rec[:children])
            unless SetUtility::SetOp.is_in_set(child_id, pchildren)
              pchildren.push(child_id)
            end
          end
          parent_rec.update(children: MultiJson.dump(pchildren))
        rescue ActiveRecord::StaleObjectError
          if retry_save > 0
            retry_save -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :add_child_again
          end
        end
      end # => end of transaction
    }
    return true

  end

  # => end of self.add_child parent_rec, child_id

  def self.fill_folders ssid, location, domain_key = nil, partial_root_node = nil, process_request = PROCESS_FOR_UNIVERSAL_REQUEST, force_make_it = false, load_layers = 2, initial_load = false
    # get uid and gid
    my_uid = SessionManager.get_uid ssid
    # get current domain at the location
    session_rec = {}
    #    ActiveRecord::Base::lock_optimistically = false
    session_rec = SpinSession.readonly.find_by_spin_session_id ssid
    if session_rec.blank?
      return nil
    end
    #    logger.debug location
    #    logger.debug session_rec
    my_current_domain = String.new
    last_session = SessionManager.get_last_session ssid

    if domain_key.present?
      my_current_domain = domain_key
    else
      case location
      when 'folder_a'
        my_current_domain = session_rec[:selected_domain_a]
        #      when 'folder_b'
        #        my_current_domain = session_rec[:selected_domain_b]
      when 'folder_at'
        my_current_domain = session_rec[:selected_domain_a]
        #      when 'folder_bt'
        #        my_current_domain = session_rec[:selected_domain_b]
      when 'folder_atfi'
        my_current_domain = session_rec[:selected_domain_a]
        #      when 'folder_btfi'
        #        my_current_domain = session_rec[:selected_domain_b]
      else
        my_current_domain = session_rec[:selected_domain_a]
      end
    end
    rethash = Hash.new

    if my_current_domain.blank?
      return {:success => true, :status => true, :result => 0}
    end

    #    # clear is_partial_root flag if partial_root_node = nil
    #    if partial_root_node == nil
    #      prtrt = self.where(["is_partial_root = true"])
    #      #      if prtrt.length > 0
    #      prtrt.each {|proot|
    #        #        if proot[:is_partial_root]
    #        proot[:is_partial_root] = false
    #        proot.save
    #        #        end
    #      }
    #    end
    # search spin_folders and spin_access_control, and fill domain table
    folder_a_location = 'folder_a'
    retry_set_sid = ACTIVE_RECORD_RETRY_COUNT
    if location == folder_a_location
      last_session_recs = FolderDatum.readonly.select("id").where(session_id: last_session)
      if last_session_recs.count > 0
        catch(:fill_folders_set_sid_again) {
          FolderDatum.transaction do
            begin
              FolderDatum.where(session_id: last_session, cont_location: location, domain_hash_key: my_current_domain).update_all(session_id: ssid)
            rescue ActiveRecord::StaleObjectError
              if retry_set_sid > 0
                retry_set_sid -= 1
                throw :fill_folders_set_sid_again
              else
                return nil
              end
            end
          end
        }
      end
      rethash = self.fill_folder_data_table ssid, last_session, my_uid, location, my_current_domain, partial_root_node, process_request,
                                            force_make_it, load_layers, initial_load
    end
    # rethash = FolderDatum.where(session_id: ssid).order("spin_did")
    return rethash
  end

  # => end of fill_folders

  def self.get_children_ids spin_node_hashkey, node_type = ANY_TYPE
    tn = nil
    begin
      if node_type == ANY_TYPE
        tn = SpinNode.find_by_spin_node_hashkey(spin_node_hashkey)
      else
        tn = SpinNode.find_by_spin_node_hashkey_and_node_type(spin_node_hashkey, node_type)
      end
      if tn.blank?
        return []
      end
      x = tn[:node_x_coord]
      y = tn[:node_y_coord]
      cids = []
      cnodes = SpinNode.select("id").where(["node_x_pr_coord = ? AND node_y_coord = ?", x, y + 1])
      cnodes.each {|cn|
        if cn.present? and cn[:id].present?
          cids.push(cn[:id])
        end
      }
    rescue ActiveRecord::RecordNotFound
      printf("No spin node : %s\n", spin_node_hashkey)
    end

    return cids
  end

  # => end of self.get_children_ids

  def self.get_folder_display_data sid, cont_location
    #    sr = nil
    #    self.transaction do
    #      sr = SpinSession.readonly.find_by_spin_session_id sid
    #    end
    uid = SessionManager.get_uid(sid)
    target_domain_key = ''
    target_domain_root_folder = ''
    #    dom_a = sr[:selected_domain_a]
    #    dom_b = sr[:selected_domain_b]

    tree_nodes = Array.new

    current_domain_node = nil

    current_parent_key = nil

    current_partial_root = nil

    #    tses = SpinSession.find_by_spin_session_id sid
    case cont_location
    when 'folder_a', 'folder_at', 'folder_atfi', 'dlfolders'
      # td = DomainDatum.find_by_session_id_and_cont_location_and_selected sid, cont_location, true
      # => search selected domain hash key  first
      td = DomainDatum.find_by_session_id_and_cont_location_and_selected sid, 'folder_a', true
      if td.blank? # => if it isn't
        # => get default domain hash key for the session
        target_domain_key = DatabaseUtility::SessionUtility.get_default_domain(sid)
        if target_domain_key.blank?
          return tree_nodes
        end
      else
        # => or get domain hash key
        target_domain_key = td[:spin_domain_hash_key]
      end
      # => get spin_domains record from domain hash key
      current_domain_node = SpinDomain.find_by_hash_key target_domain_key
      if current_domain_node.blank?
        return []
      end
      # => get domain root node hash key
      # target_domain_root_folder = current_domain_node[:domain_root_node_hashkey]
    when 'folder_bt', 'folder_btfi'
      return []
      #    when 'folder_b','folder_bt','folder_btfi'
    when 'folder_b'
      td = DomainDatum.find_by_session_id_and_cont_location_and_selected sid, cont_location, true
      if td.blank?
        target_domain_key = DatabaseUtility::SessionUtility.get_default_domain(sid)
      else
        target_domain_key = td[:spin_domain_hash_key]
      end
      #      target_domain_key = td[:spin_domain_hash_key]
      #      target_domain_key = tses[:selected_domain_b]
      if target_domain_key.blank?
        target_domain_key = DatabaseUtility::SessionUtility.get_default_domain(sid)
        # target_domain_root_folder = SpinDomain.get_domain_root_node_key(target_domain_key)
      else
        #        tdwrk = DomainDatum.find_by_session_id_and_cont_location_and_hash_key sid, 'folder_b', target_domain_key
        #        if tdwrk == nil
        sd = SpinDomain.find_by_hash_key target_domain_key
        if sd.blank?
          return tree_nodes
        end
        target_domain_root_folder = sd[:domain_root_node_hashkey]
        #        else
        #          target_domain_selected_folder = tdwrk[:selected_folder_b]
        #        end
      end
    end

    # root_node_key = target_domain_root_folder
    root_node_key = String.new

    begin
      td = SpinDomain.find_by_hash_key target_domain_key
      if td.blank?
        return tree_nodes
      end
      root_node_key = td[:domain_root_node_hashkey]
    rescue ActiveRecord::RecordNotFound
      return tree_nodes
    end

    # Is it a partial view?
    #    partial_view = false
    self.transaction do
      if cont_location =~ /folder_[ab]/
        begin
          current_partial_root = self.find_by_session_id_and_domain_hash_key_and_cont_location_and_is_partial_root(sid, target_domain_key, cont_location, true)
          if current_partial_root.present?
            root_node_key = current_partial_root[:spin_node_hashkey]
          end
        rescue ActiveRecord::RecordNotFound
        end
      end

    end # => end of transaction

    current_parent_key = root_node_key
    unless SpinAccessControl.is_accessible_node(sid, current_parent_key, NODE_DIRECTORY)
      return tree_nodes # => empty array at this time!
    end

    current_parent = self.find_by_session_id_and_domain_hash_key_and_is_partial_root_and_cont_location(sid, target_domain_key, true, cont_location)
    # get domain_root_node_key
    target_domain_root_node_key = SpinDomain.get_domain_root_node_key(target_domain_key)

    # => make tree data    
    # tree_nodes = make_folder_tree sid, cont_location, nil, root_node_key, target_domain_key, (uid == 0 ? true : false)
    # if current_parent.present?
    #   tree_nodes.push current_parent
    # end
    tree_nodes = make_folder_tree sid, cont_location, current_parent, target_domain_key, (uid == 0 ? true : false)

    return tree_nodes

  end

  # => end of get_folder_display_data

  def self.make_folder_tree(sid, cont_location, tree_root_folder, target_domain_key, root_user_access = false)

    # initialize
    tree_nodes = Array.new
    skip_current = false

    # children_nodes is an array of integer.
    children_nodes = Array.new

    if tree_root_folder.present?
      skip_current = true
      if tree_root_folder['children'].present?
        children_nodes = MultiJson.load(tree_root_folder['children']) # They are ID's. ID = 1,2,3,4...N
      end
    else # =>  tree_root_folder == nil => tree_root == domain_root
      target_domain_root_node_key = SpinDomain.get_domain_root_node_key(target_domain_key)
      tree_root_folder = self.find_by_session_id_and_spin_node_hashkey(sid, target_domain_root_node_key)
      return tree_nodes if tree_root_folder.blank? # => SHOULD NOT HAPPEN.
      if tree_root_folder['children'].present?
        children_nodes = MultiJson.load(tree_root_folder['children']) # They are ID's. ID = 1,2,3,4...N
      end
    end

    hcurrent = Hash.new
    hchild = Hash.new

    csn = SpinNode.new
    cn = self.new

    flag_selected = false
    tree_root_folder.attributes.each {|key, value|
      if key == 'children'
        hcurrent['children'] = Array.new
        next
      end
      hcurrent[key] = value
    } # => copy tree_root_folder to hcurrent

    if children_nodes.blank?
      # => no children
      hcurrent['children'] = Array.new
      tree_nodes.push hcurrent
      return tree_nodes
    end

    children_nodes.each {|cnid|
      begin
        csn = SpinNode.select("spin_node_hashkey").find(cnid)
        if csn.blank?
          return tree_nodes
        end
      rescue ActiveRecord::RecordNotFound
        return tree_nodes
      end

      # => get child folder from node hashkey
      cn = self.find_by_session_id_and_cont_location_and_spin_node_hashkey(sid, cont_location, csn[:spin_node_hashkey])
      if cn.blank?
        next
      end

      unless skip_current
        if cn[:selected] == true
          hcurrent['expanded'] = true
          self.set_expand_folder(sid,cont_location,csn[:spin_node_hashkey],target_domain_key)
        end
        hcurrent['leaf'] = false
        # self.set_partial_root(sid, cont_location, csn[:spin_node_hashkey], target_domain_key)
        if hcurrent['children'].blank?
          hcurrent['children'] = make_folder_tree(sid, cont_location, cn, target_domain_key, root_user_access)
        else
          hcurrent['children'] += make_folder_tree(sid, cont_location, cn, target_domain_key, root_user_access)
        end
        # hcurrent['children'] += make_folder_tree(sid, cont_location, cn, target_domain_key, root_user_access)
        if hcurrent['file_size'].present?
          hcurrent['file_size'] = (hcurrent['file_size_upper'] * (MAX_INTEGER + 1)) + hcurrent['file_size']
          hcurrent['file_size_upper'] = 0
        end
      else # for each child
        c_children_nodes = Array.new
        hchild = Hash.new
        ccsn = SpinNode.new
        ccn = self.new
        flag_selected = false

        cn.attributes.each {|key, value|
          if key == 'children'
            hchild['children'] = Array.new
            next
          end
          hchild[key] = value
        } # => copy cn to hcurrent

        # children_nodes.push(SpinNode.get_id_from_key(tree_root_folder[:spin_node_hashkey]))
        if cn['children'].present?
          c_children_nodes = MultiJson.load(cn['children']) # They are ID's. ID = 1,2,3,4...N
        end

        c_children_nodes.each {|ccnid|
          begin
            ccsn = SpinNode.select("spin_node_hashkey").find(ccnid)
            if ccsn.blank?
              return tree_nodes
            end
          rescue ActiveRecord::RecordNotFound
            return tree_nodes
          end

          # => get child folder from node hashkey
          ccn = self.find_by_session_id_and_cont_location_and_spin_node_hashkey(sid, cont_location, ccsn[:spin_node_hashkey])

          if ccn.blank?
            next
          end

          if ccn[:selected] == true
            hchild['expanded'] = true
            self.set_expand_folder(sid, cont_location, ccsn[:spin_node_hashkey], target_domain_key)
          end
          hchild['leaf'] = false
          # self.set_partial_root(sid, cont_location, ccsn[:spin_node_hashkey], target_domain_key)
          if hchild['children'].blank?
            hchild['children'] = make_folder_tree(sid, cont_location, ccn, target_domain_key, root_user_access)
          else
            hchild['children'] += make_folder_tree(sid, cont_location, ccn, target_domain_key, root_user_access)
          end
          # hchild['children'] += make_folder_tree(sid, cont_location, cn, target_domain_key, root_user_access)
          if hchild['file_size'].present?
            hchild['file_size'] = (hchild['file_size_upper'] * (MAX_INTEGER + 1)) + hchild['file_size']
            hchild['file_size_upper'] = 0
          end
        }
        tree_nodes.push hchild
      end
    }
    #    end

    unless skip_current
      tree_nodes.push hcurrent
    end

    unless tree_nodes.blank?
      tree_nodes.sort! {|a, b| a['text'] <=> b['text']}
      # if tree_root_folder.blank?
      #   tree_nodes[0]['selected'] = true
      # end
    end

    return tree_nodes
  end

  def self.set_expand_folder sid, location, hkey, domain_key = nil
    rethash = {:success => false, :status => ERROR_NO_RECORD_FOUND, :result => "expand folder failed"}

    unless domain_key.present?
      domain_key = SessionManager.get_selected_domain(sid, location)
    end

    retry_save = ACTIVE_RECORD_RETRY_COUNT

    ActiveRecord::Base.lock_optimistically = true
    catch(:set_expand_folder_again) {

      self.transaction do

        begin

          fd = nil
          dirty_flag = DomainDatum.is_dirty_domain(sid, location, domain_key)
          fd = self.find_by(session_id: sid, spin_node_hashkey: hkey, cont_location: location, domain_hash_key: domain_key)
          # Is there dirty parents?
          #        dpcan = self.select("id").where(["session_id = ? AND cont_location = ? AND domain_hash_key = ? AND py < ? AND is_dirty = true",sid,location,domain_key,fd[:py]])
          #        if dpcan.length > 0
          #          dirty_flag = true
          #        end
          pkey = SpinLocationManager.get_parent_key(fd[:spin_node_hashkey], NODE_DIRECTORY)
          if fd.present?
            if dirty_flag
              # self.reset_partial_root(sid, location, domain_key)
              rethash = {:success => true, :status => STAT_DATA_NOT_LOADED_YET, :isDirty => true, :result => true}
              self.fill_folders(sid, location, domain_key)
              self.select_folder(sid, hkey, location, domain_key)
              self.set_partial_root(sid, location, pkey, domain_key)
            elsif fd[:expanded].present? && fd[:expanded] || fd[:expand_counter] > 0
              rethash = {:success => true, :status => STAT_DATA_ALREADY_LOADED, :isDirty => false, :result => true}
              self.select_folder(sid, hkey, location, domain_key)
              # clear and set is_partial_root flag
              #              self.reset_partial_root(sid, location, domain_key)
              self.set_partial_root(sid, location, pkey, domain_key)
            elsif fd[:is_dirty] or fd[:is_new]
              rethash = {:success => true, :status => STAT_DATA_NOT_LOADED_YET, :isDirty => false, :result => true}
              # self.load_folder_recs(sid, hkey, domain_key, fd[:parent_hash_key], location, DEPTH_TO_TRAVERSE, SessionManager.get_last_session(sid))
              self.fill_folders(sid, location, domain_key, hkey)
              self.select_folder(sid, hkey, location, domain_key)
              self.set_partial_root(sid, location, pkey, domain_key)
              # clear and set is_partial_root flag
              #              self.reset_partial_root(sid, location, domain_key)
            end # => end of if dirty_flag
            #          rethash = {:success => false, :status => ERROR_FAILED_TO_SAVE_EXPANDED, :result => "expand folder failed" }
          else # fd isn't present.
            pfd = self.get_parent_folder(sid, hkey)
            if dirty_flag # domain is dirty
              self.reset_partial_root(sid, location, domain_key)
              rethash = {:success => true, :status => STAT_DATA_NOT_LOADED_YET, :isDirty => true, :result => true}
              self.fill_folders(sid, location, domain_key)
              self.select_folder(sid, hkey, location, domain_key)
            else
              rethash = {:success => true, :status => STAT_DATA_NOT_LOADED_YET, :isDirty => false, :result => true}
              self.load_folder_recs(sid, hkey, domain_key, pfd[:spin_node_hashkey], location, DEPTH_TO_TRAVERSE, SessionManager.get_last_session(sid))
              self.fill_folders(sid, location, domain_key, pfd[:spin_node_hashkey])
              self.select_folder(sid, hkey, location, domain_key)
              self.set_partial_root(sid, location, pfd[:parent_hash_key], domain_key)
            end
          end
        rescue ActiveRecord::StaleObjectError
          if retry_save > 0
            retry_save -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :set_expand_folder_again
          end
        end
      end # => end of transaction
    }

    self.set_expanded(sid, location, hkey, domain_key)

    DatabaseUtility::SessionUtility.set_current_folder(sid, hkey, location, domain_key).blank?

    return rethash
  end

  # => end of set_expand_folder

  def self.set_partial_root sid, cont_location, partial_root_key, domain_hash_key = nil
    ret = true
    unless domain_hash_key.present?
      domain_hash_key = SessionManager.get_selected_domain(sid, cont_location)
    end

    ActiveRecord::Base.lock_optimistically = true

    retry_set_partial_root = ACTIVE_RECORD_RETRY_COUNT
    catch(:set_partial_root_again) {

      self.transaction do

        begin
          proot = self.find_by_spin_node_hashkey_and_session_id_and_cont_location(partial_root_key, sid, cont_location)
          if proot.blank?
            return false
          end
          #          ActiveRecord::Base.lock_optimistically = false
          #          xcount = proot[:expand_counter]
          FolderDatum.where(session_id: sid, cont_location: cont_location).update_all(is_partial_root: false)
          FolderDatum.where(spin_node_hashkey: partial_root_key, session_id: sid, cont_location: cont_location).update_all(is_partial_root: true)
            #          proot.update(is_partial_root: true, is_partial_view: false)
            #          proot[:is_partial_root] = true
            #          proot[:is_partial_view] = false
            #          proot[:expanded] = true
            #          proot[:expand_counter] = xcount + 1
            #          ret = proot.save
            #          ActiveRecord::Base.lock_optimistically = true
        rescue ActiveRecord::StaleObjectError
          if retry_set_partial_root > 0
            retry_set_partial_root -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :set_partial_root_again
          else
            throw ActiveRecord::StaleObjectError
          end
        end

      end # => end of transaction
    }

    return ret
  end

  # => end of self.set_partial_root partial_root_key

  def self.reset_partial_root sid, cont_location, domain_hash_key = nil

    unless domain_hash_key.present?
      domain_hash_key = SessionManager.get_selected_domain(sid, cont_location)
      return nil
    end

    ActiveRecord::Base.lock_optimistically = true

    retry_reset = ACTIVE_RECORD_RETRY_COUNT
    ActiveRecord::Base.lock_optimistically = true
    catch(:reset_partial_root_again) {

      self.transaction do
        begin
          # clear is_partial_root flag
          #          ActiveRecord::Base.lock_optimistically = false
          FolderDatum.where(["session_id = ? AND cont_location = ? And domain_hash_key = ?", sid, cont_location, domain_hash_key]).update_all(is_partial_root: false)
            # prts.each {|prt|
            #
            #   prt[:is_partial_root] = false
            #   prt.save
            # }
            # ActiveRecord::Base.lock_optimistically = true

        rescue ActiveRecord::StaleObjectError
          if retry_reset > 0
            retry_reset -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :reset_partial_root_again
          else
            throw ActiveRecord::StaleObjectError
          end
        end

      end # => end of transaction
    } # => end of catch block
    return domain_hash_key
  end

  # => end of self.reset_partial_root(my_session_id,paramshash[:cont_location], paramshash[:domain_hash_key])

  def self.set_expanded sid, location, hkey, domain_key

    retry_save = ACTIVE_RECORD_RETRY_COUNT

    catch(:set_expanded_again) {

      self.transaction do

        begin
          xnode = self.find_by_session_id_and_cont_location_and_spin_node_hashkey_and_domain_hash_key sid, location, hkey, domain_key
          if xnode.present?
            #            xnode[:expanded] = true
            #            xnode[:is_dirty] = false
            xc = xnode[:expand_counter]
            #            xnode[:expand_counter] = xc + 1
            #            xnode.save
            recs = FolderDatum.where(session_id: sid, spin_node_hashkey: hkey, cont_location: location, domain_hash_key: domain_key).update_all(expanded: true, is_dirty: false, expand_counter: xc + 1)
            unless recs > 0
              return nil
            end
          else
            return nil
          end
        rescue ActiveRecord::StaleObjectError
          if retry_save > 0
            retry_save -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :set_expanded_again
          end
        end
      end # => end of transaction
    } # => end of catch block
  end

  # => end of self.set_expanded sid, location, hkey

  def self.setup_expand_counter sid
    ActiveRecord::Base::lock_optimistically = true
    count = 0
    retry_save = ACTIVE_RECORD_RETRY_COUNT
    catch(:setup_expand_counter_again) {
      self.transaction do
        begin
          nrecs = self.where(["session_id = ? AND expanded = true", sid]).update_all(expand_counter: 1)
          count += nrecs
            # recs.each { |rec|
            #   ec = 0
            #   if rec[:expanded]
            #     rec[:expand_counter] = 1
            #   end
            #   rec.update(expand_counter: ec)
            #   count += 1
            # }
        rescue ActiveRecord::StaleObjectError
          if retry_save > 0
            retry_save -= 1
            throw :setup_expand_counter_again
            elseƒmeke_tr
            throw ActiveRecord::StaleObjectError
          end
        end
      end
    }
    return count
  end

  # => end of self.clear_expand_count sid

  def self.set_collapse_folder sid, location, hkey, domain_key
    retry_save = ACTIVE_RECORD_RETRY_COUNT
    ActiveRecord::Base.lock_optimistically = true
    # fd = nil
    ActiveRecord::Base.lock_optimistically = true
    catch(:set_collapse_folder_again) {

      self.transaction do

        begin
          xnode = self.find_by_session_id_and_cont_location_and_spin_node_hashkey_and_domain_hash_key sid, location, hkey, domain_key
          if xnode.present?
            FolderDatum.where(session_id: sid, spin_node_hashkey: hkey, cont_location: location, domain_hash_key: domain_key).update_all(expanded: false, is_dirty: false, expand_counter: 0)
          else
            return {:success => false, :status => ERROR_FAILED_TO_COLLAPSE_FOLDER, :result => "collapse folder failed"}
          end
            #          fd = self.find_by_session_id_and_spin_node_hashkey_and_cont_location_and_domain_hash_key sid, hkey, location, domain_key
            #          if fd.present?
            #            fd[:expanded] = false
            #            xc = fd[:expand_counter]
            #            fd[:expand_counter] = xc - 1
            #            #      SpinNode.set_expanded hkey, false
            #            fd.save
            #          else
            #            return {:success => false, :status => ERROR_FAILED_TO_COLLAPSE_FOLDER, :result => "collapse folder failed" }
            #          end
        rescue ActiveRecord::StaleObjectError
          if retry_save > 0
            retry_save -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :set_collapse_folder_again
          else
            return {:success => false, :status => ERROR_FAILED_TO_COLLAPSE_FOLDER, :result => "collapse folder failed"}
          end
        end
        #    end

      end # => end of transction
    } # => end of catch block
    return {:success => true, :status => INFO_COLLAPSE_FOLDER_SUCCESS, :result => 0}

  end

  # => end of set_expand_folder

  def self.select_folder sid, folder_key, location, domain_key = nil
    if domain_key.blank?
      domain_key = SessionManager.get_selected_domain(sid, location)
    end

    recs = 0
    FolderDatum.transaction do
      recs = FolderDatum.where(session_id: sid, cont_location: 'folder_a', domain_hash_key: domain_key).update_all(selected: false)
    end

    retry_select_folder_loaded = ACTIVE_RECORD_RETRY_COUNT

    catch(:select_folder_loaded_again) {

      FolderDatum.transaction do
        begin

          if recs > 0
            urecs = FolderDatum.where(spin_node_hashkey: folder_key, session_id: sid, cont_location: 'folder_a', domain_hash_key: domain_key).update_all(selected: true)
            if urecs != 1
              FileManager.rails_logger("#{urecs} records are set as \"true\"")
            end
          else # => node is not loaded yet
            if folder_key.blank?
              folder_key = self.get_first_folder_of_domain(sid, domain_key, location)
            end
            if folder_key == SpinDomain.get_domain_root_node_key(domain_key) # => may be called by mobile request broker
              parent_key = folder_key
              folder_key = self.get_first_folder_of_domain(sid, domain_key, location)
              if folder_key.blank?
                folder_key = parent_key
              end
              # parent_key = self.get_parent_folder(sid, folder_key)
            else
              parent_key = self.get_parent_folder(sid, folder_key)
              if parent_key.blank?
                return false
              end
            end # => end of if folder_key == SpinDomain.get_domain_root_node_key(domain_key)
            if self.load_folder_recs(sid, folder_key, domain_key, parent_key, location, DEPTH_TO_TRAVERSE, SessionManager.get_last_session(sid)) > 0
              #              ActiveRecord::Base.lock_optimistically = false
              recs = FolderDatum.where(spin_node_hashkey: folder_key, session_id: sid, cont_location: 'folder_a', domain_hash_key: domain_key).update_all(selected: true)
              unless recs == 1
                return false
              end
              #              fol_to_be_selected = self.find_by_session_id_and_cont_location_and_spin_node_hashkey_and_domain_hash_key sid, location, folder_key, domain_key
              #              return false if fol_to_be_selected.blank?
              #              self.unset_folder_selected(sid, location, domain_key)
              #              fol_to_be_selected.update(selected: true )  # => set selected
              #              ActiveRecord::Base.lock_optimistically = true
            end
          end
        rescue ActiveRecord::StaleObjectError
          retry_select_folder_loaded -= 1
          if retry_select_folder_loaded > 0
            sleep(AR_RETRY_WAIT_MSEC)
            throw :select_folder_loaded_again
          else
            throw ActiveRecord::StaleObjectError
          end
        end
      end
    } # => end of catch block
    DomainDatum.set_selected_folder(sid, domain_key, folder_key, location)
    if DatabaseUtility::SessionUtility.set_current_folder(sid, folder_key, location, domain_key).blank?
      return false
    end
    return true
  end

  # => end of set_current_folder

  def self.load_folder_recs sid, folder_key, domain_key, parent_node_hashkey = nil, cont_location = '', plus_generations = 3, last_ssid = nil
    # get children in plus_generations
    #    fols = self.where :session_id => sid, :spin_node_hashkey => folder_key, :domain_hash_key => domain_key
    #    number_of_folders_to_load = 0
    #    locations = CONT_LOCATIONS_LIST
    new_key = nil
    root_user_access = false
    my_uid = SessionManager.get_uid(sid, true)
    if my_uid == 0
      root_user_access = true
    end

    # Is there a folder record already?
    is_dirty = false
    frec = nil
    #    ActiveRecord::Base::lock_optimistically = false

    retry_save = ACTIVE_RECORD_RETRY_COUNT
    location = cont_location
    accessible_children = []
    loaded_recs = 0

    ActiveRecord::Base.lock_optimistically = true
    catch(:load_folder_rec_again) {

      self.transaction do

        begin

          frec = self.find_by(session_id: sid, cont_location: cont_location, spin_node_hashkey: folder_key, domain_hash_key: domain_key)
          if frec.present? # => Use it.
            new_key = frec[:hash_key]
            is_dirty = frec[:is_dirty]
            FolderDatum.where(session_id: sid, cont_location: cont_location, parent_hash_key: folder_key, domain_hash_key: domain_key).update_all(is_dirty: false, leaf: false)
            #            frec.update(is_dirty: false, expand_counter: 0)
            #            frec[:is_dirty] = false
            #            frec[:expand_counter] = 0
            #            #      frec[:expanded] = false
            #            frec.save
            loaded_recs += 1
            if is_dirty == true
              #      frec.destroy
              # frec = self.find_by_session_id_and_cont_location_and_spin_node_hashkey_and_domain_hash_key(sid, cont_location, frec_node_key, domain_key)
              new_key = self.update_folder_rec(sid, location, frec, domain_key, -1, nil, nil, root_user_access)
              if new_key.present?
                self.has_updated(sid, folder_key, NEW_CHILD, false)
                #        self.add_child_to_parent(new_rec)
              else
                return 0
              end
            end
          else
            frec_node_key = nil
            frec_node_key = self.create_new_folder_rec(sid, location, folder_key, parent_node_hashkey, domain_key, -1, nil, nil, root_user_access, last_ssid)
            if frec_node_key.blank?
              return 0
            end
            frec = self.find_by_session_id_and_cont_location_and_spin_node_hashkey_and_domain_hash_key(sid, cont_location, frec_node_key, domain_key)
          end
        rescue ActiveRecord::StaleObjectError
          if retry_save > 0
            retry_save -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :load_folder_rec_again
          else
            return 0
          end
        end
      end # => end of transaction
    } # => end of catch block

    if frec.blank?
      return 0
    end

    if plus_generations > 0 or frec[:expanded]
      accessible_children = SpinNode.get_active_children(sid, folder_key, NODE_DIRECTORY)

      accessible_children.each {|ach|
        child_frec = self.find_by_session_id_and_cont_location_and_spin_node_hashkey_and_domain_hash_key(sid, cont_location, ach['spin_node_hashkey'], domain_key)
        rrecs = 0
        if child_frec.blank?
          new_child_key = self.create_new_folder_rec(sid, location, ach['spin_node_hashkey'], folder_key, domain_key, -1, nil, nil, root_user_access, last_ssid)
        end
        if new_child_key.present?
          if frec[:expanded]
            plus_generations = DEPTH_TO_TRAVERSE
          end
          self.add_child_to_parent(new_child_key, folder_key, sid)
          plus_generations_sub = plus_generations - 1
          rrecs = self.load_folder_recs(sid, ach['spin_node_hashkey'], domain_key, folder_key, location, plus_generations_sub, last_ssid)
          loaded_recs += rrecs
        end
      }
    end

    #    end
    return loaded_recs
  end

  # => end of self.load_folder_recs sid, folder_key, location

  def self.copy_folder_data_from_location_to_location sid, source_location, copy_location, domain_key = nil

    if true
      return {:success => true, :status => true, :result => 0}
    end
    ## get source recs

    #    ActiveRecord::Base::lock_optimistically = false

    if domain_key.blank?
      srecs = self.readonly.where(["session_id = ? AND cont_location = ?", sid, source_location])
    else
      srecs = self.readonly.where(["session_id = ? AND cont_location = ? AND domain_hash_key = ?", sid, source_location, domain_key])
    end

    copied_records = 0

    # clear data at copy_location
    self.transaction do
      if domain_key.blank?
        #        crecs = self.where(["session_id = ? AND cont_location = ?",sid,copy_location])
        delquery = sprintf("DELETE FROM folder_data WHERE session_id = \'%s\' AND cont_location = \'%s\';", sid, copy_location)
        self.find_by_sql(delquery)
      else
        #        crecs = self.where(["session_id = ? AND cont_location = ? AND domain_hash_key = ?",sid,copy_location,domain_key])
        delquery = sprintf("DELETE FROM folder_data WHERE session_id = \'%s\' AND cont_location = \'%s\' AND domain_hash_key =\'%s\';", sid, copy_location, domain_key)
        self.find_by_sql(delquery)
      end

      #      crecs.each {|delrec|
      #        delrec.destroy
      #      }

      #    end # => end of trransaction

      # copy recs
      srecs.each {|src|
        new_rec = self.new
        src.attributes.each {|key, value|
          next if key == 'id'
          next if key == 'hash_key'
          next if key == 'cont_location'
          new_rec[key] = value
        } # => end of src.attributes.each {|key,value|
        r = Random.new
        new_hash_key = Security.hash_key_s(src[:spin_node_hashkey] + copy_location + src[:domain_hash_key] + r.rand.to_s)
        new_rec[:hash_key] = new_hash_key
        new_rec[:cont_location] = copy_location
        if new_rec.save
          copied_records += 1
        end
      } # => end of srecs.each {|src|

    end # => end of transaction

    return {:success => true, :status => true, :result => copied_records}
    #    return copied_records
  end

  # => end of self.copy_folder_data_from_location_to_location sid, source_location, copy_location, domain_key = nil

  def self.create_new_folder_rec ssid, location, folder_hash_key, parent_node_key, domain_hash_key, root_y = -1, current_root_node = nil, partial_view = nil, root_user_access = false, last_ssid = nil

    #    ActiveRecord::Base::lock_optimistically = false

    empty_key = nil
    new_folder_node_key = nil
    acls = {:user => ACL_NODE_NO_ACCESS, :group => ACL_NODE_NO_ACCESS, :world => ACL_NODE_NO_ACCESS}
    acls_p = {:user => ACL_NODE_NO_ACCESS, :group => ACL_NODE_NO_ACCESS, :world => ACL_NODE_NO_ACCESS}
    r = Random.new
    current_domain_data = nil
    case location
    when 'folder_a', 'folder_at', 'folder_atfi'
      current_domain_data = DomainDatum.find_by_spin_domain_hash_key_and_cont_location domain_hash_key, 'folder_a'
    when 'folder_b', 'folder_bt', 'folder_btfi'
      current_domain_data = DomainDatum.find_by_spin_domain_hash_key_and_cont_location domain_hash_key, 'folder_b'
    end
    if current_domain_data.blank?
      return empty_key
    end
    my_uid = SessionManager.get_uid(ssid)
    tn = SpinNode.find_by(spin_node_hashkey: folder_hash_key)
    if tn.blank?
      return empty_key
    end

    # => get parent folder
    pkey = nil
    if parent_node_key.present? # => parent is not the domain root node
      # => get parent folder record
      pkey = parent_node_key
    end

    new_hash_key = Security.hash_key_s(tn[:spin_node_hashkey] + location + current_domain_data[:id].to_s + r.rand.to_s)

    retry_create_new = ACTIVE_RECORD_RETRY_COUNT

    catch(:create_new_folder_rec_again) {
      self.transaction do

        begin
          # => get folder record from the last session
          new_folder_datum = FolderDatum.find_or_create_by(session_id: last_ssid, cont_location: location, spin_node_hashkey: tn[:spin_node_hashkey], domain_hash_key: domain_hash_key) {|nf|
            nf[:hash_key] = new_hash_key
            nf[:target_hash_key] = new_hash_key
            nf[:expand_counter] = 0
            nf[:session_id] = ssid
            nf[:capacity] = -1
            #    children = self.get_children_ids(tn[:spin_node_hashkey],NODE_DIRECTORY)
            #    if children and children.blank? == false
            #      nf[:children] = children.to_json
            #    else
            nf[:children] = ''
            #    end
            nf[:cls] = "folder"
            nf[:cont_location] = location
            nf[:target_cont_location] = location
            if pkey.blank?
              pn = SpinLocationManager.get_parent_node(tn)
              pkey = pn[:spin_node_hashkey]
            end
            nf[:parent_hash_key] = pkey
            #    pkey = SpinLocationManager.get_parent_key(tn[:spin_node_hashkey],NODE_DIRECTORY)
            if root_user_access
              nf[:control_right] = true
              nf[:folder_readable_status] = true
              nf[:folder_writable_status] = true
              nf[:target_folder_readable_status] = true
              nf[:target_folder_writable_status] = true
              nf[:other_readable] = false
              nf[:other_writable] = false
              nf[:parent_readable_status] = true
              nf[:parent_writable_status] = true
              nf[:target_parent_readable_status] = true
              nf[:target_parent_writable_status] = true
              #      pkey = SpinLocationManager.get_parent_key(tn[:spin_node_hashkey],NODE_DIRECTORY)
            else
              acls = SpinAccessControl.has_acl_values(ssid, tn[:spin_node_hashkey], NODE_DIRECTORY)
              nf[:folder_readable_status] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_READ) != 0 ? true : false)
              nf[:folder_writable_status] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_WRITE) != 0 ? true : false)
              nf[:target_folder_readable_status] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_READ) != 0 ? true : false)
              nf[:target_folder_writable_status] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_WRITE) != 0 ? true : false)
              nf[:control_right] = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_CONTROL) != 0 ? true : false)
              nf[:other_readable] = ((acls[:world] & ACL_NODE_READ) != 0 ? true : false)
              nf[:other_writable] = ((acls[:world] & ACL_NODE_WRITE) != 0 ? true : false)
              acls_p = SpinAccessControl.has_acl_values(ssid, pkey, NODE_DIRECTORY)
              nf[:parent_readable_status] = (((acls_p[:user] | acls_p[:group] | acls_p[:world]) & ACL_NODE_READ) != 0 ? true : false)
              nf[:parent_writable_status] = (((acls_p[:user] | acls_p[:group] | acls_p[:world]) & ACL_NODE_WRITE) != 0 ? true : false)
              nf[:target_parent_readable_status] = (((acls_p[:user] | acls_p[:group] | acls_p[:world]) & ACL_NODE_READ) != 0 ? true : false)
              nf[:target_parent_writable_status] = (((acls_p[:user] | acls_p[:group] | acls_p[:world]) & ACL_NODE_WRITE) != 0 ? true : false)
            end
            nf[:vpath] = tn[:virtual_path]
            nf[:created_date] = tn[:created_at]
            nf[:creator] = SpinUserAttribute.get_user_name(tn[:spin_uid])
            nf[:expanded] = false
            nf[:fileNumber] = -1
            nf[:folder_name] = tn[:node_name]
            nf[:img] = "file_type_icon/FolderDocument.png"
            nf[:leaf] = false
            nf[:owner] = SpinUserAttribute.get_user_name(tn[:spin_uid])
            nf[:ownership] = ((tn[:spin_uid] == my_uid) ? "me" : "other")
            nf[:target_ownership] = ((tn[:spin_uid] == my_uid) ? "me" : "other")
            nf[:spin_node_hashkey] = tn[:spin_node_hashkey]
            new_folder_node_key = tn[:spin_node_hashkey]
            nf[:target_folder] = tn[:spin_node_hashkey]
            nf[:domain_hash_key] = domain_hash_key
            nf[:parent_hash_key] = pkey
            nf[:restSpace] = -1
            nf[:subFolders] = -1
            nf[:text] = tn[:node_name]
            nf[:updated_date] = tn[:updated_at]
            nf[:updater] = SpinUserAttribute.get_user_name(tn[:updated_by])
            nf[:usedRate] = -1
            nf[:usedSpace] = -1
            nf[:workingFolder] = SpinUser.get_working_directory(my_uid)
            nf[:px] = tn[:node_x_coord]
            nf[:py] = tn[:node_y_coord]
            nf[:ppx] = tn[:node_x_pr_coord]
            if tn[:node_y_coord] == root_y
              nf[:is_domain_root] = true
            else
              nf[:is_domain_root] = false
            end
            if root_y >= 0
              nf[:is_partial_view] = ((tn[:node_y_coord] > root_y or tn[:spin_node_hashkey] == current_root_node) ? partial_view : false)
            else
              nf[:is_partial_view] = false
            end
            nf[:updated_at] = tn[:updated_at]
            nf[:spin_updated_at] = tn[:spin_updated_at]
            nf[:spin_created_at] = tn[:spin_created_at]
            nf[:selected] = SessionManager.is_selected_folder(ssid, tn[:spin_node_hashkey], location)
          }
          if new_folder_datum.present? and new_folder_datum[:session_id] == last_ssid
            FolderDatum.where(session_id: last_ssid, cont_location: location, spin_node_hashkey: tn[:spin_node_hashkey], domain_hash_key: domain_hash_key).update_all(session_id: ssid, is_partial_root: false)
          end
        rescue ActiveRecord::StaleObjectError
          retry_create_new -= 1
          if retry_create_new < 0
            return empty_key
          end
          sleep(AR_RETRY_WAIT_MSEC)
          throw :create_new_folder_rec_again
        end # => end of begin-rescue block
      end # => end of transaction
    }
    return new_folder_node_key
  end

  # => end of self.create_new_folder_rec ssid, location, folder_hash_key, domain_hash_key

  def self.update_folder_rec ssid, location, folder_rec, domain_hash_key, root_y = -1, current_root_node = nil, partial_view = nil, root_user_access = false, initial_load = false
    empty_key = ''
    acls = {:user => ACL_NODE_NO_ACCESS, :group => ACL_NODE_NO_ACCESS, :world => ACL_NODE_NO_ACCESS}
    acls_p = {:user => ACL_NODE_NO_ACCESS, :group => ACL_NODE_NO_ACCESS, :world => ACL_NODE_NO_ACCESS}
    my_uid = SessionManager.get_uid(ssid)

    tn = SpinNode.find_by(spin_node_hashkey: folder_rec[:spin_node_hashkey])
    if tn.blank?
      return empty_key
    end

    retry_save = ACTIVE_RECORD_RETRY_COUNT

    catch(:update_folder_rec_update_again) {

      self.transaction do

        begin

          # determine variables value
          v_expand_counter = 0 # => reset counter
          if initial_load
            v_expand_counter = folder_rec[:expanded] ? 1 : 0
          else
            v_expand_counter = folder_rec[:expanded] ? folder_rec[:expand_counter] + 1 : 0
          end
          # Is there a new child?
          v_notify_new_child = 0
          if folder_rec[:notify_new_child] == 1
            v_notify_new_child = 0
          end
          v_control_right = true
          v_folder_readable_status = true
          v_folder_writable_status = true
          v_target_folder_readable_status = true
          v_target_folder_writable_status = true
          v_other_readable = false
          v_other_writable = false
          v_parent_readable_status = true
          v_parent_writable_status = true
          v_target_parent_readable_status = true
          v_target_parent_writable_status = true
          v_control_right = SpinAccessControl.is_controlable(ssid, tn[:spin_node_hashkey])
          v_creator = SpinUserAttribute.get_user_name (tn[:spin_uid])
          v_owner = SpinUserAttribute.get_user_name(tn[:spin_uid])
          v_updater = SpinUserAttribute.get_user_name(tn[:updated_by])
          v_workingFolder = SpinUser.get_working_directory(my_uid)

          unless root_user_access
            acls = SpinAccessControl.has_acl_values(ssid, tn[:spin_node_hashkey], NODE_DIRECTORY)
            v_folder_readable_status = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_READ) != 0 ? true : false)
            v_folder_writable_status = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_WRITE) != 0 ? true : false)
            v_target_folder_readable_status = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_READ) != 0 ? true : false)
            v_target_folder_writable_status = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_WRITE) != 0 ? true : false)
            v_control_right = (((acls[:user] | acls[:group] | acls[:world]) & ACL_NODE_CONTROL) != 0 ? true : false)
            v_other_readable = ((acls[:world] & ACL_NODE_READ) != 0 ? true : false)
            v_other_writable = ((acls[:world] & ACL_NODE_WRITE) != 0 ? true : false)
            pn = SpinLocationManager.get_parent_node(tn)
            pkey = pn[:spin_node_hashkey]
            acls_p = SpinAccessControl.has_acl_values(ssid, pkey, NODE_DIRECTORY)
            v_parent_readable_status = (((acls_p[:user] | acls_p[:group] | acls_p[:world]) & ACL_NODE_READ) != 0 ? true : false)
            v_parent_writable_status = (((acls_p[:user] | acls_p[:group] | acls_p[:world]) & ACL_NODE_WRITE) != 0 ? true : false)
            v_target_parent_readable_status = (((acls_p[:user] | acls_p[:group] | acls_p[:world]) & ACL_NODE_READ) != 0 ? true : false)
            v_target_parent_writable_status = (((acls_p[:user] | acls_p[:group] | acls_p[:world]) & ACL_NODE_WRITE) != 0 ? true : false)
          end

          folder_rec.update(
              capacity: -1,
              cls: "folder",
              cont_location: location,
              target_cont_location: location,
              creator: v_creator,
              fileNumber: -1,
              folder_name: tn[:node_name],
              text: tn[:node_name],
              img: "file_type_icon/FolderDocument.png",
              leaf: false,
              owner: v_owner,
              control_right: v_control_right,
              folder_readable_status: v_folder_readable_status,
              folder_writable_status: v_folder_writable_status,
              target_folder_readable_status: v_target_folder_readable_status,
              target_folder_writable_status: v_target_folder_writable_status,
              other_readable: v_other_readable,
              other_writable: v_other_writable,
              parent_readable_status: v_parent_readable_status,
              parent_writable_status: v_parent_writable_status,
              target_parent_readable_status: v_target_parent_readable_status,
              target_parent_writable_status: v_target_parent_writable_status,
              ownership: (tn[:spin_uid] == my_uid) ? "me" : "other",
              target_ownership: (tn[:spin_uid] == my_uid) ? "me" : "other",
              spin_node_hashkey: tn[:spin_node_hashkey],
              target_folder: tn[:spin_node_hashkey],
              domain_hash_key: domain_hash_key,
              restSpace: -1,
              subFolders: -1,
              updater: v_updater,
              usedRate: -1,
              usedSpace: -1,
              workingFolder: v_workingFolder,
              is_partial_view: (tn[:node_y_coord] > root_y ? partial_view : false),
              is_domain_root: (tn[:node_y_coord] == root_y ? true : false),
              updated_at: tn[:updated_at],
              spin_updated_at: tn[:spin_updated_at],
              spin_created_at: tn[:spin_created_at]
          )
        rescue ActiveRecord::StaleObjectError
          if retry_save > 0
            retry_save -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :update_folder_rec_update_again
          end
          throw ActiveRecord::StaleObjectError
        end
      end # => end of transaction
    }
    return folder_rec[:hash_key]

  end

  # => end of self.create_new_folder_rec ssid, location, folder_hash_key, domain_hash_key

  def self.add_folder_rec sid, folder_key, domain_key, cont_location = '', last_ssid = nil
    # get children in plus_generations
    #    fols = self.where :session_id => sid, :spin_node_hashkey => folder_key, :domain_hash_key => domain_key
    #    number_of_folders_to_load = 0
    locations = CONT_LOCATIONS_LIST
    root_user_access = false
    if SessionManager.get_uid(sid) == 0
      root_user_access = true
    end
    #
    #    fols.each { |fol|
    #      next if fol[:expanded] != true and plus_generations <= 0
    #      number_of_folders_to_load += 1
    #    }
    #    if number_of_folders_to_load == 0
    #      return 0
    #    end

    if cont_location.blank?
      #      locations.each { |location|
      #        if location == locations[0]
      location = locations[0]
      new_key = self.create_new_folder_rec(sid, location, folder_key, domain_key, -1, nil, nil, root_user_access, last_ssid)
    else
      new_key = self.create_new_folder_rec(sid, cont_location, folder_key, domain_key, -1, nil, nil, root_user_access, last_ssid)

      #      self.has_updated_to_parent(sid, folder_key, NEW_CHILD, false)

      #      locations -= [ cont_location ]
      #      locations.each { |location|
      #        next if location == cont_location
      #        reth = self.copy_folder_data_from_location_to_location sid, cont_location, location, domain_key
      #      }
    end
    if new_key.blank?
      return false
    else
      self.add_child_to_parent(new_key, folder_key, sid)
      return true
    end
  end

  # => self.add_folder_rec sid, folder_key, location

  def self.get_domain sid, fhk, location
    # returns domain hash_key it belongs to
    # fhk : hash key of the folder
    target_domain = nil
    doms = SpinNode.get_domains(fhk)
    ids = SessionManager.get_uid_gid(sid, false)
    gids = ids[:gids]
    #    gids += SpinGroupMember.get_parent_gids ids[:gid]
    adoms = SpinDomain.search_accessible_domains(ids[:uid], gids)
    td = SpinSession.readonly.find_by(spin_session_id: sid)
    doms.each {|dom|
      td = nil
      case location
      when 'folder_a', 'folder_at', 'folder_atfi'
        if td.blank?
          pp 'td nil'
          adoms.each {|ad|
            if ad[:hash_key] == dom
              target_domain = dom
              return target_domain
            end
          }
          break if target_domain.present?
        else
          if td[:selected_domain_a] == dom
            target_domain = td[:selected_domain_a]
            return target_domain
          end
        end
      when 'folder_b', 'folder_bt', 'folder_btfi'
        #        td = SpinSession.find_by_spin_session_id_and_selected_folder_b sid, fhk
        if td.blank?
          pp 'td nil'
          adoms.each {|ad|
            if ad[:hash_key] == dom
              target_domain = dom
              return target_domain
            end
          }
        else
          if td[:selected_domain_b] == dom
            target_domain = td[:selected_domain_b]
            return target_domain
          end
        end
      else
        if td.blank?
          pp 'td nil'
          adoms.each {|ad|
            if ad[:hash_key] == dom
              target_domain = dom
              return target_domain
            end
          }
        else
          if td[:selected_domain_a] == dom
            target_domain = td[:selected_domain_a]
            return target_domain
          end
        end
      end
    }
    return target_domain
  end

  # => end of get_domain

  def self.get_first_folder_of_domain sid, target_domain, cont_location
    folders = self.where(session_id: sid, domain_hash_key: target_domain, cont_location: cont_location).order("vpath ASC")
    if folders.count > 0
      return folders[0][:spin_node_hashkey]
    end
    return nil
  end

  def self.get_selected_folder_of_domain sid, target_domain, cont_location
    selected_folder = self.find_by(session_id: sid, domain_hash_key: target_domain, cont_location: cont_location, selected: true)
    if selected_folder.present?
      return selected_folder[:spin_node_hashkey]
    end
    return nil
  end

  def self.xget_domain sid, fhk, location
    # returns domain hash_key it belongs to
    # fhk : spin_node_hashkey of the folder
    #    ActiveRecord::Base::lock_optimistically = false
    case location
    when 'folder_a', 'folder_at', 'folder_atfi'
      location = 'folder_a'
    when 'folder_b', 'folder_bt', 'folder_btfi'
      location = 'folder_b'
    else
      location = 'folder_a'
    end
    doms = SpinNode.get_domains(fhk)
    doms.each {|d|
      td = DomainDatum.readonly.find_by_spin_domain_hash_key_and_cont_location d, location
      if td.present?
        return td[:hash_key]
      end
    }
    return nil
    #    fd = nil
    #    #    self.transaction do
    #    fd = DomainDatum.readonly.find_by_session_id_and_selected sid, true
    #    if fd == nil
    #      return nil
    #    end
    #    #    end
    #    return fd[:hash_key]
  end

  # => end of get_domain

  def self.is_expanded_folder sid, location, node_key
    #    self.transaction do
    expanded_folder = self.readonly.find_by_session_id_and_cont_location_and_spin_node_hashkey sid, location, node_key
    if expanded_folder.present? and expanded_folder[:expanded] == true
      return true
    else
      return false
    end
    #    end
  end

  # => end of is_expanded_folder

  def self.is_expanded_folder2 sid, location, domain_key, node_key
    #    self.transaction do
    expanded_folder = self.readonly.find_by_session_id_and_cont_location_and_domain_hash_key_and_spin_node_hashkey sid, location, domain_key, node_key
    if expanded_folder.present? and expanded_folder[:expanded] == true
      return true
    else
      return false
    end
    #    end
  end

  # => end of is_expanded_folder

  def self.has_updated sid, folder_key, update_type = NEW_CHILD, file_only = true
    #    ActiveRecord::Base.lock_optimistically = false
    retry_save = ACTIVE_RECORD_RETRY_COUNT

    ActiveRecord::Base.lock_optimistically = true
    catch(:has_updated_again) {

      self.transaction do
        fols = self.where(["session_id = ? AND spin_node_hashkey = ?", sid, folder_key])
        fols.each {|fol|
          #        fol.with_lock do
          #      fol[:spin_updated_at] = Time.now

          if file_only
            begin
              unless fol[:is_dirty_list]
                fol[:is_dirty_list] = true
                fol[:is_new_list] = false
                case update_type
                when NEW_CHILD
                  fol[:new_children] += 1
                  fol[:notify_new_child] = I_TRUE
                  #              unless child_key.blank?
                  #                self.add_child_to_parent(child_key, folder_key)
                  #              end
                when DISMISS_CHILD
                  fol[:new_children] -= 1
                  #              unless child_key.blank?
                  #                self.remove_child_from_parent(child_key, folder_key)
                  #              end
                when ACL_CHANGED
                when NOTIFY_EVENT
                end
                fol.save
              end
            rescue ActiveRecord::StaleObjectError
              if retry_save > 0
                retry_save -= 1
                sleep(AR_RETRY_WAIT_MSEC)
                throw :has_updated_again
              end
            rescue ActiveRecord::StatementInvalid
              #              ActiveRecord::Base.lock_optimistically = true
              return false
            end
          else
            begin
              unless fol[:is_dirty_list]
                fol[:is_dirty_list] = true
                fol[:is_new_list] = false
                fol.save
              end
            rescue ActiveRecord::StaleObjectError
              if retry_save > 0
                retry_save -= 1
                sleep(AR_RETRY_WAIT_MSEC)
                throw :has_updated_again
              end
            rescue ActiveRecord::StatementInvalid
              #              ActiveRecord::Base.lock_optimistically = true
              return false
            end
            begin
              unless fol[:is_dirty]
                fol[:is_dirty] = true
                fol[:is_new] = false
                case update_type
                when NEW_CHILD
                  fol[:new_children] += 1
                  fol[:notify_new_child] = I_TRUE
                when DISMISS_CHILD
                  fol[:new_children] -= 1
                when ACL_CHANGED
                when NOTIFY_EVENT
                end
                fol.save
              end
            rescue ActiveRecord::StaleObjectError
              if retry_save > 0
                retry_save -= 1
                sleep(AR_RETRY_WAIT_MSEC)
                throw :has_updated_again
              end
            rescue ActiveRecord::StatementInvalid
              #              ActiveRecord::Base.lock_optimistically = true
              return false
            end
          end
        }
        #        end
      end # => end of transanction
    } # => end of catch block
    #    ActiveRecord::Base.lock_optimistically = true
    return true
  end

  # => end of self.has_updated sid, folder_key

  def self.has_updated_to_parent sid, folder_key, update_type, file_only = true
    #    ActiveRecord::Base.lock_optimistically = false
    #    children_fols = self.where(["session_id = ? AND spin_node_hashkey = ?",sid,folder_key])
    fols = []
    parent_key = SpinLocationManager.get_parent_key(folder_key, NODE_DIRECTORY)
    parent_node = self.find_by_session_id_and_spin_node_hashkey(sid, parent_key)
    if parent_node.blank?
      return false
    end

    fols.push(parent_node) if parent_node.present?

    #    children_fols.each {|cf|
    #      pf = self.find_by_session_id_and_spin_node_hashkey sid, cf[:parent_hash_key]
    #      if pf != nil
    #        fols.push pf
    #      end
    #    }
    retry_has_updated_to_parent = ACTIVE_RECORD_RETRY_COUNT
    catch(:has_updated_to_parent_again) {
      self.transaction do

        fols.each {|fol|
          #        fol.with_lock do
          #      fol[:spin_updated_at] = Time.now
          if file_only
            begin
              unless fol[:is_dirty_list]
                v_is_dirty_list = true
                v_is_new_list = false
                v_new_children = fol[:new_children]
                v_notify_new_child = fol[:notify_new_child]
                case update_type
                when NEW_CHILD
                  v_new_children += 1
                  v_notify_new_child = I_TRUE
                when DISMISS_CHILD
                  v_new_children -= 1
                when ACL_CHANGED
                when PENDING_CHILD
                end
                fol.update(is_dirty_list: v_is_dirty_list, is_new_list: v_is_new_list, new_children: v_new_children, notify_new_child: v_notify_new_child)
              end
            rescue ActiveRecord::StaleObjectError
              next
            rescue ActiveRecord::StatementInvalid
              #              ActiveRecord::Base.lock_optimistically = true
              return nil
            end
          else
            begin
              unless fol[:is_dirty_list]
                v_is_dirty_list = true
                v_is_new_list = false
                fol.update(is_dirty_list: v_is_dirty_list, is_new_list: v_is_new_list)
              end
            rescue ActiveRecord::StaleObjectError
              next
            rescue ActiveRecord::StatementInvalid
              #              ActiveRecord::Base.lock_optimistically = true
              return nil
            end
            begin
              unless fol[:is_dirty]
                v_is_dirty = fol[:is_dirty]
                v_is_new = fol[:is_new]
                case update_type
                when NEW_CHILD
                  v_new_children += 1
                  v_notify_new_child = I_TRUE
                when DISMISS_CHILD
                  v_new_children -= 1
                when ACL_CHANGED
                when PENDING_CHILD
                end
                fol.update(is_dirty: v_is_dirty, is_new: v_is_new, new_children: v_new_children, notify_new_child: v_notify_new_child)
              end
            rescue ActiveRecord::StaleObjectError
              next
            rescue ActiveRecord::StatementInvalid
              #              ActiveRecord::Base.lock_optimistically = true
              return nil
            end
          end
        }
        #        end
      end # => end of transaction
    } # => end of catch block
    #    ActiveRecord::Base.lock_optimistically = true
    return parent_node
  end

  # => end of self.has_updated sid, folder_key

  def self.get_parent_folder sid, folder_key

    parent_key = SpinLocationManager.get_parent_key(folder_key, NODE_DIRECTORY)
    if parent_key.blank?
      return nil
    end
    parent_folder = self.readonly.find_by_session_id_and_spin_node_hashkey(sid, parent_key)
    if parent_folder.blank?
      return nil
    else
      return parent_folder
    end
  end

  # => end of self.has_updated sid, folder_key

  def self.set_parent_folders_dirty node_key
    # find domains in which node_key is
    parent_key = SpinLocationManager.get_parent_key node_key
    nfolders = 0
    ActiveRecord::Base.lock_optimistically = true
    catch(:set_parent_folders_dirty_again) {
      self.transaction do
        begin
          nfolders = FolderDatum.find_by(session_id: sid, spin_node_hashkey: parent_key, is_dirty: false).update(is_dirty: true, is_new: false, is_dirty_list: true, expand_counter: 0)
            # nfolders = FolderDatum.where(session_id: sid, spin_node_hashkey: parent_key, is_dirty: false).update_all(is_dirty: true, is_new: false, is_dirty_list: true, expand_counter: 0)
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :set_parent_folders_dirty_again
        end
      end # => end of transaction
    }
    return folders
  end

  # => end of set_folders_dirty

  def self.set_folder_dirty sid, node_key
    ActiveRecord::Base.lock_optimistically = true
    nfolders = 0
    catch(:set_folder_dirty_again) {
      self.transaction do
        retry_count = ACTIVE_RECORD_RETRY_COUNT
        begin
          nfolders = FolderDatum.find_by(session_id: sid, spin_node_hashkey: node_key, is_dirty: false).update(is_dirty: true, is_new: false, is_dirty_list: true, set_expand_foldercounter: 0)
            # nfolders = FolderDatum.where(session_id: sid, spin_node_hashkey: node_key, is_dirty: false).update_all(is_dirty: true, is_new: false, is_dirty_list: true, expand_counter: 0)
        rescue ActiveRecord::StaleObjectError
          next
        rescue
          if retry_count > 0
            retry_count -= 1
            sleep(AR_RETRY_WAIT_MSEC)
            throw :set_folder_dirty_again # => try again!
          end
        end
      end # => end of transaction
    }
    return nfolders
  end

  # => end of set_folders_dirty

  def self.unset_folder_selected sid, location, domain_key
    self.transaction do
      begin
        fols = self.where(session_id: sid, cont_location: location, domain_hash_key: domain_key)
        fols.each {|fol|
          fol.update(selected: false)
        }
      rescue ActiveRecord::StaleObjectError
        throw ActiveRecord::StaleObjectError
      end
    end
  end

  def self.unset_folder_dirty node_key, location, is_list = false
    # find domains in which node_key is
    ActiveRecord::Base.lock_optimistically = true
    catch(:unset_folder_dirty) {
      self.transaction do
        folders = self.where :spin_node_hashkey => node_key, :cont_location => location
        folders.each {|folder|
          begin
            v_is_dirty_list = folder[:is_dirty_list]
            v_is_new_list = folder[:is_new_list]
            v_is_dirty = folder[:is_dirty]
            v_is_new = folder[:is_new]
            if is_list
              v_is_dirty_list = true
              v_is_new_list = false
              folder[:is_new_list] = false
            else
              v_is_dirty = true
              v_is_new = false
            end
            folder[:expand_counter] = 0
            fol.update(is_dirty: v_is_dirty, is_new: v_is_new, is_dirty_list: v_is_dirty_list, is_new_list: v_is_new_list)
          rescue ActiveRecord::StaleObjectError
            sleep(AR_RETRY_WAIT_MSEC)
            throw :unset_folder_dirty
          end
        }
      end
    }
  end

  # => end of set_folders_dirty

  def self.is_dirty_folder sid, location, folder_key, is_list = false
    d = nil
    #    self.transaction do
    d = self.find_by_session_id_and_cont_location_and_spin_node_hashkey sid, location, folder_key
    if d.blank?
      return false
    end

    #    end
    unless d.present?
      return true
    end
    if is_list
      return d[:is_dirty_list]
    else
      return d[:is_dirty]
    end
  end

  # => end of is_dirty_domain domain_key

  def self.is_dirty_folder_tree sid, location, folder_hash_key
    # returns true if there is a folder which is dirty. except folder_hash_key
    fols = self.where(["session_id = ? AND cont_location = ?", sid, location])
    fols.each {|fol|
      if fol[:is_dirty] and fol[:hash_key] != folder_hash_key
        return true
      end
    }
    return false
  end

  def self.destroy_folder_tree delete_sid, delete_folder_key

    d = self.where(["session_id = ? AND spin_node_hashkey = ?", delete_sid, delete_folder_key]).map(&:domain_hash_key).uniq
    d.each {|fd|
      begin
        dfl = self.where :domain_hash_key => fd
        dfl.destroy_all
      rescue ActiveRecord::StaleObjectError
        FileManager.logger(delete_sid, 'already destroyed folder tree')
      end
    }
    #    end
  end

  # => end of destroy_folder_tree delete_sid, delete_file_key

  #  def self.display_format node, cont_location
  #    rh = node.to_json
  #    case cont_location
  #    when 'folder_a','folder_b'
  #      #      rh = node
  #    when 'folder_at','folder_bt','folder_atfi','folder_btfi'
  #      rh.gsub! /\"hash_key\":/, '"target_hash_key":'
  #      rh.gsub! /\"cont_location\":/, '"target_cont_location":'
  #      rh.gsub! /\"ownership\":/, '"target_ownership":'
  #      rh.gsub! /\"parent_readable_status\":/, '"target_parent_readable_status":'
  #      rh.gsub! /\"parent_writable_status\":/, '"target_parent_writable_status":'
  #      rh.gsub! /\"folder_readable_status\":/, '"target_folder_readable_status":'
  #      rh.gsub! /\"folder_writable_status\":/, '"target_folder_writable_status":'
  #    end
  #    rh_obj = JSON.parse rh
  #    return rh_obj
  #  end # => end of self.display_format cn, cont_location

  def self.clear_data sid
    recs = self.find_by_session_id sid
    recs.each {|r|
      r.destroy
    }
  end

  def self.clear_partial_root(sid, cont_location, domain_key)
    prtrts = self.where(["session_id = ? AND cont_location = ? AND domain_hash_key = ?", sid, cont_location, domain_key]).update_all(is_partial_root: false)
    # prtrts.each {|prt|
    #   prt.update(is_partial_root: false)
    # }
  end

  # => end of clear_partial_root(sid, 'folder_b', my_login_domain)

  def self.clear_folder_tree(sid, clear_sid = SESSION_NONE, cont_locations = CONT_LOCATIONS_LIST)
    rethash = {:success => true, :status => INFO_CLEAR_FOLDER_TREE_SUCCESS}
    target_session = (clear_sid == SESSION_NONE ? sid : clear_sid)
    target_locations = (cont_locations.class == Array ? cont_locations : [cont_locations])
    uids = SessionManager.get_uid_gid(sid, true)
    uid = uids[:uid]
    gid = uids[:gid]
    clear_recs = 0
    target_locations.each {|location|

      retry_clear = ACTIVE_RECORD_RETRY_COUNT
      ActiveRecord::Base.lock_optimistically = true
      catch(:clear_folder_tree_again) {
        self.transaction do

          begin
            begin
              prtrts = []
              if (uid == ACL_SUPERUSER_UID or gid == ACL_SUPERUSER_GID) and clear_sid == SESSION_ANY
                delquery = sprintf("DELETE FROM folder_data WHERE cont_location = \'%s\'", location)
                self.find_by_sql(delquery)
              elsif clear_sid == SESSION_NONE
                delquery = sprintf("DELETE FROM folder_data WHERE session_id = \'%s\' AND cont_location = \'%s\'", target_session, location)
                self.find_by_sql(delquery)
              else
                delquery = sprintf("DELETE FROM folder_data WHERE owner = %d AND cont_location = \'%s\'", SpinUser.get_uname(uid), location)
                self.find_by_sql(delquery)
              end

            rescue ActiveRecord::StatementInvalid
              rethash[:success] = false
              rethash[:status] = ERROR_FAILED_TO_CLEAR_FOLDER_TREE
              rethash[:errors] = 'Failed to clear folder tree data due to some database access error!'
              return rethash
            rescue
              rethash[:success] = false
              rethash[:status] = ERROR_FAILED_TO_CLEAR_FOLDER_TREE
              rethash[:errors] = 'Failed to clear folder tree data.'
              return rethash
            end
            clear_recs += prtrts.length
          rescue ActiveRecord::StatementInvalid
            retry_clear -= 1
            if retry_clear > 0
              sleep(AR_RETRY_WAIT_MSEC)
              throw :clear_folder_tree_again
            else
              rethash[:success] = false
              rethash[:status] = ERROR_FAILED_TO_CLEAR_FOLDER_TREE
              rethash[:errors] = 'Failed to clear folder tree data.'
              return rethash
            end
          end
        end
      }
    }
    rethash[:result] = clear_recs
    return rethash
  end

  # => end of clear_partial_root(sid, 'folder_b', my_login_domain)


  def self.remove_folder_rec sid, location, node_hash_key
    remove_locations = []
    if location == LOCATION_ANY
      remove_locations = CONT_LOCATIONS_LIST
    else
      remove_locations.push(location)
    end
    #    ActiveRecord::Base::lock_optimistically = false
    remove_locations.each {|remove_location|
      # get children and call myself
      cns = nil
      cns = self.where(["session_id = ? AND cont_location = ? AND parent_hash_key = ?", sid, remove_location, node_hash_key])
      cns.each {|cn|
        self.remove_folder_rec sid, remove_location, cn[:spin_node_hashkey]
      }
      next if cns == nil

      self.transaction do
        begin
          begin
            n = self.find_by_session_id_and_cont_location_and_spin_node_hashkey sid, remove_location, node_hash_key
            if n.present?
              n.destroy
            end
          rescue ActiveRecord::RecordNotFound
            next
          end
        rescue ActiveRecord::StaleObjectError
          FileManager.logger(sid, "folder record is alread removed")
        end
      end
    }
  end

end
