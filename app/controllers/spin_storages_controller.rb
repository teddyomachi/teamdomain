class SpinStoragesController < ApplicationController
  # GET /spin_storages
  # GET /spin_storages.json
  def index
    @spin_storages = SpinStorage.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @spin_storages }
    end
  end

  # GET /spin_storages/1
  # GET /spin_storages/1.json
  def show
    @spin_storage = SpinStorage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @spin_storage }
    end
  end

  # GET /spin_storages/new
  # GET /spin_storages/new.json
  def new
    @spin_storage = SpinStorage.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @spin_storage }
    end
  end

  # GET /spin_storages/1/edit
  def edit
    @spin_storage = SpinStorage.find(params[:id])
  end

  # POST /spin_storages
  # POST /spin_storages.json
  def create
    @spin_storage = SpinStorage.new(params[:spin_storage])

    respond_to do |format|
      if @spin_storage.save
        format.html { redirect_to @spin_storage, :notice => 'Spin storage was successfully created.' }
        format.json { render :json => @spin_storage, :status => :created, :location => @spin_storage }
      else
        format.html { render :action => "new" }
        format.json { render :json => @spin_storage.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /spin_storages/1
  # PUT /spin_storages/1.json
  def update
    @spin_storage = SpinStorage.find(params[:id])

    respond_to do |format|
      if @spin_storage.update_attributes(params[:spin_storage])
        format.html { redirect_to @spin_storage, :notice => 'Spin storage was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @spin_storage.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /spin_storages/1
  # DELETE /spin_storages/1.json
  def destroy
    @spin_storage = SpinStorage.find(params[:id])
    @spin_storage.destroy

    respond_to do |format|
      format.html { redirect_to spin_storages_url }
      format.json { head :no_content }
    end
  end
end
