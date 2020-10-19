class GroupDataController < ApplicationController
  # GET /group_data
  # GET /group_data.json
  def index
    @group_data = GroupDatum.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @group_data }
    end
  end

  # GET /group_data/1
  # GET /group_data/1.json
  def show
    @group_datum = GroupDatum.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @group_datum }
    end
  end

  # GET /group_data/new
  # GET /group_data/new.json
  def new
    @group_datum = GroupDatum.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @group_datum }
    end
  end

  # GET /group_data/1/edit
  def edit
    @group_datum = GroupDatum.find(params[:id])
  end

  # POST /group_data
  # POST /group_data.json
  def create
    @group_datum = GroupDatum.new(params[:group_datum])

    respond_to do |format|
      if @group_datum.save
        format.html { redirect_to @group_datum, :notice => 'Group datum was successfully created.' }
        format.json { render :json => @group_datum, :status => :created, :location => @group_datum }
      else
        format.html { render :action => "new" }
        format.json { render :json => @group_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /group_data/1
  # PUT /group_data/1.json
  def update
    @group_datum = GroupDatum.find(params[:id])

    respond_to do |format|
      if @group_datum.update_attributes(params[:group_datum])
        format.html { redirect_to @group_datum, :notice => 'Group datum was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @group_datum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /group_data/1
  # DELETE /group_data/1.json
  def destroy
    @group_datum = GroupDatum.find(params[:id])
    @group_datum.destroy

    respond_to do |format|
      format.html { redirect_to group_data_url }
      format.json { head :no_content }
    end
  end
end
