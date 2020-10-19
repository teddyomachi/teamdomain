class SpinUserAttributesController < ApplicationController
  # GET /spin_user_attributes
  # GET /spin_user_attributes.json
  def index
    @spin_user_attributes = SpinUserAttribute.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @spin_user_attributes }
    end
  end

  # GET /spin_user_attributes/1
  # GET /spin_user_attributes/1.json
  def show
    @spin_user_attribute = SpinUserAttribute.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @spin_user_attribute }
    end
  end

  # GET /spin_user_attributes/new
  # GET /spin_user_attributes/new.json
  def new
    @spin_user_attribute = SpinUserAttribute.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @spin_user_attribute }
    end
  end

  # GET /spin_user_attributes/1/edit
  def edit
    @spin_user_attribute = SpinUserAttribute.find(params[:id])
  end

  # POST /spin_user_attributes
  # POST /spin_user_attributes.json
  def create
    @spin_user_attribute = SpinUserAttribute.new(params[:spin_user_attribute])

    respond_to do |format|
      if @spin_user_attribute.save
        format.html { redirect_to @spin_user_attribute, :notice => 'Spin user attribute was successfully created.' }
        format.json { render :json => @spin_user_attribute, :status => :created, :location => @spin_user_attribute }
      else
        format.html { render :action => "new" }
        format.json { render :json => @spin_user_attribute.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /spin_user_attributes/1
  # PUT /spin_user_attributes/1.json
  def update
    @spin_user_attribute = SpinUserAttribute.find(params[:id])

    respond_to do |format|
      if @spin_user_attribute.update_attributes(params[:spin_user_attribute])
        format.html { redirect_to @spin_user_attribute, :notice => 'Spin user attribute was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @spin_user_attribute.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /spin_user_attributes/1
  # DELETE /spin_user_attributes/1.json
  def destroy
    @spin_user_attribute = SpinUserAttribute.find(params[:id])
    @spin_user_attribute.destroy

    respond_to do |format|
      format.html { redirect_to spin_user_attributes_url }
      format.json { head :no_content }
    end
  end
end
