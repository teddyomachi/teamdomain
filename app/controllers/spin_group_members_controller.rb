class SpinGroupMembersController < ApplicationController
  # GET /spin_group_members
  # GET /spin_group_members.json
  def index
    @spin_group_members = SpinGroupMember.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @spin_group_members }
    end
  end

  # GET /spin_group_members/1
  # GET /spin_group_members/1.json
  def show
    @spin_group_member = SpinGroupMember.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @spin_group_member }
    end
  end

  # GET /spin_group_members/new
  # GET /spin_group_members/new.json
  def new
    @spin_group_member = SpinGroupMember.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @spin_group_member }
    end
  end

  # GET /spin_group_members/1/edit
  def edit
    @spin_group_member = SpinGroupMember.find(params[:id])
  end

  # POST /spin_group_members
  # POST /spin_group_members.json
  def create
    @spin_group_member = SpinGroupMember.new(params[:spin_group_member])

    respond_to do |format|
      if @spin_group_member.save
        format.html { redirect_to @spin_group_member, :notice => 'Spin group member was successfully created.' }
        format.json { render :json => @spin_group_member, :status => :created, :location => @spin_group_member }
      else
        format.html { render :action => "new" }
        format.json { render :json => @spin_group_member.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /spin_group_members/1
  # PUT /spin_group_members/1.json
  def update
    @spin_group_member = SpinGroupMember.find(params[:id])

    respond_to do |format|
      if @spin_group_member.update_attributes(params[:spin_group_member])
        format.html { redirect_to @spin_group_member, :notice => 'Spin group member was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @spin_group_member.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /spin_group_members/1
  # DELETE /spin_group_members/1.json
  def destroy
    @spin_group_member = SpinGroupMember.find(params[:id])
    @spin_group_member.destroy

    respond_to do |format|
      format.html { redirect_to spin_group_members_url }
      format.json { head :no_content }
    end
  end
end
