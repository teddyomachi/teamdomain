# coding: utf-8
require 'const/vfs_const'
require 'const/acl_const'
require 'tasks/session_management'
require 'tasks/security'
require 'utilities/file_manager_utilities'
require 'pg'
require 'pp'

class SpinNodeKeeper < ActiveRecord::Base
  include Vfs
  include Acl
  include FileManager
  
  # attr_accessor :title, :body
  def self.test_and_set_layer_info layer_number, with_transaction = true
    r = {}
    if with_transaction
      self.transaction do
        l = self.find_by_layer layer_number
        if l
          l.last_x += 1
          l.first_free_x = l.last_x
          l.updated_at = Time.now
          l.save
          r = l
        else
          nl = self.new
          nl.layer = layer_number
          nl.last_x = 0
          nl.first_free_x = 0
          nl.save
          r = nl
        end
      end # => end of transaction
    else # => use this when call it in a transaction
      l = self.find_by_layer layer_number
      if l
        l.last_x += 1
        l.first_free_x = l.last_x
        l.updated_at = Time.now
        l.save
        r = l
      else
        nl = self.new
        nl.layer = layer_number
        nl.last_x = 0
        nl.first_free_x = 0
        nl.save
        r = nl
      end
    end
    return r
  end # => end of test_and_set_layer_info layer_number
  
  def self.test_and_set_x layer_number
    lx = -1
    layer = nil
    
    catch(:test_and_set_x_again) {
      
      #    ActiveRecord::Base.lock_optimistically = false
      SpinNodeKeeper.transaction do
        begin
          #      SpinNodeKeeper.find_by_sql('LOCK TABLE spin_node_keepers IN ROW EXCLUSIVE MODE;')
          layer = SpinNodeKeeper.find_by_layer_and_ny(layer_number,layer_number*(-1))
          if layer.blank?
            layer = self.create(:nx => INITIAL_X_COORD_VALUE, :ny => layer_number*(-1), :layer => layer_number, :last_x => (INITIAL_X_COORD_VALUE - 1), :first_free_x => INITIAL_X_COORD_VALUE)
            lx = INITIAL_X_COORD_VALUE - 1
            layer.save
          else
            lx = layer[:last_x] + 1
            layer[:last_x] = lx
            layer[:first_free_x] = lx + 1
            layer[:updated_at] = Time.now
            layer.save
          end
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :test_and_set_x_again
        end
      end # => end of transaction
    } # => end of cathch block

    # set pesimistic lock
    return lx
  end # => end of test_and_set_x layer_number
  
  #  def self.test_and_set_xy_org sid, request_loc, vfile_name = '', node_type = NODE_FILE
  #    # request_loc   [ X, Y, P, V ] : Y should be Z+-{0}, P spould be Z+, V may be REQUEST_COORD_VALUE
  #    # vfile_name  : file or directory name to assign coordinate value
  #    # node_type   : type of node { NODE_DIRECTORY, NODE_FILE,... } : optional
  #    
  #    # initialize var
  #    node_loc = [] # => array of length 0
  #    directory_node_exists = false
  #    # start
  #    # initialize
  #    x = REQUEST_COORD_VALUE
  #    y = REQUEST_COORD_VALUE
  #    v = REQUEST_COORD_VALUE # => any negative value
  #    #      request_rec = {}
  #      
  #    if request_loc[X] != REQUEST_COORD_VALUE # => new x-coord value is requested
  #      x = request_loc[X]
  #    end
  #    if request_loc[Y] != REQUEST_COORD_VALUE # => new y-coord value is requested
  #      y = request_loc[Y]
  #    end
  #
  #    
  #    layer_rec = {}
  #    layer_rec_r = {}
  #
  #    create_new_layer = proc {|layer|
  #      ret_val = nil
  #      # set pesimistic lock
  #      ActiveRecord::Base.lock_optimistically = false
  #      # get layer-0 lock! : for locking layers
  #      layer0 = self.find(["layer = ? AND ny = ?",LAYER0_LAYER,LAYER0_NY])
  #      if layer0 == nil
  #        ret_val = nil # => exit from test_and_set_xy
  #      else
  #        layer0.with_lock do
  #          # check layer again
  #          new_layer = self.find(["layer = ? AND ny = ?",layer,layer*(-1)])
  #          if new_layer == nil
  #            new_layer = self.create :nx => INITIAL_X_COORD_VALUE, :ny => layer*(-1), :layer => layer, :last_x => INITIAL_X_COORD_VALUE-1, :first_free_x => INITIAL_X_COORD_VALUE
  #          end
  #          ret_val = new_layer
  #          # create additional layers
  #          inc_layers = 1
  #          inc_layers.upto(ADD_NUMBER_OF_LAYERS) {|i|
  #            new_layer_number = new_layer[:layer] + i
  #            begin
  #              nl = self.create :nx => INITIAL_X_COORD_VALUE, :ny => new_layer_number*(-1), :layer => new_layer_number, :last_x => INITIAL_X_COORD_VALUE-1, :first_free_x => INITIAL_X_COORD_VALUE
  #            rescue
  #              next
  #            end
  #          }
  #        end # => end of layer0.with_lock do        
  #      end
  #      # set pesimistic lock
  #      ActiveRecord::Base.lock_optimistically = true
  #      ret_val
  #    }
  #    
  #    # check if there is a target layer first!
  #    self.transaction do
  #      layer_rec = self.find(["layer = ? AND ny = ?",y,y*(-1)]) # => layer_rec number is 'y-coord' value
  #      if layer_rec == nil
  #        # I need new layer
  #        layer_rec = create_new_layer.call y
  #        # check layer again
  #        if layer_rec == nil
  #          tstxy_log_msg = "test_and_set_xy : layer_rec == il at layer = #{y}"
  #          FileManager.logger(sid, tstxy_log_msg, nil)
  #          return [ -1, -1, -1, -1 ]
  #        end
  #      end
  #    end # => end of transaction
  #
  #    # set pesimistic lock
  #    ActiveRecord::Base.lock_optimistically = false
  #
  #    self.transaction do
  #      # is there rec for (x,y)?
  #      request_rec = self.find(["nx_pr = ? AND ny = ?",request_loc[PRX],y],:lock=>true)
  #      if request_rec != nil # => already is
  #        request_rec.with_lock do
  #          x = request_rec[:nx]
  #          prx = request_loc[PRX]
  #          begin
  #            if node_type == NODE_DIRECTORY
  #              v = INITIAL_VERSION_NUMBER
  #              directory_node_exists = true
  #            else
  #              vc = request_rec[:current_version]
  #              v = request_rec[:current_version] + 1
  #              request_rec[:current_version] = v
  #              request_rec[:node_type] = node_type
  #              request_rec.save
  #            end
  #          rescue  ActiveRecord::RecordNotUnique
  #            ActiveRecord::Base.lock_optimistically = true
  #            #            msg_a = [ request_rec[:nx],request_rec[:layer],vc,nv0[:max_versions]]
  #            tstxy_log_msg = "test_and_set_xy : exception : request_rec ActiveRecord::RecordNotUnique : " + request_rec.to_s
  #            FileManager.logger(sid, tstxy_log_msg, nil)
  #            return [ -1, -1, -1, -1 ]
  #          end # => end of begin-rescue
  #        end # => end of request_rec.with_lock
  #      else # => no request_rec : request_rec == nil
  #        # Get lock for the layer!
  #        layer_retry_count = ACTIVE_RECORD_RETRY_COUNT
  #        while layer_retry_count  = ACTIVE_RECORD_RETRY_COUNT
  #          begin
  #            layer_rec_r = self.find(["layer = ? AND ny = ?",y,y*(-1)],:lock=>true) # => layer_rec number is 'y-coord' value
  #            break
  #          rescue ActiveRecord::RecordNotFound
  #            layer_retry_count -= 1
  #          end
  #        end
  #        if layer_retry_count < 0
  #          return [ -1, -1, -1, -1 ]
  #        end
  #        layer_rec_r.with_lock do
  #          request_rec_r = self.find(["nx_pr = ? AND layer = ? AND node_name = ?",request_loc[PRX],y,vfile_name],:lock=>true)
  #          if request_rec_r != nil
  #            request_rec_r.with_lock do
  #              x = request_rec_r[:nx]
  #              prx = request_loc[PRX]
  #              begin
  #                if node_type == NODE_DIRECTORY
  #                  v = INITIAL_VERSION_NUMBER
  #                  directory_node_exists = true
  #                else
  #                  v = request_rec_r[:current_version] + 1
  #                  request_rec_r[:current_version] = v
  #                  request_rec_r[:node_type] = node_type
  #                  request_rec_r.save
  #                end
  #              rescue  ActiveRecord::RecordNotUnique
  #                tstxy_log_msg = "test_and_set_xy : exception : request_rec_r ActiveRecord::RecordNotUnique : " + request_rec_r.to_s
  #                FileManager.logger(sid, tstxy_log_msg, nil)
  #                ActiveRecord::Base.lock_optimistically = true
  #                return [ -1, -1, -1, -1 ]
  #              end # => end of begin-rescue
  #            end # => end of request_rec.with_lock
  #          else # => no request_rec_r : request_rec_r == nil
  #            # start
  #            x = layer_rec_r[:first_free_x]
  #            # => no P(x,y), create new
  #            prx = request_loc[PRX]
  #            v = INITIAL_VERSION_NUMBER
  #            #          x = layer_rec_r[:first_free_x]
  #            begin
  #              new_node_keeper_rec =  self.create :nx => x, :ny => y, :layer => y, :nx_pr => prx, :node_name => vfile_name, :current_version => INITIAL_VERSION_NUMBER, :node_type => node_type
  #              layer_rec_r[:last_x] = new_node_keeper_rec[:nx]
  #              layer_rec_r[:first_free_x] = new_node_keeper_rec[:nx] + 1
  #              layer_rec_r.save
  #            rescue ActiveRecord::RecordNotUnique
  #              if node_type == NODE_DIRECTORY
  #                node_loc = [ x, y, request_loc[PRX], v*(-1), nil, node_type ]
  #              else
  #                node_loc = [ x, y, request_loc[PRX], v, nil, node_type ]
  #              end
  #              return node_loc
  #            end # => end of begin-rescue block
  #          end # => end of if request_rec_r != nil
  #        end # => layer_rec_r.with_lock do
  #      end # => end of if request_rec != nil      
  #    end # => end of transaction
  #      
  #    ActiveRecord::Base.lock_optimistically = true
  #    
  #    if directory_node_exists
  #      node_loc = [ x, y, request_loc[PRX], v*(-1), nil, node_type ]
  #    else
  #      node_loc = [ x, y, request_loc[PRX], v, nil, node_type ]
  #    end
  #    
  #    return node_loc
  #  end # => end of test_and_set_xy parent_loc, vfile_name
  #
  #  def self.test_and_set_xy2 sid, request_loc, vfile_name = '', node_type = NODE_FILE
  #    # request_loc   [ X, Y, P, V ] : Y should be Z+-{0}, P spould be Z+, V may be REQUEST_COORD_VALUE
  #    # vfile_name  : file or directory name to assign coordinate value
  #    # node_type   : type of node { NODE_DIRECTORY, NODE_FILE,... } : optional
  #    
  #    # initialize var
  #    node_loc = [] # => array of length 0
  #    directory_node_exists = false
  #    # start
  #    # initialize
  #    x = REQUEST_COORD_VALUE
  #    y = REQUEST_COORD_VALUE
  #    prx = REQUEST_COORD_VALUE
  #    v = REQUEST_COORD_VALUE # => any negative value
  #    #      request_rec = {}
  #      
  #    if request_loc[X] != REQUEST_COORD_VALUE # => new x-coord value is requested
  #      x = request_loc[X]
  #    end
  #    if request_loc[Y] != REQUEST_COORD_VALUE # => new y-coord value is requested
  #      y = request_loc[Y]
  #    end
  #    if request_loc[PRX] != REQUEST_COORD_VALUE # => new x-coord value is requested
  #      prx = request_loc[PRX]
  #    end
  #
  #    
  #    layer_rec = {}
  #    layer_rec_r = {}
  #
  #    create_new_layer = proc {|layer|
  #      ret_val = nil
  #      # set pesimistic lock
  #      ActiveRecord::Base.lock_optimistically = false
  #      # get layer-0 lock! : for locking layers
  #      layer0 = self.find(["layer = ? AND ny = ?",LAYER0_LAYER,LAYER0_NY])
  #      if layer0 == nil
  #        ret_val = nil # => exit from test_and_set_xy
  #      else
  #        layer0.with_lock do
  #          # check layer again
  #          new_layer = self.find(["layer = ? AND ny = ?",layer,layer*(-1)])
  #          if new_layer == nil
  #            new_layer = self.create :nx => INITIAL_X_COORD_VALUE, :ny => layer*(-1), :layer => layer, :last_x => INITIAL_X_COORD_VALUE-1, :first_free_x => INITIAL_X_COORD_VALUE
  #          end
  #          ret_val = new_layer
  #          # create additional layers
  #          inc_layers = 1
  #          inc_layers.upto(ADD_NUMBER_OF_LAYERS) {|i|
  #            new_layer_number = new_layer[:layer] + i
  #            begin
  #              nl = self.create :nx => INITIAL_X_COORD_VALUE, :ny => new_layer_number*(-1), :layer => new_layer_number, :last_x => INITIAL_X_COORD_VALUE-1, :first_free_x => INITIAL_X_COORD_VALUE
  #            rescue
  #              next
  #            end
  #          }
  #        end # => end of layer0.with_lock do        
  #      end
  #      # set pesimistic lock
  #      ActiveRecord::Base.lock_optimistically = true
  #      ret_val
  #    }
  #    
  #    # check if there is a target layer first!
  #    self.transaction do
  #      layer_rec = self.find(["layer = ? AND ny = ?",y,y*(-1)]) # => layer_rec number is 'y-coord' value
  #      if layer_rec == nil
  #        # I need new layer
  #        layer_rec = create_new_layer.call y
  #        # check layer again
  #        if layer_rec == nil
  #          tstxy_log_msg = "test_and_set_xy : layer_rec == il at layer = #{y}"
  #          FileManager.logger(sid, tstxy_log_msg, nil)
  #          return [ -1, -1, -1, -1 ]
  #        end
  #      end
  #    end # => end of transaction
  #
  #    # set pesimistic lock
  #    ActiveRecord::Base.lock_optimistically = false
  #
  #    self.transaction do
  #      # Get lock for the layer!
  #      layer_retry_count = ACTIVE_RECORD_RETRY_COUNT
  #      while layer_retry_count  = ACTIVE_RECORD_RETRY_COUNT
  #        begin
  #          layer_rec_r = self.find(["layer = ? AND ny = ?",y,y*(-1)],:lock=>true) # => layer_rec number is 'y-coord' value
  #          break
  #        rescue ActiveRecord::RecordNotFound
  #          layer_retry_count -= 1
  #        end
  #      end
  #      if layer_retry_count < 0
  #        return [ -1, -1, -1, -1 ]
  #      end
  #      layer_rec_r.with_lock do
  #
  #        existing_nodes = SpinNode.readonly.select("node_x_coord,node_y_coord,node_x_pr_coord,node_type,node_version").where(["node_x_pr_coord = ? AND node_y_coord = ? AND node_name = ? AND is_void = false AND in_trash_flag = false",prx,y,vfile_name]).order("node_version DESC")
  #        #        existing_nodes = SpinNode.readonly.where(["node_x_pr_coord = ? AND node_y_coord = ? AND node_name = ?",prx,y,vfile_name]).order("node_version DESC")
  #        if existing_nodes.length > 0
  #          if existing_nodes[0][:node_type] == NODE_DIRECTORY and node_type == NODE_DIRECTORY
  #            node_loc = [ existing_nodes[0][:node_x_coord], existing_nodes[0][:node_y_coord], existing_nodes[0][:node_x_pr_coord], INITIAL_VERSION_NUMBER * (-1), nil, node_type ]
  #            ActiveRecord::Base.lock_optimistically = true
  #            return node_loc # => returns existing direcotry node location
  #          elsif existing_nodes[0][:node_type] == NODE_DIRECTORY and node_type != NODE_DIRECTORY
  #            x = layer_rec_r[:first_free_x]
  #            layer_rec_r[:last_x] = x
  #            layer_rec_r[:first_free_x] = x + 1
  #            layer_rec_r.save
  #            node_loc = [ x, y, prx, INITIAL_VERSION_NUMBER, nil, node_type ]
  #            ActiveRecord::Base.lock_optimistically = true
  #            return node_loc # => returns existing direcotry node location
  #          elsif existing_nodes[0][:node_type] != NODE_DIRECTORY and node_type == NODE_DIRECTORY
  #            x = layer_rec_r[:first_free_x]
  #            layer_rec_r[:last_x] = x
  #            layer_rec_r[:first_free_x] = x + 1
  #            layer_rec_r.save
  #            node_loc = [ x, y, prx, INITIAL_VERSION_NUMBER, nil, node_type ]
  #            ActiveRecord::Base.lock_optimistically = true
  #            return node_loc # => returns existing direcotry node location
  #          else # => file exists
  #            node_loc = [ existing_nodes[0][:node_x_coord], y, prx, existing_nodes[0][:node_version] + 1, nil, node_type ]
  #            ActiveRecord::Base.lock_optimistically = true
  #            return node_loc # => returns existing direcotry node location
  #          end
  #        else # => no existing nodes
  #          x = layer_rec_r[:first_free_x]
  #          layer_rec_r[:last_x] = x
  #          layer_rec_r[:first_free_x] = x + 1
  #          layer_rec_r.save
  #          node_loc = [ x, y, prx, INITIAL_VERSION_NUMBER, nil, node_type ]
  #          ActiveRecord::Base.lock_optimistically = true
  #          return node_loc # => returns existing direcotry node location
  #        end # => end of if existing_nodes.length > 0
  #      end # => layer_rec_r.with_lock do
  #    end # => end of transaction
  #      
  #    ActiveRecord::Base.lock_optimistically = true
  #    
  #    if directory_node_exists
  #      node_loc = [ x, y, request_loc[PRX], v*(-1), nil, node_type ]
  #    else
  #      node_loc = [ x, y, request_loc[PRX], v, nil, node_type ]
  #    end
  #    
  #    return node_loc
  #  end # => end of test_and_set_xy parent_loc, vfile_name

  def self.xx_test_and_set_xy sid, request_loc, vfile_name = '', node_type = NODE_FILE
    # request_loc   [ X, Y, P, V ] : Y should be Z+-{0}, P spould be Z+, V may be REQUEST_COORD_VALUE
    # vfile_name  : file or directory name to assign coordinate value
    # node_type   : type of node { NODE_DIRECTORY, NODE_FILE,... } : optional
    
    # initialize var
    node_loc = [] # => array of length 0
    directory_node_exists = false
    # start
    # initialize
    x = REQUEST_COORD_VALUE
    y = REQUEST_COORD_VALUE
    v = REQUEST_COORD_VALUE # => any negative value
    #      request_rec = {}
      
    if request_loc[X] != REQUEST_COORD_VALUE # => new x-coord value is requested
      x = request_loc[X]
    end
    if request_loc[Y] != REQUEST_COORD_VALUE # => new y-coord value is requested
      y = request_loc[Y]
    end
    if request_loc[V] != REQUEST_VERSION_NUMBER # => new y-coord value is requested
      v = request_loc[V]
    end

    
    layer_rec = {}

    create_new_layer = proc {|layer|
      ret_val = nil
      # set pesimistic lock
      #      ActiveRecord::Base.lock_optimistically = false
      # get layer-0 lock! : for locking layers
      new_layer = self.create(:nx => INITIAL_X_COORD_VALUE, :ny => layer*(-1), :layer => layer, :last_x => INITIAL_X_COORD_VALUE-1, :first_free_x => INITIAL_X_COORD_VALUE)
      ret_val = new_layer
      # set pesimistic lock
      ret_val
    }
    
    # set pesimistic lock
    #    ActiveRecord::Base.lock_optimistically = false

    self.transaction do
      retry_lock_count = SPIN_NODE_KEEPER_RETRY_COUNT
      lock_object = nil
      while retry_lock_count > 0 do
        lock_objects = self.where(["ny < 0",:lock=>true]) # => layer_rec number is 'y-coord' value
        if lock_objects.blank?
          sleep(1 + SPIN_NODE_KEEPER_RETRY_COUNT - retry_lock_count)
          retry_lock_count -= 1
          next
        else
          break
        end
      end
      
      lock_object = lock_objects[0]
      
      return NoXYPV if lock_object == nil
            
      lock_object.with_lock do # => lock object { parent, layer }
        # check if there is a target layer first!
        layer_rec = self.find_by_layer_and_ny(y,y*(-1)) # => layer_rec number is 'y-coord' value
        if layer_rec.blank?
          # I need new layer
          layer_rec = create_new_layer.call y
          # check layer again
          if layer_rec.blank?
            tstxy_log_msg = "test_and_set_xy : layer_rec == il at layer = #{y}"
            FileManager.logger(sid, tstxy_log_msg, 'LOCAL', LOG_ERROR)
            return NoXYPV
          end
        end

        # is there rec for (x,y)?
        request_rec = self.find(["nx = ? AND ny = ? AND node_name = ?",request_loc[X],y,vfile_name],:lock=>true)
        if request_rec
          x = request_rec[:nx]
          prx = request_loc[PRX]
          begin
            if node_type == NODE_DIRECTORY
              v = INITIAL_VERSION_NUMBER
              directory_node_exists = true
            else
              #              vc = request_rec[:current_version]
              vc = (v == REQUEST_VERSION_NUMBER  ? request_rec[:current_version] + 1 : v)
              v = vc
              request_rec[:current_version] = vc
              request_rec[:node_type] = node_type
              request_rec.save
            end
          rescue  ActiveRecord::RecordNotUnique
            ActiveRecord::Base.lock_optimistically = true
            #            msg_a = [ request_rec[:nx],request_rec[:layer],vc,nv0[:max_versions]]
            tstxy_log_msg = "test_and_set_xy : exception 1 : request_rec ActiveRecord::RecordNotUnique : " + request_rec.to_s
            FileManager.logger(sid, tstxy_log_msg, 'LOCAL', LOG_ERROR)
            return NoXYPV
          end # => end of begin-rescue
        else
          # Is there rec for (prx,y)?
          request_rec = self.find(["nx_pr = ? AND ny = ? AND node_name = ?",request_loc[PRX],y,vfile_name],:lock=>true)
          if request_rec.present?
            x = request_rec[:nx]
            prx = request_loc[PRX]
            begin
              if node_type == NODE_DIRECTORY
                v = INITIAL_VERSION_NUMBER
                directory_node_exists = true
              else
                #                vc = request_rec[:current_version]
                vc = (v == REQUEST_VERSION_NUMBER  ? request_rec[:current_version] + 1 : v)
                #                v = request_rec[:current_version] + 1
                v = vc
                request_rec[:current_version] = vc
                request_rec[:node_type] = node_type
                request_rec.save
              end
            rescue  ActiveRecord::RecordNotUnique
              ActiveRecord::Base.lock_optimistically = true
              #            msg_a = [ request_rec[:nx],request_rec[:layer],vc,nv0[:max_versions]]
              tstxy_log_msg = "test_and_set_xy : exception 2 : request_rec ActiveRecord::RecordNotUnique : " + request_rec.to_s
              FileManager.logger(sid, tstxy_log_msg, 'LOCAL', LOG_ERROR)
              return NoXYPV
            end # => end of begin-rescue
          else # => no request_rec : request_rec == nil
            # Get lock for the layer!
            #            layer_retry_count = SPIN_NODE_KEEPER_RETRY_COUNT
            if lock_object[:ny] < 0 # => lock object is a layer
              request_rec_r = self.find(["nx_pr = ? AND layer = ? AND node_name = ?",request_loc[PRX],y,vfile_name],:lock=>true)
              if request_rec_r.present?
                request_rec_r.with_lock do
                  x = request_rec_r[:nx]
                  prx = request_loc[PRX]
                  begin
                    if node_type == NODE_DIRECTORY
                      v = INITIAL_VERSION_NUMBER
                      directory_node_exists = true
                    else
                      vc = (v == REQUEST_VERSION_NUMBER  ? request_rec_r[:current_version] + 1 : v)
                      #                    v = request_rec_r[:current_version] + 1
                      v = vc
                      request_rec_r[:current_version] = vc
                      request_rec_r[:node_type] = node_type
                      request_rec_r.save
                    end
                  rescue  ActiveRecord::RecordNotUnique
                    tstxy_log_msg = "test_and_set_xy : exception 3 : request_rec_r ActiveRecord::RecordNotUnique : " + request_rec_r.to_s
                    FileManager.logger(sid, tstxy_log_msg, 'LOCAL', LOG_ERROR)
                    ActiveRecord::Base.lock_optimistically = true
                    return NoXYPV
                  end # => end of begin-rescue
                end # => end of request_rec.with_lock
              else # => no request_rec_r : request_rec_r == nil
                # start
                layer_rec_r = lock_object
                x = layer_rec_r[:first_free_x]
                # => no P(x,y), create new
                prx = request_loc[PRX]
                vc = (v == REQUEST_VERSION_NUMBER  ? INITIAL_VERSION_NUMBER : v)
                if node_type == NODE_DIRECTORY
                  v = INITIAL_VERSION_NUMBER
                else
                  v = vc
                end
                #          x = layer_rec_r[:first_free_x]
                begin
                  new_node_keeper_rec =  self.create(:nx => x, :ny => y, :layer => y, :nx_pr => prx, :node_name => vfile_name, :current_version => vc, :node_type => node_type)
                  layer_rec_r[:last_x] = new_node_keeper_rec[:nx]
                  layer_rec_r[:first_free_x] = new_node_keeper_rec[:nx] + 1
                  layer_rec_r.save
                rescue ActiveRecord::RecordNotUnique
                  if node_type == NODE_DIRECTORY
                    node_loc = [ x, y, request_loc[PRX], v*(-1), nil, node_type ]
                  else
                    node_loc = [ x, y, request_loc[PRX], v, nil, node_type ]
                  end
                  return node_loc
                end # => end of begin-rescue block
              end # => end of if request_rec_r != nil
            end # => end of if lock_object[:ny] < 0
          end # => end of if request_rec != nil      
        end # => end of if request_rec
      end # => end of lock_object.with_lock
    end # => end of transaction
      
    ActiveRecord::Base.lock_optimistically = true
    
    if directory_node_exists
      node_loc = [ x, y, request_loc[PRX], v*(-1), nil, node_type ]
    else
      node_loc = [ x, y, request_loc[PRX], v, nil, node_type ]
    end
    
    return node_loc
  end # => end of test_and_set_xy parent_loc, vfile_name
  
  def self.test_and_set_xy sid, request_loc, vfile_name = '', node_type = NODE_FILE
    # => 2 type of request parameter set
    # => 
    # 1) [ REQUEST_COORD_VALUE, y, p, v, n, t ]   n : vfile_name
    #   if there is a node with ( y, p, n, t ) and v == 0
    #   => returns the location of the node
    #   
    #   if there is a node with ( y, p, n, t ) and v == -1 ( REQUEST_VERSION_NUMBER )
    #   => create new location ( x, y, p, v, n, t ) and returns it
    #   
    # 2) [ x, y, p, n, t ]
    #   if there is a node with ( x, y, p, n, t )
    #   => returns the location of the node
    #   else
    #   => create new location ( x, y ) and returns it
    # request_loc   [ X, Y, P, V ] : Y should be Z+-{0}, P spould be Z+, V may be REQUEST_COORD_VALUE
    # vfile_name  : file or directory name to assign coordinate value
    # node_type   : type of node { NODE_DIRECTORY, NODE_FILE,... } : optional
    
    # initialize var
    node_loc = [] # => array of length 0

    # start
    # initialize
    prx = request_loc[PRX]
    t = node_type
    x = request_loc[X]
    y = request_loc[Y]
    v = request_loc[V]
      
    layer_rec = {}
    
    first_free_x = INITIAL_X_COORD_VALUE
    
    # use optimistic lock
    #    ActiveRecord::Base.lock_optimistically = false
    
    # check if there is a target layer first!
    retry_alloc_coord = ACTIVE_RECORD_RETRY_COUNT
    
    catch(:test_and_set_xy_again) {
      
      SpinNodeKeeper.transaction do

        # => decide request pattern
        if v == REQUEST_VERSION_NUMBER # => test and rquest for new (x,y)
          #          SpinNodeKeeper.find_by_sql('LOCK TABLE spin_node_keepers IN ROW EXCLUSIVE MODE;')
          request_recs = Array.new
          begin
            if x == REQUEST_COORD_VALUE
              request_recs = SpinNodeKeeper.where(["(nx_pr = ? AND ny = ? AND node_name = ? AND node_type = ?) OR (layer = ? AND ny = ?)",prx,y,vfile_name,t,y,y*(-1)]).order("ny ASC, current_version DESC")
            else
              request_recs = SpinNodeKeeper.where(["(nx = ? AND nx_pr = ? AND ny = ? AND node_name = ? AND node_type = ?) OR (layer = ? AND ny = ?)",x,prx,y,vfile_name,t,y,y*(-1)]).order("ny ASC, current_version DESC")
            end
            if request_recs.size >= 2 # => found rec
              layer_rec = request_recs[0]
              request_rec = request_recs[1]
              if node_type == NODE_DIRECTORY
                node_loc = [ request_rec[:nx], request_rec[:ny], request_rec[:nx_pr], INITIAL_VERSION_NUMBER ]
              else # =>  file
                begin
                  if v < 0 # => assign new version
                    #              x = layer_rec[:last_x]
                    node_loc = [ request_rec[:nx], request_rec[:ny], request_rec[:nx_pr], request_rec[:current_version] + 1 ]
                    request_rec[:current_version] = request_rec[:current_version] + 1
                    request_rec.save
                  else # => return current version
                    node_loc = [ request_rec[:nx], request_rec[:ny], request_rec[:nx_pr], request_rec[:current_version] ]
                  end
                rescue ActiveRecord::StaleObjectError
                  sleep(AR_RETRY_WAIT_MSEC)
                  throw :test_and_set_xy_again
                end
              end
            elsif request_recs.size == 1 # => create new
              begin
                layer_rec = request_recs[0]
                x = layer_rec[:first_free_x]
                unless first_free_x == INITIAL_X_COORD_VALUE
                  x = first_free_x
                end
                y = layer_rec[:layer]
                layer_rec[:last_x] = x
                layer_rec[:first_free_x] = x + 1
                if layer_rec[:max_versions].blank?
                  layer_rec[:max_versions] = -1
                end
                layer_rec.save
                #              SpinNodeKeeper.create(:nx => x, :ny => y, :layer => y, :nx_pr => prx, :node_name => vfile_name, :current_version => INITIAL_VERSION_NUMBER, :node_type => node_type, :max_versions => -1)
                new_rec = SpinNodeKeeper.new {|new_rec|
                  new_rec[:nx] = x
                  new_rec[:ny] = y
                  new_rec[:layer] = y
                  new_rec[:nx_pr] = prx
                  new_rec[:node_name] = vfile_name
                  new_rec[:current_version] = INITIAL_VERSION_NUMBER
                  new_rec[:node_type] = node_type
                  new_rec[:max_versions] = -1
                }
                new_rec.save
                node_loc = [ x, y, prx, -1 ]
              rescue ActiveRecord::StaleObjectError
                retry_alloc_coord -= 1
                tx = layer_rec[:first_free_x]
                if tx < (Vfs::MAX_INTEGER - 100) and retry_alloc_coord > 0
                  first_free_x = tx + 100
                  sleep(AR_RETRY_WAIT_MSEC)
                  throw :test_and_set_xy_again
                end
                ActiveRecord::Base.lock_optimistically = true
                tstxy_log_msg = "test_and_set_xy : exception 4 : request_rec ActiveRecord::RecordNotUnique : " + request_rec.to_s
                FileManager.logger(sid, tstxy_log_msg, 'LOCAL', LOG_ERROR)
                return NoXYPV
              rescue
                return NoXYPV
              end
            else # => error
              node_loc = NoXYPV
            end
          rescue ActiveRecord::RecordNotFound
            begin
              new_layer = SpinNodeKeeper.new {|new_layer|
                new_layer[:nx] = INITIAL_X_COORD_VALUE
                new_layer[:ny] = y*(-1)
                new_layer[:layer] = y
                new_layer[:last_x] = INITIAL_X_COORD_VALUE
                new_layer[:first_free_x] = INITIAL_X_COORD_VALUE + 1
              }
              new_layer.save
              new_rec = SpinNodeKeeper.new {|new_rec|
                new_rec[:nx] = INITIAL_X_COORD_VALUE
                new_rec[:ny] = y
                new_rec[:layer] = y
                new_rec[:nx_pr] = prx
                new_rec[:node_name] = vfile_name
                new_rec[:current_version] = INITIAL_VERSION_NUMBER
                new_rec[:node_type] = node_type
              }
              new_rec.save
            rescue ActiveRecord::StaleObjectError
              sleep(AR_RETRY_WAIT_MSEC)
              throw :test_and_set_xy_again
            rescue
              return NoXYPV
            end
            node_loc = [ INITIAL_X_COORD_VALUE, y, prx, INITIAL_VERSION_NUMBER*(-1) ]
          end

        else # => test only

          request_recs = SpinNodeKeeper.where(["(nx_pr = ? AND ny = ? AND node_name = ? AND node_type = ?) OR (layer = ? AND ny = ?)",prx,y,vfile_name,t,y,y*(-1)])
          if request_recs.size == 2 # => found rec
            if request_recs[0][:ny] < 0
              layer_rec = request_recs[0]
              request_rec = request_recs[1]
            else
              layer_rec = request_recs[1]
              request_rec = request_recs[0]
            end
            node_loc = [ request_rec[:nx], request_rec[:ny], request_rec[:nx_pr], request_rec[:current_version] ]
          else
            tstxy_log_msg = "test_and_set_xy : requested node isn't found" + request_rec.to_s
            FileManager.logger(sid, tstxy_log_msg, 'LOCAL', LOG_ERROR)
            return NoXYPV
          end
        end # => end of if v == REQUEST_VERSION_NUMBER
      
      end # => end of transaction

    } # => end of catch block

    return node_loc

  end # => end of test_and_set_xy parent_loc, vfile_name

  def self.test_and_set_xy_save sid, request_loc, vfile_name = '', node_type = NODE_FILE
    # => 2 type of request parameter set
    # => 
    # 1) [ REQUEST_COORD_VALUE, y, p, v, n, t ]   n : vfile_name
    #   if there is a node with ( y, p, n, t ) and v == 0
    #   => returns the location of the node
    #   
    #   if there is a node with ( y, p, n, t ) and v == -1 ( REQUEST_VERSION_NUMBER )
    #   => create new location ( x, y, p, v, n, t ) and returns it
    #   
    # 2) [ x, y, p, n, t ]
    #   if there is a node with ( x, y, p, n, t )
    #   => returns the location of the node
    #   else
    #   => create new location ( x, y ) and returns it
    # request_loc   [ X, Y, P, V ] : Y should be Z+-{0}, P spould be Z+, V may be REQUEST_COORD_VALUE
    # vfile_name  : file or directory name to assign coordinate value
    # node_type   : type of node { NODE_DIRECTORY, NODE_FILE,... } : optional
    
    # initialize var
    node_loc = [] # => array of length 0

    # start
    # initialize
    prx = request_loc[PRX]
    t = node_type
    x = request_loc[X]
    y = request_loc[Y]
    v = request_loc[V]
      
    layer_rec = {}
    
    first_free_x = INITIAL_X_COORD_VALUE
    
    # use optimistic lock
    #    ActiveRecord::Base.lock_optimistically = false
    
    # check if there is a target layer first!
    retry_alloc_coord = ACTIVE_RECORD_RETRY_COUNT
    
    catch(:test_and_set_xy_again) {
      
      SpinNodeKeeper.transaction do

        # => decide request pattern
        if v == REQUEST_VERSION_NUMBER # => test and rquest for new (x,y)
          #          SpinNodeKeeper.find_by_sql('LOCK TABLE spin_node_keepers IN ROW EXCLUSIVE MODE;')
          request_recs = Array.new
          if x == REQUEST_COORD_VALUE
            request_recs = SpinNodeKeeper.where(["(nx_pr = ? AND ny = ? AND node_name = ? AND node_type = ?) OR (layer = ? AND ny = ?)",prx,y,vfile_name,t,y,y*(-1)]).order("ny ASC, current_version DESC")
          else
            request_recs = SpinNodeKeeper.where(["(nx = ? AND nx_pr = ? AND ny = ? AND node_name = ? AND node_type = ?) OR (layer = ? AND ny = ?)",x,prx,y,vfile_name,t,y,y*(-1)]).order("ny ASC, current_version DESC")
          end
          if request_recs.size >= 2 # => found rec
            layer_rec = request_recs[0]
            request_rec = request_recs[1]
            if node_type == NODE_DIRECTORY
              node_loc = [ request_rec[:nx], request_rec[:ny], request_rec[:nx_pr], INITIAL_VERSION_NUMBER ]
            else # =>  file
              begin
                if v < 0 # => assign new version
                  #              x = layer_rec[:last_x]
                  node_loc = [ request_rec[:nx], request_rec[:ny], request_rec[:nx_pr], request_rec[:current_version] + 1 ]
                  request_rec[:current_version] = request_rec[:current_version] + 1
                  request_rec.save
                else # => return current version
                  node_loc = [ request_rec[:nx], request_rec[:ny], request_rec[:nx_pr], request_rec[:current_version] ]
                end
              rescue ActiveRecord::StaleObjectError
                sleep(AR_RETRY_WAIT_MSEC)
                throw :test_and_set_xy_again
              end
            end
          elsif request_recs.size == 1 # => create new
            begin
              layer_rec = request_recs[0]
              x = layer_rec[:first_free_x]
              unless first_free_x == INITIAL_X_COORD_VALUE
                x = first_free_x
              end
              y = layer_rec[:layer]
              layer_rec[:last_x] = x
              layer_rec[:first_free_x] = x + 1
              if layer_rec[:max_versions].blank?
                layer_rec[:max_versions] = -1
              end
              layer_rec.save
              SpinNodeKeeper.create(:nx => x, :ny => y, :layer => y, :nx_pr => prx, :node_name => vfile_name, :current_version => INITIAL_VERSION_NUMBER, :node_type => node_type, :max_versions => -1)
              node_loc = [ x, y, prx, -1 ]
            rescue ActiveRecord::StaleObjectError
              sleep(AR_RETRY_WAIT_MSEC)
              throw :test_and_set_xy_again
            rescue  ActiveRecord::RecordNotUnique
              retry_alloc_coord -= 1
              tx = layer_rec[:first_free_x]
              if tx < (Vfs::MAX_INTEGER - 100) and retry_alloc_coord > 0
                first_free_x = tx + 100
                sleep(AR_RETRY_WAIT_MSEC)
                throw :test_and_set_xy_again
              end
              ActiveRecord::Base.lock_optimistically = true
              tstxy_log_msg = "test_and_set_xy : exception 4 : request_rec ActiveRecord::RecordNotUnique : " + request_rec.to_s
              FileManager.logger(sid, tstxy_log_msg, 'LOCAL', LOG_ERROR)
              return NoXYPV
            rescue
              return NoXYPV
            end
          elsif request_recs.size == 0 # => new layer, new rec
            begin
              new_layer = SpinNodeKeeper.create
              new_layer[:nx] = INITIAL_X_COORD_VALUE
              new_layer[:ny] = y*(-1)
              new_layer[:layer] = y
              new_layer[:last_x] = INITIAL_X_COORD_VALUE
              new_layer[:first_free_x] = INITIAL_X_COORD_VALUE + 1
              new_layer.save
              new_rec = SpinNodeKeeper.create
              new_rec[:nx] = INITIAL_X_COORD_VALUE
              new_rec[:ny] = y
              new_rec[:layer] = y
              new_rec[:nx_pr] = prx
              new_rec[:node_name] = vfile_name
              new_rec[:current_version] = INITIAL_VERSION_NUMBER
              new_rec[:node_type] = node_type
              new_rec.save
            rescue ActiveRecord::StaleObjectError
              sleep(AR_RETRY_WAIT_MSEC)
              throw :test_and_set_xy_again
            rescue  ActiveRecord::RecordNotUnique
              ActiveRecord::Base.lock_optimistically = true
              tstxy_log_msg = "test_and_set_xy : exception 5 : request_rec ActiveRecord::RecordNotUnique : " + request_rec.to_s
              Rails.logger(tstxy_log_msg)
              FileManager.logger(sid, tstxy_log_msg, 'LOCAL', LOG_ERROR)
              return NoXYPV
            rescue
              return NoXYPV
            end
            node_loc = [ INITIAL_X_COORD_VALUE, y, prx, INITIAL_VERSION_NUMBER*(-1) ]
          else # => error
            node_loc = NoXYPV
          end

        else # => test only

          request_recs = SpinNodeKeeper.where(["(nx_pr = ? AND ny = ? AND node_name = ? AND node_type = ?) OR (layer = ? AND ny = ?)",prx,y,vfile_name,t,y,y*(-1)])
          if request_recs.size == 2 # => found rec
            if request_recs[0][:ny] < 0
              layer_rec = request_recs[0]
              request_rec = request_recs[1]
            else
              layer_rec = request_recs[1]
              request_rec = request_recs[0]
            end
            node_loc = [ request_rec[:nx], request_rec[:ny], request_rec[:nx_pr], request_rec[:current_version] ]
          else
            tstxy_log_msg = "test_and_set_xy : requested node isn't found" + request_rec.to_s
            FileManager.logger(sid, tstxy_log_msg, 'LOCAL', LOG_ERROR)
            return NoXYPV
          end
        end # => end of if v == REQUEST_VERSION_NUMBER
      
      end # => end of transaction

    } # => end of catch block

    return node_loc

  end # => end of test_and_set_xy parent_loc, vfile_name

  def self.test_and_set_xy_prev sid, request_loc, vfile_name = '', node_type = NODE_FILE
    # request_loc   [ X, Y, P, V ] : Y should be Z+-{0}, P spould be Z+, V may be REQUEST_COORD_VALUE
    # vfile_name  : file or directory name to assign coordinate value
    # node_type   : type of node { NODE_DIRECTORY, NODE_FILE,... } : optional
    
    # initialize var
    node_loc = [] # => array of length 0
    directory_node_exists = false
    # start
    # initialize
    x = REQUEST_COORD_VALUE
    y = REQUEST_COORD_VALUE
    v = REQUEST_COORD_VALUE # => any negative value
    #      request_rec = {}
      
    if request_loc[X] != REQUEST_COORD_VALUE # => new x-coord value is requested
      x = request_loc[X]
    end
    if request_loc[Y] != REQUEST_COORD_VALUE # => new y-coord value is requested
      y = request_loc[Y]
    end
    if request_loc[V] != REQUEST_VERSION_NUMBER # => new y-coord value is requested
      v = request_loc[V]
    end
    
    layer_rec = {}

    create_new_layer = proc {|layer|
      ret_val = nil
      new_layer = self.find(["layer = ? AND ny = ?",layer,layer*(-1)])
      if new_layer == nil
        new_layer = self.create(:nx => INITIAL_X_COORD_VALUE, :ny => layer*(-1), :layer => layer, :last_x => INITIAL_X_COORD_VALUE-1, :first_free_x => INITIAL_X_COORD_VALUE)
      end
      ret_val = new_layer
      ret_val
    }
    
    # check if there is a target layer first!
    
    # set pesimistic lock
    ActiveRecord::Base.lock_optimistically = false
    SpinNodeKeeper.transaction do
      #      SpinNodeKeeper.find_by_sql('LOCK TABLE spin_node_keepers IN ROW EXCLUSIVE MODE;')
      layer_rec = SpinNodeKeeper.find(["layer = ? AND ny = ?",y,y*(-1)]) # => layer_rec number is 'y-coord' value
      #      layer_rec.lock!
      unless layer_rec.present?
        # I need new layer
        layer_rec = create_new_layer.call y
        # check layer again
        if layer_rec == nil
          tstxy_log_msg = "test_and_set_xy : layer_rec == il at layer = #{y}"
          FileManager.logger(sid, tstxy_log_msg, 'LOCAL', LOG_ERROR)
          return NoXYPV
        end
      end
    end # => end of transaction

    # set pesimistic lock
    #    ActiveRecord::Base.lock_optimistically = false

    #    SpinNodeKeeper.transaction do
      
    #      SpinNodeKeeper.find_by_sql('LOCK spin_node_keepers IN SHARE SHARE MODE;')

    #      retry_lock_count = SPIN_NODE_KEEPER_RETRY_COUNT
    #      lock_object = nil
    #      while retry_lock_count > 0 do
    SpinNodeKeeper.transaction do
      #      SpinNodeKeeper.find_by_sql('LOCK TABLE spin_node_keepers IN ROW EXCLUSIVE MODE;')
      lock_object = SpinNodeKeeper.find(["layer = ? AND ny = ?",y,y*(-1)]) # => layer_rec number is 'y-coord' value

      # is there rec for (x,y)?
      request_rec = SpinNodeKeeper.find(["nx = ? AND ny = ? AND node_name = ?",request_loc[X],y,vfile_name])
      if request_rec.present?
        x = request_rec[:nx]
        prx = request_loc[PRX]
        begin
          if node_type == NODE_DIRECTORY
            v = INITIAL_VERSION_NUMBER
            directory_node_exists = true
          else
            #              vc = request_rec[:current_version]
            vc = (v == REQUEST_VERSION_NUMBER  ? request_rec[:current_version] + 1 : v)
            v = vc
            request_rec[:current_version] = vc
            request_rec[:node_type] = node_type
            request_rec.save
          end
        rescue  ActiveRecord::RecordNotUnique
          ActiveRecord::Base.lock_optimistically = true
          #            msg_a = [ request_rec[:nx],request_rec[:layer],vc,nv0[:max_versions]]
          tstxy_log_msg = "test_and_set_xy : exception 6 : request_rec ActiveRecord::RecordNotUnique : " + request_rec.to_s
          FileManager.logger(sid, tstxy_log_msg, 'LOCAL', LOG_ERROR)
          return NoXYPV
        end # => end of begin-rescue
      else
        # Is there rec for (prx,y)?
        request_rec = SpinNodeKeeper.find(["nx_pr = ? AND ny = ? AND node_name = ?",request_loc[PRX],y,vfile_name])
        if request_rec.present?
          x = request_rec[:nx]
          prx = request_loc[PRX]
          begin
            if node_type == NODE_DIRECTORY
              v = INITIAL_VERSION_NUMBER
              directory_node_exists = true
            else
              #                vc = request_rec[:current_version]
              vc = (v == REQUEST_VERSION_NUMBER  ? request_rec[:current_version] + 1 : v)
              #                v = request_rec[:current_version] + 1
              v = vc
              request_rec[:current_version] = vc
              request_rec[:node_type] = node_type
              request_rec.save
            end
          rescue  ActiveRecord::RecordNotUnique
            ActiveRecord::Base.lock_optimistically = true
            #            msg_a = [ request_rec[:nx],request_rec[:layer],vc,nv0[:max_versions]]
            tstxy_log_msg = "test_and_set_xy : exception 7 : request_rec ActiveRecord::RecordNotUnique : " + request_rec.to_s
            FileManager.logger(sid, tstxy_log_msg, 'LOCAL', LOG_ERROR)
            return NoXYPV
          end # => end of begin-rescue
        else # => no request_rec : request_rec == nil
          # Get lock for the layer!
          #            layer_retry_count = SPIN_NODE_KEEPER_RETRY_COUNT
          if lock_object[:ny] < 0 # => lock object is a layer
            request_rec_r = SpinNodeKeeper.find(["nx_pr = ? AND layer = ? AND node_name = ?",request_loc[PRX],y,vfile_name])
            if request_rec_r.present?
              #              request_rec_r.with_lock do
              x = request_rec_r[:nx]
              prx = request_loc[PRX]
              begin
                if node_type == NODE_DIRECTORY
                  v = INITIAL_VERSION_NUMBER
                  directory_node_exists = true
                else
                  vc = (v == REQUEST_VERSION_NUMBER  ? request_rec_r[:current_version] + 1 : v)
                  #                    v = request_rec_r[:current_version] + 1
                  v = vc
                  request_rec_r[:current_version] = vc
                  request_rec_r[:node_type] = node_type
                  request_rec_r.save
                end
              rescue  ActiveRecord::RecordNotUnique
                tstxy_log_msg = "test_and_set_xy : exception 8 : request_rec_r ActiveRecord::RecordNotUnique : " + request_rec_r.to_s
                FileManager.logger(sid, tstxy_log_msg, 'LOCAL', LOG_ERROR)
                ActiveRecord::Base.lock_optimistically = true
                return NoXYPV
              end # => end of begin-rescue
              #              end # => end of request_rec.with_lock
            else # => no request_rec_r : request_rec_r == nil
              # start
              layer_rec_r = lock_object
              x = layer_rec_r[:first_free_x]
              # => no P(x,y), create new
              prx = request_loc[PRX]
              vc = (v == REQUEST_VERSION_NUMBER  ? INITIAL_VERSION_NUMBER : v)
              if node_type == NODE_DIRECTORY
                v = INITIAL_VERSION_NUMBER
              else
                v = vc
              end
              #          x = layer_rec_r[:first_free_x]
              begin
                new_node_keeper_rec =  SpinNodeKeeper.create(:nx => x, :ny => y, :layer => y, :nx_pr => prx, :node_name => vfile_name, :current_version => vc, :node_type => node_type)
                layer_rec_r[:last_x] = new_node_keeper_rec[:nx]
                layer_rec_r[:first_free_x] = new_node_keeper_rec[:nx] + 1
                layer_rec_r.save
              rescue ActiveRecord::RecordNotUnique
                if node_type == NODE_DIRECTORY
                  node_loc = [ x, y, request_loc[PRX], v*(-1), nil, node_type ]
                else
                  node_loc = [ x, y, request_loc[PRX], v, nil, node_type ]
                end
                return node_loc
              end # => end of begin-rescue block
            end # => end of if request_rec_r != nil
          end # => end of if lock_object[:ny] < 0
        end # => end of if request_rec != nil      
      end # => end of if request_rec
      #      end # => end of lock_object.with_lock
      #    end # => end of transaction
      
      ActiveRecord::Base.lock_optimistically = true
    
      if directory_node_exists
        node_loc = [ x, y, request_loc[PRX], v*(-1), nil, node_type ]
      else
        node_loc = [ x, y, request_loc[PRX], v, nil, node_type ]
      end
    
    end

    return node_locx
  end # => end of test_and_set_xy parent_loc, vfile_name
  
  def self.delete_node_keeper_record(px,py,v = ANY_VERSION)
    # set pesimistic lock
    #    ActiveRecord::Base.lock_optimistically = false
        
    catch(:delete_node_keeper_record_again) {
      
      self.transaction do
      
        #      self.find_by_sql('LOCK TABLE spin_node_keepers IN ROW EXCLUSIVE MODE;')
        knode = self.find_by_nx_and_ny(px,py)
        if knode.blank?
          return false
        end
    
        begin
          if knode[:current_version].present?
            if v == ANY_VERSION or v == knode[:current_version]
              knode.destroy
            elsif v < knode[:current_version]
              return true
            else  # => v > knode[:current_version]
              return false
            end    
          else
            return true
          end
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :delete_node_keeper_record_again
        end
    
      end # => end of transaction
    
    } # => end of catch block
    
  end # => end of SpinNodeKeeper.delete_node_keeper_record(sid,delete_file_key)
  
  def self.modify_node_keeper_node_name(px,py,new_node_name)
    # set pesimistic lock
    #    ActiveRecord::Base.lock_optimistically = false
    
    catch(:modify_node_keeper_node_name_again) {
      
      self.transaction do
        begin
          nrecs = SpinNodeKeeper.where(nx: px, ny: py).update_all(node_name: new_node_name)
          if nrecs != 1
            return ERROR_FAILED_TO_CHANGE_NODE_NAME
          end
        rescue ActiveRecord::StaleObjectError
          sleep(AR_RETRY_WAIT_MSEC)
          throw :modify_node_keeper_node_name_again
        end

      end # => end of transaction

    } # => end od catch block

    ActiveRecord::Base.lock_optimistically = true

    return INFO_CHANGE_NODE_NAME_SUCCESS

  end # => end of SpinNodeKeeper.delete_node_keeper_record(sid,delete_file_key)
  
  def self.init_spin_node_keeper
    # set pesimistic lock
    
    retl = nil
    retry_init_spin_node_keeper = ACTIVE_RECORD_RETRY_COUNT
    catch(:init_spin_node_keeper_again){
      
      SpinNodeKeeper.transaction do
        
        begin
          # get layer-0 lock! : for locking layers
          layer0 = nil
          layer0 = self.find_by_layer_and_nx(LAYER0_LAYER,INITIAL_X_COORD_VALUE)
          if layer0.blank?
            ilayer0 = self.new {|ilayer0|
              ilayer0[:nx] = INITIAL_X_COORD_VALUE
              ilayer0[:ny] = LAYER0_NY
              ilayer0[:layer] = LAYER0_LAYER
              ilayer0[:last_x] = INITIAL_X_COORD_VALUE - 1
              ilayer0[:first_free_x] = INITIAL_X_COORD_VALUE
            }
            ilayer0.save
            retl = ilayer0
          end
    
          new_layer = nil
          # check layer again
          # create additional layers
          inc_layers = FIRST_LAYER
          inc_layers.upto(ADD_NUMBER_OF_LAYERS) {|i|
            new_layer = self.find_by_layer_and_ny(i,i*(-1))
            if new_layer.blank?
              inew_layer = self.new {|inew_layer|
                inew_layer[:nx] = INITIAL_X_COORD_VALUE
                inew_layer[:ny] = i*(-1)
                inew_layer[:layer] = i
                inew_layer[:last_x] = INITIAL_X_COORD_VALUE - 1
                inew_layer[:first_free_x] = INITIAL_X_COORD_VALUE
              }
              inew_layer.save
              retl = inew_layer
            end
            #          new_layer = self.find(["layer = ? AND ny = ?",i,i*(-1)])
          }
        rescue ActiveRecord::StaleObjectError
          retry_init_spin_node_keeper -= 1
          if retry_init_spin_node_keeper > 0
            sleep(AR_RETRY_WAIT_MSEC)
            throw :init_spin_node_keeper_again
          else
            return nil
          end
        end
      end
    }
    return retl
  end # => end of init_spin_node_keeper
  
end
