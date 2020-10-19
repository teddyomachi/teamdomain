class DomainDataController < ApplicationController
  # GET /domain_data
  # GET /domain_data.json
  def index
    @domain_data = DomainDatum.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @domain_data }
    end
  end

  # GET /domain_data/1
  # GET /domain_data/1.json
  def show
    @domain_datum = DomainDatum.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @domain_datum }
    end
  end

  # GET /domain_data/new
  # GET /domain_data/new.json
  def new
    @domain_datum = DomainDatum.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @domain_datum }
    end
  end

  # GET /domain_data/1/edit
  def edit
    @domain_datum = DomainDatum.find(params[:id])
  end

  # POST /domain_data
  # POST /domain_data.json
  def create
    @domain_datum = DomainDatum.new(params[:domain_datum])

    respond_to do |format|
      if @domain_datum.save
        format.html { redirect_to @domain_datum, :notice => 'Domain datum was successfully created.' }
        format.json { render :json => @domain_datum, :status => :created, :location => @domain_datum }
      else
        format.html { render :action => "new" }
        format.json { render :json => @domain_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /domain_data/1
  # PUT /domain_data/1.json
  def update
    @domain_datum = DomainDatum.find(params[:id])

    respond_to do |format|
      if @domain_datum.update_attributes(params[:domain_datum])
        format.html { redirect_to @domain_datum, :notice => 'Domain datum was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @domain_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /domain_data/1
  # DELETE /domain_data/1.json
  def destroy
    @domain_datum = DomainDatum.find(params[:id])
    @domain_datum.destroy

    respond_to do |format|
      format.html { redirect_to domain_data_url }
      format.json { head :no_content }
    end
  end
end
