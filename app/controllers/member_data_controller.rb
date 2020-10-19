class MemberDataController < ApplicationController
  # GET /member_data
  # GET /member_data.json
  def index
    @member_data = MemberDatum.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @member_data }
    end
  end

  # GET /member_data/1
  # GET /member_data/1.json
  def show
    @member_datum = MemberDatum.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @member_datum }
    end
  end

  # GET /member_data/new
  # GET /member_data/new.json
  def new
    @member_datum = MemberDatum.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @member_datum }
    end
  end

  # GET /member_data/1/edit
  def edit
    @member_datum = MemberDatum.find(params[:id])
  end

  # POST /member_data
  # POST /member_data.json
  def create
    @member_datum = MemberDatum.new(params[:member_datum])

    respond_to do |format|
      if @member_datum.save
        format.html { redirect_to @member_datum, :notice => 'Member datum was successfully created.' }
        format.json { render :json => @member_datum, :status => :created, :location => @member_datum }
      else
        format.html { render :action => "new" }
        format.json { render :json => @member_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /member_data/1
  # PUT /member_data/1.json
  def update
    @member_datum = MemberDatum.find(params[:id])

    respond_to do |format|
      if @member_datum.update_attributes(params[:member_datum])
        format.html { redirect_to @member_datum, :notice => 'Member datum was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @member_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /member_data/1
  # DELETE /member_data/1.json
  def destroy
    @member_datum = MemberDatum.find(params[:id])
    @member_datum.destroy

    respond_to do |format|
      format.html { redirect_to member_data_url }
      format.json { head :no_content }
    end
  end
end
