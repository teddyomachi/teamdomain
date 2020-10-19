class SpinGroupsController < ApplicationController
  # GET /spin_groups
  # GET /spin_groups.json
  def index
    @spin_groups = SpinGroup.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @spin_groups }
    end
  end

  # GET /spin_groups/1
  # GET /spin_groups/1.json
  def show
    @spin_group = SpinGroup.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @spin_group }
    end
  end

  # GET /spin_groups/new
  # GET /spin_groups/new.json
  def new
    @spin_group = SpinGroup.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @spin_group }
    end
  end

  # GET /spin_groups/1/edit
  def edit
    @spin_group = SpinGroup.find(params[:id])
  end

  # POST /spin_groups
  # POST /spin_groups.json
  def create
    @spin_group = SpinGroup.new(params[:spin_group])

    respond_to do |format|
      if @spin_group.save
        format.html { redirect_to @spin_group, :notice => 'Spin group was successfully created.' }
        format.json { render :json => @spin_group, :status => :created, :location => @spin_group }
      else
        format.html { render :action => "new" }
        format.json { render :json => @spin_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /spin_groups/1
  # PUT /spin_groups/1.json
  def update
    @spin_group = SpinGroup.find(params[:id])

    respond_to do |format|
      if @spin_group.update_attributes(params[:spin_group])
        format.html { redirect_to @spin_group, :notice => 'Spin group was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @spin_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /spin_groups/1
  # DELETE /spin_groups/1.json
  def destroy
    @spin_group = SpinGroup.find(params[:id])
    @spin_group.destroy

    respond_to do |format|
      format.html { redirect_to spin_groups_url }
      format.json { head :no_content }
    end
  end
end
