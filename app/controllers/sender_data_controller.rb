class SenderDataController < ApplicationController
  # GET /sender_data
  # GET /sender_data.json
  def index
    @sender_data = SenderDatum.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @sender_data }
    end
  end

  # GET /sender_data/1
  # GET /sender_data/1.json
  def show
    @sender_datum = SenderDatum.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @sender_datum }
    end
  end

  # GET /sender_data/new
  # GET /sender_data/new.json
  def new
    @sender_datum = SenderDatum.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @sender_datum }
    end
  end

  # GET /sender_data/1/edit
  def edit
    @sender_datum = SenderDatum.find(params[:id])
  end

  # POST /sender_data
  # POST /sender_data.json
  def create
    @sender_datum = SenderDatum.new(params[:sender_datum])

    respond_to do |format|
      if @sender_datum.save
        format.html { redirect_to @sender_datum, :notice => 'Sender datum was successfully created.' }
        format.json { render :json => @sender_datum, :status => :created, :location => @sender_datum }
      else
        format.html { render :action => "new" }
        format.json { render :json => @sender_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /sender_data/1
  # PUT /sender_data/1.json
  def update
    @sender_datum = SenderDatum.find(params[:id])

    respond_to do |format|
      if @sender_datum.update_attributes(params[:sender_datum])
        format.html { redirect_to @sender_datum, :notice => 'Sender datum was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @sender_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /sender_data/1
  # DELETE /sender_data/1.json
  def destroy
    @sender_datum = SenderDatum.find(params[:id])
    @sender_datum.destroy

    respond_to do |format|
      format.html { redirect_to sender_data_url }
      format.json { head :no_content }
    end
  end
end
