class SpinObjectsController < ApplicationController
  # GET /spin_objects
  # GET /spin_objects.json
  def index
    @spin_objects = SpinObject.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @spin_objects }
    end
  end

  # GET /spin_objects/1
  # GET /spin_objects/1.json
  def show
    @spin_object = SpinObject.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @spin_object }
    end
  end

  # GET /spin_objects/new
  # GET /spin_objects/new.json
  def new
    @spin_object = SpinObject.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @spin_object }
    end
  end

  # GET /spin_objects/1/edit
  def edit
    @spin_object = SpinObject.find(params[:id])
  end

  # POST /spin_objects
  # POST /spin_objects.json
  def create
    @spin_object = SpinObject.new(params[:spin_object])

    respond_to do |format|
      if @spin_object.save
        format.html { redirect_to @spin_object, :notice => 'Spin object was successfully created.' }
        format.json { render :json => @spin_object, :status => :created, :location => @spin_object }
      else
        format.html { render :action => "new" }
        format.json { render :json => @spin_object.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /spin_objects/1
  # PUT /spin_objects/1.json
  def update
    @spin_object = SpinObject.find(params[:id])

    respond_to do |format|
      if @spin_object.update_attributes(params[:spin_object])
        format.html { redirect_to @spin_object, :notice => 'Spin object was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @spin_object.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /spin_objects/1
  # DELETE /spin_objects/1.json
  def destroy
    @spin_object = SpinObject.find(params[:id])
    @spin_object.destroy

    respond_to do |format|
      format.html { redirect_to spin_objects_url }
      format.json { head :no_content }
    end
  end
end
