# coding: utf-8
require 'const/vfs_const'
require 'const/acl_const'
require 'tasks/spin_file_system'

class RecyclerDatum < ActiveRecord::Base
  include Vfs
  include Acl
  include SpinFileManager

  attr_accessor :cont_location, :file_exact_size, :file_exact_size_upper, :file_name, :file_type, :hash_key, :spin_uid, :session_id, :url
  TREE_NOT_INCLUDE_ROOT = false
  TREE_INCLUDE_ROOT = true
    
  def self.get_recycler_display_data sid, offset = DEFAULT_OFFSET, limit = DEFAULT_PAGE_SIZE
    uid = SessionManager.get_uid sid
    n_files = RecyclerDatum.limit(limit).offset(offset).where(["spin_uid = ? AND latest = true AND is_thrown = true", uid])
    total = n_files.count
    
    file_list = []
    n_files.each {|f|
      #      sn = SpinNode.select("is_pending").find(["spin_node_hashkey = ?",f[:spin_node_hashkey]])
      unless f[:is_busy]
        file_list.push(f)
      end
    }
    
    #    file_list = RecyclerDatum.limit(limit).offset(offset).where(:spin_uid => uid,:latest => true,:is_thrown => true)
    #    if file_list == nil
    #    unless file_list.length > 0
    #      return { :success => false }
    #    end
    file_list.each {|fl|
      if fl[:file_size] and fl[:file_size_upper]
        fl[:file_exact_size] = (fl[:file_size] + fl[:file_size_upper]*2**31).to_s
      else
        fl[:file_exact_size] = "0"
      end
    }
    return { :success => true, :total => total, :recycler => file_list }
  end # => end of get_recycler_list_display_data
  
  #  def self.may_be_latest hkey # => returns {true,false}
  #    # => side effect : it may update 'latest' flag
  #    self.transaction do
  #      vloc = SpinLocationManager.key_to_location hkey
  #      if vloc == [ -1, -1, -1, -1 ] # => error : hkey may be invalid!
  #        return false
  #      end
  #      me = SpinNode.find_by_spin_node_hashkey hkey
  #      # => There is a node which has the same key with it
  #      if me[:latest] # => It is the latest
  #        return true
  #      end
  #      my_version = me[:node_version]
  #      # get nodes which has the same coords
  #      same_nodes = SpinNode.where :node_x_coord => me[:node_x_coord], :node_y_coord => me[:node_y_coord]
  #      if same_nodes.count <= 1
  #        return true
  #      end
  #      keys = []
  #      vers = []
  #      same_nodes.each {|n|
  #        keys.push n[:spin_node_hashkey]
  #        vers.push n[:node_version]
  #      }
  #      # => get the key of the latest and its version number
  #      node_count = keys.length
  #      latest_key = keys[0]
  #      max_version = vers[0]
  #      1.upto(node_count) { |i|
  #        if vers[i] > max_version
  #          max_version = vers[i]
  #          latest_key = keys[i]
  #        end
  #      }
  #      if my_version > max_version
  #        former_latest = SpinNode.find_by_spin_node_hashkey latest_key
  #        former_latest[:latest] = false
  #        former_latest.save
  #        me[:latest] = true
  #        me.save
  #        return true
  #      else
  #        return false
  #      end
  #    end
  #  end # => end of may_be_latest

  def self.set_busy(delete_sid, v_delete_file_key)
    catch(:set_busy_again) {
      self.transaction do
        begin
          rrec = self.find_by_session_id_and_spin_node_hashkey(delete_sid, v_delete_file_key)
          if rrec != nil
            rrec[:is_busy] = true
            if rrec.save
              return true
            end
          end
        rescue ActiveRecord::StaleObjectError
          thrown :set_busy_again
        end
      end
    }    
    return false
  end # => end of self.set_busy(delete_sid, v_delete_file_key)

  def self.reset_busy(delete_sid, v_delete_file_key)
    catch(:reset_busy_again) {
      self.transaction do
        begin
          rrec = self.find_by_session_id_and_spin_node_hashkey(delete_sid, v_delete_file_key)
          if rrec != nil
            rrec[:is_busy] = false
            if rrec.save
              return true
            end
          end
        rescue ActiveRecord::StaleObjectError
          thrown :reset_busy_again
        end
      end
    }
    return false
  end # => end of self.reset_busy(delete_sid, v_delete_file_key)

  def self.put_node_into_recycler sid, node_key, is_thrown = false
    rethash = {}
    # retreive_file_key is thrown file
    trash_it = SpinNode.find_by_spin_node_hashkey node_key
    #    tn = SpinNode.readonly.select("virtual_path, node_type").find(["spin_node_hashkey = ?",node_key])

    if trash_it == nil
      Rails.logger.warn(">> put_node_into_recycler : trash_it is nil")
      rethash[:success] = false
      rethash[:status] = ERROR_FAILED_TO_TRASH_FILE
      rethash[:errors] = 'ファイルが有りません'
      return rethash
    end
    
    Rails.logger.warn(">> put_node_into_recycler : trash_it node = " + trash_it[:node_name])

    if trash_it[:node_type] == NODE_DIRECTORY or is_thrown
      unless SpinAccessControl.is_deletable_node(sid, trash_it, NODE_FILE)
        Rails.logger.warn(">> put_node_into_recycler : trash_it is not deletable")
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_TRASH_FILE
        rethash[:errors] = 'ゴミ箱に捨てられないファイルです'
        return rethash
      end
    end
    
    catch(:put_node_into_recycler_again) {
      
      RecyclerDatum.transaction do
        begin
          rcns = self.find_by_spin_node_hashkey node_key
          rcns.destroy if rcns.present?
        rescue ActiveRecord::StaleObjectError
          throw :put_node_into_recycler_again
        end
      end # => end of transaction
      # 
      #      trash_it = SpinNode.find_by_spin_node_hashkey node_key
      
      retn = SpinNode.delete_node sid, trash_it[:spin_node_hashkey], false # => it doesn't delete node and file, only set in_trash_flag and is_pending
      if retn == false
        Rails.logger.warn(">> put_node_into_recycler : failed to delete trash_it")
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_PUT_NODE_INTO_RECYCLER
        rethash[:errors] = '削除できないファイル／フォルダがあります'
        return rethash
      end
    
      if is_thrown
        FolderDatum.transaction do
          # create new entry for recycler
          begin
            recycler = RecyclerDatum.new
            recycler[:session_id] = sid
            recycler[:spin_uid] = SessionManager.get_uid sid
            recycler[:hash_key] = Security.hash_key_s(node_key+Time.now.to_s)
            recycler[:spin_node_hashkey] = trash_it[:spin_node_hashkey]
            recycler[:latest] = trash_it[:latest]
            recycler[:node_x_coord] = trash_it[:node_x_coord]
            recycler[:node_y_coord] = trash_it[:node_y_coord]
            recycler[:node_x_pr_coord] = trash_it[:node_x_pr_coord]
            recycler[:node_version] = trash_it[:node_version]
            recycler[:file_name] = trash_it[:node_name]
            recycler[:node_type] = trash_it[:node_type]
            recycler[:file_type] = (trash_it[:node_type] == NODE_DIRECTORY ? "folder" : trash_it[:node_name].split(/\./)[-1])
            recycler[:url] = trash_it[:spin_url]
            recycler[:created_at] = Time.now # => trashed time
            recycler[:updated_at] = recycler[:created_at]
            recycler[:file_size] = trash_it[:node_size]
            recycler[:file_size_upper] = trash_it[:node_size_upper]
            recycler[:cont_location] = trash_it[:cont_location]
            recycler[:is_thrown] = is_thrown
            recycler[:virtual_path] = trash_it[:virtual_path]
            recycler[:is_busy] = false
            if recycler.save
              delquery = sprintf("DELETE FROM folder_data WHERE session_id = \'%s\' AND spin_node_hashkey = \'%s\';",sid,trash_it[:spin_node_hashkey])
              FolderDatum.connection.select_all(delquery)
            end
          rescue ActiveRecord::StaleObjectError
            throw :put_node_into_recycler_again
          end
        end # => end of transaction
        FolderDatum.transaction do
          begin
            delquery = sprintf("DELETE FROM file_data WHERE session_id = \'%s\' AND spin_node_hashkey = \'%s\';",sid,trash_it[:spin_node_hashkey])
            FileDatum.connection.select_all(delquery)
          rescue ActiveRecord::StaleObjectError
            throw :put_node_into_recycler_again
          end
        end
      end
    } # => end of catch block
    
    trash_it[:in_trash_flag] = true
    if trash_it.save
      pn = SpinLocationManager.get_parent_node(trash_it)
      parent_node = pn[:spin_node_hashkey]
      SpinNode.has_updated(sid, parent_node)
      FolderDatum.has_updated(sid, parent_node, DISMISS_CHILD, false)
      rethash[:success] = true
      rethash[:status] = INFO_PUT_NODE_INTO_RECYCLER_SUCCESS
    else
      rethash[:success] = false
      rethash[:status] = ERROR_FAILED_TO_PUT_NODE_INTO_RECYCLER
      rethash[:errors] = '削除できないファイル／フォルダがあります'
      return rethash
    end
    rethash[:success] = retn
    if retn
      rethash[:status] = INFO_PUT_NODE_INTO_RECYCLER_SUCCESS
    else
      rethash[:status] = ERROR_FAILED_TO_PUT_NODE_INTO_RECYCLER
      rethash[:errors] = '削除できないファイル／フォルダがあります'
    end
    return rethash

  end # => end of put_node_into_recycler sid, node_key
  
  
  def self.retrieve_node_from_recycler sid, node_keys
    ret_file_keys = Array.new
    if node_keys.length > 0
      #      my_uid = SessionManager.get_uid sid
      clocation = SessionManager.get_current_location(sid)
      domain_key = SessionManager.get_selected_domain(sid,clocation)
      
      node_keys.each { |nk|
        retrieve_node_rec = {}
        #        next if retrieve_node_rec == nil
        is_thrown_file = self.is_thrown_file(nk)
        if is_thrown_file
          retrieve_node_rec =self.find_by_spin_node_hashkey(nk)
          px = retrieve_node_rec[:node_x_coord]
          py = retrieve_node_rec[:node_y_coord]
          pv = retrieve_node_rec[:node_version]
          parent_node_key = SpinLocationManager.get_parent_key(nk, NODE_DIRECTORY)
          parent_node = SpinNode.find_by_spin_node_hashkey(parent_node_key)
          #          parent_node = SpinNode.find(["spin_tree_type = 0 AND node_x_coord = ? AND node_y_coord = ?",retrieve_node_rec[:node_x_pr_coord],retrieve_node_rec[:node_y_coord] - 1])
          if parent_node == nil or parent_node[:is_void] == true or SpinAccessControl.is_writable(sid, parent_node[:spin_node_hashkey]) == false
            return []
          end
        else
          retrieve_node_rec = SpinNode.find_by_spin_node_hashkey(nk)
          px = retrieve_node_rec[:node_x_coord]
          py = retrieve_node_rec[:node_y_coord]
          pv = retrieve_node_rec[:node_version]
        end
        #        next unless SpinAccessControl.is_writable(sid, parent_node[:spin_node_hashkey]) # => put it back to the original directory
        # => retrerive all versions which are in trash box
        #        rt_nodes = SpinNode.where(["spin_tree_type = 0 AND node_x_coord = ? AND node_y_coord = ? AND in_trash_flag = true AND is_void = false",retrieve_node_rec[:node_x_coord],retrieve_node_rec[:node_y_coord]])
        rt_node = SpinNode.find_by_spin_node_hashkey(nk)
        if rt_node.blank?
          return false
        end
        retn = false
        # => delete existing nodes which have same name and coordinates
        del_nodes = SpinNode.where(["spin_tree_type = 0 AND node_x_coord = ? AND node_y_coord = ? AND node_version = ? AND in_trash_flag = false AND is_void = false",px,py,pv])
        del_nodes.each {|delnode|
          SpinNode.delete_node(sid, delnode[:spin_node_hashkey], true)
        }
        #        rt_nodes.each {|rtnk|
        retn = SpinNode.retrieve_node nk # rtnk[:spin_node_hashkey]
        if retn
          ret_file_keys.append nk # rtnk[:spin_node_hashkey]
          if rt_node[:node_type] == NODE_DIRECTORY
            if is_thrown_file
              SpinNode.has_updated sid, parent_node[:spin_node_hashkey]
              FolderDatum.load_folder_recs(sid, nk, domain_key, clocation, DEPTH_TO_TRAVERSE, SessionManager.get_last_session(sid))
              FolderDatum.add_child_to_parent(nk, parent_node[:spin_node_hashkey],sid,clocation)
              #              FolderDatum.add_child_to_parent(nk, clocation)
            end
          else
            if is_thrown_file
              FileDatum.fill_file_list(sid, clocation, parent_node[:spin_node_hashkey])
            end
          end
          if is_thrown_file and retrieve_node_rec
            retrieve_node_rec.destroy
          end
        end
        #        }
      }
      
    else # => node_keys.length <= 0
      return ret_file_keys
    end # => end of if node_keys.length > 0
    return ret_file_keys
  end # => end of self.retrieve_node_from_recycler sid, node_key
  
  def self.is_thrown_file node_key
    tf = self.readonly.select("is_thrown").find_by_spin_node_hashkey(node_key)
    if tf.present?
      return tf[:is_thrown]
    else
      return false
    end
  end
  
  def self.complete_trash_operation delete_sid, v_delete_file_key
  
    trashed_path = SpinLocationManager.get_key_vpath(delete_sid, v_delete_file_key, NODE_DIRECTORY)
    #    trashed_path.gsub!(/\'/,'\'\'')
    if trashed_path == nil #ゴミ箱にないときはパスがないのでNULL対策
      FileManager.rails_logger(">> complete_trash_operation : trashd_path = nil")
      return false
    end
  
    catch(:complete_trash_operation_again) {
      self.transaction do
    
        vpquery = "(virtual_path = \'#{trashed_path.gsub(/\'/,'\'\'')}\' OR left(virtual_path,#{trashed_path.length + 1}) = \'#{trashed_path.gsub(/\'/,'\'\'')}/\') AND in_trash_flag = true AND is_pending = true"

        #    ActiveRecord::Base.lock_optimistically = false
    
        trashed_recs = SpinNode.where("#{vpquery}")
    
        if trashed_recs.length == 0
          #      ActiveRecord::Base.lock_optimistically = true
          return true
        end
    
        trashed_directory_vpaths = []
        trashed_recs.each {|tr|
          begin
            tr[:is_pending] = false
            tr.save
            if tr[:node_type] == NODE_DIRECTORY
              if trashed_directory_vpaths.length == 0
                notify_flag = self.has_notification(delete_sid,tr[:spin_node_hashkey],NODE_DIRECTORY)
                FileManager.rails_logger(">> complete_trash_operation : notify_flag = " + notify_flag.to_s)
                unless (notify_flag&DELETE_NOTIFICATION) == 0 # => deleted
                  trashed_directory_vpaths.push(tr[:virtual_path])
                end
              else
                trashed_directory_vpaths.each {|tdvp|
                  unless tr[:virtual_path] =~ /^#{tdvp}/
                    notify_flag = self.has_notification(delete_sid,tr[:spin_node_hashkey],NODE_DIRECTORY)
                    FileManager.rails_logger(">> complete_trash_operation : notify_flag = " + notify_flag.to_s)
                    unless (notify_flag&DELETE_NOTIFICATION) == 0 # => deleted
                      trashed_directory_vpaths.push(tr[:virtual_path])
                    end
                  end
                }
              end
            end
          rescue ActiveRecord::StaleObjectError
            throw :complete_trash_operation_again
          rescue
            return false
          end
        }
    
      end # => end of transaction
    } # => end of catch block
    #    ActiveRecord::Base.lock_optimistically = true
    
    trashed_directory_vpaths.each {|tvp|
      tvpquery = "left(virtual_path,#{tvp.length + 1}) = \'#{tvp.gsub(/'/,'\'\'')}/\'"

      trashed_vp_recs = SpinNode.select("virtual_path").where("#{tvpquery}")
      trashed_vps = []
      trashed_vp_recs.each {|t|
        trashed_vps.push(t[:virtual_path])
      }
      thr = Thread.new do
        #        trashed_vps.uniq!
        SpinNotifyControl.notify_delete(delete_sid,trashed_vps)
      end
    }
    
    return true
  end # => end of self.complete_trash_operation delete_sid, v_delete_file_key
  
  def self.recover_pending_trash_operation sid
    uid = SessionManager.get_uid(sid, true)

    #    ActiveRecord::Base.lock_optimistically = false

    catch(:recover_pending_trash_operation_again) {
      self.transaction do
        
        recover_nodes = SpinNode.where(["changed_by = ? AND is_pending = true AND in_trash_flag = true",uid])
    
        ctime = Time.now

        recover_nodes.each {|rcvn|
          begin
            rcvn[:is_pending] = false
            rcvn[:in_trash_flag] = false
            rcvn[:spin_updated_at] = ctime
            rcvn[:ctime] = ctime
            rcvn[:changed_by] = uid
            unless rcvn.save
              return false
            end
          rescue ActiveRecord::StaleObjectError
            throw :recover_pending_trash_operation_again
          rescue
            #        ActiveRecord::Base.lock_optimistically = true
            return false
          end
        }
    
      end # => end of transaction
    } # => end of catch block
    
    #    ActiveRecord::Base.lock_optimistically = true
    
    return true
  end # => end of self.recover_pending_trash_operation sid
  
  def self.search_files_in_recycler(retrieve_sid, retrieve_file_key)
    # get uid
    my_uid = SessionManager.get_uid(retrieve_sid, true)
    search_files = Array.new
  
    # retreive_file_key is thrown file
    tn = SpinNode.readonly.select("virtual_path").find_by_spin_node_hashkey(retrieve_file_key)
    if tn.blank?
      return search_files
    end
    vp = tn[:virtual_path]
    #    vp.gsub!(/\'/,'\'\'')
    # serach recycler db for retrieve_file_key
    vpquery = sprintf("SELECT spin_node_hashkey,virtual_path FROM spin_nodes WHERE (virtual_path = \'%s\' OR left(virtual_path,%d) = \'%s/\') AND spin_tree_type = %d AND in_trash_flag = true AND is_void = false AND orphan = false ORDER BY node_type DESC,node_y_coord DESC,node_version ASC;",vp.gsub(/'/,'\'\''),vp.length + 1,vp.gsub(/'/,'\'\''),SPIN_NODE_VTREE)
    #    vpquery = "(virtual_path = \'#{vp.gsub(/'/,'\'\'')}\' OR left(virtual_path,#{vp.length + 1}) = \'#{vp.gsub(/'/,'\'\'')}/\') AND spin_tree_type = #{SPIN_NODE_VTREE} AND in_trash_flag = true AND is_void = false AND orphan = false"
    #    vpquery = "(virtual_path = \'#{vp}\' OR virtual_path LIKE \'#{vp}/%\') AND in_trash_flag = true AND is_void = false AND orphan = false"
    snodes = SpinNode.connection.select_all(vpquery)
    #    snodes = SpinNode.readonly.select("spin_node_hashkey,virtual_path").where("#{vpquery}").order( "node_type DESC,node_y_coord DESC,node_version ASC")
    FileManager.rails_logger("snodes.length = " + snodes.length.to_s)
    #    rfile = self.find(["spin_uid = ? AND spin_node_hashkey = ?",my_uid,retrieve_file_key])
    
    # return error unless rfile
    return search_files unless snodes.length > 0 # returns empty array
    
    #    # do recursive search if it is a directory
    #    if snodes[0][:node_type] != NODE_DIRECTORY
    #      snodes.each {|s|
    #        search_files.push(s[:spin_node_hashkey])
    #      }
    #      return search_files # => .push(rfile[:spin_node_hashkey]) # => return if it is a file
    #    end
    
    search_files = snodes.map {|x| x['spin_node_hashkey']}
    
    #    children_files = self.where(["spin_uid = ? AND node_x_pr_coord = ? AND node_y_coord = ?",my_uid,snodes[0][:node_x_coord],snodes[0][:node_y_coord]+1])
    #    children_files.each {|chf|
    #      if chf[:node_type] == NODE_DIRECTORY
    #        search_files += self.search_files_in_recycler(retrieve_sid, chf[:spin_node_hashkey])
    #      else
    #        search_files.push(chf[:spin_node_hashkey])
    #      end
    #    }
    
    return search_files
    
  end # => end of self.search_files_in_recycler(retrieve_sid, retf)

  def self.search_file_vpaths_in_recycler(retrieve_sid, retrieve_file_key)
    # get uid
    my_uid = SessionManager.get_uid(retrieve_sid, true)
  
    search_files = []
    # retreive_file_key is thrown file
    tn = SpinNode.readonly.select("virtual_path").find_by_spin_node_hashkey_and_in_trash_flag_and_is_void(retrieve_file_key, false)
    if tn.blank?
      return search_files
    end
    
    vp = tn[:virtual_path]
    #    vp.gsub!(/\'/,'\'\'')
    # serach recycler db for retrieve_file_key
    vpquery = sprintf("SELECT spin_node_hashkey,virtual_path,spin_uid FROM spin_nodes WHERE (virtual_path = \'%s\' OR left(virtual_path,%d) = \'%s/\') AND spin_tree_type = %d AND in_trash_flag = true AND is_void = false AND orphan = false ORDER BY node_type DESC,node_y_coord DESC,node_version ASC;",vp.gsub(/'/,'\'\''),vp.length + 1,vp.gsub(/'/,'\'\''),SPIN_NODE_VTREE)
    #    vpquery = "(virtual_path = \'#{vp.gsub(/'/,'\'\'')}\' OR left(virtual_path,#{vp.length + 1}) = \'#{vp.gsub(/'/,'\'\'')}/\') AND spin_tree_type = #{SPIN_NODE_VTREE} AND in_trash_flag = true AND is_void = false AND orphan = false"
    #    vpquery = "(virtual_path = \'#{vp}\' OR virtual_path LIKE \'#{vp}/%\') AND in_trash_flag = true AND is_void = false AND orphan = false"
    snodes = SpinNode.find_by_sql(vpquery)
    #    snodes = SpinNode.readonly.select("spin_node_hashkey,virtual_path").where("#{vpquery}").order( "node_type DESC,node_y_coord DESC,node_version ASC")
    FileManager.rails_logger("snodes.length = " + snodes.length.to_s)
    #    rfile = self.find(["spin_uid = ? AND spin_node_hashkey = ?",my_uid,retrieve_file_key])
    
    # return error unless rfile
    return search_files unless snodes.length > 0 # returns empty array
    
    #    # do recursive search if it is a directory
    #    if snodes[0][:node_type] != NODE_DIRECTORY
    #      snodes.each {|s|
    #        search_files.push(s[:spin_node_hashkey])
    #      }
    #      return search_files # => .push(rfile[:spin_node_hashkey]) # => return if it is a file
    #    end
    
    search_files = snodes.map {|x| { :vritual_path=>x['virtual_path'], :spin_node_hashkey=>x['spin_node_hashkey'], :spin_uid=>x['spin_uid'].to_i }}
    
    #    children_files = self.where(["spin_uid = ? AND node_x_pr_coord = ? AND node_y_coord = ?",my_uid,snodes[0][:node_x_coord],snodes[0][:node_y_coord]+1])
    #    children_files.each {|chf|
    #      if chf[:node_type] == NODE_DIRECTORY
    #        search_files += self.search_files_in_recycler(retrieve_sid, chf[:spin_node_hashkey])
    #      else
    #        search_files.push(chf[:spin_node_hashkey])
    #      end
    #    }
    
    return search_files
    
  end # => end of self.search_files_in_recycler(retrieve_sid, retf)
  
  def self.delete_node_from_recycler remove_sid, remove_file_key, async_mode = false
    # get uid and remove from recycler_data
    
    catch(:delete_node_from_recycler) {
      self.transaction do
        
        begin
          uid = SessionManager.get_uid remove_sid
          rms = self.where(["spin_uid = ? AND spin_node_hashkey = ?", uid, remove_file_key])
          rms.each {|r|
            r.destroy
          }
          ret = ''
          remove_node = SpinNode.find_by_spin_node_hashkey remove_file_key
          if async_mode == false
            remove_node[:in_use_uid] = uid
            remove_node[:in_trash_flag] = false
            remove_node[:is_pending] = false
            remove_node.save
            if remove_node[:node_type] != NODE_DIRECTORY or async_mode
              if SpinNode.delete_node(remove_sid,remove_file_key, true, false)
                ret = remove_file_key
              end
            else # => directory node
              #      retk = SpinNodeKeeper.delete_node_keeper_record(remove_node[:node_x_coord],remove_node[:node_y_coord])
              if SpinNode.delete_node(remove_sid,remove_file_key, true, true)
                ret = remove_file_key
              end
            end # => end of remove_node[:node_type] != NODE_DIRECTORY
          else # => async_mode == true
            
          end
        rescue ActiveRecord::StaleObjectError
          throw :delete_node_from_recycler
        end
      end # => end of transaction
    } # => end of catch block
    
    # remove node 
    return ret #  removed rec
  end # => end of self.delete_node_from_recycler remove_sid, rf
  
  def self.clear_trashed_nodes remove_sid, clear_uid = -1, clear_vpath = '', async_mode = false
    if remove_sid == nil or remove_sid.empty?
      return false
    end
    
    ret = false
    rm_count = 0
    #    ret = self.destroy_all :spin_uid => uid, :spin_node_hashkey => remove_file_key
    # set in_use_uid in spin_nodes rec
    
    rquery = 'in_trash_flag = true'
    unless clear_uid == -1
      rquery += ' AND spin_uid = ' + clear_uid.to_s
    end
    unless clear_vpath.empty?
      #      clear_vpath.gsub!(/\'/,'\'\'')
      rquery += ' AND virtual_path = \'' + clear_vpath.gsub(/\'/,'\'\'') + '\''
    end
    
    while true do
      remove_nodes = SpinNode.limit(1000).where("#{rquery}")

      #    return -1 unless remove_nodes.length > 0
      break unless remove_nodes.length > 0

      remove_nodes.each {|remove_node|
        #    nt = remove_node[:node_type]
        remove_file_key = remove_node[:spin_node_hashkey]

        if remove_node[:node_type] != NODE_DIRECTORY or async_mode
          fm_args = Array.new
          fm_args.append remove_file_key
          case ENV['RAILS_ENV']
          when 'development'
            $http_host = 'http://127.0.0.1/'
            retj = SpinFileManager.request remove_sid, 'remove_node', fm_args
            reth = JSON.parse retj
            if reth['success'] == true
              ret = SpinNode.delete_node(remove_sid, remove_file_key)
            else
              ret = nil
            end
            #      return remove_file_key
          when 'production'
            $http_host = 'http://127.0.0.1/'
            retj = SpinFileManager.request remove_sid, 'remove_node', fm_args
            reth = JSON.parse retj
            if reth['success']
              ret = SpinNode.delete_node(remove_sid, remove_file_key)
            else
              ret = nil
            end
          end
        else # => directory node
          ret = SpinNode.delete_node(remove_sid, remove_file_key)
        end # => end of remove_node[:node_type] != NODE_DIRECTORY
        if ret
          rm_count += 1
          acls = SpinAccessControl.remove_node_acls(remove_sid, remove_file_key)
        end
      } # => remove_nodes.each loop
    end # => end of while true loop
    # remove node 
    return rm_count #  removed rec
  end # => end of self.delete_node_from_recycler remove_sid, rf
  
end
