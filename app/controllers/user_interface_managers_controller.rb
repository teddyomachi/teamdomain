class UserInterfaceManagersController < ApplicationController
  # GET /user_interface_managers
  # GET /user_interface_managers.json
  def index
    @user_interface_managers = UserInterfaceManager.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @user_interface_managers }
    end
  end

  # GET /user_interface_managers/1
  # GET /user_interface_managers/1.json
  def show
    @user_interface_manager = UserInterfaceManager.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @user_interface_manager }
    end
  end

  # GET /user_interface_managers/new
  # GET /user_interface_managers/new.json
  def new
    @user_interface_manager = UserInterfaceManager.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @user_interface_manager }
    end
  end

  # GET /user_interface_managers/1/edit
  def edit
    @user_interface_manager = UserInterfaceManager.find(params[:id])
  end

  # POST /user_interface_managers
  # POST /user_interface_managers.json
  def create
    @user_interface_manager = UserInterfaceManager.new(params[:user_interface_manager])

    respond_to do |format|
      if @user_interface_manager.save
        format.html { redirect_to @user_interface_manager, :notice => 'User interface manager was successfully created.' }
        format.json { render :json => @user_interface_manager, :status => :created, :location => @user_interface_manager }
      else
        format.html { render :action => "new" }
        format.json { render :json => @user_interface_manager.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /user_interface_managers/1
  # PUT /user_interface_managers/1.json
  def update
    @user_interface_manager = UserInterfaceManager.find(params[:id])

    respond_to do |format|
      if @user_interface_manager.update_attributes(params[:user_interface_manager])
        format.html { redirect_to @user_interface_manager, :notice => 'User interface manager was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @user_interface_manager.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /user_interface_managers/1
  # DELETE /user_interface_managers/1.json
  def destroy
    @user_interface_manager = UserInterfaceManager.find(params[:id])
    @user_interface_manager.destroy

    respond_to do |format|
      format.html { redirect_to user_interface_managers_url }
      format.json { head :no_content }
    end
  end
end
