class SearchOptionDataController < ApplicationController
  # GET /search_option_data
  # GET /search_option_data.json
  def index
    @search_option_data = SearchOptionDatum.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @search_option_data }
    end
  end

  # GET /search_option_data/1
  # GET /search_option_data/1.json
  def show
    @search_option_datum = SearchOptionDatum.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @search_option_datum }
    end
  end

  # GET /search_option_data/new
  # GET /search_option_data/new.json
  def new
    @search_option_datum = SearchOptionDatum.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @search_option_datum }
    end
  end

  # GET /search_option_data/1/edit
  def edit
    @search_option_datum = SearchOptionDatum.find(params[:id])
  end

  # POST /search_option_data
  # POST /search_option_data.json
  def create
    @search_option_datum = SearchOptionDatum.new(params[:search_option_datum])

    respond_to do |format|
      if @search_option_datum.save
        format.html { redirect_to @search_option_datum, :notice => 'Search option datum was successfully created.' }
        format.json { render :json => @search_option_datum, :status => :created, :location => @search_option_datum }
      else
        format.html { render :action => "new" }
        format.json { render :json => @search_option_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /search_option_data/1
  # PUT /search_option_data/1.json
  def update
    @search_option_datum = SearchOptionDatum.find(params[:id])

    respond_to do |format|
      if @search_option_datum.update_attributes(params[:search_option_datum])
        format.html { redirect_to @search_option_datum, :notice => 'Search option datum was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @search_option_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /search_option_data/1
  # DELETE /search_option_data/1.json
  def destroy
    @search_option_datum = SearchOptionDatum.find(params[:id])
    @search_option_datum.destroy

    respond_to do |format|
      format.html { redirect_to search_option_data_url }
      format.json { head :no_content }
    end
  end
end
