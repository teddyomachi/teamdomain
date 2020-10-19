# coding: utf-8
require 'const/vfs_const'
require 'const/acl_const'
require 'const/stat_const'
require 'utilities/image_utilities'

class ClipBoards < ActiveRecord::Base
  include Vfs
  include Acl
  include Stat
  
  # attr_accessor :title, :body
  
  def self.put_nodes operation_id, session_id, node_key_list, operation = OPERATION_COPY
    rethash = {}
    unless node_key_list.length > 0
      rethash[:success] = false
      rethash[:status] = ERROR_KEY_LIST_IS_EMPTY
      rethash[:errors] = 'No nodes are specified.'
      return rethash
    end
    # clear clibboard
    #    last_data = self.where(["session_id = ?",session_id])
    #    last_data.each {|l|
    #      l.destroy
    #    }
    put_count = 0
    directory_nodes = []
    node_key_list.each {|nk|
      next unless SpinNode.is_active_node(nk)
      if operation == OPERATION_CUT and SpinAccessControl.is_writable(session_id, nk, ANY_TYPE) != true
        rethash[:success] = false
        rethash[:status] = ERROR_FAILED_TO_MOVE_ORIGIN_NODE
        rethash[:errors] = '移動できないファイル／フォルダです'
        return rethash
      end
      next unless SpinAccessControl.is_readable(session_id, nk, ANY_TYPE)
      #        ClipBoard.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      #        SpinNode.set_pending(nk)
      nloc = SpinLocationManager.key_to_location(nk, ANY_TYPE)
      #      clip_data = self.find_by_nodex_and_nodey nloc[X], nloc[Y]
      clip_nodes = SpinNode.where(["spin_tree_type = 0 AND node_x_coord = ? AND node_y_coord = ?",nloc[X],nloc[Y]]).order("node_version ASC")
      clip_nodes.each {|cn|
        next unless SpinNode.is_active_node(cn[:spin_node_hashkey])
        retry_save_count = ACTIVE_RECORD_RETRY_COUNT
        catch(:clip_boards_put_nodes_again){
            
          ClipBoards.transaction do

            begin
              clip_data = self.find_by_session_id_and_nodex_and_nodey_and_nodev session_id, nloc[X], nloc[Y], cn[:node_version]
              if clip_data == nil
                clip_data = self.new
              end
              nk_node_type = ( SpinNode.is_directory(nk) ? NODE_DIRECTORY : NODE_FILE )
              clip_data[:session_id] = session_id
              clip_data[:nodex] = cn[:node_x_coord]
              clip_data[:nodey] = cn[:node_y_coord]
              clip_data[:nodeprx] = cn[:node_x_pr_coord]
              clip_data[:nodev] = cn[:node_version]
              clip_data[:nodet] = nk_node_type
              clip_data[:node_hash_key] = cn[:spin_node_hashkey]
              clip_data[:opr_id] = operation_id
              clip_data[:opr] = operation
              clip_data[:get_marker] = GET_MARKER_CLEAR
              clip_data[:parent_flg] = true
              if clip_data.save
                put_count += 1
              end
              if nk_node_type == NODE_DIRECTORY
                directory_nodes.push(nk)
              end
            rescue ActiveRecord::StaleObjectError
              retry_save_count -= 1
              if retry_save_count > 0
                throw :clip_borads_put_nodes_again
              else
                rethash[:success] = false
                rethash[:status] = ERROR_KEY_LIST_IS_EMPTY
                rethash[:errors] = 'Failed to save nodes in clipboard'
                return rethash
              end
            end
          end # => end of transaction
        }
      }
    }
    
    if directory_nodes.length > 0
      directory_nodes.each { |dn|
        rethash = self.put_directory_node operation_id, session_id, dn, operation
        if rethash[:success]
          put_count += rethash[:result]
        else
          return rethash # => error!
        end
      }
    end
    rethash[:success] = true
    rethash[:status] = INFO_PUT_NODES_INTO_CLIPBORD_SUCCESS
    rethash[:result] = put_count
    return rethash
  end # => end of put_nodes session_id, node_key_list, operation = OPERATION_COPY

  # => not used
  def self.put_node operation_id, session_id, node_key, operation = OPERATION_COPY
    nloc = SpinLocationManager.key_to_location(node_key, ANY_TYPE)
    clip_nodes = SpinNode.where(["spin_tree_type = 0 AND node_x_coord = ? AND node_y_coord = ? AND is_void = false AND in_trash_flag = false",nloc[X],nloc[Y]]).order("node_version ASC")
    clip_nodes.each {|cn|
      clip_data = self.find_by_session_id_and_nodex_and_nodey session_id, nloc[X], nloc[Y]
      if clip_data == nil
        clip_data = self.new
      end
      clip_data[:session_id] = session_id
      clip_data[:nodex] = cn[:node_x_coord]
      clip_data[:nodey] = cn[:node_y_coord]
      clip_data[:nodeprx] = cn[:node_x_pr_coord]
      clip_data[:nodev] = cn[:node_version]
      clip_data[:nodet] = cn[:node_type]
      clip_data[:node_hash_key] = cn[:spin_node_hashkey]
      clip_data[:opr_id] = operation_id
      clip_data[:opr] = operation
      unless clip_data.save
        return false
      end
    }
    return true
  end # => end of put_nodes session_id, node_key_list, operation = OPERATION_COPY
  
  def self.get_node operation_id, session_id, operation = OPERATION_COPY, get_marker_status = GET_MARKER_CLEAR
    marker_values = ''
    rethash = { :node_hash_key=>nil, :node_type=>ANY_TYPE }
    if (get_marker_status&GET_MARKER_SET) != 0 and (get_marker_status&GET_MARKER_PROCESSED) != 0
      marker_values = GET_MARKER_SET.to_s + ',' + GET_MARKER_PROCESSED.to_s
    else
      marker_values = get_marker_status.to_s
    end
    nodes = self.where(["opr_id = ? AND session_id = ? AND opr = ? AND get_marker IN (#{marker_values})", operation_id, session_id, operation]).order("nodey ASC,nodet ASC,nodex ASC,nodeprx ASC,nodev ASC")
    if nodes.blank?
      return rethash
    else
      node = nodes[0]
      node[:get_marker] = (get_marker_status|GET_MARKER_STATUS_DONE)
      if node.save
        rethash[:node_hash_key] = node[:node_hash_key]
        rethash[:node_type] = node[:nodet]
        return rethash
      else
        return rethash
      end
    end
  end # => end of put_nodes session_id, node_key_list, operation = OPERATION_COPY
    
  def self.put_directory_node operation_id, session_id, node_key, operation = OPERATION_COPY
    nloc = SpinLocationManager.key_to_location(node_key, ANY_TYPE)
    put_count = 0
    dir_files = []
    rethash = {}
    # get file list under this directory
    dir_files = SpinNode.readonly.where(["spin_tree_type = ? AND node_y_coord = ? AND node_x_pr_coord = ?",SPIN_NODE_VTREE, nloc[Y] + 1, nloc[X]]).order("node_name ASC, node_version ASC")
    if dir_files.length > 0
      last_node_name = ''
      dir_files.each { |df|
        next unless SpinNode.is_active_node(df[:spin_node_hashkey])
        next if df[:node_name] == last_node_name
        if operation == OPERATION_CUT and SpinAccessControl.is_writable(session_id, df[:spin_node_hashkey], ANY_TYPE) != true
          rethash[:success] = false
          rethash[:status] = ERROR_FAILED_TO_MOVE_ORIGIN_NODE
          rethash[:errors] = '移動できないフォルダがあります'
          return rethash
        end
        next unless SpinAccessControl.is_readable(session_id, df[:spin_node_hashkey], NODE_DIRECTORY)
        next if operation == OPERATION_CUT and SpinAccessControl.is_writable(session_id, df[:spin_node_hashkey], NODE_DIRECTORY) != true
        
        retry_save_count = ACTIVE_RECORD_RETRY_COUNT
        catch(:clip_boards_put_directory_node_again) {
          
          ClipBoards.transaction do
            begin
              #          ClipBoard.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
              #          SpinNode.set_pending(df[:spin_node_hashkey])
              clip_data = ClipBoards.new
              clip_data[:session_id] = session_id
              clip_data[:nodex] = df[:node_x_coord]
              clip_data[:nodey] = df[:node_y_coord]
              clip_data[:nodeprx] = df[:node_x_pr_coord]
              clip_data[:nodev] = df[:node_version]
              clip_data[:nodet] = df[:node_type]
              clip_data[:node_hash_key] = df[:spin_node_hashkey]
              clip_data[:opr_id] = operation_id
              clip_data[:opr] = operation
              clip_data.save
              put_count += 1
            rescue ActiveRecord::StaleObjectError
              retry_save_count -= 1
              if retry_save_count > 0
              else
                throw :clip_boards_put_directory_node_again
              end
            end
          end # => end of transaction
        } # => wend of catch block
        
        if SpinNode.is_directory(df[:spin_node_hashkey])
          rethash = self.put_directory_node operation_id, session_id, df[:spin_node_hashkey], operation
          unless rethash[:success]
            return rethash
          end
          put_count += rethash[:result]
        end
      }
    end
    rethash[:success] = true
    rethash[:status] = INFO_PUT_NODES_INTO_CLIPBORD_SUCCESS
    rethash[:result] = put_count
    return rethash
  end # => end of put_nodes session_id, node_key_list, operation = OPERATION_COPY
  
  def self.remove_nodes session_id, node_key_list = nil
    remove_count = 0

    retry_count = ACTIVE_RECORD_RETRY_COUNT
    catch(:clip_boards_remove_nodes_again) {
      self.transaction do
        begin
          if node_key_list.blank?
            rmnodes = self.where(["session_id = ?",session_id])
            remove_count = rmnodes.length
            unless rmnodes.destroy_all
              return 0
            end
          else
            node_key_list.each {|nk|
              rmnode = self.find_by_session_id_and_node_hash_key session_id, nk
              if rmnode.destroy
                remove_count += 1
              end
            }
          end
        rescue ActiveRecord::StaleObjectError
          retry_count -= 1
          if retry_count > 0
            throw :clip_boards_remove_nodes_again
          else
            return 0
          end
          
        end
      end
    }
    return remove_count
  end # => end of remove_nodes session_id, node_key_list

  def self.set_operation_completed opr_id, sid, operation_type, node_key, new_node_key
    
    retry_count = ACTIVE_RECORD_RETRY_COUNT
    catch(:set_operation_completed_again) {
      self.transaction do
        begin
          rec = self.find_by_opr_id_and_session_id_and_node_hash_key opr_id, sid, node_key
    
          case operation_type
          when OPERATION_CUT
            #      SpinNode.delete_node(sid, node_key, true)
            SpinNode.set_active(new_node_key)
            FolderDatum.remove_folder_rec(sid, LOCATION_ANY, node_key)
            FileDatum.remove_file_rec(sid, LOCATION_ANY, node_key)
          when OPERATION_COPY
            SpinNode.set_active(new_node_key)
          else
            SpinNode.set_active(new_node_key)
          end
          if rec.present?
            rec[:opr_complete] = true
            rec[:get_marker] = GET_MARKER_COMPLETED
            rec.save
          end
        rescue ActiveRecord::StaleObjectError
          retry_count -= 1
          if retry_count > 0
            throw :set_operation_completed_again
          else
            emsg = 'set_operation_completed : StaleObjectError'
            Rails.logger(emsg)
            return false
          end
        end
      end # => end of transaction
    }
    return true
  end # => end of self.set_operation_completed move_sid, mvf
  
  def self.rollback_operation opr_id, sid, operation_type, node_key
    retry_count = ACTIVE_RECORD_RETRY_COUNT
    catch(:rollback_operation_again) {
      self.transaction do
        begin
          rec = self.find_by_opr_id_and_session_id_and_node_hash_key opr_id, sid, node_key
    
          if rec.present?
            rec[:opr_complete] = true
            if rec.save == true
              return true
            else
              return false
            end
          end
        rescue ActiveRecord::StaleObjectError
          retry_count -= 1
          if retry_count > 0
            throw :rollback_operation_again
          else
            emsg = 'rollback_operation : StaleObjectError'
            Rails.logger(emsg)
            return false
          end
        end
      end # => end of transaction
    }
  end # => end of self.rollback_operation move_sid, mvf
  
  def self.set_operation_processed opr_id, sid, operation_type, node_key
    rec = self.find_by_opr_id_and_session_id_and_node_hash_key opr_id, sid, node_key
    
    if rec.blank?
      return false
    end

    retry_count = ACTIVE_RECORD_RETRY_COUNT
    catch(:set_operation_processed_again) {
      self.transaction do
        begin
          case operation_type
          when OPERATION_CUT
            rec[:get_marker] = GET_MARKER_PROCESSED
            if rec.save
              return rec[:node_hash_key]
            else
              return nil
            end
          when OPERATION_COPY
            rec[:get_marker] = GET_MARKER_PROCESSED
            if rec.save
              return rec[:node_hash_key]
            else
              return nil
            end
          else
            rec[:get_marker] = GET_MARKER_PROCESSED
            if rec.save
              return rec[:node_hash_key]
            else
              return nil
            end
          end    
        rescue ActiveRecord::StaleObjectError
          retry_count -= 1
          if retry_count > 0
            throw :set_operation_processed_again
          else
            emsg = 'set_operation_processed : StaleObjectError'
            Rails.logger(emsg)
            return nil
          end
        end
      end # => end of transaction
    }
  end # => end of self.set_operation_completed move_sid, mvf
  
  def self.get_files_in_folder_loc sid, location
    fl = self.readonly.where(["session_id = ? AND nodey = ? AND nodeprx = ? AND opr_complete = false",sid,location[Y]+1,location[X]])
    return fl
  end # => end of self.get_files_in_folder_loc move_sid, my_loc
  
  def self.get_keys_in_folder_loc sid, location
    fl = self.readonly.where(["session_id = ? AND nodey = ? AND nodeprx = ? AND opr_complete = false",sid,location[Y]+1,location[X]])
    keys = []
    fl.each {|f|
      keys.push f[:node_hash_key]
    }
    return keys
  end # => end of self.get_files_in_folder_loc move_sid, my_loc
    
  def self.get_clipboards_display_data sid, offset = DEFAULT_OFFSET, limit = DEFAULT_PAGE_SIZE
    n_clip = ClipBoards.limit(limit).offset(offset).where(["session_id = ? AND parent_flg = true", sid])
    total = n_clip.count
    
    clip_list = []
    
    n_clip.each {|cll|
      cl = {}
      cll.attributes.each { |key,value|
        cl[key] = value
      }
      
      if cl["opr"] == OPERATION_COPY
        cl["opr_disp"] = 'コピー'
      else
        cl["opr_disp"] = 'カット'
      end
      
      cp_node = SpinNode.find_by_spin_node_hashkey cl["node_hash_key"]
      if cp_node[:node_type] == 1
        # フォルダ
        #        n_disp = FolderDatum.find(:first, :conditions=>["session_id = ? AND spin_node_hashkey = ?",sid,cl[:node_hash_key]]);
        #        if n_disp
        cl["hash_key"] = cp_node[:spin_node_hashkey]
        cl["cont_location"] = 'folder_a'
        cl["file_name"] = cp_node[:node_name]
        cl["file_type"] = 'folder'
        cl["file_size"] = ''
        cl["file_size_upper"] = ''
        cl["url"] = ''
        #        end
      else
        # ファイル
        #        n_disp = FileDatum.find(:first, :conditions=>["session_id = ? AND spin_node_hashkey = ?",sid,cl[:node_hash_key]]);
        #        if n_disp
        cl["hash_key"] = cp_node[:spin_node_hashkey]
        cl["cont_location"] = 'folder_a'
        cl["file_name"] = cp_node[:node_name]
        cl["file_type"] = 'file'
        cl["file_size"] = cp_node[:node_size]
        cl["file_size_upper"] = cp_node[:node_size_upper]
        cl["url"] = cp_node[:spin_url]
        #        end
      end
      clip_list.push(cl)
    }

    return { :success => true, :total => total, :clipboards => clip_list }
  end # => end of get_clipboard_display_data

  def self.clear_nodes_all sid
    retry_count = ACTIVE_RECORD_RETRY_COUNT
    catch(:clip_boards_clear_nodes_all_again) {
      self.transaction do
        begin
          cns = self.where(["session_id = ?",sid])
          cns.each {|r|
            r.destroy
          }
        rescue ActiveRecord::StaleObjectError
          retry_count -= 1
          if retry_count > 0
            throw :clip_boards_clear_nodes_all_again
          else
            return { :success => false }
          end
        end
      end
    }
    
    return { :success => true }
  end # => end of get_clipboard_display_data

  def self.clear_nodes_hashkey sid, node_hash_key
    
    retry_count = ACTIVE_RECORD_RETRY_COUNT
    catch(:clip_boards_clear_nodes_hashkey_again) {
      self.transaction do
        begin
          cns = self.where(["session_id = ? AND node_hash_key = ?", sid, node_hash_key])
          cns.each {|r|
            r.destroy
          }
        rescue ActiveRecord::StaleObjectError
          retry_count -= 1
          if retry_count > 0
            throw :clip_boards_clear_nodes_hashkey_again
          else
            return { :success => false }
          end
        end
      end
    }
    
    return { :success => true }
  end # => end of get_clipboard_display_data

  
end
