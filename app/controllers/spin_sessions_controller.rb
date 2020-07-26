class SpinSessionsController < ApplicationController
  # GET /spin_sessions
  # GET /spin_sessions.json
  def index
    @spin_sessions = SpinSession.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @spin_sessions }
    end
  end

  # GET /spin_sessions/1
  # GET /spin_sessions/1.json
  def show
    @spin_session = SpinSession.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @spin_session }
    end
  end

  # GET /spin_sessions/new
  # GET /spin_sessions/new.json
  def new
    @spin_session = SpinSession.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @spin_session }
    end
  end

  # GET /spin_sessions/1/edit
  def edit
    @spin_session = SpinSession.find(params[:id])
  end

  # POST /spin_sessions
  # POST /spin_sessions.json
  def create
    @spin_session = SpinSession.new(params[:spin_session])

    respond_to do |format|
      if @spin_session.save
        format.html { redirect_to @spin_session, :notice => 'Spin session was successfully created.' }
        format.json { render :json => @spin_session, :status => :created, :location => @spin_session }
      else
        format.html { render :action => "new" }
        format.json { render :json => @spin_session.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /spin_sessions/1
  # PUT /spin_sessions/1.json
  def update
    @spin_session = SpinSession.find(params[:id])

    respond_to do |format|
      if @spin_session.update_attributes(params[:spin_session])
        format.html { redirect_to @spin_session, :notice => 'Spin session was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @spin_session.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /spin_sessions/1
  # DELETE /spin_sessions/1.json
  def destroy
    @spin_session = SpinSession.find(params[:id])
    @spin_session.destroy

    respond_to do |format|
      format.html { redirect_to spin_sessions_url }
      format.json { head :no_content }
    end
  end
end
