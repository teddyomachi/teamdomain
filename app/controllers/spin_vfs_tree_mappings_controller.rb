class SpinVfsTreeMappingsController < ApplicationController
  # GET /spin_vfs_tree_mappings
  # GET /spin_vfs_tree_mappings.json
  def index
    @spin_vfs_tree_mappings = SpinVfsTreeMapping.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @spin_vfs_tree_mappings }
    end
  end

  # GET /spin_vfs_tree_mappings/1
  # GET /spin_vfs_tree_mappings/1.json
  def show
    @spin_vfs_tree_mapping = SpinVfsTreeMapping.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @spin_vfs_tree_mapping }
    end
  end

  # GET /spin_vfs_tree_mappings/new
  # GET /spin_vfs_tree_mappings/new.json
  def new
    @spin_vfs_tree_mapping = SpinVfsTreeMapping.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @spin_vfs_tree_mapping }
    end
  end

  # GET /spin_vfs_tree_mappings/1/edit
  def edit
    @spin_vfs_tree_mapping = SpinVfsTreeMapping.find(params[:id])
  end

  # POST /spin_vfs_tree_mappings
  # POST /spin_vfs_tree_mappings.json
  def create
    @spin_vfs_tree_mapping = SpinVfsTreeMapping.new(params[:spin_vfs_tree_mapping])

    respond_to do |format|
      if @spin_vfs_tree_mapping.save
        format.html { redirect_to @spin_vfs_tree_mapping, :notice => 'Spin vfs tree mapping was successfully created.' }
        format.json { render :json => @spin_vfs_tree_mapping, :status => :created, :location => @spin_vfs_tree_mapping }
      else
        format.html { render :action => "new" }
        format.json { render :json => @spin_vfs_tree_mapping.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /spin_vfs_tree_mappings/1
  # PUT /spin_vfs_tree_mappings/1.json
  def update
    @spin_vfs_tree_mapping = SpinVfsTreeMapping.find(params[:id])

    respond_to do |format|
      if @spin_vfs_tree_mapping.update_attributes(params[:spin_vfs_tree_mapping])
        format.html { redirect_to @spin_vfs_tree_mapping, :notice => 'Spin vfs tree mapping was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @spin_vfs_tree_mapping.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /spin_vfs_tree_mappings/1
  # DELETE /spin_vfs_tree_mappings/1.json
  def destroy
    @spin_vfs_tree_mapping = SpinVfsTreeMapping.find(params[:id])
    @spin_vfs_tree_mapping.destroy

    respond_to do |format|
      format.html { redirect_to spin_vfs_tree_mappings_url }
      format.json { head :no_content }
    end
  end
end
