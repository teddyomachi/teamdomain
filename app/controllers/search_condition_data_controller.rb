class SearchConditionDataController < ApplicationController
  # GET /search_condition_data
  # GET /search_condition_data.json
  def index
    @search_condition_data = SearchConditionDatum.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @search_condition_data }
    end
  end

  # GET /search_condition_data/1
  # GET /search_condition_data/1.json
  def show
    @search_condition_datum = SearchConditionDatum.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @search_condition_datum }
    end
  end

  # GET /search_condition_data/new
  # GET /search_condition_data/new.json
  def new
    @search_condition_datum = SearchConditionDatum.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @search_condition_datum }
    end
  end

  # GET /search_condition_data/1/edit
  def edit
    @search_condition_datum = SearchConditionDatum.find(params[:id])
  end

  # POST /search_condition_data
  # POST /search_condition_data.json
  def create
    @search_condition_datum = SearchConditionDatum.new(params[:search_condition_datum])

    respond_to do |format|
      if @search_condition_datum.save
        format.html { redirect_to @search_condition_datum, :notice => 'Search condition datum was successfully created.' }
        format.json { render :json => @search_condition_datum, :status => :created, :location => @search_condition_datum }
      else
        format.html { render :action => "new" }
        format.json { render :json => @search_condition_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /search_condition_data/1
  # PUT /search_condition_data/1.json
  def update
    @search_condition_datum = SearchConditionDatum.find(params[:id])

    respond_to do |format|
      if @search_condition_datum.update_attributes(params[:search_condition_datum])
        format.html { redirect_to @search_condition_datum, :notice => 'Search condition datum was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @search_condition_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /search_condition_data/1
  # DELETE /search_condition_data/1.json
  def destroy
    @search_condition_datum = SearchConditionDatum.find(params[:id])
    @search_condition_datum.destroy

    respond_to do |format|
      format.html { redirect_to search_condition_data_url }
      format.json { head :no_content }
    end
  end
end
