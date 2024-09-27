class HomeController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:index, :checkout]

  def checkout
    session[:planId] = params[:planId]
    if current_user.present?
      if params[:attachment].present?
        transaction = PlanTransaction.new(
          user: current_user,
          package_id: params[:plan_id],
          deposit_amount: params[:deposit_amount],
          attachment: params[:attachment],
          transaction_date: Time.now
        )

        if transaction.save
          render json: { message: "Transaction completed and attachment uploaded successfully.", success: true }
        else
          render json: { message: "Failed to save transaction.", success: false }
        end
      else
        redirect_to checkout_page_path(planId: session[:planId])
      end
    else
      redirect_to login_path
    end
  end
end
