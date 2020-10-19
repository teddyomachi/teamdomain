class FolderDataController < ApplicationController
  # GET /folder_data
  # GET /folder_data.json
  def index
    @folder_data = FolderDatum.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @folder_data }
    end
  end

  # GET /folder_data/1
  # GET /folder_data/1.json
  def show
    @folder_datum = FolderDatum.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @folder_datum }
    end
  end

  # GET /folder_data/new
  # GET /folder_data/new.json
  def new
    @folder_datum = FolderDatum.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @folder_datum }
    end
  end

  # GET /folder_data/1/edit
  def edit
    @folder_datum = FolderDatum.find(params[:id])
  end

  # POST /folder_data
  # POST /folder_data.json
  def create
    @folder_datum = FolderDatum.new(params[:folder_datum])

    respond_to do |format|
      if @folder_datum.save
        format.html { redirect_to @folder_datum, :notice => 'Folder datum was successfully created.' }
        format.json { render :json => @folder_datum, :status => :created, :location => @folder_datum }
      else
        format.html { render :action => "new" }
        format.json { render :json => @folder_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /folder_data/1
  # PUT /folder_data/1.json
  def update
    @folder_datum = FolderDatum.find(params[:id])

    respond_to do |format|
      if @folder_datum.update_attributes(params[:folder_datum])
        format.html { redirect_to @folder_datum, :notice => 'Folder datum was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @folder_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /folder_data/1
  # DELETE /folder_data/1.json
  def destroy
    @folder_datum = FolderDatum.find(params[:id])
    @folder_datum.destroy

    respond_to do |format|
      format.html { redirect_to folder_data_url }
      format.json { head :no_content }
    end
  end
end
