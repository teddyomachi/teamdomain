class SpinUsersController < ApplicationController
  # GET /spin_users
  # GET /spin_users.json
  def index
    @spin_users = SpinUser.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @spin_users }
    end
  end

  # GET /spin_users/1
  # GET /spin_users/1.json
  def show
    @spin_user = SpinUser.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @spin_user }
    end
  end

  # GET /spin_users/new
  # GET /spin_users/new.json
  def new
    @spin_user = SpinUser.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @spin_user }
    end
  end

  # GET /spin_users/1/edit
  def edit
    @spin_user = SpinUser.find(params[:id])
  end

  # POST /spin_users
  # POST /spin_users.json
  def create
    @spin_user = SpinUser.new(params[:spin_user])

    respond_to do |format|
      if @spin_user.save
        format.html { redirect_to @spin_user, :notice => 'Spin user was successfully created.' }
        format.json { render :json => @spin_user, :status => :created, :location => @spin_user }
      else
        format.html { render :action => "new" }
        format.json { render :json => @spin_user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /spin_users/1
  # PUT /spin_users/1.json
  def update
    @spin_user = SpinUser.find(params[:id])

    respond_to do |format|
      if @spin_user.update_attributes(params[:spin_user])
        format.html { redirect_to @spin_user, :notice => 'Spin user was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @spin_user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /spin_users/1
  # DELETE /spin_users/1.json
  def destroy
    @spin_user = SpinUser.find(params[:id])
    @spin_user.destroy

    respond_to do |format|
      format.html { redirect_to spin_users_url }
      format.json { head :no_content }
    end
  end
end
