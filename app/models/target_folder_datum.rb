# coding: utf-8
require 'const/vfs_const'
require 'const/acl_const'
require 'const/stat_const'
require 'tasks/spin_location_manager'
require 'tasks/session_management'

class TargetFolderDatum < ActiveRecord::Base
  include Vfs
  include Acl  

  attr_accessor :id, :children, :session_id, :target_cont_location, :target_folder, :target_folder_readable_status, :target_folder_writable_status, :target_hash_key, :target_ownership, :target_parent_readable_status, :target_parent_writable_status, :text
  TREE_NOT_INCLUDE_ROOT = false
  TREE_INCLUDE_ROOT = true
  
  def self.fill_target_folder_data_table ssid, last_ssid,  my_uid, location, current_domain_key
    # get current domain for the session 'ssid'
    # current_domain_key = SpinSession.find_by_spin_session_id ssid
    if current_domain_key == nil or current_domain_key == "" or current_domain_key == "0"
      logger.debug ">>> get_default_domain"
      current_domain_key = DatabaseUtility::SessionUtility.get_default_domain ssid
    end

    current_domain_root_obj = SpinDomain.find_by_hash_key current_domain_key
    current_domain_data = DomainDatum.find_by_hash_key current_domain_key
    
    if current_domain_data == nil
      DomainDatum.fill_domains(ssid, location)
      current_domain_data = DomainDatum.find_by_hash_key current_domain_key
    end

    #    if current_domain_data[:target_is_new] == false and current_domain_data[:target_is_dirty] == false
    #      return {:success => true, :status => true, :result => 1 } 
    #    end
    # Is it dirty?
    if SessionManager.is_dirty_location(ssid, location) == false
      fs = self.select("id").where(:session_id => ssid, :target_cont_location => location)
      return {:success => true, :status => STAT_DATA_ALREADY_LOADED, :result => fs.length }
    end

    
    
    if current_domain_data[:target_is_new] == true
      current_domain_data[:target_is_new] = false
    end    
    if current_domain_data[:target_is_dirty] == true
      current_domain_data[:target_is_dirty] = false
    end
    #    current_domain_data.save
    
    d_root_loc = SpinLocationManager.key_to_location current_domain_root_obj[:domain_root_node_hashkey], NODE_DIRECTORY
    
    if d_root_loc[Y] == 0
      pp "root \'/\'"
    end

    # folder_tree_obj = SpinLocationManager.get_sub_tree my_uid, d_root_loc, TREE_NOT_INCLUDE_ROOT
    # folder_tree_nodes = SpinLocationManager.get_sub_tree_nodes_acl ssid,  my_uid, d_root_loc   # => get array of nodes under d_root_loc
    folder_tree_nodes = SpinLocationManager.get_expanded_sub_tree_nodes ssid, location, current_domain_root_obj[:domain_root_node_hashkey]   # => get array of nodes under d_root_loc
    if folder_tree_nodes == nil # => no children
      return {:success => true, :status => true, :result => 0 }      
    end
    
    expanded_folders = Array.new
    
    DomainDatum.has_updated ssid, current_domain_key, 'target_folder'
        
    # build FolderData
    saved_records = 0
    folder_rec = Hash.new
    reuse_last = false
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      folder_tree_nodes.each { |tn|
        d = SpinNode.find_by_spin_node_hashkey_and_node_type tn[:spin_node_hashkey], NODE_DIRECTORY
        next if d[:in_trash_flag] or d[:is_pending]
        # acls = SpinAccessControl.has_acl_values ssid, tn[:spin_node_hashkey]
        # if acls[:user] > ACL_NODE_NO_ACCESS or acls[:group] > ACL_NODE_NO_ACCESS  or acls[:world] > ACL_NODE_NO_ACCESS # => match!
        folder_rec = self.find_by_target_hash_key_and_session_id_and_target_cont_location_and_domain_hash_key tn[:spin_node_hashkey], ssid, location, current_domain_key
        if folder_rec # => there are already folder data for the session, ignore the last session
          reuse_last = false
        elsif last_ssid
          folder_rec = self.find_by_target_hash_key_and_session_id_and_target_cont_location_and_domain_hash_key tn[:spin_node_hashkey], last_ssid, location, current_domain_key
          reuse_last = true
        end # => end of if ssid
        if folder_rec # => there is folder data
          if reuse_last
            folder_rec.session_id = ssid
          end
          if folder_rec.spin_updated_at < d.spin_updated_at
            #            folder_rec.capacity = -1
            folder_rec.children = nil
            folder_rec.target_cont_location = location
            # folder_rec.expanded = false
            folder_rec.target_folder = d.node_name
            folder_rec.target_folder_readable_status = SpinAccessControl.is_readable ssid, tn[:spin_node_hashkey], ACL_TYPE_DIRECTORY
            folder_rec.target_folder_writable_status = SpinAccessControl.is_writable ssid, tn[:spin_node_hashkey], ACL_TYPE_DIRECTORY
            # folder_rec.target_folder_readable_status = ((acls[:user]|acls[:group]|acls[:world])&ACL_NODE_READ) != 0? true : false
            # folder_rec.target_folder_writable_status = ((acls[:user]|acls[:group]|acls[:world])&ACL_NODE_WRITE) != 0? true : false
            # folder_rec.img = "file_type_icon/FolderDocument.png"
            # folder_rec.leaf = true
            folder_rec.target_ownership = (d.spin_uid == my_uid) ? "me" : "other"
            pkey = SpinLocationManager.get_parent_key(d.spin_node_hashkey,NODE_DIRECTORY)
            folder_rec.target_parent_readable_status = SpinAccessControl.is_readable ssid, pkey, ACL_TYPE_DIRECTORY
            folder_rec.target_parent_writable_status = SpinAccessControl.is_writable ssid, pkey, ACL_TYPE_DIRECTORY
            folder_rec.spin_node_hashkey = d.spin_node_hashkey
            folder_rec.domain_hash_key = current_domain_key
            folder_rec.parent_hash_key = pkey
            folder_rec.text = d.node_name
            # folder_rec.text = SpinObject.get_object_name_by_key d.spin_node_hashkey
            # folder_rec.updated_at = d.updated_at
            # if folder_rec.save # => save = update database
            # flag_saved = true
            # saved_records += 1
            # else
            # flag_saved = false
            # break
            # end # => end of if
            folder_rec.updated_at = d.updated_at
            folder_rec.spin_updated_at = d.spin_updated_at
            # folder_rec.selected = SessionManager.is_selected_folder ssid, d.spin_node_hashkey, location
            if folder_rec.save # => save = update database
              saved_records += 1
              SessionManager.set_location_clean(ssid, location)
            else
              break
            end # => end of if
          else # =>  folder_rec.updated_at >= d.updated_at
            if reuse_last # => rewrite session_id to ssid
              if folder_rec.save # => save = update database
                saved_records += 1
                SessionManager.set_location_clean(ssid, location)
              else
                break
              end # => end of if
            else # => don't reuse
              # do nothing but increment saved_records
              saved_records += 1
            end # => end of if reuse_last
          end # => if folder_rec.updated_at < d.updated_at
        else # => no folder rec's
          new_folder_datum = new
          new_folder_datum.session_id = ssid
          #          new_folder_datum.capacity = -1
          new_folder_datum.children = nil
          new_folder_datum.target_cont_location = location
          new_folder_datum.expanded = SetUtility::SetOp.is_in_set tn[:spin_node_hashkey], expanded_folders
          # new_folder_datum.expanded = false
          new_folder_datum.target_folder = d.node_name
          new_folder_datum.target_folder_readable_status = SpinAccessControl.is_readable ssid, tn[:spin_node_hashkey]
          new_folder_datum.target_folder_writable_status = SpinAccessControl.is_writable ssid, tn[:spin_node_hashkey]
          # new_folder_datum.target_folder_readable_status = ((acls[:user]|acls[:group]|acls[:world])&ACL_NODE_READ) != 0? true : false
          # new_folder_datum.target_folder_writable_status = ((acls[:user]|acls[:group]|acls[:world])&ACL_NODE_WRITE) != 0? true : false
          new_folder_datum.target_hash_key = d.spin_node_hashkey
          new_folder_datum.leaf = true
          new_folder_datum.target_ownership = (d.spin_uid == my_uid)? "me" : "other"
          pkey = SpinLocationManager.get_parent_key(d.spin_node_hashkey,NODE_DIRECTORY)
          new_folder_datum.target_parent_readable_status = SpinAccessControl.is_readable ssid, pkey
          new_folder_datum.target_parent_writable_status = SpinAccessControl.is_writable ssid, pkey
          new_folder_datum.spin_node_hashkey = d.spin_node_hashkey
          new_folder_datum.domain_hash_key = current_domain_key
          new_folder_datum.parent_hash_key = pkey
          new_folder_datum.text = d.node_name
          # new_folder_datum.text = SpinObject.get_object_name_by_key d.spin_node_hashkey
          new_folder_datum.updated_at = d.updated_at
          new_folder_datum.spin_updated_at = d.spin_updated_at
          if new_folder_datum.save # => save = update database
            saved_records += 1
            SessionManager.set_location_clean(ssid, location)
          else
            break
          end # => end of if
        end # => end of if folder_rec
        # end # => end of if acls[:user

      } # =>  end of folder_tree_nodes.each
    end # => end of transaction
    # printf ">> number of records saved : "
    # pp saved_records
    return {:success => true, :status => true, :result => saved_records }
  end  

  def self.fill_target_folders ssid, location
    # get uid and gid
    my_uid = SessionManager.get_uid ssid
    # get current domain at the location
    session_rec = SpinSession.find_by_spin_session_id ssid
    my_current_domain = String.new
    last_session = SessionManager.get_last_session ssid
    case location
    when 'folder_at'
      my_current_domain = session_rec[:selected_domain_a]
    when 'folder_bt'
      my_current_domain = session_rec[:selected_domain_b]
    else
      my_current_domain = session_rec[:selected_domain_a]
    end
    rethash = Hash.new
    # search spin_folders and spin_access_control, and fill domain table
    rethash = fill_target_folder_data_table ssid, last_session, my_uid, location, my_current_domain
    # rethash = FolderDatum.where(:session_id => ssid).order("spin_did")
    return rethash
  end # => end of fill_folders
  
  def self.get_tree_node hash_key, tree_node
    # pp tree_node
    if tree_node == nil
      return nil
    end
    tree_node.each { |t|
      if t[:target_hash_key] == hash_key
        return t
      elsif t[:children]
        tt = self.get_tree_node hash_key, t[:children]
        if tt
          return tt
        end
      else
        # do nothing
      end
    }
    return nil
  end # => end of get_tree_node
  
  def self.get_target_folder_display_data sid, cont_location
    # cont_location : specifies pane to use for display folder tree { 'foldersA', 'foldersB' }
    # get current domain at domainsA or domainsB
    sr = SpinSession.find_by_spin_session_id sid
    target_domain = sr[:selected_domain_a]
    target_domain_selected_folder = ''
    dom_a = sr[:selected_domain_a]
    dom_b = sr[:selected_domain_b]
    my_uid = sr[:spin_uid]

    # if cont_location == foldersA => domainsA
    # if cont_location == foldersB => domainsB
    case cont_location
    when 'folder_at'
      root_node_key = SpinDomain.get_domain_root_node_key dom_a  
      target_domain = dom_a
    when 'folder_bt'
      root_node_key = SpinDomain.get_domain_root_node_key dom_b  
      target_domain = dom_b
    else
      root_node_key = SpinDomain.get_domain_root_node_key dom_a  
      target_domain = dom_a
    end # => end of case
    target_domain_selected_folder = DomainDatum.get_selected_folder sid, target_domain, cont_location
    # build arfray of tree nodes
    tree_nodes = Array.new
    stack_nodes = Array.new
    current_tree_node = Hash.new
    current_parent = root_node_key
    # children_y = root_node_loc[Y] + 1
    # process tree 
    self.transaction do
      # self.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      children_nodes = TargetFolderDatum.where(:parent_hash_key => current_parent, :session_id => sid, :target_cont_location => cont_location, :domain_hash_key => target_domain)
      #    children_nodes.uniq!
      if children_nodes.count > 1
        children_nodes.sort! {|a,b| a.text <=> b.text}
      end
      while children_nodes.count > 0 || stack_nodes.count > 0  # => there are nodes under the current node
        # there are some children
        children_nodes.order("folder_name DESC")
        children_nodes.each { |cn|
          # pp "+++++++ child node"
          # pp cn
          if cn[:spin_node_hashkey] == target_domain_selected_folder
            cn[:selected] = true
          else
            cn[:selected] = false
          end
          cn.save
          if current_parent == root_node_key
            tree_nodes << cn
          else
            # current_tree_node = self.add_child current_tree_node, cn
            current_tree_node[:leaf] = false
            if current_tree_node[:children]
              current_tree_node[:children] << cn
            else
              current_tree_node[:children] = [cn]
            end
          end
          stack_nodes << cn
          # pp ">>>>> tree_nodes"
          # pp tree_nodes
        } # => end of children_nodes.each
        # pop 1 from stack_nodes
        if stack_nodes.count > 0
          c = stack_nodes[-1]
          current_tree_node = self.get_tree_node c[:target_hash_key], tree_nodes
          current_parent = c[:target_hash_key] # => pop 1
          stack_nodes -= [c]                         # => remove it
        else # => end of children of the layers
          break # => exit from while loop
        end # => end of if stack_nodes.count > 0
        children_nodes = TargetFolderDatum.where(:parent_hash_key => current_parent, :session_id => sid, :target_cont_location => cont_location)
      end # =>  end of while
    end
    current_parent = root_node_key
    # pp ">>>>> tree_nodes at end of get_folder_display_data"
    # pp tree_nodes
    return tree_nodes
  end # => end of get_folder_display_data
  
  def self.set_expand_target_folder sid, location, hkey
    fd = self.find_by_session_id_and_target_cont_location_and_spin_node_hashkey sid, location, hkey
    if fd
      fd.expanded = true
      if fd.save
        return {:success => true, :status => true, :result => true }
      else
        return {:success => false, :status => false, :result => "expand folder failed" }
      end
    else
      return {:success => false, :status => false, :result => "expand folder failed" }
    end
    return {:success => true, :status => true, :result => true }
  end # => end of set_expand_folder
    
  def self.set_collapse_target_folder sid, location, hkey
    fd = self.find_by_session_id_and_target_cont_location_and_spin_node_hashkey sid, location, hkey
    if fd
      fd.expanded = false
      if fd.save
        return {:success => true, :status => true, :result => true }
      else
        return {:success => false, :status => false, :result => "collapse target folder failed" }
      end
    else
      return {:success => false, :status => false, :result => "collapse target folder failed" }
    end
    return {:success => true, :status => true, :result => true }
  end # => end of set_expand_folder
    
  def self.is_expanded_folder sid, location, node_key
    expanded = self.select( :expanded ).find_by_session_id_and_target_cont_location_and_spin_node_hashkey sid, location, node_key
  end # => end of is_expanded_folder

  def self.destroy_folder_tree delete_sid, delete_folder_key
    d = self.where( :session_id => delete_sid, :spin_node_hashkey => delete_folder_key ).map(&:domain_hash_key).uniq
    d.each { |fd|
      dfl = self.where :domain_hash_key => fd
      dfl.destroy_all
    }
  end # => end of destroy_folder_tree delete_sid, delete_file_key
    
end
