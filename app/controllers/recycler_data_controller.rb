class RecyclerDataController < ApplicationController
  # GET /recycler_data
  # GET /recycler_data.json
  def index
    @recycler_data = RecyclerDatum.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @recycler_data }
    end
  end

  # GET /recycler_data/1
  # GET /recycler_data/1.json
  def show
    @recycler_datum = RecyclerDatum.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @recycler_datum }
    end
  end

  # GET /recycler_data/new
  # GET /recycler_data/new.json
  def new
    @recycler_datum = RecyclerDatum.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @recycler_datum }
    end
  end

  # GET /recycler_data/1/edit
  def edit
    @recycler_datum = RecyclerDatum.find(params[:id])
  end

  # POST /recycler_data
  # POST /recycler_data.json
  def create
    @recycler_datum = RecyclerDatum.new(params[:recycler_datum])

    respond_to do |format|
      if @recycler_datum.save
        format.html { redirect_to @recycler_datum, :notice => 'Recycler datum was successfully created.' }
        format.json { render :json => @recycler_datum, :status => :created, :location => @recycler_datum }
      else
        format.html { render :action => "new" }
        format.json { render :json => @recycler_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /recycler_data/1
  # PUT /recycler_data/1.json
  def update
    @recycler_datum = RecyclerDatum.find(params[:id])

    respond_to do |format|
      if @recycler_datum.update_attributes(params[:recycler_datum])
        format.html { redirect_to @recycler_datum, :notice => 'Recycler datum was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @recycler_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /recycler_data/1
  # DELETE /recycler_data/1.json
  def destroy
    @recycler_datum = RecyclerDatum.find(params[:id])
    @recycler_datum.destroy

    respond_to do |format|
      format.html { redirect_to recycler_data_url }
      format.json { head :no_content }
    end
  end
end
