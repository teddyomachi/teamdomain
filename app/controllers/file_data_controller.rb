class FileDataController < ApplicationController
  # GET /file_data
  # GET /file_data.json
  def index
    @file_data = FileDatum.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @file_data }
    end
  end

  # GET /file_data/1
  # GET /file_data/1.json
  def show
    @file_datum = FileDatum.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @file_datum }
    end
  end

  # GET /file_data/new
  # GET /file_data/new.json
  def new
    @file_datum = FileDatum.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @file_datum }
    end
  end

  # GET /file_data/1/edit
  def edit
    @file_datum = FileDatum.find(params[:id])
  end

  # POST /file_data
  # POST /file_data.json
  def create
    @file_datum = FileDatum.new(params[:file_datum])

    respond_to do |format|
      if @file_datum.save
        format.html { redirect_to @file_datum, :notice => 'File datum was successfully created.' }
        format.json { render :json => @file_datum, :status => :created, :location => @file_datum }
      else
        format.html { render :action => "new" }
        format.json { render :json => @file_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /file_data/1
  # PUT /file_data/1.json
  def update
    @file_datum = FileDatum.find(params[:id])

    respond_to do |format|
      if @file_datum.update_attributes(params[:file_datum])
        format.html { redirect_to @file_datum, :notice => 'File datum was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @file_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /file_data/1
  # DELETE /file_data/1.json
  def destroy
    @file_datum = FileDatum.find(params[:id])
    @file_datum.destroy

    respond_to do |format|
      format.html { redirect_to file_data_url }
      format.json { head :no_content }
    end
  end
end
