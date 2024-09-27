class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_module_name
  skip_before_action :authenticate_user! , only:  :create
  before_action :set_permissions, only: [:index, :create, :update, :destroy]

  def index
    @users = User.all
    create_activity("View Users Index Page", "User", 0)
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
      ActivityStream.create_activity_stream("Create #{User.last.email} New User", "User", User.last.id, user, "create")
      flash[:notice] = "User Created Successfully"
    else
      if user.errors.full_messages.first == "Email has already been taken"
        flash[:alert] = user.errors.full_messages.first
      else
        flash[:alert] = "Something Went Wrong"
      end
    end
    redirect_to user_path
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
