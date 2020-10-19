class OperatorDataController < ApplicationController
  # GET /operator_data
  # GET /operator_data.json
  def index
    @operator_data = OperatorDatum.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @operator_data }
    end
  end

  # GET /operator_data/1
  # GET /operator_data/1.json
  def show
    @operator_datum = OperatorDatum.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @operator_datum }
    end
  end

  # GET /operator_data/new
  # GET /operator_data/new.json
  def new
    @operator_datum = OperatorDatum.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @operator_datum }
    end
  end

  # GET /operator_data/1/edit
  def edit
    @operator_datum = OperatorDatum.find(params[:id])
  end

  # POST /operator_data
  # POST /operator_data.json
  def create
    @operator_datum = OperatorDatum.new(params[:operator_datum])

    respond_to do |format|
      if @operator_datum.save
        format.html { redirect_to @operator_datum, :notice => 'Operator datum was successfully created.' }
        format.json { render :json => @operator_datum, :status => :created, :location => @operator_datum }
      else
        format.html { render :action => "new" }
        format.json { render :json => @operator_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /operator_data/1
  # PUT /operator_data/1.json
  def update
    @operator_datum = OperatorDatum.find(params[:id])

    respond_to do |format|
      if @operator_datum.update_attributes(params[:operator_datum])
        format.html { redirect_to @operator_datum, :notice => 'Operator datum was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @operator_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /operator_data/1
  # DELETE /operator_data/1.json
  def destroy
    @operator_datum = OperatorDatum.find(params[:id])
    @operator_datum.destroy

    respond_to do |format|
      format.html { redirect_to operator_data_url }
      format.json { head :no_content }
    end
  end
end
