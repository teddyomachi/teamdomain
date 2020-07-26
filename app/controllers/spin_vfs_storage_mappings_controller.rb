class SpinVfsStorageMappingsController < ApplicationController
  # GET /spin_vfs_storage_mappings
  # GET /spin_vfs_storage_mappings.json
  def index
    @spin_vfs_storage_mappings = SpinVfsStorageMapping.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @spin_vfs_storage_mappings }
    end
  end

  # GET /spin_vfs_storage_mappings/1
  # GET /spin_vfs_storage_mappings/1.json
  def show
    @spin_vfs_storage_mapping = SpinVfsStorageMapping.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @spin_vfs_storage_mapping }
    end
  end

  # GET /spin_vfs_storage_mappings/new
  # GET /spin_vfs_storage_mappings/new.json
  def new
    @spin_vfs_storage_mapping = SpinVfsStorageMapping.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @spin_vfs_storage_mapping }
    end
  end

  # GET /spin_vfs_storage_mappings/1/edit
  def edit
    @spin_vfs_storage_mapping = SpinVfsStorageMapping.find(params[:id])
  end

  # POST /spin_vfs_storage_mappings
  # POST /spin_vfs_storage_mappings.json
  def create
    @spin_vfs_storage_mapping = SpinVfsStorageMapping.new(params[:spin_vfs_storage_mapping])

    respond_to do |format|
      if @spin_vfs_storage_mapping.save
        format.html { redirect_to @spin_vfs_storage_mapping, :notice => 'Spin vfs storage mapping was successfully created.' }
        format.json { render :json => @spin_vfs_storage_mapping, :status => :created, :location => @spin_vfs_storage_mapping }
      else
        format.html { render :action => "new" }
        format.json { render :json => @spin_vfs_storage_mapping.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /spin_vfs_storage_mappings/1
  # PUT /spin_vfs_storage_mappings/1.json
  def update
    @spin_vfs_storage_mapping = SpinVfsStorageMapping.find(params[:id])

    respond_to do |format|
      if @spin_vfs_storage_mapping.update_attributes(params[:spin_vfs_storage_mapping])
        format.html { redirect_to @spin_vfs_storage_mapping, :notice => 'Spin vfs storage mapping was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @spin_vfs_storage_mapping.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /spin_vfs_storage_mappings/1
  # DELETE /spin_vfs_storage_mappings/1.json
  def destroy
    @spin_vfs_storage_mapping = SpinVfsStorageMapping.find(params[:id])
    @spin_vfs_storage_mapping.destroy

    respond_to do |format|
      format.html { redirect_to spin_vfs_storage_mappings_url }
      format.json { head :no_content }
    end
  end
end
