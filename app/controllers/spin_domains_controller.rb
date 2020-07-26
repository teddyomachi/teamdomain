require 'const/vfs_const'
require 'const/acl_const'
require 'tasks/security'
require 'tasks/spin_location_manager'

class SpinDomainsController < ApplicationController
  include Vfs
  include Acl
  
  # GET /spin_domains
  # GET /spin_domains.json
  def index
    @spin_domains = SpinDomain.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @spin_domains }
    end
  end

  # GET /spin_domains/1
  # GET /spin_domains/1.json
  def show
    @spin_domain = SpinDomain.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @spin_domain }
    end
  end

  # GET /spin_domains/new
  # GET /spin_domains/new.json
  def new
    @spin_domain = SpinDomain.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @spin_domain }
    end
  end

  # GET /spin_domains/1/edit
  def edit
    @spin_domain = SpinDomain.find(params[:id])
  end

  # POST /spin_domains
  # POST /spin_domains.json
  def create
    @spin_domain = SpinDomain.new(params[:spin_domain])

    # generate hash_key for the new entry
    # => get (x,y,px,v) first
    flag_make_dir_if_not_exeits = false
    node_not_found = [-1,-1,-1,-1,nil]
    
    # coord_value is an array : [x,y,prx,v]
    coord_value = SpinLocationManager.get_location_coordinates ADMIN_SESSION_ID, 'folder_a', @spin_domain[:spin_domain_root], flag_make_dir_if_not_exeits

    # do nothing if coord_value = [-1,-1,-1,-1,nil]
    if coord_value != node_not_found
      # generate hash code for the node
      domain_root_node_hashkey = coord_value[HASHKEY]
      # domain_root_node_hashkey = Security.hash_key coord_value[X],coord_value[Y],coord_value[PRX],coord_value[V]
      # domain_root_node_hashkey = Security.hash_key coord_value[:node_x_coord],coord_value[:node_y_coord],coord_value[:node_x_pr_coord],coord_value[:node_version]
      if domain_root_node_hashkey
        @spin_domain[:domain_root_node_hashkey] = domain_root_node_hashkey
        r = Random.new
        @spin_domain[:hash_key] = Security.hash_key_s @spin_domain[:spin_domain_root] + r.rand.to_s
      end
    end # => end of 'coord_value' is not [-1,-1,-1,-1,nil]
    
    # add value to attributes
    
    # go futher if they are successful or fail!
    
    respond_to do |format|
        format.json { render :json => @spin_domain, :status => :created, :location => @spin_domain }
      if coord_value != node_not_found
        if @spin_domain.save
          format.html { redirect_to @spin_domain, :notice => 'Spin domain was successfully created.' }
        else
          format.json { render :json => @spin_domain.errors, :status => :unprocessable_entity }
        end
      else
        format.html { render :action => "new" }
        format.json { render :json => @spin_domain.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /spin_domains/1
  # PUT /spin_domains/1.json
  def update
    @spin_domain = SpinDomain.find(params[:id])

    respond_to do |format|
      if @spin_domain.update_attributes(params[:spin_domain])
        format.html { redirect_to @spin_domain, :notice => 'Spin domain was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @spin_domain.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /spin_domains/1
  # DELETE /spin_domains/1.json
  def destroy
    @spin_domain = SpinDomain.find(params[:id])
    @spin_domain.destroy

    respond_to do |format|
      format.html { redirect_to spin_domains_url }
      format.json { head :no_content }
    end
  end
end
