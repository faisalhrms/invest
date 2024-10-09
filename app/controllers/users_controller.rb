class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_module_name
  skip_before_action :authenticate_user! , only:  :create
  before_action :set_permissions, only: [:index, :create, :update, :destroy]

  def index
    @users = User.all
    create_activity("View Users Index Page", "User", 0)
  end

  def reset_rank_flag
    if current_user.update(new_rank_assigned: false)
      render json: { success: true }, status: :ok
    else
      render json: { error: 'Failed to reset rank flag' }, status: :unprocessable_entity
    end
  end
  def current_profit
    filter = params[:filter] || 'total'
    render json: { profit: current_user.displayed_profit(filter) }
  end
  def create
    referring_user = User.find_by(referral_id: params[:referral_id])
    user = User.new(user_params)

    if params[:register]
      role = Role.find_by_name("Member")
      user.role_id = role.id
      user.user_type = "member"
      user.is_active = true
      user.referral_id = generate_unique_referral_code
      user.referred_by = referring_user.id if referring_user.present?
    end

    if user.save
      # Create an activity stream for the new user creation
      ActivityStream.create_activity_stream("Create #{user.email} New User", "User", user.id, user, "create")

      # Auto-login the newly created user
      user.update(authentication_token: SecureRandom.urlsafe_base64)
      session[:auth_id] = user.authentication_token
      session[:user_id] = user.id

      # Log the user's login history
      ip_address = request.remote_ip
      browser_name = request.user_agent
      LoginHistory.create(user_id: user.id, ip_address: ip_address, browser_name: browser_name, is_active: true)

      flash[:notice] = "User Created Successfully and Logged in."

      # Redirect based on user type
      if user.user_type == "administrator"
        redirect_to admin_path
      else
        user.update_cumulative_profit!
        redirect_to dashboard_path
      end
    else
      # Handle errors and show specific validation messages
      if user.errors.any?
        flash[:alert] = user.errors.full_messages.to_sentence
      else
        flash[:alert] = "Something went wrong. Please try again."
      end
      redirect_to signup_path
    end
  end


  def login
    ip_address = request.remote_ip
    browser_name = request.user_agent
    user = User.find_by(email: params[:email].downcase)

    if user && user.authenticate(params[:password])
      if user.is_active
        user.update(authentication_token: SecureRandom.urlsafe_base64)
        session[:auth_id] = user.authentication_token
        session[:user_id] = user.id

        if user.role&.is_active
          @current_user = user
          LoginHistory.create(user_id: user.id, ip_address: ip_address, browser_name: browser_name, is_active: true)
          ActivityStream.create_activity_stream("#{user.email} Logged-in To Dashboard", "User", user.id, user, "login")

          flash[:notice] = "Logged in successfully."

          # Check for plan_id and plan_type in session
          if session[:plan_id].present? && session[:plan_type].present? && user.user_type != "administrator"
            plan_id = session.delete(:plan_id)
            plan_type = session.delete(:plan_type)
            redirect_to new_purchase_path(plan_id: plan_id, plan_type: plan_type)
          elsif user.user_type == "administrator"
            redirect_to admin_path
          else
            user.update_cumulative_profit!
            redirect_to dashboard_path
          end
        else
          flash[:notice] = "Your Role/Permission Is Inactive, Contact Admin"
          redirect_to login_path
        end
      else
        flash[:notice] = "Account is currently inactive, Contact Admin"
        redirect_to login_path
      end
    else
      flash[:alert] = "Invalid Login Credentials."
      redirect_to login_path
    end
  end


  def update
    if params[:is_active].nil?
      params[:is_active] = false
    end
    user = User.find(params[:id])
    if user.update(user_params)
      ActivityStream.create_activity_stream("Update #{user.email} Existing User", "User", user.id, @current_user, "edit")
      flash[:notice] = "User Updated Successfully"
    else
      flash[:alert] = "Something Went Wrong"
    end
    redirect_to user_path
  end
  def update_preference
    current_user.update(target:  params[:open_links_in_new_window])
    head :ok
  end
  def destroy
    user = User.find(params[:id])
    if user.login_histories.where(:is_active => true).present?
      flash[:alert] = "User Logged-In Somewhere"
    else
      ActivityStream.create_activity_stream("Delete #{user.email} From Users", "User", user.id, @current_user, "delete")
      user.login_histories.update_all(:is_active => false)
      user.activity_streams.delete_all
      ActivityStream.where(:user_id => nil).delete_all
      user.delete
      flash[:notice] = "User Deleted"
    end
    redirect_to user_path
  end

  def change_password
    user = User.find(params[:id])
    if user.authenticate(params[:old_password]).present?

      if params[:password].length > 7
        user.update(:password => params[:password])
        ActivityStream.create_activity_stream("Update #{user.email} Password", "User", user.id, @current_user, "edit")
        flash[:notice] = "Password Updated"
      else
        flash[:alert] = "Password Length Should Be Greater Then 8"
      end
    else
      flash[:alert] = "Kindly Enter Correct Password"
    end
    redirect_to user_path
  end
  def user_profile
    @module_name = "user_profile"
    @activity_streams = current_user.activity_streams.where(:action_date => (Date.today - 1.days)..Date.today)
  end
  private

  def user_params
    params.permit(:full_name, :email, :password, :avatar, :is_active, :user_type, :role_id, :user_name,:mobile_with_country_code,:country , :referral_id,:rank)
  end

  def generate_unique_referral_code
    loop do
      code = SecureRandom.hex(4)
      break code unless User.exists?(referral_id: code)
    end
  end
  def set_module_name
    @module_name = "authentication"
    @sub_module_name = "users"
  end

end
