class SpinVirtualFileSystemsController < ApplicationController
  # GET /spin_virtual_file_systems
  # GET /spin_virtual_file_systems.json
  def index
    @spin_virtual_file_systems = SpinVirtualFileSystem.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @spin_virtual_file_systems }
    end
  end

  # GET /spin_virtual_file_systems/1
  # GET /spin_virtual_file_systems/1.json
  def show
    @spin_virtual_file_system = SpinVirtualFileSystem.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @spin_virtual_file_system }
    end
  end

  # GET /spin_virtual_file_systems/new
  # GET /spin_virtual_file_systems/new.json
  def new
    @spin_virtual_file_system = SpinVirtualFileSystem.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @spin_virtual_file_system }
    end
  end

  # GET /spin_virtual_file_systems/1/edit
  def edit
    @spin_virtual_file_system = SpinVirtualFileSystem.find(params[:id])
  end

  # POST /spin_virtual_file_systems
  # POST /spin_virtual_file_systems.json
  def create
    @spin_virtual_file_system = SpinVirtualFileSystem.new(params[:spin_virtual_file_system])

    respond_to do |format|
      if @spin_virtual_file_system.save
        format.html { redirect_to @spin_virtual_file_system, :notice => 'Spin virtual file system was successfully created.' }
        format.json { render :json => @spin_virtual_file_system, :status => :created, :location => @spin_virtual_file_system }
      else
        format.html { render :action => "new" }
        format.json { render :json => @spin_virtual_file_system.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /spin_virtual_file_systems/1
  # PUT /spin_virtual_file_systems/1.json
  def update
    @spin_virtual_file_system = SpinVirtualFileSystem.find(params[:id])

    respond_to do |format|
      if @spin_virtual_file_system.update_attributes(params[:spin_virtual_file_system])
        format.html { redirect_to @spin_virtual_file_system, :notice => 'Spin virtual file system was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @spin_virtual_file_system.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /spin_virtual_file_systems/1
  # DELETE /spin_virtual_file_systems/1.json
  def destroy
    @spin_virtual_file_system = SpinVirtualFileSystem.find(params[:id])
    @spin_virtual_file_system.destroy

    respond_to do |format|
      format.html { redirect_to spin_virtual_file_systems_url }
      format.json { head :no_content }
    end
  end
end
