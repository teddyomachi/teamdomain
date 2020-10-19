# coding: utf-8
require 'pg'
require 'const/vfs_const'
require 'const/acl_const'
require 'const/stat_const'
require 'tasks/security'
require 'utilities/file_manager_utilities'

module SpinFileManager
  
  include Vfs
  include Acl
  include Stat
  include FileManager
  
  # node management
  def create_node( sid, x, y, z, v, type, name, my_storage )
    # check spin-node table if there already is another node
    my_hashkey = Security.hash_key x, y, z, v
    ne = SpinNode.find_by_spin_node_hashkey my_hashkey
    # Is there a node?
    if ne.present?
      return ne
    else
      # create new node
      new_node = SpinNode.new
      # assign values
      new_node.node_hashkey = my_hashkey        # => hashkey : identifier string
      new_node.storage_id = my_storage          # => storage id : integer
      new_node.node_x_coord = x                 # => x coord value of the node
      new_node.node_y_coord = y                 # => y coord value of the node
      new_node.node_x_pr_coord = z              # => x coord value of the @arent node
      new_node.node_type = type                 # => { file, directory, symbolic link }
      new_node.node_name = name                 # => node name, may be file or directory or symlink
      new_node.node_version = 1                 # => version number starts at 1
      new_node.node_created_date = Time.now
      new_node.node_modified_date = Time.now
      new_node.spin_updated_at = Time.now
      new_node.node_in_trash_flag = false       # => not in trash
      new_node.node_is_dirty_flag = false       # =>  not dirty because there isn't real file. this is mata data.
      new_node.node_is_under_maintenance = true # => is under construction because tehre isn't real file yet!      
      new_node.node_in_use_uid = 0              # => root user
      # save in the spin_nodes table            
      new_node.save
    end          
  end

  def add_node( sid, x, y, z, v, type, name )
  end
  
  def self.request sid, fm_request, fm_args, fm_server_params = nil
    # buid request params hash
    request_params = { :session_id => sid, :request => fm_request, :params => fm_args }
    
    if fm_request == 'remove_node'
      # => fm_args is an array of hash keys of nodes to be removed
      if fm_args.count > 0
        fm_args.each {|node_key|
          SpinNode.set_void(node_key)
        }
      end
      
      void_nodes = SpinNode.readonly.where(["is_void = true"])
      if void_nodes.count > MAX_REMOVE_QUEUE_COUNT
        request_params = { :session_id => sid, :request => 'remove_void_nodes', :params => [] }
        resp = FileManager.post_request request_params, fm_server_params
      else
        resp = {}
        resp[:success] = true
        resp[:status] = INFO_REMOVE_NODE_REQUEST_ACCEPTED # => 1076
        resp[:result] = fm_args
        return resp
      end
    elsif fm_request == 'remove_thumbnail'
      if fm_args.count > 0
        fm_args.each {|node_key|
          SpinNode.set_void(node_key)
        }
      end
      
      void_nodes = SpinNode.readonly.where(["is_void = true"])
      if void_nodes.count > MAX_REMOVE_QUEUE_COUNT
        request_params = { :session_id => sid, :request => 'remove_void_thumbnails', :params => [] }
        resp = FileManager.post_request request_params, fm_server_params
      else
        resp = {}
        resp[:success] = true
        resp[:status] = INFO_REMOVE_NODE_REQUEST_ACCEPTED # => 1076
        resp[:result] = fm_args
        return resp
      end
    else # => remove_node request
      resp = FileManager.post_request request_params, fm_server_params
      return resp
    end
  end # => end of self.file_manager_request
  
  def self.remove_node sid, node_hash_key
    # Does this user has acl to remove node?
    acls = SpinAccessControl.has_acl_values sid, node_hash_key, ANY_TYPE
    if acls[:user] >= ACL_NODE_WRITE or acls[:group] >= ACL_NODE_WRITE  or acls[:world] >= ACL_NODE_WRITE # => match!
      pp 'Here is!'
      # ask FileManager to remove real file of he has one
      ret = FileManager.request_remove_node sid, 'remove_node', node_hash_key
      # then do remove it with spin access controll record  
      return ret  
    end
     
  end # => end of self.remove_node sid, node_hassh_key

end # => end of module SpinFileManager
