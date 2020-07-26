## coding: utf-8
#require 'const/vfs_const'
#require 'const/acl_const'
#require 'const/spin_types'
#require 'utilities/set_utilities'
#
#class SpinGroupAccessControl < ActiveRecord::Base
#  include Vfs
#  include Acl
#  include Types
#  
#  ID_NOT_SET = -1
#  # # constants internal
#  # X = 0         # => position of X coordinate value 
#  # Y = 1         # => position of Y coordinate value
#  # PRX = 2       # => position of prX coordinate value
#  # V = 3         # => position of V coordinate value
#  # HASHKEY = 4   # => spin_node_hashkey
#  #     
#  # # node value indicates no directory
#  # [-1,-1,-1,-1,nil] = [-1,-1,-1,-1,nil]
#  
#  # for test
#  # ADMIN_SESSION_ID = "_special_administrator_session"
#  
#  # # flag to indicate that it is a hard link
#  # LINKED_NODE_FLAG = 32768      # => 17th bit is 1 
#  #   
#  # attr_accessor :title, :body
#  attr_accessor :spin_node_hashkey, :spin_uid, :spin_uid_access_right, :spin_gid, :managed_node_hashkey, :created_at, :updated_at, :spin_node_type
#  
#  def self.set_folder_privilege sid, privileges, groups
#    #      privileges[:folder_name] = paramshash[:text]
#    #      privileges[:folder_hashkey] = paramshash[:hash_key]
#    #      privileges[:target] = paramshash[:target]
#    #      privileges[:range] = paramshash[:range]
#    #      privileges[:owner] = paramshash[:owner]
#    #      privileges[:other_writable] = paramshash[:other_writable] # => boolean
#    #      privileges[:other_readable] = paramshash[:other_readable] # => boolean
#    #      privileges[:group_writable] = paramshash[:group_writable] # => boolean
#    #      privileges[:group_readable] = paramshash[:group_readable] # => boolean
#    #      privileges[:group_editable] = paramshash[:group_editable] # => boolean
#    # set privilege to nodes and access controls for each group
#    recs = 0
#    node = {}
#    gacl = 0
#    wacl = 0
#    self.transaction do
#      node = SpinNode.find_by_spin_node_hashkey privileges[:folder_hashkey]
#      gacl = ((privileges[:group_readable] ? ACL_NODE_READ : ACL_NODE_NO_ACCESS ) | (privileges[:group_writable] ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS ) | (privileges[:group_editable] ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS ))
#      wacl = ((privileges[:other_readable] ? ACL_NODE_READ : ACL_NODE_NO_ACCESS ) | (privileges[:other_writable] ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS ))
#      node.spin_world_access_right = wacl
#      if self.is_controlable sid, node[:spin_node_hashkey], NODE_DIRECTORY
#        node.spin_gid_access_right = gacl
#      end
#      node.save
#    end
#    self.set_groups_access_control gacl, privileges[:folder_hashkey], groups
#    # check range
#    sub_folders = Array.new
#    my_file_list = Array.new
#    case privileges[:range]
#    when 'all_folders' # => this and sub folders
#      sub_folders =  SpinLocationManager.list_files sid, node[:spin_node_hashkey], NODE_DIRECTORY, true
#      if sub_folders.length > 0
#        # go through sub_folders
#        sub_folders.each {|subf|
#          self.transaction do
#            sub_node = SpinNode.find_by_spin_node_hashkey subf[:node_key]
#            sub_node.spin_world_access_right = wacl
#            if self.is_controlable sid, sub_node[:spin_node_hashkey], NODE_DIRECTORY
#              sub_node.spin_gid_access_right = gacl
#            end
#            sub_node.save
#          end
#          recs += self.set_groups_access_control gacl, subf[:node_key], groups
#          # check target and set privilege
#          my_file_list = Array.new
#          case privileges[:target]
#            #          when "folder_file" # => folders and files
#            #            my_file_list = SpinLocationManager.list_files sid, subf[:node_key], ANY_TYPE
#          when "file" # => files only
#            my_file_list = SpinLocationManager.list_files sid, subf[:node_key], NODE_FILE
#            #          when "folder" # => folders only
#            #            my_file_list = SpinLocationManager.list_files sid, subf[:node_key], NODE_DIRECTORY
#          else
#            my_file_list = SpinLocationManager.list_files sid, subf[:node_key], NODE_FILE
#          end
#          if my_file_list.length > 0
#            self.transaction do
#              my_file_list.each {|f|
#                fn = SpinNode.find_by_spin_node_hashkey f[:node_key]
#                fn.spin_world_access_right = wacl
#                if self.is_controlable sid, fn[:spin_node_hashkey], NODE_FILE
#                  fn.spin_gid_access_right = gacl
#                end
#                fn.save
#                recs += self.set_groups_access_control gacl, f[:node_key], groups
#              }
#            end
#          end
#        }
#      end
#    when 'folder' # => this folder only
#      pp "nop"
#    else # => files in this folder
#      # check target and set privilege
#      case privileges[:target]
#      when "folder_file" # => folders and files
#        my_file_list = SpinLocationManager.list_files sid, node[:spin_node_hashkey], ANY_TYPE
#      when "file" # => files only
#        my_file_list = SpinLocationManager.list_files sid, node[:spin_node_hashkey], NODE_FILE
#      when "folder" # => folders only
#        my_file_list = SpinLocationManager.list_files sid, node[:spin_node_hashkey], NODE_DIRECTORY
#      else
#        my_file_list = SpinLocationManager.list_files sid, node[:spin_node_hashkey], ANY_TYPE
#      end
#      if my_file_list.length > 0
#        my_file_list.each {|f|
#          self.transaction do
#            fn = SpinNode.find_by_spin_node_hashkey f[:node_key]
#            fn.spin_world_access_right = wacl
#            if self.is_controlable sid, fn[:spin_node_hashkey], ANY_TYPE
#              fn.spin_gid_access_right = gacl
#            end
#            fn.save
#          end
#          recs += self.set_groups_access_control gacl, f[:node_key], groups
#        }
#      end
#    end # => end of case privilege[:range]
#    SpinNode.has_updated( SpinLocationManager.get_parent_key privileges[:folder_hashkey], ANY_TYPE )
#    return recs
#    
#  end # =>  end of set_privilege privileges
#
#  def self.set_file_privilege sid, privileges, groups
#    #      privileges[:folder_name] = paramshash[:text]
#    #      privileges[:folder_hashkey] = paramshash[:hash_key]
#    #      privileges[:target] = paramshash[:target]
#    #      privileges[:range] = paramshash[:range]
#    #      privileges[:owner] = paramshash[:owner]
#    #      privileges[:other_writable] = paramshash[:other_writable] # => boolean
#    #      privileges[:other_readable] = paramshash[:other_readable] # => boolean
#    #      privileges[:group_writable] = paramshash[:group_writable] # => boolean
#    #      privileges[:group_readable] = paramshash[:group_readable] # => boolean
#    #      privileges[:group_editable] = paramshash[:group_editable] # => boolean
#    # set privilege to nodes and access controls for each group
#    recs = 0
#    gacl = 0
#    wacl = 0
#    self.transaction do
#      node = SpinNode.find_by_spin_node_hashkey privileges[:file_hashkey]
#      gacl = ((privileges[:group_readable] ? ACL_NODE_READ : ACL_NODE_NO_ACCESS ) | (privileges[:group_writable] ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS ) | (privileges[:group_editable] ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS ))
#      wacl = ((privileges[:other_readable] ? ACL_NODE_READ : ACL_NODE_NO_ACCESS ) | (privileges[:other_writable] ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS ))
#      node.spin_world_access_right = wacl
#      if self.is_controlable sid, node[:spin_node_hashkey], NODE_DIRECTORY
#        node.spin_gid_access_right = gacl
#      end
#      node.save
#    end
#    recs += 1
#    recs += self.set_groups_access_control gacl, privileges[:file_hashkey], groups
#    SpinNode.has_updated( SpinLocationManager.get_parent_key privileges[:file_hashkey], ANY_TYPE )
#    return recs
#    
#  end # =>  end of set_privilege privileges
#
#  def self.add_user_access_control node_hashkey, user_acl, spin_uid
#    # first : get record which has spin_uid value
#    my_acl = SpinAccessControl.where :spin_uid => spin_uid
#    if my_acl.count
#      self.transaction do
#        my_acl.each { |a|
#          a[:spin_uid_access_right] = user_acl
#          a.save
#        } 
#      end
#      return true
#    end
#    
#    # get records which has not used spin_uid(-1) field
#    no_user_acl = SpinAccessControl.where :spin_uid => ID_NOT_SET
#    if no_user_acl.count
#      self.transaction do
#        no_user_acl.each { |a|
#          a[:spin_uid] = spin_uid
#          a[:spin_uid_access_right] = user_acl
#          a[:updated_at] = Time.now
#          a.save
#          break
#        }
#      end
#      return true
#    end
#    
#    # create new record
#    # set spin_access_contrtol
#    self.transaction do
#      new_acl = SpinAccessControl.new
#      new_acl.spin_uid = spin_uid
#      new_acl.spin_uid_access_right = user_acl
#      new_acl.spin_world_access_right = 0
#      r = Random.new
#      new_acl.spin_node_hashkey = Security.hash_key_s node_hashkey + r.rand.to_s
#      new_acl.managed_node_hashkey = node_hashkey
#      new_acl.created_at = Time.now
#      new_acl.updated_at = Time.now
#      new_acl.save
#    end
#    return true    
#  end
#
#  def self.add_groups_access_control node_hashkey, gacl, groups
#    # first : get record which has spin_gid values
#    acl_records = 0
#    # for groups in array 'groups'
#    groups.each {|g|
#      # analyze group
#      # it may be a member of the group
#      # we use member's primary group ( group assigned at user registration ) if it is
#      my_acl = nil
#      my_group = nil
#      primary_group = -1
#      if g[:member_id] != nil
#        primary_group = SpinUser.get_primary_group g[:member_id]
#        self.transaction do
#          my_acl = SpinAccessControl.where( :spin_gid => primary_group,:managed_node_hashkey => node_hashkey ).first
#        end
#      else
#        self.transaction do
#          my_group = SpinGroup.select("spin_gid").where(:spin_group_name => g[:group_name]).first
#          my_acl = SpinAccessControl.where( :spin_gid => my_group[:spin_gid],:managed_node_hashkey => node_hashkey ).first
#        end
#      end
#      if my_acl
#        gacl_str = g[:group_privilege]
#        gacl = ((gacl_str[0] == 'r' ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (gacl_str[1] == 'w' ? ACL_NODE_WRITE : ACL_NODE_NO_ACCESS) | (gacl_str[2] == 'a' ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
#        my_acl[:spin_gid_access_right] |= gacl
#      else
#        # get records which has not used spin_gid(-1) field
#        self.transaction do
#          my_acl = SpinAccessControl.where( :managed_node_hashkey => node_hashkey, :spin_gid => ID_NOT_SET ).first
#          if my_acl
#            gacl_str = g[:group_privilege]
#            gacl = ((gacl_str[0] == 'r' ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (gacl_str[1] == 'w' ? ACL_NODE_WRITE : ACL_NODE_NO_ACCESS) | (gacl_str[2] == 'a' ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
#            my_acl[:spin_gid_access_right] = gacl
#            my_acl[:spin_gid] = my_group[:spin_gid]
#          else
#            # create new record
#            my_acl = SpinAccessControl.new
#            # set spin_access_contrtol
#            #          gacl_str = g[:group_privilege]
#            #          gacl = ((gacl_str[0] == 'r' ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (gacl_str[1] == 'w' ? ACL_NODE_WRITE : ACL_NODE_NO_ACCESS) | (gacl_str[2] == 'a' ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
#            my_acl[:spin_gid_access_right] = gacl
#            my_acl[:spin_gid] = (my_group == nil ? primary_group : my_group[:spin_gid])
#            my_acl.spin_uid = ID_NOT_SET
#            my_acl.spin_uid_access_right = ACL_NODE_NO_ACCESS
#            my_acl.spin_world_access_right = ACL_NODE_NO_ACCESS
#            r = Random.new
#            my_acl.spin_node_hashkey = Security.hash_key_s node_hashkey + r.rand.to_s
#            my_acl.managed_node_hashkey = node_hashkey
#            my_acl.created_at = Time.now
#            #          my_acl.updated_at = Time.now
#          end
#          if my_acl.save
#            acl_records += 1
#          end
#        end
#      end
#    } # => end of group   
#    return acl_records
#  end # => end of add_groups_access_control node_hashkey, groups
#
#  #  def self.add_groups_access_control gacl, node_hashkey, groups
#  #    # first : get record which has spin_gid values
#  #    acl_records = 0
#  #    # for groups in array 'groups'
#  #    groups.each {|g|
#  #      # analyze group
#  #      # it may be a member of the group
#  #      # we use member's primary group ( group assigned at user registration ) if it is
#  #      my_acl = nil
#  #      my_group = nil
#  #      primary_group = -1
#  #      if g[:member_id] != nil
#  #        primary_group = SpinUser.get_primary_group g[:member_id]
#  #        my_acl = SpinAccessControl.where( :spin_gid => primary_group,:managed_node_hashkey => node_hashkey ).first
#  #      else
#  #        my_group = SpinGroup.select("spin_gid").where(:spin_group_name => g[:group_name]).first
#  #        my_acl = SpinAccessControl.where( :spin_gid => my_group[:spin_gid],:managed_node_hashkey => node_hashkey ).first
#  #      end
#  #      if my_acl
#  #        gacl_str = g[:group_privilege]
#  #        gacl = ((gacl_str[0] == 'r' ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (gacl_str[1] == 'w' ? ACL_NODE_WRITE : ACL_NODE_NO_ACCESS) | (gacl_str[2] == 'a' ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
#  #        my_acl[:spin_gid_access_right] |= gacl
#  #      else
#  #        # get records which has not used spin_gid(-1) field
#  #        my_acl = SpinAccessControl.where( :managed_node_hashkey => node_hashkey, :spin_gid => ID_NOT_SET ).first
#  #        if my_acl
#  #          gacl_str = g[:group_privilege]
#  #          gacl = ((gacl_str[0] == 'r' ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (gacl_str[1] == 'w' ? ACL_NODE_WRITE : ACL_NODE_NO_ACCESS) | (gacl_str[2] == 'a' ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
#  #          my_acl[:spin_gid_access_right] = gacl
#  #          my_acl[:spin_gid] = my_group[:spin_gid]
#  #        else
#  #          # create new record
#  #          my_acl = SpinAccessControl.new
#  #          # set spin_access_contrtol
#  ##          gacl_str = g[:group_privilege]
#  ##          gacl = ((gacl_str[0] == 'r' ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (gacl_str[1] == 'w' ? ACL_NODE_WRITE : ACL_NODE_NO_ACCESS) | (gacl_str[2] == 'a' ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
#  #          my_acl[:spin_gid_access_right] = gacl
#  #          my_acl[:spin_gid] = (my_group == nil ? primary_group : my_group[:spin_gid])
#  #          my_acl.spin_uid = ID_NOT_SET
#  #          my_acl.spin_uid_access_right = ACL_NODE_NO_ACCESS
#  #          my_acl.spin_world_access_right = ACL_NODE_NO_ACCESS
#  #          my_acl.spin_node_hashkey = Security.hash_key_s node_hashkey + r.rand.to_s
#  #          my_acl.managed_node_hashkey = node_hashkey
#  #          my_acl.created_at = Time.now
#  ##          my_acl.updated_at = Time.now
#  #        end
#  #      end
#  #      if my_acl.save
#  #        acl_records += 1
#  #      end
#  #    } # => end of group   
#  #    return acl_records
#  #  end # => end of add_groups_access_control node_hashkey, groups
#
#  def self.set_groups_access_control gacl, node_hashkey, groups
#    # first : get record which has spin_gid values
#    acl_records = 0
#    # for groups in array 'groups'
#    groups.each {|g|
#      # analyze group
#      # it may be a member of the group
#      # we use member's primary group ( group assigned at user registration ) if it is
#      my_acls = []
#      my_group = {}
#      primary_group = -1
#      if g[:member_id] != ""
#        primary_group = SpinUser.get_primary_group g[:member_id]
#        my_group[:spin_gid] = primary_group
#        self.transaction do
#          my_acls = SpinAccessControl.where( :spin_gid => primary_group,:managed_node_hashkey => node_hashkey ).first
#        end
#      else
#        self.transaction do
#          my_group = SpinGroup.select("spin_gid").where(:spin_group_name => g[:group_name]).first
#          my_acls = SpinAccessControl.where( :spin_gid => my_group[:spin_gid],:managed_node_hashkey => node_hashkey ).first
#        end
#      end
#      my_acls.each { |my_acl|
#        self.transaction do
#          if my_acl
#            my_acl[:spin_gid_access_right] = gacl
#            my_acl[:spin_gid] = my_group[:spin_gid]
#          else
#            # create new record
#            my_acl = SpinAccessControl.new
#            # set spin_access_contrtol
#            #          gacl_str = g[:group_privilege]
#            #          gacl = ((gacl_str[0] == 'r' ? ACL_NODE_READ : ACL_NODE_NO_ACCESS) | (gacl_str[1] == 'w' ? ACL_NODE_WRITE : ACL_NODE_NO_ACCESS) | (gacl_str[2] == 'a' ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS))
#            my_acl[:spin_gid_access_right] = gacl
#            my_acl[:spin_gid] = (my_group == nil ? primary_group : my_group[:spin_gid])
#            my_acl[:spin_uid] = ID_NOT_SET
#            my_acl[:spin_uid_access_right] = ACL_NODE_NO_ACCESS
#            my_acl[:spin_world_access_right] = ACL_NODE_NO_ACCESS
#            r = Random.new
#            my_acl[:spin_node_hashkey] = Security.hash_key_s node_hashkey + r.rand.to_s
#            my_acl[:managed_node_hashkey] = node_hashkey
#            my_acl[:created_at] = Time.now
#            my_acl[:px] = my_acl[:px]
#            my_acl[:py] = my_acl[:py]
#            my_acl[:ppx] = my_acl[:ppx]
#            #          my_acl.updated_at = Time.now
#          end
#          if my_acl.save
#            acl_records += 1
#          end
#        end
#      }
#    } # => end of group   
#    return acl_records
#  end # => end of set_groups_access_control node_hashkey, groups
#
#  def self.set_group_access_control node_hashkey, gid, priv
#    # first : get record which has spin_gid values
#    self.transaction do
#      my_acl = SpinAccessControl.find_by_spin_gid gid
#      if my_acl == nil
#        # get records which has not used spin_gid(-1) field
#        my_acl = SpinAccessControl.where( :spin_gid => ID_NOT_SET ).first
#        if my_acl == nil
#          # create new record
#          self.transaction do
#            my_acl = SpinAccessControl.new
#            # set spin_access_contrtol
#            my_acl.spin_uid = ID_NOT_SET
#            my_acl.spin_uid_access_right = ACL_NODE_NO_ACCESS
#            my_acl.spin_world_access_right = ACL_NODE_NO_ACCESS
#            r = Random.new
#            my_acl.spin_node_hashkey = Security.hash_key_s node_hashkey + r.rand.to_s
#            my_acl.managed_node_hashkey = node_hashkey
#            my_acl.created_at = Time.now
#            my_acl.updated_at = Time.now
#            my_acl[:spin_gid_access_right] = priv
#            my_acl.save
#          end
#          return true
#        else
#          my_acl[:spin_gid_access_right] = priv
#          if my_acl.save
#            return true
#          else
#            return false
#          end    
#        end
#      else
#        my_acl[:spin_gid_access_right] = priv
#        if my_acl.save
#          return true
#        else
#          return false
#        end    
#      end
#    end
#  end # => end of set_group_access_control node_hashkey, group
#
#  def self.remove_groups_access_control gacl, node_hashkey, groups
#    # first : get record which has spin_gid values
#    acl_records = 0
#    # for groups in array 'groups'
#    groups.each {|g|
#      # analyze group
#      # it may be a member of the group
#      # we use member's primary group ( group assigned at user registration ) if it is
#      my_acl = nil
#      my_group = nil
#      primary_group = -1
#      if g[:member_id]
#        primary_group = SpinUser.get_primary_group g[:member_id]
#        self.transaction do
#          my_acl = SpinAccessControl.where( :spin_gid => primary_group,:managed_node_hashkey => node_hashkey )
#        end
#      else
#        self.transaction do
#          my_group = SpinGroup.select("spin_gid").where(:spin_group_name => g[:group_name]).first
#          my_acl = SpinAccessControl.where( :spin_gid => my_group[:spin_gid],:managed_node_hashkey => node_hashkey )
#        end
#      end
#      r = my_acl.length
#      if r > 0
#        self.transaction do
#          my_acl.each {|a|
#            a.destroy
#          }
##          my_acl.destroy_all
#          acl_records += r
#        end
#      end
#    } # => end of group
#    return acl_records
#  end # => end of add_groups_access_control node_hashkey, groups
#
#  def self.remove_folder_privilege sid, privileges, groups
#    #      privileges[:folder_name] = paramshash[:text]
#    #      privileges[:folder_hashkey] = paramshash[:hash_key]
#    #      privileges[:target] = paramshash[:target]
#    #      privileges[:range] = paramshash[:range]
#    #      privileges[:owner] = paramshash[:owner]
#    #      privileges[:other_writable] = paramshash[:other_writable] # => boolean
#    #      privileges[:other_readable] = paramshash[:other_readable] # => boolean
#    #      privileges[:group_writable] = paramshash[:group_writable] # => boolean
#    #      privileges[:group_readable] = paramshash[:group_readable] # => boolean
#    #      privileges[:group_editable] = paramshash[:group_editable] # => boolean
#    # set privilege to nodes and access controls for each group
#    recs = 0
#    node = {}
#    gacl = 0
#    wacl = 0
#    self.transaction do
#      node = SpinNode.find_by_spin_node_hashkey privileges[:folder_hashkey]
#      gacl = ((privileges[:group_readable] ? ACL_NODE_READ : ACL_NODE_NO_ACCESS ) | (privileges[:group_writable] ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS ) | (privileges[:group_editable] ? ACL_NODE_CONTROL : ACL_NODE_NO_ACCESS ))
#      wacl = ((privileges[:other_readable] ? ACL_NODE_READ : ACL_NODE_NO_ACCESS ) | (privileges[:other_writable] ? (ACL_NODE_WRITE | ACL_NODE_DELETE) : ACL_NODE_NO_ACCESS ))
#      node.spin_world_access_right = wacl
#      if self.is_controlable sid, node[:spin_node_hashkey], NODE_DIRECTORY
#        node.spin_gid_access_right = gacl
#      end
#      node.save
#    end
#    self.remove_groups_access_control gacl, privileges[:folder_hashkey], groups
#    # check range
#    sub_folders = Array.new
#    my_file_list = Array.new
#    case privileges[:range]
#    when 'all_folders' # => this and sub folders
#      sub_folders =  SpinLocationManager.list_files sid, node[:spin_node_hashkey], NODE_DIRECTORY, true
#      if sub_folders.length > 0
#        # go through sub_folders
#        sub_folders.each {|subf|
#          self.transaction do
#            sub_node = SpinNode.find_by_spin_node_hashkey subf[:node_key]
#            sub_node.spin_world_access_right = wacl
#            if self.is_controlable sid, sub_node[:spin_node_hashkey], NODE_DIRECTORY
#              sub_node.spin_gid_access_right = gacl
#            end
#            sub_node.save
#          end
#          recs += self.remove_groups_access_control gacl, subf[:node_key], groups
#          # check target and set privilege
#          my_file_list = Array.new
#          case privileges[:target]
#            #          when "folder_file" # => folders and files
#            #            my_file_list = SpinLocationManager.list_files sid, subf[:node_key], ANY_TYPE
#          when "file" # => files only
#            my_file_list = SpinLocationManager.list_files sid, subf[:node_key], NODE_FILE
#            #          when "folder" # => folders only
#            #            my_file_list = SpinLocationManager.list_files sid, subf[:node_key], NODE_DIRECTORY
#          else
#            my_file_list = SpinLocationManager.list_files sid, subf[:node_key], NODE_FILE
#          end
#          if my_file_list.length > 0
#            self.transaction do
#              my_file_list.each {|f|
#                fn = SpinNode.find_by_spin_node_hashkey f[:node_key]
#                fn.spin_world_access_right = wacl
#                if self.is_controlable sid, fn[:spin_node_hashkey], NODE_FILE
#                  fn.spin_gid_access_right = gacl
#                end
#                fn.save
#                recs += self.remove_groups_access_control gacl, f[:node_key], groups
#              }
#            end
#          end
#        }
#      end
#    when 'folder' # => this folder only
#      pp "nop"
#    else # => files in this folder
#      # check target and set privilege
#      case privileges[:target]
#      when "folder_file" # => folders and files
#        my_file_list = SpinLocationManager.list_files sid, node[:spin_node_hashkey], ANY_TYPE
#      when "file" # => files only
#        my_file_list = SpinLocationManager.list_files sid, node[:spin_node_hashkey], NODE_FILE
#      when "folder" # => folders only
#        my_file_list = SpinLocationManager.list_files sid, node[:spin_node_hashkey], NODE_DIRECTORY
#      else
#        my_file_list = SpinLocationManager.list_files sid, node[:spin_node_hashkey], ANY_TYPE
#      end
#      if my_file_list.length > 0
#        self.transaction do
#          my_file_list.each {|f|
#            fn = SpinNode.find_by_spin_node_hashkey f[:node_key]
#            fn.spin_world_access_right = wacl
#            if self.is_controlable sid, fn[:spin_node_hashkey], ANY_TYPE
#              fn.spin_gid_access_right = gacl
#            end
#            fn.save
#            recs += self.remove_groups_access_control gacl, f[:node_key], groups
#          }
#        end
#      end
#    end # => end of case privilege[:range]
#    SpinNode.has_updated( SpinLocationManager.get_parent_key privileges[:folder_hashkey], ANY_TYPE )
#    GroupDatum.reset_folder_group_access_list sid, GROUP_LIST_FOLDER
#    return recs
#    
#  end # =>  end of set_privilege privileges
#
#  def self.get_group_acl_string gid, tf
#    
#  end # => end of self.get_group_acl_string sid, tf
#  
#  def self.is_accessible_node sid, node_key, node_type = ANY_TYPE
#    # get acl from the node which has hashkey 'node_key'
#    anode = nil
#    self.transaction do
#      if node_type == ANY_TYPE
#        anode = SpinNode.readonly.find_by_spin_node_hashkey node_key
#      else
#        anode = SpinNode.readonly.find_by_spin_node_hashkey_and_node_type node_key, node_type  
#      end
#    end
#    # get uid and gid
#    ids = SessionManager.get_uid_gid sid
#    # Does ids has access right?
#    if anode[:spin_world_access_right] > ACL_NODE_NO_ACCESS
#      return true
#    end
#    ids[:gids].each { |g|
#      if anode[:spin_gid] == g and anode[:spin_gid_access_right] > ACL_NODE_NO_ACCESS
#        return true
#      end
#    }
#    if anode[:spin_uid] == ids[:uid] and anode[:spin_uid_access_right] > ACL_NODE_NO_ACCESS
#      return true
#    end
#    # check access control table
#    aclnodes = []
#    self.transaction do
#      aclnodes = self.readonly.where(:managed_node_hashkey => node_key, :spin_uid => ids[:uid])
#      aclnodes |= self.readonly.where(:managed_node_hashkey => node_key, :spin_gid => ids[:gids])
#    end
#    if aclnodes
#      aclnodes.each { |an|
#        if an.spin_world_access_right > ACL_NODE_NO_ACCESS
#          return true
#        end
#        if an.spin_uid == ids[:uid] and an.spin_uid_access_right > ACL_NODE_NO_ACCESS
#          return true
#        end
#        ids[:gids].each { |g|
#          if an.spin_gid == g and an.spin_gid_access_right > ACL_NODE_NO_ACCESS
#            return true
#          end
#        } # => end of ids[:gids].each
#      } # => end of aclnodes.each
#    end # => end of if aclnodes
#  end # => end of is_accessible_node
#
#  def self.is_readable sid, node_key, node_type = ANY_TYPE
#    # # returns union of acls for uid and gids
#    # return { :user => u_acl, :group => g_acl, :world => w_acl }
#    acls_hash = self.has_acl_values sid, node_key, node_type
#    u_acl = acls_hash[:user]
#    g_acl = acls_hash[:group]
#    w_acl = acls_hash[:world]
#    
#    if (u_acl | g_acl | w_acl)&ACL_NODE_READ == 0
#      return false
#    else
#      return true
#    end
#    # acl.values.each { |a|
#    # if (a & ACL_NODE_READ) != 0
#    # return true
#    # end
#    # }  
#    # return false
#  end # => end of is_readable
#    
#  def self.is_writable sid, node_key, node_type = ANY_TYPE
#    # acl.values.each { |a|
#    # if (a & ACL_NODE_WRITE) != 0
#    # return true
#    # end
#    # }  
#    # return false
#    acls_hash = self.has_acl_values sid, node_key, node_type
#    unless acls_hash
#      return false
#    end
#    u_acl = acls_hash[:user]
#    g_acl = acls_hash[:group]
#    w_acl = acls_hash[:world]
#    
#    if (u_acl | g_acl | w_acl)&ACL_NODE_WRITE == 0
#      return false
#    elsif (u_acl | g_acl | w_acl)&ACL_NODE_DELETE == 0
#      return false
#    else
#      return true
#    end
#  end # => end of is_writable
#    
#  def self.is_other_readable sid, node_key, node_type = ANY_TYPE
#    # # returns union of acls for uid and gids
#    # return { :user => u_acl, :group => g_acl, :world => w_acl }
#    acls_hash = self.has_acl_values sid, node_key, node_type
#    w_acl = acls_hash[:world]
#    
#    if w_acl&ACL_NODE_READ != 0
#      return true
#    else
#      return false
#    end
#  end # => end of is_readable
#    
#  def self.is_other_writable sid, node_key, node_type = ANY_TYPE
#    acls_hash = self.has_acl_values sid, node_key, node_type
#    w_acl = acls_hash[:world]
#    
#    if w_acl&ACL_NODE_WRITE == 0 or w_acl&ACL_NODE_DELETE == 0
#      return false
#    else
#      return true
#    end
#  end # => end of is_writable
#    
#  def self.is_controlable sid, node_key, node_type = ANY_TYPE
#    # acl.values.each { |a|
#    # if (a & ACL_NODE_WRITE) != 0
#    # return true
#    # end
#    # }  
#    # return false
#    n = {}
#    my_uid = SessionManager.get_uid(sid)
#    self.transaction do
#      n = SpinNode.readonly.find_by_spin_node_hashkey node_key
#    end
#    if n[:spin_uid] == my_uid
#      return true
#    end
#    acls_hash = self.has_acl_values sid, node_key, node_type
#    u_acl = acls_hash[:user]
#    g_acl = acls_hash[:group]
#    w_acl = acls_hash[:world]
#    
#    if (u_acl | g_acl | w_acl)&ACL_NODE_CONTROL != 0
#      return true
#    else
#      return false
#    end
#  end # => end of is_writable
#    
#  def self.x_has_acl sid, node_key, node_type = ACL_TYPE_DIRECTORY
#    # initialize object
#    ids = Hash.new
#    u_acls = Hash.new
#    g_acls = Hash.new
#    w_acls = Hash.new
#    acl = ACL_NODE_NO_ACCESS
#    # get acl from the node which has hashkey 'node_key'
#    anode = {}
#    self.transaction do
#      anode = SpinNode.readonly.find_by_spin_node_hashkey_and_node_type node_key, node_type  
#    end
#    # get uid and gid
#    ids = SessionManager.get_uid_gid sid
#    # Does ids has access right?
#    if anode[:spin_world_access_right] > ACL_NODE_NO_ACCESS
#      acl |= anode[:spin_world_access_right]
#    end
#    if anode[:spin_gid] == ids[:gid] and anode[:spin_gid_access_right] > ACL_NODE_NO_ACCESS
#      acl |= anode[:spin_gid_access_right]
#    end
#    if anode[:spin_uid] == ids[:uid] and anode[:spin_uid_access_right] > ACL_NODE_NO_ACCESS
#      acl |= anode[:spin_uid_access_right]
#    end
#    # search spin_acces_contorols for ACL related with these ID's
#    # are there records which have my uid or gid? 
#    self.transaction do
#      w_acls = self.readonly.where(:managed_node_hashkey => node_key, :spin_node_type => node_type)
#      w_acls.each { |fa|
#        acl |= fa[:spin_world_access_right]
#      }
#      u_acls = self.readonly.where(:managed_node_hashkey => node_key, :spin_uid => ids[:uid], :spin_node_type => node_type)
#      u_acls.each { |fa|
#        acl |= fa[:spin_uid_access_right]
#      }
#      g_acls = self.readonly.where(:managed_node_hashkey => node_key, :spin_gid => ids[:gids], :spin_node_type => node_type)
#      g_acls.each { |ga|
#        acl |= ga[:spin_gid_access_right]
#      }
#    end
#    # returns union of acls for uid and gids
#    return acl
#  end # => end of has_acl
#
#  def self.has_acl sid, node_key, node_type = ANY_TYPE
#    # get acl from the node which has hashkey 'node_key'
#    anode = {}
#    self.transaction do
#      if node_type == ANY_TYPE
#        anode = SpinNode.readonly.find_by_spin_node_hashkey node_key  
#      else
#        anode = SpinNode.readonly.find_by_spin_node_hashkey_and_node_type node_key, node_type  
#      end
#    end
#    # get uid and gid
#    ids = SessionManager.get_uid_gid sid
#    if ids[:uid] == ACL_SUPERUSER_UID or ids[:gid] == ACL_SUPERUSER_GID
#      return ACL_NODE_SUPERUSER_ACCESS
#    end
#    if SetUtility::SetOp.is_in_set ACL_SUPERUSER_GID, ids[:gids]
#      return ACL_NODE_SUPERUSER_ACCESS
#    end
#    
#    # initialize object
#    u_acls = Hash.new
#    g_acls = Hash.new
#    w_acls = Hash.new
#    u_acl = ACL_NODE_NO_ACCESS
#    g_acl = ACL_NODE_NO_ACCESS
#    w_acl = ACL_NODE_NO_ACCESS
#    
#    # Does ids has access rights in the node record?
#    if anode
#      if anode[:spin_world_access_right] > ACL_NODE_NO_ACCESS
#        w_acl = anode[:spin_world_access_right]
#      end
#      if anode[:spin_gid] == ids[:gid] and anode[:spin_gid_access_right] > ACL_NODE_NO_ACCESS
#        g_acl = anode[:spin_gid_access_right]
#      end
#      if anode[:spin_uid] == ids[:uid] and anode[:spin_uid_access_right] > ACL_NODE_NO_ACCESS
#        u_acl = anode[:spin_uid_access_right]
#      end
#    else
#      return nil
#    end
#
#    # search spin_acces_contorols for ACL related with these ID's
#    # are there records which have my uid or gid?
#    node_acls = Array.new
#    self.transaction do
#      if node_type == ANY_TYPE
#        node_acls = self.readonly.where(:managed_node_hashkey =>  node_key)
#      else # => node type specified
#        node_acls = self.readonly.where(:managed_node_hashkey => node_key, :spin_node_type => node_type)
#      end
#      node_acls.each {|na|
#        w_acl |= na[:spin_world_access_right]
#        if na[:spin_uid] == ids[:uid]
#          u_acl |= na[:spin_uid_access_right]
#        end
#        n = ids[:gids].count
#        for i in 0..(n-1)
#          g = ids[:gids][i]
#          if g[:spin_gid] == na[:spin_gid]
#            g_acl |= na[:spin_gid_access_right]
#          end
#        end
#      }
#    end
#    # returns union of acls for uid and gids
#    return ( u_acl | g_acl | w_acl )
#  end # => end of has_acl
#  
#  def self.has_acl_values sid, node_key, node_type = ANY_TYPE
#    # get acl from the node which has hashkey 'node_key'
#    # for DEBUG
#    # if node_key == '64ad4d6cc914f1738a0325086a3e79282231d2d3'
#    # pp 'Yes'
#    # end
#    anode = {}
#    self.transaction do
#      if node_type == ANY_TYPE
#        anode = SpinNode.readonly.find_by_spin_node_hashkey node_key  
#      else
#        anode = SpinNode.readonly.find_by_spin_node_hashkey_and_node_type node_key, node_type  
#      end
#    end
#    # get uid and gid
#    ids = SessionManager.get_uid_gid sid
#
#    # initialize object
#    u_acl = ACL_NODE_NO_ACCESS
#    g_acl = ACL_NODE_NO_ACCESS
#    w_acl = ACL_NODE_NO_ACCESS
#    
#    if ids[:uid] == ACL_SUPERUSER_UID
#      return { :user => ACL_NODE_SUPERUSER_ACCESS, :group => ACL_NODE_SUPERUSER_ACCESS, :world => ACL_NODE_SUPERUSER_ACCESS }
#    end
#    
#    # does this user has superuser priviledge?
#    if ids[:uid] == ACL_SUPERUSER_UID or ids[:gid] == ACL_SUPERUSER_GID or SetUtility::SetOp.is_in_set( ACL_SUPERUSER_GID, ids[:gids] )
#      if ids[:uid] == ACL_SUPERUSER_UID
#        u_acl = ACL_NODE_SUPERUSER_ACCESS
#      end
#      if ids[:gid] == ACL_SUPERUSER_GID or SetUtility::SetOp.is_in_set( ACL_SUPERUSER_GID, ids[:gids] )
#        g_acl = ACL_NODE_SUPERUSER_ACCESS
#      end
#      return { :user => u_acl, :group => g_acl, :world => w_acl }
#    end # => end of if su check block
#
#    # Does ids has access rights in the node record?
#    if anode
#      if anode[:spin_world_access_right] > ACL_NODE_NO_ACCESS
#        w_acl = anode[:spin_world_access_right]
#      end
#      if anode[:spin_gid] == ids[:gid] and anode[:spin_gid_access_right] > ACL_NODE_NO_ACCESS
#        g_acl = anode[:spin_gid_access_right]
#      end
#      if anode[:spin_uid] == ids[:uid] and anode[:spin_uid_access_right] > ACL_NODE_NO_ACCESS
#        u_acl = anode[:spin_uid_access_right]
#      end
#    else
#      return nil
#    end
#
#    # search spin_acces_contorols for ACL related with these ID's
#    # are there records which have my uid or gid?
#    node_acls = Array.new
#    self.transaction do
#      if node_type == ANY_TYPE
#        node_acls = self.readonly.where(:managed_node_hashkey =>  node_key)
#      else # => node type specified
#        node_acls = self.readonly.where(:managed_node_hashkey => node_key, :spin_node_type => node_type)
#      end
#      node_acls.each {|na|
#        w_acl |= na[:spin_world_access_right]
#        if na[:spin_uid] == ids[:uid]
#          u_acl |= na[:spin_uid_access_right]
#        end
#        n = ids[:gids].count
#        for i in 0..(n-1)
#          g = ids[:gids][i]
#          if g[:spin_gid] == na[:spin_gid]
#            g_acl |= na[:spin_gid_access_right]
#          end
#        end
#      }
#    end
#    # returns hash of acls for uid and gids
#    return { :user => u_acl, :group => g_acl, :world => w_acl }
#  end # => end of has_acl
#  
#  def self.copy_parent_acls sid, new_node, acls, type = ANY_TYPE # => new_node = [x,y,prx,v,hashkey]
#    # get acls
#    parent_key = SpinLocationManager.get_parent_key new_node[4], type # => pass hashkey
#    acl_recs = []
#    self.transaction do
#      acl_recs = self.where(:managed_node_hashkey => parent_key)
#    end
#    # group_acls = [ {:gid => n,:acl => N},{:gid => n,acl :N},...,{:gid => -1,:acl => N}] where ":gid => -1" is for WORLD ACCESS RIGHT
#    # user_acls = [ {:uid => n,:acl => N},{:uid => n,acl :N},...,{:uid => n,:acl => N}]
#    my_uid = SessionManager.get_uid(sid)
#    group_acls = Array.new
#    user_acls = Array.new
#    world_acl = ACL_NODE_NO_ACCESS
#    self.transaction do
#      acl_recs.each {|a|
#        # duplicate it for new_node
#        # create new record
#        # set spin_access_contrtol
#        new_node_acl = SpinAccessControl.new
#        new_node_acl.spin_uid = my_uid
#        #        new_node_acl.spin_uid = a[:spin_uid]
#        new_node_acl.spin_gid = a[:spin_gid]
#        new_node_acl.spin_node_type = a[:spin_node_type]
#        new_node_acl.spin_domain_flag = a[:spin_domain_flag]
#        new_node_acl.user_level_x = a[:user_level_x]
#        new_node_acl.user_level_y = a[:user_level_y]
#        if a[:spin_gid_access_right] > ACL_NODE_NO_ACCESS
#          new_node_acl.spin_gid_access_right = a[:spin_gid_access_right]
#          gx = { :gid => a[:spin_gid], :acl => a[:spin_gid_access_right] }
#          group_acls.append gx
#        end
#        if a[:spin_world_access_right] > ACL_NODE_NO_ACCESS
#          new_node_acl.spin_world_access_right = a[:spin_world_access_right]
#          world_acl |= a[:spin_world_access_right]
#        end
#        if a[:spin_uid_access_right] > ACL_NODE_NO_ACCESS
#          new_node_acl.spin_uid_access_right = a[:spin_uid_access_right]
#          ux = { :uid => my_uid, :acl => a[:spin_uid_access_right] }
#          user_acls.append ux
#        end
#        r = Random.new
#        new_node_acl.spin_node_hashkey = Security.hash_key_s ACL_PREFIX + a[:spin_node_hashkey] + r.rand.to_s
#        new_node_acl.managed_node_hashkey = new_node[4] # => node_hashkey from caller
#        new_node_acl.created_at = Time.now
#        new_node_acl.updated_at = Time.now
#        new_node_acl.save
#        logger.debug new_node_acl
#        # new_node_acl = new
#        # new_node_acl = a
#        # new_node_acl[:managed_node_hashkey] = new_node[4] # => node_hashkey from caller 
#        # new_node_acl.save
#      }
#    end
#    wgx = { :gid => ACL_WORLD_GID, :acl => world_acl }
#    group_acls.append wgx
#    # return acls set
#    return { :user_acl => user_acls, :group_acl => group_acls }
#  end # => end of copy_parent_acls new_node # => new_node = [x,y,prx,v,hashkey]
#  
#  def self.inq_node_access_right sid, node_key
#    return self.has_acl_values sid, node_key
#  end # => end of inq_node_access_right
#  
#end
##class SpinGroupAccessControl < ActiveRecord::Base
#  # attr_accessor :title, :body
##end
