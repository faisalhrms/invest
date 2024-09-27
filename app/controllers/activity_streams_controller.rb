class ActivityStreamsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_module_name, :only => [:index, :show]


  def index
    ActivityStream.create_activity_stream("View Activity Stream Index Page", "ActivityStream", 0, @current_user, "view")
  end

  def activity_streams
    @activity_streams = ActivityStream.includes(:user).first(100)
    respond_to do |format|
      format.json { render 'activity_streams/activity_stream' }
    end
  end

  def show
    @activity_streams = ActivityStream.all
    if params[:start_date].present? and params[:end_date].present?
      @activity_streams = @activity_streams.where(:action_date => params[:start_date].to_date..params[:end_date].to_date)
    end
    if params[:user_id].present?
      @activity_streams = @activity_streams.where(:user_id => params[:user_id])
    end
    if params[:table_name].present?
      @activity_streams = @activity_streams.where(:table_name => params[:table_name])
    end
    if params[:slug].present?
      @activity_streams = @activity_streams.where(:slug => params[:slug])
    end
    if @activity_streams.present?
      ActivityStream.create_activity_stream("Filter Activity Streams", "ActivityStream", 0, @current_user, "filter")
      flash[:notice] = "Activity Stream Found Successfully"
    else
      flash[:alert] = "No Record Found"
    end

    if params[:page].present?
      render 'users/user_profile'
    else
      render 'activity_streams/index'
    end
  end

  private

  def set_module_name
    @module_name = "activity_streams"
  end

end
