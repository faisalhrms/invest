class SessionsController < ApplicationController
  def create
    ip_address = request.remote_ip
    browser_name = request.user_agent

    user = User.find_by(email: params[:email].downcase)

    if user && user.authenticate(params[:password])
      if user.is_active == true
        user.update(authentication_token: SecureRandom.urlsafe_base64)
        cookies[:auth_id] = user.authentication_token
        session[:user_id] = user.id
        if user.role.present?
          if user.role.is_active == true
            if user.login_histories.where(is_active: true, browser_name: browser_name, ip_address: ip_address).present?
              @current_user = user
              if @current_user.present?
                flash[:notice] = "Logged in successfully."
                ActivityStream.create_activity_stream("#{user.email} Logged-in To Dashboard", "User", @current_user.id, @current_user, "login")
                # Check for plan_id and plan_type in session
                if session[:plan_id].present? && session[:plan_type].present?
                  plan_id = session.delete(:plan_id)
                  plan_type = session.delete(:plan_type)
                  redirect_to new_purchase_path(plan_id: plan_id, plan_type: plan_type) and return
                elsif current_user.user_type == "administrator"
                  redirect_to admin_path and return
                else
                  redirect_to dashboard_path and return
                end
              end
            else
              user.update(is_logged_in: true)
              session[:user_id] = user.id
              @current_user = user
              if @current_user.present?
                LoginHistory.create(user_id: @current_user.id, ip_address: ip_address, browser_name: browser_name, is_active: true)
                flash[:notice] = "Logged in successfully."
                ActivityStream.create_activity_stream("#{user.email} Logged-in To Dashboard", "User", @current_user.id, @current_user, "login")
                # Check for plan_id and plan_type in session
                if session[:plan_id].present? && session[:plan_type].present?
                  plan_id = session.delete(:plan_id)
                  plan_type = session.delete(:plan_type)
                  redirect_to new_purchase_path(plan_id: plan_id, plan_type: plan_type) and return
                elsif current_user.user_type == "administrator"
                  redirect_to admin_path and return
                else
                  redirect_to dashboard_path and return
                end
              end
            end
          else
            flash[:notice] = "Your Role/Permission Is In-Active, Contact To Admin"
            redirect_to login_path
          end
        else
          flash[:notice] = "No Role/Permission Assigned, Contact To Admin"
          redirect_to login_path
        end
      else
        flash[:notice] = "Account Is Currently In-Active, Contact To Admin"
        redirect_to login_path
      end
    else
      flash[:alert] = "Invalid Login Credentials."
      redirect_to login_path
    end
  end


  def destroy
    user = User.find(session[:user_id])
    if user.present?
      ActivityStream.create_activity_stream("#{user.email} Logout From Dashboard", "User", user.id, user, "logout")
      user.login_histories.where(:is_active => true).update(:is_active => false)
      user.update(:authentication_token => SecureRandom.urlsafe_base64)
      session[:user_id] = nil
      cookies[:auth_id] = nil
      flash[:notice] = "You have been logged out"
      redirect_to root_path
    else
      redirect_to root_path
    end
  end

  def send_recover_email
    user = User.find_by(email: params[:email])

    if user.present?
      if user.is_active
        if user.otp.present? && user.otp_expires_at > Time.current
          flash[:alert] = "Recovery email already sent. Please check your inbox or spam."
        else
          otp = (0...3).map { (1..100).to_a[rand(100)] }.join
          user.update(otp: otp.to_s, otp_expires_at: 5.minutes.from_now)
          user_id = user.id
          NotificationMailer.send_password_recover_email(params[:email], otp, user_id).deliver_now
          flash[:notice] = "Recovery email sent successfully. Check your inbox or spam."
          render 'confirm_mail'
        end
      else
        flash[:alert] = "Your account is currently inactive. Contact the admin."
      end
    else
      flash[:alert] = "Email not found in the system."
    end

    redirect_to recover_path
  end

  def reset_user_password
    user = User.find(params[:id])
    @id = params[:id]
    if user.present?
      if user.otp.present? && user.otp_expires_at > Time.current
        if user.otp == params[:otp]
          user.update(password: params[:password], otp: nil, otp_expires_at: nil)
          ActivityStream.create_activity_stream("Reset #{user.email} Password", "User", user.id, user, "edit")
          flash[:notice] = "Password Updated, You Can Login Now."
          redirect_to root_path
        else
          flash[:alert] = "OTP Not Matched, Enter Correct OTP"
          render 'sessions/reset_password'
        end
      else
        flash[:alert] = "OTP has expired or is invalid."
        render 'sessions/reset_password'
      end
    else
      flash[:alert] = "User Not Found"
      render 'sessions/reset_password'
    end
  end

end
