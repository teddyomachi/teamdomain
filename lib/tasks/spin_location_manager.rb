# coding: utf-8
require 'tasks/session_management'
require 'tasks/spin_file_system'
require 'utilities/database_utilities'
require 'utilities/file_manager_utilities'
require 'const/vfs_const'
require 'const/acl_const'

module SpinLocationManager
  include Vfs
  include Acl

  # You should call this with target_folder_name as FULL PATH at SPIN VIRTUAL FILE SYSTEM!!
  def self.get_location_coordinates sid, location, target_folder_name, mkdir_if_not_exists = false, owner_uid = NO_USER, owner_gid = NO_GROUP, u_acl = (ACL_NODE_CONTROL | ACL_NODE_DELETE | ACL_NODE_WRITE | ACL_NODE_READ), g_acl = (ACL_NODE_DELETE | ACL_NODE_WRITE | ACL_NODE_READ), w_acl = ACL_NODE_NO_ACCESS, is_sticky = false
    # analyze target_folder_name path
    # => ex. /clients/a_coorporation/orginization/.../

    log_msg = "get_location_coordinates :target_folder_name => " + target_folder_name
    FileManager.rails_logger(log_msg)

    vloc = [0, 0, 0, 0] # => means ROOT
    vdirs = []
    #    ploc = vloc
    #    cloc = vloc
    # flag_make_path = true # => create intermediate dirctories if not exists
    flag_make_path = mkdir_if_not_exists # => create intermediate dirctories if not exists

    # => it's the ROOT if target_folder_name == '/'
    if target_folder_name == '/'
      return vloc
    end

    # Is it a relative path?
    if target_folder_name[0, 2] == "./" # => relative path
      # resolve it and make absolute path
      #      ckey = DatabaseUtility::SessionUtility.get_location_current_directory sid, location
      #      cloc = self.key_to_location(sid,ckey)
      target_current_folder_name = DatabaseUtility::SessionUtility.get_current_directory_path sid
      vdirs = target_current_folder_name.scan(/[^\/]+/) # => ex. [ "usr", "local", "spin path" ]
      vdirs_rel = target_folder_name.scan(/[^\/]+/) # => ex. [ "usr", "local", "spin path" ]
      vdirs += vdirs_rel[1..-1]
      #      ploc = cloc
    elsif target_folder_name[0, 1] != "/" # => relative path
      # resolve it and make absolute path
      #      ckey = DatabaseUtility::SessionUtility.get_location_current_directory sid, location
      #      cloc = self.key_to_location(ckey, NODE_DIRECTORY)
      # cpath = DatabaseUtility::SessionUtility.get_current_directory_path ADMIN_SESSION_ID
      vdirs = target_folder_name.scan(/[^\/]+/) # => ex. [ "usr", "local", "spin path" ]
      #      ploc = cloc
    else # => abosolute path
      vdirs = target_folder_name.scan(/[^\/]+/) # => ex. [ "usr", "local", "spin path" ]
      # => ploc = cloc = [root location]
    end


    #    # count '/' to get the layer of the target path
    #    sc = target_folder_name.count('/')
    #    # get virtual directory names from target_folder_name
    #    # seach DB from the ROOT
    #    depth = ploc[Y]
    #    parent_x = ploc[X]

    # check vpath first
    tmp_vdirs = vdirs
    vdirs_size = vdirs.size
    #    tmp_vdirs.pop
    tmp_vpath = ''
    tmp_vpath_p = ''
    tmp_vdirs.each_with_index {|tvp, idx|
      tmp_vpath += ('/' + tvp)
      if idx < (vdirs_size - 1)
        tmp_vpath_p += ('/' + tvp)
      end
    }

    #    tmp_vpath.gsub!(/\'/, '\'\'')
    existing_vpath = nil
    SpinNode.transaction do
      #      SpinNode.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      existing_vpath = SpinNode.select("node_x_coord,node_y_coord,node_x_pr_coord,node_version,spin_node_hashkey").find_by_spin_tree_type_and_virtual_path_and_is_void_and_in_trash_flag(SPIN_NODE_VTREE, tmp_vpath, false, false)
      if existing_vpath.present?
        vloc[X] = existing_vpath[:node_x_coord]
        vloc[Y] = existing_vpath[:node_y_coord]
        vloc[PRX] = existing_vpath[:node_x_pr_coord]
        vloc[V] = existing_vpath[:node_version]
        vloc[K] = existing_vpath[:spin_node_hashkey]
        return vloc
      elsif flag_make_path != true
        return [-1, -1, -1, -1]
      end
    end # => end of transaction

    ids = SessionManager.get_uid_gid(sid, true)

    # process loop
    #    vp = ''
    #    vp_prev = ''
    pkey_prev = ''
    x_prev = ANY_VALUE
    y_prev = ANY_VALUE
    existing_parent_vpath = tmp_vpath_p
    existing_parent_node = nil
    #    existing_parent_vpath.gsub!(/\'/, '\'\'')

    SpinNode.transaction do
      #      SpinNode.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      while existing_parent_vpath != ''
        begin
          existing_parent_node = SpinNode.select("spin_node_hashkey,node_x_coord,node_y_coord,virtual_path").find_by_spin_tree_type_and_virtual_path_and_is_void_and_in_trash_flag(SPIN_NODE_VTREE, existing_parent_vpath, false, false)
          if existing_parent_node.blank?
            rpos = existing_parent_vpath.rindex("/") - 1
            if rpos == -1
              existing_parent_vpath = '/'
              break
            else
              existing_parent_vpath = existing_parent_vpath[0..rpos]
            end
          else
            existing_parent_vpath = existing_parent_node[:virtual_path]
          end
          break
        rescue ActiveRecord::RecordNotFound
          rpos = existing_parent_vpath.rindex("/") - 1
          if rpos == -1
            existing_parent_vpath = '/'
            break
          else
            existing_parent_vpath = existing_parent_vpath[0..rpos]
          end
        end
      end # => end of while-loop
    end # => end of transaction

    if existing_parent_node.present?
      #      vp = existing_parent_vpath
      #      vp_prev = tmp_vpath_p
      pkey_prev = existing_parent_node[:spin_node_hashkey]
      x_prev = existing_parent_node[:node_x_coord]
      y_prev = existing_parent_node[:node_y_coord]
      parent_vdirs = existing_parent_vpath.scan(/[^\/]+/)
      psize = parent_vdirs.size
      relems = vdirs_size - psize
      if relems == 0
        vdirs = []
      elsif relems == 1
        vdirs = [vdirs[-1]]
      else
        vdirs = vdirs[(relems * (-1))..-1]
      end
      #      vdirs -= parent_vdirs
    end

    vdirs.each {|vdir|

      # create directory if vn == nil
      if flag_make_path == true # => check flag
        #        pkey = self.get_vpath_key(vp_prev)
        pkey = pkey_prev
        if SpinAccessControl.is_writable(sid, pkey, NODE_DIRECTORY)
          #          pn = SpinNode.readonly.select("node_x_coord,node_y_coord").find_by_spin_node_hashkey = ?",pkey])
          request_loc = [ANY_VALUE, y_prev + 1, x_prev, REQUEST_VERSION_NUMBER]
          #          request_loc = [ ANY_VALUE, pn[:node_y_coord] + 1, pn[:node_x_coord], REQUEST_VERSION_NUMBER ]
          retry_tst_xy = ACTIVE_RECORD_RETRY_COUNT
          while retry_tst_xy > 0
            new_node_location = SpinNodeKeeper.test_and_set_xy(sid, request_loc, vdir, NODE_DIRECTORY)
            log_msg = "get_location_coordinates test_and_set_xy returned => " + new_node_location.to_s
            FileManager.rails_logger(log_msg)
            if new_node_location.present? and new_node_location != NoXYPV
              break
            elsif new_node_location.blank?
              retry_tst_xy -= 1
              next
            end
            random_sleep_factor = Random.new.rand(100)
            if random_sleep_factor == 0
              random_sleep_factor = 1
            end
            sleep(1.0 / random_sleep_factor)
            retry_tst_xy -= 1
          end
          if new_node_location == NoXYPV
            return [-1, -1, -1, -1]
          end
          if owner_uid == NO_USER
            owner_uid = ids[:uid]
          end
          if owner_gid == NO_GROUP
            owner_gid = ids[:gid]
          end
          acls = {:user => u_acl, :group => g_acl, :world => w_acl}
          if new_node_location.present? # => directory exists!
            reth = SpinNode.is_active_dir_node_location(new_node_location)
            if reth[:is_active]
              vloc = new_node_location
              vloc.append reth[:hash_key]
              #              vloc[V] = INITIAL_VERSION_NUMBER
            else
              vloc = SpinNode.create_spin_node(sid, new_node_location[X], new_node_location[Y], new_node_location[PRX], INITIAL_VERSION_NUMBER, vdir, NODE_DIRECTORY, owner_uid, owner_gid, acls, is_sticky)
              SpinAccessControl.copy_parent_acls(sid, vloc, NODE_DIRECTORY, pkey, ids[:uid])
              #              vloc = new_node_location
              #              vloc[V] = INITIAL_VERSION_NUMBER
            end
          else # => crate new directory
            vloc = SpinNode.create_spin_node(sid, new_node_location[X], new_node_location[Y], new_node_location[PRX], INITIAL_VERSION_NUMBER, vdir, NODE_DIRECTORY, owner_uid, owner_gid, acls, is_sticky)
            SpinAccessControl.copy_parent_acls(sid, vloc, NODE_DIRECTORY, pkey, ids[:uid])
          end
          x_prev = vloc[X]
          y_prev = vloc[Y]
        else # => cannot create node because the parent is not writable
          return [-1, -1, -1, -1]
        end # => end of if SpinAccessControl.is_writable(sid, pkey, NODE_DIRECTORY)
      else # => doesn't make path
        return [-1, -1, -1, -1]
      end # => end of if flag_make_path == true # => check flag
    }

    log_msg = "get_location_coordinates finished."
    FileManager.rails_logger(log_msg)

    if vloc.size > K
      return vloc[X..K]
    else
      return vloc[X..V]
    end
  end

  # => end of get_location_coordinates

  def self.get_location_coordinates2 sid, location, target_folder_name, mkdir_if_not_exists = false, owner_uid = NO_USER, owner_gid = NO_GROUP, u_acl = (ACL_NODE_CONTROL | ACL_NODE_DELETE | ACL_NODE_WRITE | ACL_NODE_READ), g_acl = (ACL_NODE_DELETE | ACL_NODE_WRITE | ACL_NODE_READ), w_acl = ACL_NODE_NO_ACCESS
    # analyze target_folder_name path
    # => ex. /clients/a_coorporation/orginization/.../

    #    log_msg = "get_location_coordinates :target_folder_name => " + target_folder_name
    #    FileManager.logger(sid, log_msg)
    vloc = [0, 0, 0, 0] # => means ROOT
    vdirs = []
    ploc = vloc
    cloc = vloc
    # flag_make_path = true # => create intermediate dirctories if not exists
    flag_make_path = mkdir_if_not_exists # => create intermediate dirctories if not exists

    # => it's the ROOT if target_folder_name == '/'
    if target_folder_name == '/'
      return vloc
    end

    # Is it a relative path?
    if target_folder_name[0, 2] == "./" # => relative path
      # resolve it and make absolute path
      ckey = DatabaseUtility::SessionUtility.get_location_current_directory sid, location
      cloc = self.key_to_location(sid, ckey)
      # cpath = DatabaseUtility::SessionUtility.get_current_directory_path ADMIN_SESSION_ID
      vdirs = target_folder_name.scan(/[^\/]+/) # => ex. [ "usr", "local", "spin path" ]
      ploc = cloc
    elsif target_folder_name[0, 1] != "/" # => relative path
      # resolve it and make absolute path
      ckey = DatabaseUtility::SessionUtility.get_location_current_directory sid, location
      cloc = self.key_to_location(ckey, NODE_DIRECTORY)
      # cpath = DatabaseUtility::SessionUtility.get_current_directory_path ADMIN_SESSION_ID
      vdirs = target_folder_name.scan(/[^\/]+/) # => ex. [ "usr", "local", "spin path" ]
      ploc = cloc
    else # => abosolute path
      vdirs = target_folder_name.scan(/[^\/]+/) # => ex. [ "usr", "local", "spin path" ]
      # => ploc = cloc = [root location]
    end


    # count '/' to get the layer of the target path
    sc = target_folder_name.count('/')
    # get virtual directory names from target_folder_name
    # seach DB from the ROOT
    depth = ploc[Y]
    parent_x = ploc[X]

    existing_vpath = SpinNode.select("node_x_coord,node_y_coord,nnode_x_pr_coord,node_version").find_by_virtual_path_and_is_void_and_in_trash_flag_and_is_pending(target_folder_name, false, false, false)
    if existing_vpath.present?
      vloc[X] = existing_vpath[:node_x_coord]
      vloc[Y] = existing_vpath[:node_y_coord]
      vloc[PRX] = existing_vpath[:node_x_pr_coord]
      vloc[V] = existing_vpath[:node_version]
      return vloc
    end

    # process loop
    vdirs.each {|vdir|
      vnode = SpinNode.select("node_x_coord,node_y_coord").find_by_node_x_pr_coord_and_node_y_coord_and_node_name_and_node_type_and_is_void_and_in_trash_flag(parent_x, depth + 1, vdir, NODE_DIRECTORY, false, false)
      #      number_of_children = vnodes.length
      if vnode.blank? # => make it if flag_make_path
        if flag_make_path == true # => check flag
          xy = [parent_x, depth]
          pkey = self.location_to_key(xy, NODE_DIRECTORY)
          if SpinAccessControl.is_writable(sid, pkey, NODE_DIRECTORY)
            request_loc = [ANY_VALUE, depth + 1, parent_x, REQUEST_VERSION_NUMBER]
            #            new_node_location = nil
            #            while new_node_location.blank?
            new_node_location = SpinNodeKeeper.test_and_set_xy(sid, request_loc, vdir, NODE_DIRECTORY)
            #            end
            ids = SessionManager.get_uid_gid(sid, true)
            if owner_uid == NO_USER
              owner_uid = ids[:uid]
            end
            if owner_gid == NO_GROUP
              owner_gid = ids[:gid]
            end
            acls = {:user => u_acl, :group => g_acl, :world => w_acl}
            #            vloc = SpinNode.create_spin_node(sid, new_node_location[X], new_node_location[Y], new_node_location[PRX], new_node_location[V], vdir, NODE_DIRECTORY, owner_uid, owner_gid, acls)
            if new_node_location[V] > 0 # => directory exists!
              vloc = new_node_location
              vloc[V] = INITIAL_VERSION_NUMBER
            else # => crate new directory
              vloc = SpinNode.create_spin_node(sid, new_node_location[X], new_node_location[Y], new_node_location[PRX], new_node_location[V] * (-1), vdir, NODE_DIRECTORY, owner_uid, owner_gid, acls)
            end
            parent_x = vloc[X]
            depth = vloc[Y]
          else # => cannot create node because the parent is not writable
            return [-1, -1, -1, -1]
          end # => end of if SpinAccessControl.is_writable(sid, pkey, NODE_DIRECTORY)
        else # => doesn't make path
          return [-1, -1, -1, -1]
        end # => end of if flag_make_path == true # => check flag
      else # => got it!
        vloc[Y] = depth = vnode[:node_y_coord]
        vloc[X] = parent_x = vnode[:node_x_coord]
      end # => end of if number_of_children == 0 # => make it if flag_make_path
    }
    return vloc
  end

  # => end of get_location_coordinates

  def self.get_location_coordinates_of_sub_folder sid, parent_folder_key, sub_folder_name, mkdir_if_not_exists = false, owner_uid = NO_USER, owner_gid = NO_GROUP, u_acl = (ACL_NODE_CONTROL | ACL_NODE_DELETE | ACL_NODE_WRITE | ACL_NODE_READ), g_acl = (ACL_NODE_DELETE | ACL_NODE_WRITE | ACL_NODE_READ), w_acl = ACL_NODE_NO_ACCESS
    # analyze sub_folder_name path
    # => ex. /clients/a_coorporation/orginization/.../

    #    log_msg = "get_location_coordinates :sub_folder_name => " + sub_folder_name
    #    FileManager.logger(sid, log_msg)
    vloc = [0, 0, 0, 0] # => means ROOT
    vdirs = []
    ploc = vloc
    cloc = vloc
    # flag_make_path = true # => create intermediate dirctories if not exists
    flag_make_path = mkdir_if_not_exists # => create intermediate dirctories if not exists

    # => it's the ROOT if sub_folder_name == '/'
    if sub_folder_name == '/'
      return vloc
    end

    # Is it a relative path?
    if sub_folder_name[0, 2] == "./" # => relative path
      # resolve it and make absolute path
      ckey = DatabaseUtility::SessionUtility.get_location_current_directory sid, location
      cloc = self.key_to_location(sid, ckey)
      # cpath = DatabaseUtility::SessionUtility.get_current_directory_path ADMIN_SESSION_ID
      vdirs = sub_folder_name.scan(/[^\/]+/) # => ex. [ "usr", "local", "spin path" ]
      ploc = cloc
    elsif sub_folder_name[0, 1] != "/" # => relative path
      # resolve it and make absolute path
      ckey = DatabaseUtility::SessionUtility.get_location_current_directory sid, location
      cloc = self.key_to_location(ckey, NODE_DIRECTORY)
      # cpath = DatabaseUtility::SessionUtility.get_current_directory_path ADMIN_SESSION_ID
      vdirs = sub_folder_name.scan(/[^\/]+/) # => ex. [ "usr", "local", "spin path" ]
      ploc = cloc
    else # => abosolute path
      vdirs = sub_folder_name.scan(/[^\/]+/) # => ex. [ "usr", "local", "spin path" ]
      # => ploc = cloc = [root location]
    end


    # count '/' to get the layer of the target path
    sc = sub_folder_name.count('/')
    # get virtual directory names from sub_folder_name
    # seach DB from the ROOT
    depth = ploc[Y]
    parent_x = ploc[X]

    # process loop
    vdirs.each {|vdir|
      vnode = SpinNode.select("node_x_coord,node_y_coord").find_by_spin_tree_type_and_node_x_pr_coord_and_node_y_coord_and_node_name_and_node_type_and_is_void_and_in_trash_flag(SPIN_NODE_VTREE, parent_x, depth + 1, vdir, NODE_DIRECTORY, false, false)
      #      number_of_children = vnodes.length
      if vnode.blank? # => make it if flag_make_path
        if flag_make_path == true # => check flag
          xy = [parent_x, depth]
          pkey = self.location_to_key(xy, NODE_DIRECTORY)
          if SpinAccessControl.is_writable(sid, pkey, NODE_DIRECTORY)
            request_loc = [ANY_VALUE, depth + 1, parent_x, REQUEST_VERSION_NUMBER]
            #            new_node_location = nil
            #            while new_node_location.blank?
            new_node_location = SpinNodeKeeper.test_and_set_xy(sid, request_loc, vdir, NODE_DIRECTORY)
            #            end
            ids = SessionManager.get_uid_gid(sid, true)
            if owner_uid == NO_USER
              owner_uid = ids[:uid]
            end
            if owner_gid == NO_GROUP
              owner_gid = ids[:gid]
            end
            acls = {:user => u_acl, :group => g_acl, :world => w_acl}
            #            vloc = SpinNode.create_spin_node(sid, new_node_location[X], new_node_location[Y], new_node_location[PRX], new_node_location[V], vdir, NODE_DIRECTORY, owner_uid, owner_gid, acls)
            if new_node_location[V] > 0 # => directory exists!
              vloc = new_node_location
              vloc[V] = INITIAL_VERSION_NUMBER
            else # => crate new directory
              vloc = SpinNode.create_spin_node(sid, new_node_location[X], new_node_location[Y], new_node_location[PRX], new_node_location[V] * (-1), vdir, NODE_DIRECTORY, owner_uid, owner_gid, acls)
              SpinAccessControl.copy_parent_acls(sid, vloc, NODE_DIRECTORY)
            end
            parent_x = vloc[X]
            depth = vloc[Y]
          else # => cannot create node because the parent is not writable
            return [-1, -1, -1, -1]
          end # => end of if SpinAccessControl.is_writable(sid, pkey, NODE_DIRECTORY)
        else # => doesn't make path
          return [-1, -1, -1, -1]
        end # => end of if flag_make_path == true # => check flag
      else # => got it!
        vloc[Y] = depth = vnode[:node_y_coord]
        vloc[X] = parent_x = vnode[:node_x_coord]
      end # => end of if number_of_children == 0 # => make it if flag_make_path
    }
    return vloc
  end

  # => end of get_location_coordinates

  def self.is_domain_root_location loc
    SpinNode.transaction do
      #       SpinNode.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      node = nil
      begin
        node = SpinNode.readonly.find_by_node_x_coord_and_node_y_coord_and_node_type_and_spin_tree_type(loc[X], loc[Y], NODE_DIRECTORY, SPIN_NODE_VTREE)
        if node.present? and node[:is_domain_root_node] == true
          return true
        else
          return false
        end
      rescue ActiveRecord::RecordNotFound
        return false
      end
    end
  end

  def self.search_domains_of_node node_rec
    # trivial check : if it is the domain root node
    domains = []
    #    ActiveRecord::Base.transaction do
    #      n = SpinNode.find_by_spin_node_hashkey node_rec
    if node_rec.present? and node_rec[:is_domain_root_node]
      return [node_rec[:spin_node_hashkey]]
    end
    # get location coordinates
    droots = []
    #      loc = self.key_to_location node_key, NODE_DIRECTORY
    # check is_domain_root_node flag
    pn = nil
    cn = node_rec
    while true
      pn = self.get_parent_node(cn)
      #        pn = SpinNode.find_by_node_x_coord_and_node_y_coord_and_node_type_and_spin_tree_type loc[PRX], loc[Y]-1, NODE_DIRECTORY, SPIN_NODE_VTREE
      if pn[:is_domain_root_node] == true
        droots.push pn[:spin_node_hashkey]
      end
      #        loc = [ pn[:node_x_coord], pn[:node_y_coord], pn[:node_x_pr_coord] ]
      break if pn == cn
      cn = pn
    end
    # search domains
    droots.each {|dr|
      dom = SpinDomain.where :domain_root_node_hashkey => dr
      if dom.length > 0
        dom.each {|dm|
          domains.push dm[:hash_key]
        }
      end
    }
    #    end
    return domains
  end

  # => end of .search_domains_of_node node_key

  def self.search_domains_of_node_by_key node_key
    # trivial check : if it is the domain root node
    domains = []
    #    ActiveRecord::Base.transaction do
    n = SpinNode.find_by_spin_node_hashkey node_key
    if n.present? and n[:is_domain_root_node]
      return [node_key]
    end
    # get location coordinates
    droots = []
    #      loc = self.key_to_location node_key, NODE_DIRECTORY
    # check is_domain_root_node flag
    pn = nil
    cn = n
    while true
      pn = self.get_parent_node(cn)
      #        pn = SpinNode.find_by_node_x_coord_and_node_y_coord_and_node_type_and_spin_tree_type loc[PRX], loc[Y]-1, NODE_DIRECTORY, SPIN_NODE_VTREE
      if pn.present? and pn[:is_domain_root_node] == true
        droots.push pn[:spin_node_hashkey]
      end
      break if pn == cn # => root!
      cn = pn
      #        loc = [ pn[:node_x_coord], pn[:node_y_coord], pn[:node_x_pr_coord] ]
    end
    # search domains
    droots.each {|dr|
      dom = SpinDomain.where :domain_root_node_hashkey => dr
      if dom.length > 0
        dom.each {|dm|
          domains.push dm[:hash_key]
        }
      end
    }
    #    end
    return domains
  end

  # => end of .search_domains_of_node node_key

  def self.get_location_vpath vloc
    # is vloc is root?
    if vloc == [0, 0, 0, 0] # => root node
      return "/"
    end

    return SpinNode.get_spin_node_vpath(vloc[X], vloc[Y])

    #    # initialize directory names
    #    dirnames = Array.new
    #    x = vloc[X]
    #    y = vloc[Y]
    #    prx = vloc[PRX]
    #    v = vloc[V]
    #    # get directory names
    #    ActiveRecord::Base.transaction do
    #      p = SpinNode.readonly.select("node_x_coord,node_y_coord,node_x_pr_coord,node_name").where(:node_x_coord => x, :node_y_coord => y).order("node_version DESC")
    #      while p.length > 0 do
    #        pp x,y,dirnames
    #        dirnames << p[-1][:node_name]
    #        y = p[-1][:node_y_coord] - 1
    #        x = p[-1][:node_x_pr_coord] 
    #        if [x,y] == [0,0] # => now at root! exit
    #          break
    #        end
    #        p = SpinNode.readonly.select("node_x_coord,node_y_coord,node_x_pr_coord,node_name").where(:node_x_coord => x, :node_y_coord => y).order("node_version DESC")
    #      end
    #    end
    #    # depth
    #    depth = dirnames.count
    #    vp = ""
    #    # inverse order
    #    # pp depth
    #    for i in 1..depth do
    #      vp << "/" << dirnames[-i]
    #    end
    #    # rturns virtual path of the location
    #    return vp    
  end

  # => end of get_location_vpath

  def self.get_key_vpath sid, key, type = ANY_TYPE
    if key.blank?
      return nil
    end
    if SpinAccessControl.is_accessible_node(sid, key, type) == false
      return nil
    end

    return SpinNode.get_vpath(key)

    #    vloc = self.key_to_location key, type
    #    # is vloc is root?
    #    if vloc == [0,0,0,0] # => root node
    #      return "/"
    #    end
    #    # initialize directory names
    #    dirnames = Array.new
    #    x = vloc[X]
    #    y = vloc[Y]
    ##    prx = vloc[PRX]
    ##    v = vloc[V]
    #    # get directory names
    #    ActiveRecord::Base.transaction do
    #      while y >= 0  do
    #        pns = SpinNode.readonly.select("node_x_coord,node_y_coord,node_x_pr_coord,node_name").where(:node_x_coord => x, :node_y_coord => y).order("node_version")
    #        pp x,y,dirnames
    #        if pns.length > 0
    #          pn = pns[-1]
    #          dirnames.push pn[:node_name]
    #          x = pn[:node_x_pr_coord] 
    #          y = pn[:node_y_coord] - 1
    #        else
    #          break
    #        end
    #      end
    #    end
    #    # depth
    #    depth = dirnames.count
    #    vp = ""
    #    # inverse order
    #    # pp depth
    #    for i in 1..depth do
    #      vp << "/" << dirnames[-i]
    #    end
    #    # rturns virtual path of the location
    #    return vp    
  end

  # => end of get_location_vpath

  #  def self.get_thumbnail_path sid, node_key, px, py, v, spin_node_tree, data_type
  #    # Is node accessible for thumbnail?
  #    thumbnail_node_rpath = ''
  #    unless SpinAccessControl.is_accessible_thumbnail_node(sid, node_key, NODE_FILE) # => always TRUE now
  #      FileManager.rails_logger ">> get_thumbnail_path rerturns not-accessible-path."
  #      return thumbnail_node_rpath # => It's empty now!
  #    end
  #    
  #    # get node
  #    imgnodes = SpinLocationMapping.where(["spin_node_tree_and_node_x_coord_and_node_y_coord_and_node_version = ?", spin_node_tree, px, py, v ]).order("node_version DESC")
  #    unless imgnodes.length > 0
  #      FileManager.rails_logger ">> get_thumbnail_path rerturns empty path."
  #    end
  #    return thumbnail_node_rpath unless imgnodes.length > 0 # => returns ''
  #
  #    case data_type
  #    when 'jpg','tiff','png','bmp','ai','psd','eps','JPG','TIFF','PNG','BMP','JPEG','TIF','eps'
  #      open_file_name = (imgnodes[0][:location_path].split('/'))[-1]
  #      thumbnail_node_rpath = (imgnodes[0][:thumbnail_location_path].blank? ? SpinUrl.generate_url(sid, node_key, open_file_name, NODE_THUMBNAIL) : imgnodes[0][:thumbnail_location_path])
  #      #      thumbnail_node_rpath = (imgnodes[0][:thumbnail_location_path].blank? ? '' : imgnodes[0][:thumbnail_location_path])
  #    when 'mp4','ogg','mov','avi','MP4','OGG','MOV','AVI'
  #      open_file_name = (imgnodes[0][:location_path].split('/'))[-1]
  #      thumbnail_node_rpath = (imgnodes[0][:proxy_location_path].blank? ? SpinUrl.generate_url(sid, node_key, open_file_name, NODE_PROXY_MOVIE) : imgnodes[0][:proxy_location_path])
  #      #      thumbnail_node_rpath = (imgnodes[0][:proxy_location_path] != nil ? imgnodes[0][:proxy_location_path] : '')
  #    else
  #      thumbnail_node_rpath = (imgnodes[0][:thumbnail_location_path].blank? ? '' : imgnodes[0][:thumbnail_location_path])
  #    end
  #    
  #    FileManager.rails_logger ">> get_thumbnail_path rerturns path = #{thumbnail_node_rpath}."
  #    return thumbnail_node_rpath
  #  end # => end of self.get_thumbnail_path

  def self.get_thumbnail_info(sid, node_key)
    # Is node accessible for thumbnail?
    #    my_thumbnail_info = Hash.new
    my_thumbnail_info = {:thumbnail_path => '', :thumbnail_size => -1}
    unless SpinAccessControl.is_accessible_thumbnail_node(sid, node_key, NODE_FILE) # => always TRUE now
      FileManager.rails_logger ">> get_thumbnail_info rerturns not-accessible-path."
      return my_thumbnail_info # => It's empty now!
    end

    # get node
    spin_node = SpinNode.select("node_x_coord,node_y_coord,node_version").find_by_spin_node_hashkey(node_key)
    if spin_node.blank?
      return my_thumbnail_info
    end
    px = spin_node[:node_x_coord]
    py = spin_node[:node_y_coord]
    v = spin_node[:node_version]
    thumbnail_node = SpinNode.find_by_node_x_coord_and_node_y_coord_and_node_version_and_spin_tree_type(px, py, v, SPIN_THUMBNAIL_VTREE)
    imgnode = SpinLocationMapping.readonly.find_by_node_hash_key(node_key)

    data_size = -1
    if thumbnail_node.present? and imgnode.present?
      data_size = thumbnail_node[:node_size_upper] * MAX_INTEGER + thumbnail_node[:node_size]
      if data_size <= MAX_INLINE_SIZE
        my_thumbnail_info[:thumbnail_path] = imgnode[:thumbnail_location_path]
        my_thumbnail_info[:thumbnail_size] = data_size
      end
    end
    return my_thumbnail_info
  end

  # => end of self.get_thumbnail_path

  def self.thumbnail_exists node_key, node_type = NODE_FILE
    tn = SpinLocationhMapping.find_by_by_node_hash_key_and_node_type(node_key, node_type)
    if tn.present? and tn[:thumbnail_location_path] != ''
      return true
    else
      return false
    end
  end

  def self.get_vpath_location sid, virtual_path
    # analyze virtual_path path
    # => ex. /clients/a_coorporation/orginization/.../

    vloc = [0, 0, 0, 0] # => means ROOT
    # => it's the ROOT if virtual_path == '/'
    if virtual_path == '/'
      return vloc
    end

    not_exists = []
    1.upto(4) {
      not_exists.push -1
    }

    vnode = nil
    begin
      vnode = SpinNode.readonly.select("node_x_coord,node_y_coord,node_x_pr_coord,node_version").find_by_virtual_path(virtual_path)
      if vnode.blank?
        return not_exists
      end
    rescue ActiveRecord::RecordNotFound
      return not_exists
    end

    if SpinAccessControl.is_accessible_node(sid, vnode, ANY_TYPE) == false
      return not_exists
    end

    vloc = []
    vloc[X] = vnode[:node_x_coord]
    vloc[Y] = vnode[:node_y_coord]
    vloc[PRX] = vnode[:node_x_pr_coord]
    vloc[V] = vnode[:node_version]

    return vloc

  end

  # => end of get_vpath_location

  def self.get_vpath_key virtual_path
    # analyze virtual_path path
    # => ex. /clients/a_coorporation/orginization/.../

    FileManager.rails_logger('get_vpath_ley : ' + virtual_path)

    if virtual_path.blank?
      root_node = SpinNode.find_by_spin_tree_type_and_node_x_coord_and_node_y_coord(0, 0, 0)
      if root_node.blank?
        return nil
      end
      return root_node[:spin_node_hashkey]
    end

    vpnode = SpinNode.find_by_virtual_path(virtual_path)
    if vpnode.blank?
      return nil
    end
    return vpnode[:spin_node_hashkey]

  end

  # => end of self.get_vpath_key virtual_path

  def self.list_files sid, node, node_type = ANY_TYPE, recursive = false, max_depth = -1 # => ls command
    # root_node_loc : [x,y,prx,v] * only [x,y] are used!
    # include_root_flag : indicates this should return the tree obj which includes root_node_loc if it is true
    # initialize
    root_node_loc = self.key_to_location node, node_type
    tree_nodes = Array.new
    stack_nodes = Array.new
    parent_x = root_node_loc[X]
    children_y = root_node_loc[Y] + 1
    search_max_depth = -1
    if max_depth != -1
      search_max_depth = children_y + max_depth
    end
    # process tree
    children_nodes = []
    #    ActiveRecord::Base.transaction do
    children_nodes = SpinNode.readonly.where(["spin_tree_type_and_node_x_pr_coord_and_node_y_coord_and_node_type_and_in_trash_flag = false AND is_void = false", SPIN_NODE_VTREE, parent_x, children_y, NODE_DIRECTORY]).order("node_name")
    #    end
    while children_nodes.count > 0 || stack_nodes.count > 0 do # => there are nodes under the current node
      # there are some children
      children_nodes.each {|cn|
        acls = SpinAccessControl.has_acl_values sid, cn[:spin_node_hashkey], NODE_DIRECTORY
        if acls[:user] > ACL_NODE_NO_ACCESS or acls[:group] > ACL_NODE_NO_ACCESS or acls[:world] > ACL_NODE_NO_ACCESS
          tree_nodes << {:node_key => cn[:spin_node_hashkey], :node_name => cn[:node_name], :node_type => cn[:node_type], :x => cn[:node_x_coord], :y => cn[:node_y_coord], :acl => cn[:spin_uid_access_right], :updated_at => cn[:updated_at], :spin_updated_at => cn[:spin_updated_at], :trashed_at => cn[:trashed_at]}
          if search_max_depth == -1 or search_max_depth >= children_y
            stack_nodes << {:node_key => cn[:spin_node_hashkey], :node_name => cn[:node_name], :node_type => cn[:node_type], :x => cn[:node_x_coord], :y => cn[:node_y_coord], :acl => cn[:spin_uid_access_right], :updated_at => cn[:updated_at], :spin_updated_at => cn[:spin_updated_at], :trashed_at => cn[:trashed_at]}
          end
        end
      }
      unless recursive
        break # => exit while loop if it isn't recursive
      end
      # pop 1 from stack_nodes
      if stack_nodes.count > 0
        s_node = stack_nodes[-1] # => pop 1
        stack_nodes -= [s_node] # => remove it
        parent_x = s_node[:x]
        children_y = s_node[:y] + 1
      else # => end of children of the layers
        break # => exit from while loop
      end # => end of if stack_nodes.count > 0
      #      ActiveRecord::Base.transaction do
      children_nodes = SpinNode.readonly.where(["spin_tree_type_and_node_x_pr_coord_and_node_y_coord_and_node_type_and_in_trash_flag = false AND is_void = false", SPIN_NODE_VTREE, parent_x, children_y, NODE_DIRECTORY]).order("node_name")
      #      end
    end # =>  end of while
    return tree_nodes
  end

  # => end of list_files

  def self.list_nodes sid, node, node_type = ANY_TYPE, recursive = false, max_depth = -1 # => ls command
    # root_node_loc : [x,y,prx,v] * only [x,y] are used!
    # include_root_flag : indicates this should return the tree obj which includes root_node_loc if it is true
    # initialize
    root_node_loc = self.key_to_location node, node_type
    tree_nodes = Array.new
    stack_nodes = Array.new
    parent_x = root_node_loc[X]
    children_y = root_node_loc[Y] + 1
    search_max_depth = -1
    if max_depth != -1
      search_max_depth = children_y + max_depth
    end
    # process tree
    children_nodes = []
    #    ActiveRecord::Base.transaction do
    children_nodes = SpinNode.readonly.where(["spin_tree_type_and_node_x_pr_coord_and_node_y_coord_and_node_type_and_in_trash_flag = false AND is_void = false", SPIN_NODE_VTREE, parent_x, children_y, NODE_DIRECTORY]).order("node_name")
    #    end
    while children_nodes.count > 0 || stack_nodes.count > 0 do # => there are nodes under the current node
      # there are some children
      children_nodes.each {|cn|
        acls = SpinAccessControl.has_acl_values sid, cn[:spin_node_hashkey], NODE_DIRECTORY
        if acls[:user] > ACL_NODE_NO_ACCESS or acls[:group] > ACL_NODE_NO_ACCESS or acls[:world] > ACL_NODE_NO_ACCESS
          tree_nodes.append cn
          if search_max_depth == -1 or search_max_depth >= children_y
            stack_nodes << {:node_key => cn[:spin_node_hashkey], :node_name => cn[:node_name], :node_type => cn[:node_type], :x => cn[:node_x_coord], :y => cn[:node_y_coord], :acl => cn[:spin_uid_access_right], :updated_at => cn[:updated_at], :spin_updated_at => cn[:spin_updated_at], :trashed_at => cn[:trashed_at]}
          end
        end
      }
      unless recursive
        break # => exit while loop if it isn't recursive
      end
      # pop 1 from stack_nodes
      if stack_nodes.count > 0
        s_node = stack_nodes[-1] # => pop 1
        stack_nodes -= [s_node] # => remove it
        parent_x = s_node[:x]
        children_y = s_node[:y] + 1
      else # => end of children of the layers
        break # => exit from while loop
      end # => end of if stack_nodes.count > 0
      #      ActiveRecord::Base.transaction do
      children_nodes = SpinNode.readonly.where(["spin_tree_type_and_node_x_pr_coord_and_node_y_coord_and_node_type_and_in_trash_flag = false AND is_void = false", SPIN_NODE_VTREE, parent_x, children_y, NODE_DIRECTORY]).order("node_name")
      #      end
    end # =>  end of while
    return tree_nodes
  end

  # => end of list_nodes

  def self.get_sub_tree_nodes sid, root_node_loc, max_depth = -1
    # root_node_loc : [x,y,prx,v] * only [x,y] are used!
    # include_root_flag : indicates this should return the tree obj which includes root_node_loc if it is true
    # initialize
    tree_nodes = Array.new
    stack_nodes = Array.new
    parent_x = root_node_loc[X]
    children_y = root_node_loc[Y] + 1
    search_max_depth = children_y
    if max_depth != -1
      search_max_depth = children_y + max_depth
    end
    children_nodes = []
    #    ActiveRecord::Base.transaction do
    children_nodes = SpinNode.readonly.where(["spin_tree_type_and_node_x_pr_coord_and_node_y_coord_and_node_type_and_is_pending = false AND in_trash_flag = false AND is_void = false AND latest = true", SPIN_NODE_VTREE, parent_x, children_y, NODE_DIRECTORY]).order("node_name")
    #    end
    stack_counter = 0
    #      while children_nodes.count > 0 || stack_nodes.count > 0 do # => there are nodes under the current node
    while stack_counter >= 0 do # => there are nodes under the current node
      # there are some children
      children_nodes.each {|cn|
        acls = SpinAccessControl.has_acl_values sid, cn[:spin_node_hashkey], NODE_DIRECTORY
        if acls[:user] > ACL_NODE_NO_ACCESS or acls[:group] > ACL_NODE_NO_ACCESS or acls[:world] > ACL_NODE_NO_ACCESS
          tree_nodes.append cn
          #          tree_nodes << { :node_key => cn[:spin_node_hashkey], :node_name => cn[:node_name], :node_type => cn[:node_type], :x => cn[:node_x_coord], :y => cn[:node_y_coord], :acl => cn[:spin_uid_access_right], :updated_at => cn[:updated_at], :spin_updated_at => cn[:spin_updated_at], :trashed_at => cn[:trashed_at] }
          if search_max_depth == -1 or search_max_depth >= children_y
            stack_nodes << {:node_key => cn[:spin_node_hashkey], :node_name => cn[:node_name], :node_type => cn[:node_type], :x => cn[:node_x_coord], :y => cn[:node_y_coord], :acl => cn[:spin_uid_access_right], :updated_at => cn[:updated_at], :spin_updated_at => cn[:spin_updated_at], :trashed_at => cn[:trashed_at]}
            stack_counter += 1
          end
        end
      }
      # pop 1 from stack_nodes
      if stack_nodes.count > 0
        s_node = stack_nodes[-1] # => pop 1
        stack_nodes -= [s_node] # => remove it
        parent_x = s_node[:x]
        children_y = s_node[:y] + 1
        stack_counter -= 1
      else # => end of children of the layers
        stack_counter -= 1
      end # => end of if stack_nodes.count > 0
      #      ActiveRecord::Base.transaction do
      children_nodes = SpinNode.readonly.where(["spin_tree_type_and_node_x_pr_coord_and_node_y_coord_and_node_type_and_is_pending = false AND in_trash_flag = false AND is_void = false AND latest = true", SPIN_NODE_VTREE, parent_x, children_y, NODE_DIRECTORY]).order("node_name")
      #      end
    end # =>  end of while
    return tree_nodes
  end

  # => end of get_sub_tree_nodes

  def self.get_expanded_sub_tree_nodes sid, location, domain_hash_key, root_node_hashkey
    # root_node_loc : [x,y,prx,v] * only [x,y] are used!
    # include_root_flag : indicates this should return the tree obj which includes root_node_loc if it is true
    # initialize
    root_node_loc = self.key_to_location root_node_hashkey, NODE_DIRECTORY
    tree_nodes = Array.new
    stack_nodes = Array.new
    parent_is_expanded_flags = Array.new
    grand_parent_is_expanded_flags = Array.new
    parent_x = root_node_loc[X]
    children_y = root_node_loc[Y] + 1
    parent_is_expanded = true
    grand_parent_is_expanded = true
    # process tree
    children_nodes = []
    #    ActiveRecord::Base.transaction do
    #          printf ">> before 1) SpinNode.readonly.find at %s\n", (Time.now).to_s
    children_nodes = SpinNode.readonly.where(["spin_tree_type_and_node_x_pr_coord_and_node_y_coord_and_node_type_and_is_pending = false AND in_trash_flag = false AND is_void = false AND latest = true", SPIN_NODE_VTREE, parent_x, children_y, NODE_DIRECTORY]).order("node_name")
    #          printf "<< after 1) SpinNode.readonly.find at %s\n", (Time.now).to_s
    # children_nodes = SpinNode.readonly.where(:node_x_pr_coord => parent_x, :node_y_coord => children_y, :node_type => NODE_DIRECTORY)
    # children_nodes.order("node_name")
    loop_count = 1
    while children_nodes.length > 0 || stack_nodes.length > 0 do # => there are nodes under the current node
      children_nodes.each {|cn|
        #          printf ">>>>> start of loop : %d\n", loop_count
        loop_count += 1
        next unless SpinAccessControl.is_accessible_node(sid, cn[:spin_node_hashkey], NODE_DIRECTORY)
        cn_is_expanded = FolderDatum.is_expanded_folder2 sid, location, domain_hash_key, cn[:spin_node_hashkey]
        #          printf ">> before SpinNode.has_children at %s\n", (Time.now).to_s
        cn_has_children = SpinNode.has_children cn[:spin_node_hashkey]
        #          printf "<< after SpinNode.has_children at %s\n", (Time.now).to_s
        #          printf ">> before pinAccessControl.has_acl_values at %s\n", (Time.now).to_s
        acls = SpinAccessControl.has_acl_values sid, cn[:spin_node_hashkey], NODE_DIRECTORY
        #          printf "<< after spinAccessControl.has_acl_values at %s\n", (Time.now).to_s
        if acls[:user] > ACL_NODE_NO_ACCESS or acls[:group] > ACL_NODE_NO_ACCESS or acls[:world] > ACL_NODE_NO_ACCESS
          tree_nodes.append cn
          if parent_is_expanded == true and cn_is_expanded == true
            stack_nodes.push cn
            parent_is_expanded_flags.push true
            grand_parent_is_expanded_flags.push true
          elsif parent_is_expanded == true and cn_is_expanded == false and cn_has_children == true
            stack_nodes.push cn
            parent_is_expanded_flags.push false
            grand_parent_is_expanded_flags.push false
          elsif grand_parent_is_expanded and cn_has_children == true
            stack_nodes.push cn
            parent_is_expanded_flags.push parent_is_expanded
            grand_parent_is_expanded_flags.push false
          else
            if cn[:node_name] == 'kiyofuji.teddy'
              #                printf ">> grand_parent_is_expanded : false, parent_is_expanded : false"
            end
          end
        end
      }
      # pop 1 from stack_nodes
      #        printf ">> stack_node.length = %d\n", stack_nodes.length
      if stack_nodes.length > 0
        s_node = stack_nodes.pop # => pop
        parent_x = s_node[:node_x_coord]
        children_y = s_node[:node_y_coord] + 1
        parent_is_expanded = parent_is_expanded_flags.pop
        grand_parent_is_expanded = grand_parent_is_expanded_flags.pop
      else # => end of children of the layers
        break # => exit from while loop
      end # => end of if stack_nodes.count > 0
      #          printf ">> before SpinNode.readonly.find at %s\n", (Time.now).to_s
      children_nodes = SpinNode.readonly.where(["spin_tree_type_and_node_x_pr_coord_and_node_y_coord_and_node_type_and_is_pending = false AND in_trash_flag = false AND is_void = false AND latest = true", SPIN_NODE_VTREE, parent_x, children_y, NODE_DIRECTORY]).order("node_name")
      #          printf "<< after SpinNode.readonly.find at %s\n", (Time.now).to_s
    end # =>  end of while
    #    end
    #    children_nodes = SpinNode.readonly.where( :order => "node_name", "node_x_pr_coord = #{parent_x} AND node_y_coord = #{children_y} AND node_type = #{NODE_DIRECTORY} AND in_trash_flag = false AND is_void = false AND is_pending = false")
    return tree_nodes
  end

  # => end of get_expanded_sub_tree_nodes

  def self.key_to_location node_key, t = ANY_TYPE
    # node_key : hash_key
    # t : node type
    node = nil
    loc = [-1, -1, -1, -1]
    #    ActiveRecord::Base.transaction do

    if t == ANY_TYPE
      node = SpinNode.readonly.select("node_x_coord,node_y_coord,node_x_pr_coord,node_version").find_by_spin_node_hashkey(node_key)
    else
      node = SpinNode.readonly.select("node_x_coord,node_y_coord,node_x_pr_coord,node_version").find_by_spin_node_hashkey_and_node_type(node_key, t)
    end
    if node.blank?
      return [-1, -1, -1, -1]
    end
    #    end
    loc[X] = node[:node_x_coord]
    loc[Y] = node[:node_y_coord]
    loc[PRX] = node[:node_x_pr_coord]
    loc[V] = node[:node_version]
    return loc
  end

  # => end of key_to_location

  def self.move_location_org move_sid, src, dst
    FileManager.rails_logger src.to_s
    FileManager.rails_logger dst.to_s
    #    ActiveRecord::Base.lock_optimistically = false
    SpinLocationMapping.transaction do
      #      SpinLocation<Mapping.find_by_sql("LOCK TABLE spin_location_mappings IN EXCLUSIVE MODE;")

      mloc = nil
      begin
        mloc = SpinLocationMapping.find_by_node_x_coord_and_node_y_coord_and_node_version(src[X], src[Y], src[V])
        if mloc.blank?
          return [-1, -1, -1, -1, nil]
        end
        #    ActiveRecord::Base.transaction do
        #      mvlocs.each { |mloc|
        mloc[:node_x_coord] = dst[X]
        mloc[:node_y_coord] = dst[Y]
        mloc[:node_x_pr_coord] = dst[PRX]
        mloc[:node_version] = dst[V]
        mloc[:node_hash_key] = dst[K]
        unless mloc.save
          return [-1, -1, -1, -1, nil]
        end
      rescue ActiveRecord::RecordNotFound
        return [-1, -1, -1, -1, nil]
      end
      #      }
    end # => end of transaction
    return dst
  end

  # => end of self.move_location src, dst

  def self.move_location move_sid, src, dst
    src_node = SpinNode.find_by_node_x_coord_and_node_y_coord_and_node_version_and_spin_tree_type src[X], src[Y], src[V], src[VTREE]
    if src_node.blank?
      return [-1, -1, -1, -1, nil]
    end
    dst_node = SpinNode.readonly.find_by_node_x_coord_and_node_y_coord_and_node_version_and_spin_tree_type dst[X], dst[Y], dst[V], dst[VTREE]
    if dst_node.blank?
      return [-1, -1, -1, -1, nil]
    end
    FileManager.rails_logger (">> SpinLocationManager.move_location " + move_sid + ', ' + src.to_s + ', ' + dst.to_s)
    #    FileManager.rails_logger src.to_s
    #    FileManager.rails_logger dst.to_s
    fm_args = []

    SpinLocationMapping.transaction do
      #      SpinLocation<Mapping.find_by_sql("LOCK TABLE spin_location_mappings IN EXCLUSIVE MODE;")
      mvlocs = SpinLocationMapping.where(["node_x_coord_and_node_y_coord_and_node_version = ?", src[X], src[Y], src[V]])
      mvlocs.each {|mvloc| # => only one instance
        coords = [mvloc[:node_x_coord], mvloc[:node_y_coord], mvloc[:node_version], src[VTREE], dst[X], dst[Y], dst[V], dst[VTREE]].to_s
        FileManager.rails_logger(">> pass coords : " + coords)
        fm_args.push(coords)
        fm_args.push(src_node[:spin_node_hashkey])
        fm_args.push(src_node[:node_name])
        fm_args.push(dst_node[:spin_node_hashkey])
        retj = SpinFileManager.request move_sid, 'move_node', fm_args
        reth = JSON.parse retj
        if reth['success']
          return dst
        else
          return [-1, -1, -1, -1, nil]
        end
      }
    end # => end of transaction
  end

  # => end of self.move_location src, dst

  def self.xxmove_location move_sid, src, dst
    src_node = SpinNode.find_by_node_x_coord_and_node_y_coord_and_node_version_and_spin_tree_type src[X], src[Y], src[V], SPIN_NODE_VTREE
    FileManager.rails_logger (">> SpinLocationManager.move_location " + move_sid + ', ' + src.to_s + ', ' + dst.to_s)
    #    FileManager.rails_logger src.to_s
    #    FileManager.rails_logger dst.to_s
    if src_node.blank?
      return [-1, -1, -1, -1, nil]
    end
    fm_args = []
    mvlocs = SpinLocationMapping.where(["node_x_coord_and_node_y_coord_and_node_version = ?", src[X], src[Y], src[V]])
    mvlocs.each {|mvloc| # => only one instance
      coords = [mvloc[:node_x_coord], mvloc[:node_y_coord], mvloc[:node_version], dst[X], dst[Y], src[V]].to_s
      FileManager.rails_logger(">> pass coords : " + coords)
      fm_args.push(coords)
      fm_args.push(src_node[:spin_node_hashkey])
      fm_args.push(src_node[:node_name])
      fm_args.push(dst[K])
      retj = SpinFileManager.request move_sid, 'move_node', fm_args
      reth = JSON.parse retj
      if reth['success']
        return dst
      else
        return [-1, -1, -1, -1, nil]
      end
    }
  end

  # => end of self.move_location src, dst

  def self.remove_node_from_storage remove_sid, remove_file_key, async_mode = false
    # get uid and remove from recycler_data
    uid = SessionManager.get_uid remove_sid
    ret = nil
    remove_node = nil
    #    ret = self.destroy_all :spin_uid => uid, :spin_node_hashkey => remove_file_key
    # set in_use_uid in spin_nodes rec
    #    ActiveRecord::Base.lock_optimistically = false
    SpinNode.transaction do
      remove_node = SpinNode.find_by_spin_node_hashkey remove_file_key
      if remove_node.blank?
        return nil
      end
      #    nt = remove_node[:node_type]
      remove_node[:in_use_uid] = uid
      remove_node[:in_trash_flag] = false
      remove_node[:is_pending] = false
      if remove_node.save
        #      if remove_node[:node_type] == NODE_DIRECTORY
        #        return remove_file_key
        #      end
      else
        return ret
      end
    end # => end of transaction
    # send remove-request to file manager
    # if nt != NODE_DIRECTORY
    # retf = SpinFileSystem::SpinFileManager.remove_node remove_sid, remove_file_key
    # end
    if remove_node[:node_type] != NODE_DIRECTORY or async_mode
      fm_args = Array.new
      fm_args.append remove_file_key
      case ENV['RAILS_ENV']
      when 'development'
        retj = SpinFileManager.request remove_sid, 'remove_node', fm_args
        reth = JSON.parse retj
        if reth['success'] == true
          SpinNode.set_void(remove_file_key)
          ret = remove_file_key
        end
        #      return remove_file_key
      when 'production'
        retj = SpinFileManager.request remove_sid, 'remove_node', fm_args
        reth = JSON.parse retj
        if reth['success']
          SpinNode.set_void(remove_file_key)
          ret = remove_file_key
        end
      end
    else # => directory node
      retk = SpinNodeKeeper.delete_node_keeper_record(remove_node[:node_x_coord], remove_node[:node_y_coord])
      if SpinNode.delete_node(remove_sid, remove_file_key, true)
        ret = remove_file_key
      end
    end # => end of remove_node[:node_type] != NODE_DIRECTORY

    # remove node 
    return ret #  removed rec
  end

  # => end of self.delete_node_from_recycler remove_sid, rf

  def self.xmove_location move_sid, src, dst
    FileManager.rails_logger src.to_s
    FileManager.rails_logger dst.to_s
    mvlocs = SpinLocationMapping.where(["node_x_coord_and_node_y_coord_and_node_version = ?", src[X], src[Y], src[V]])
    #    ActiveRecord::Base.lock_optimistically = false
    SpinLocationMapping.transaction do
      #       SpinLocationMapping.find_by_sql('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;')
      mvlocs.each {|mloc|
        mloc[:node_x_coord] = dst[X]
        mloc[:node_y_coord] = dst[Y]
        mloc[:node_x_pr_coord] = dst[PRX]
        mloc[:node_version] = dst[V]
        mloc[:node_hash_key] = dst[K]
        mloc.save
      }
    end # => end of transaction
  end

  # => end of self.move_location src, dst

  def self.copy_location copy_sid, src, dst
    src_node = SpinNode.readonly.find_by_node_x_coord_and_node_y_coord_and_node_version_and_spin_tree_type src[X], src[Y], src[V], src[VTREE]
    if src_node.blank?
      return [-1, -1, -1, -1, nil]
    end
    dst_node = SpinNode.readonly.find_by_node_x_coord_and_node_y_coord_and_node_version_and_spin_tree_type dst[X], dst[Y], dst[V], dst[VTREE]
    if dst_node.blank?
      return [-1, -1, -1, -1, nil]
    end
    FileManager.rails_logger (">> SpinLocationManager.copy_location " + copy_sid + ', ' + src.to_s + ', ' + dst.to_s)
    #    FileManager.rails_logger src.to_s
    #    FileManager.rails_logger dst.to_s
    cplocs = SpinLocationMapping.readonly.where(["node_x_coord_and_node_y_coord_and_node_version = ?", src[X], src[Y], src[V]])
    cplocs.each {|cploc| # => only one instance
      fm_args = [cploc[:node_x_coord], cploc[:node_y_coord], cploc[:node_version], src[VTREE], dst[X], dst[Y], dst[V], dst[VTREE]]
      fm_args.push(src_node[:spin_node_hashkey])
      fm_args.push(src_node[:node_name])
      fm_args.push(dst_node[:spin_node_hashkey])
      FileManager.rails_logger(">> pass coords and args: " + fm_args.to_s)
      retj = SpinFileManager.request copy_sid, 'copy_node', fm_args
      reth = JSON.parse retj
      if reth['success']
        return dst
      else
        FileManager.rails_logger (">> SpinLocationManager.copy_location : spin_file_manager returned FALSE")
        return [-1, -1, -1, -1, nil]
      end
    }
  end

  # => end of self.copy_location src, dst

  def self.location_to_key xy, t = ANY_TYPE
    # xy : [x,y,prx,v]
    # t : node type
    key = String.new
    len = xy.length
    if len < 2 # => invalid
      return nil
    elsif len >= 3
      #      if xy[Y] < 0
      #        xy[0,4].each {|v|
      #          v *= (-1)
      #        }
      #      end
      if xy[PRX] == ANY_PRX
        ks = []
        # k = SpinNode.readonly.find_by_node_x_coord_and_node_y_coord_and_node_version_and_node_type  xy[X],xy[Y],xy[V],t
        #        ActiveRecord::Base.transaction do
        if t == ANY_TYPE
          ks = SpinNode.readonly.select("spin_node_hashkey").where(["spin_tree_type = ? AND node_x_coord = ? And node_y_coord = ?", SPIN_NODE_VTREE, xy[X], xy[Y]]).order("node_version DESC")
        else
          ks = SpinNode.readonly.select("spin_node_hashkey").where(["spin_tree_type = ? AND node_x_coord = ? And node_y_coord = ? AND node_type = ?", SPIN_NODE_VTREE, xy[X], xy[Y]], t).order("node_version DESC")
        end
        #        end
        if ks.blank?
          return nil
        end
        key = ks[0][:spin_node_hashkey]
      else
        # k = SpinNode.readonly.find_by_node_x_coord_and_node_y_coord_and_node_x_pr_coord_and_node_version_and_node_type xy[X],xy[Y],xy[PRX],xy[V],t
        ks = []
        #        ActiveRecord::Base.transaction do
        if t == ANY_TYPE
          ks = SpinNode.readonly.select("spin_node_hashkey").where(["spin_tree_type = ? AND node_x_coord = ? AND node_y_coord = ? AND node_x_pr_coord = ?", SPIN_NODE_VTREE, xy[X], xy[Y], xy[PRX]]).order("node_version DESC")
        else
          ks = SpinNode.readonly.select("spin_node_hashkey").where(["spin_tree_type = ? AND node_x_coord = ? AND node_y_coord = ? AND node_x_pr_coord = ? AND node_type = ?", SPIN_NODE_VTREE, xy[X], xy[Y], xy[PRX], t]).order("node_version DESC")
        end
        #        end
        if ks.blank?
          return nil
        end
        key = ks[0][:spin_node_hashkey]
      end
    else # => (x,y)
      #      if xy[Y] < 0
      #        xy[0,2].each {|v|
      #          v *= (-1)
      #        }
      #      end
      ks = []
      #      ActiveRecord::Base.transaction do
      if t == ANY_TYPE
        ks = SpinNode.readonly.select("spin_node_hashkey").where(["spin_tree_type = ? AND node_x_coord = ? AND node_y_coord = ?", SPIN_NODE_VTREE, xy[X], xy[Y]]).order("node_version DESC")
      else
        ks = SpinNode.readonly.select("spin_node_hashkey").where(["spin_tree_type = ? AND node_x_coord = ? AND node_y_coord = ? AND node_type = ?", SPIN_NODE_VTREE, xy[X], xy[Y], t]).order("node_version DESC")
      end
      #      end
      if ks.blank?
        return nil
      end
      key = ks[0][:spin_node_hashkey]
    end
    return key
  end

  # => end of key_to_location

  def self.location_to_id xy, t = ANY_TYPE
    # xy : [x,y,prx,v]
    # t : node type
    key = String.new
    len = xy.length
    if len < 2 # => invalid
      return nil
    elsif len >= 4
      if xy[PRX] == ANY_PRX
        # k = SpinNode.readonly.find_by_node_x_coord_and_node_y_coord_and_node_version_and_node_type  xy[X],xy[Y],xy[V],t
        ks = []
        #        ActiveRecord::Base.transaction do
        if t == ANY_TYPE
          ks = SpinNode.readonly.find_by_spin_tree_type_and_node_x_coord_and_node_y_coord_and_latest(SPIN_NODE_VTREE, xy[X], xy[Y], true)
        else
          ks = SpinNode.readonly.find_by_spin_tree_type_and_node_x_coord_and_node_y_coord_and_node_type_and_latest(SPIN_NODE_VTREE, xy[X], xy[Y], t, true)
        end
        #        end
        if ks.blank?
          return nil
        end
        key = ks[0][:spin_node_hashkey]
      else
        # k = SpinNode.readonly.find_by_node_x_coord_and_node_y_coord_and_node_x_pr_coord_and_node_version_and_node_type xy[X],xy[Y],xy[PRX],xy[V],t
        ks = []
        #        ActiveRecord::Base.transaction do
        if t == ANY_TYPE
          #          ks = SpinNode.readonly.where(:node_x_coord => xy[X],:node_y_coord => xy[Y],:node_x_pr_coord => xy[PRX]).order("node_version DESC")
          ks = SpinNode.readonly.find_by_spin_tree_type_and_node_x_coord_and_node_y_coord_and_node_x_pr_coord_and_latest(SPIN_NODE_VTREE, xy[X], xy[Y], xy[PRX], true)
        else
          #          ks = SpinNode.readonly.where(:node_x_coord => xy[X],:node_y_coord => xy[Y],:node_x_pr_coord => xy[PRX],:node_type => t).order("node_version DESC")
          ks = SpinNode.readonly.find_by_spin_tree_type_and_node_x_coord_and_node_y_coord_and_node_x_pr_coord_and_node_type_and_latest(SPIN_NODE_VTREE, xy[X], xy[Y], xy[PRX], t, true)
        end
        #        end
        if ks.blank?
          return nil
        end
        key = ks[:id]
      end
    else
      ks = []
      #      ActiveRecord::Base.transaction do
      if t == ANY_TYPE
        ks = SpinNode.readonly.find_by_spin_tree_type_and_node_x_coord_and_node_y_coord_and_latest(SPIN_NODE_VTREE, xy[X], xy[Y], true)
      else
        ks = SpinNode.readonly.find_by_spin_tree_type_and_node_x_coord_and_node_y_coord_and_node_type_and_latest(SPIN_NODE_VTREE, xy[X], xy[Y], t, true)
      end
      #      end
      if ks.blank?
        return nil
      end
      key = ks[:id]
    end
    return key
  end

  # => end of key_to_location

  def self.get_parent_key node_key, t = ANY_TYPE
    #    if t == NODE_FILE
    #      pp "stop for debug!"
    #    end
    begin
      child = SpinNode.readonly.select("virtual_path,node_x_coord,node_y_coord").find_by_spin_node_hashkey(node_key)
      if child.blank?
        return nil
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    end

    # Is it ROOR?
    if child[:node_x_coord] == 0 and child[:node_y_coord] == 0
      return node_key # => Yes it is
    end

    #    FileManager.rails_logger("get_parent_key::child[:virtual_path] = " + child[:virtual_path])
    virtual_path = Pathname(child[:virtual_path]).to_s
    parent_path = Pathname(child[:virtual_path]).dirname.to_s

    if virtual_path.length == 0
      return nil
    end

    parents = Array.new
    if virtual_path == parent_path # => parent is ROOT
      root_vpath = '/'
      parents = SpinNode.readonly.select("spin_node_hashkey").where(["spin_tree_type = ? AND virtual_path = ? OR (node_x_coord = 0 AND node_y_coord = 0)", SPIN_NODE_VTREE, root_vpath]).order("node_version DESC")
    else
      parent_vpath = parent_path
      parents = SpinNode.readonly.select("spin_node_hashkey").where(["spin_tree_type = ? AND virtual_path = ? AND latest = ?", SPIN_NODE_VTREE, parent_vpath, true]).order("node_version DESC")
    end
    if parents.blank?
      return nil
    else
      return parents[0][:spin_node_hashkey]
    end
  end

  # => end of get_parent_key

  def self.get_parent_node child
    #    if t == NODE_FILE
    #      pp "stop for debug!"
    #    end
    # Is it ROOR?
    if child[:node_x_coord] == 0 and child[:node_y_coord] == 0
      return child # => Yes it is
    end

    begin
      parent = SpinNode.readonly.find_by_spin_tree_type_and_node_x_coord_and_node_y_coord_and_node_type_and_latest(SPIN_NODE_VTREE, child[:node_x_pr_coord], child[:node_y_coord] - 1, NODE_DIRECTORY, true)
      if parent.blank?
        return child
      end
      return parent
    rescue ActiveRecord::RecordNotFound
      return child
    end

  end

  # => end of get_parent_key

  def self.is_in_sub_tree(move_source_folder_hashkey, move_target_folder_hashkey)
    # self check
    if move_source_folder_hashkey == move_target_folder_hashkey
      return true
    end

    begin
      src = SpinNode.readonly.select("virtual_path").find_by_spin_node_hashkey(move_source_folder_hashkey)
      if src.blank?
        return false
      end
      tgt = SpinNode.readonly.select("virtual_path").find_by_spin_node_hashkey(move_target_folder_hashkey)
      if tgt.blank?
        return false
      end
    rescue ActiveRecord::RecordNotFound
      return false
    end

    src_vpath_dir = src[:virtual_path] + '/'
    if /#{src_vpath_dir}/ =~ tgt[:virtual_path]
      return true
    else
      return false
    end

  end

  # => end of self.is_in_sub_tree(move_source_folder_hashkey,move_target_folder_hashkey)

  def self.locate_domain_by_key sid, node_key
    pkey = node_key
    while pkey
      begin
        dom = DomainDatum.find_by_session_id_and_folder_hash_key sid, pkey
        if dom.present?
          return dom[:hash_key]
        end
      rescue ActiveRecord::RecordNotFound
      end
      pkey = self.get_parent_key pkey
    end
    return nil
  end

  # => end of locate_domain_by_key

  def self.vpath_mapping_locations vpx, vps, vpt
    # make difference between vpx and vps
    #    FileManager.rails_logger("vpx = " + vpx)
    #    FileManager.rails_logger("vps = " + vps)
    svpx = vpx.split('/')
    svps = vps.split('/')
    sl = svps.length
    dvp = svpx[sl..-1]

    # make new vpath : vpt + f(dvp)
    fvpt = vpt
    dvp.each {|dx|
      fvpt += ('/' + dx)
    }

    # fvpt will be the vpath you want.
    return fvpt
  end

  # => end of self.vpath_mapping_locations(fvpx, vps, vpt)

  def self.vpath_mapping_parent_vpath vpx
    # split vpath vpx
    svpx = vpx.split(/\//)
    fvpx = ''

    # make new vpath : vpt + f(dvp)
    svpx[0..-2].each {|dx|
      next if dx.blank?
      fvpx += ('/' + dx)
    }

    # fvpx will be the vpath you want.
    return fvpx
  end # => end of self.vpath_mapping_locations(fvpx, vps, vpt)

end
