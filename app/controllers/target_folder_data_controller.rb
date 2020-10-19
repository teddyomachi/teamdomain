class TargetFolderDataController < ApplicationController
  # GET /target_folder_data
  # GET /target_folder_data.json
  def index
    @target_folder_data = TargetFolderDatum.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @target_folder_data }
    end
  end

  # GET /target_folder_data/1
  # GET /target_folder_data/1.json
  def show
    @target_folder_datum = TargetFolderDatum.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @target_folder_datum }
    end
  end

  # GET /target_folder_data/new
  # GET /target_folder_data/new.json
  def new
    @target_folder_datum = TargetFolderDatum.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @target_folder_datum }
    end
  end

  # GET /target_folder_data/1/edit
  def edit
    @target_folder_datum = TargetFolderDatum.find(params[:id])
  end

  # POST /target_folder_data
  # POST /target_folder_data.json
  def create
    @target_folder_datum = TargetFolderDatum.new(params[:target_folder_datum])

    respond_to do |format|
      if @target_folder_datum.save
        format.html { redirect_to @target_folder_datum, :notice => 'Target folder datum was successfully created.' }
        format.json { render :json => @target_folder_datum, :status => :created, :location => @target_folder_datum }
      else
        format.html { render :action => "new" }
        format.json { render :json => @target_folder_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /target_folder_data/1
  # PUT /target_folder_data/1.json
  def update
    @target_folder_datum = TargetFolderDatum.find(params[:id])

    respond_to do |format|
      if @target_folder_datum.update_attributes(params[:target_folder_datum])
        format.html { redirect_to @target_folder_datum, :notice => 'Target folder datum was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @target_folder_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /target_folder_data/1
  # DELETE /target_folder_data/1.json
  def destroy
    @target_folder_datum = TargetFolderDatum.find(params[:id])
    @target_folder_datum.destroy

    respond_to do |format|
      format.html { redirect_to target_folder_data_url }
      format.json { head :no_content }
    end
  end
end
