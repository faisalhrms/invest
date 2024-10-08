class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session
  helper_method :current_user, :authenticate_user!
  add_flash_types :success, :danger, :info, :warning
  include RolesHelper
  before_action :set_permissions
  before_action :clear_user_session_if_root_path

  private

  def authenticate_user!
    if current_user.nil?
      if params[:plan_id] && params[:plan_type]
        session[:plan_id] = params[:plan_id]
        session[:plan_type] = params[:plan_type]
      end
      flash[:alert] = "Please login."
      redirect_to login_path
    else
      session[:last_active_time] = Time.now.to_i
    end
  end



  def current_user
    return @current_user if defined?(@current_user)

    if session[:user_id].present?
      user = User.find_by(id: session[:user_id])

      # Check if both `user.authentication_token` and `cookies["auth_id"]` are present
      if user && user.authentication_token.present? && session["auth_id"].present? &&
        ActiveSupport::SecurityUtils.secure_compare(user.authentication_token, session["auth_id"])
        @current_user = user
      end
    end

    @current_user
  end

  def clear_user_session_if_root_path
    if current_user.present? && request.path == root_path
      # Clear user session and cookies if on root path
      session[:user_id] = nil
      cookies[:auth_id] = nil

      # Also clear these if they are set in the session
      session[:plan_id] = nil
      session[:plan_type] = nil
    end
  end
  def session_expired?
    session[:last_active_time].present? && (Time.now.to_i - session[:last_active_time].to_i) > 30.minutes
  end

  def create_activity(action, resource, resource_id)
    ActivityStream.create_activity_stream(action, resource, resource_id, current_user, action.split(' ').first.downcase)
  end

  def set_permissions
    return unless defined?(@sub_module_name) && @sub_module_name.present?

    permissions = fetch_permissions_for_submodule(@sub_module_name, current_user)
    @can_create = permissions[:can_create]
    @can_edit = permissions[:can_edit]
    @can_delete = permissions[:can_delete]
  end

end
