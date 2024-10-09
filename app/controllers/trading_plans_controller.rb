class TradingPlansController < ApplicationController
  before_action :authenticate_user!
  before_action :set_module_name
  before_action :set_permissions, only: [:index, :create, :update, :destroy]


  def index
    @trading_plan = TradingPlan.all
    @trading_plan_users = User.joins(:purchases)
                              .where(purchases: { trading_plan_id: @trading_plan.pluck(:id), status: 'active', approved: true })
                              .distinct
    ActivityStream.create_activity_stream("View Trading Plans Index Page", "TradingPlans", 0, @current_user, "view")
  end

  def edit_modal
    @trading_plan = TradingPlan.find(params[:id])
    render partial: 'trading_plans/edit_modal', locals: { trading_plan: @trading_plan}
  end

  def trading
    # Fetch all purchases for trading plans
    @trading_purchases = Purchase.joins(:user).where.not(trading_plan_id: nil)
  end

  def apply_manual_profit_loss
    user_ids = params[:user_ids]
    percentage = params[:percentage].to_f
    profit_loss_type = params[:profit_loss_type]
    plan_type = params[:plan_type] || 'trading_plan'  # You can adjust this if you need to apply to other plans

    if user_ids.present? && percentage.present?
      User.where(id: user_ids).each do |user|
        user.apply_manual_profit_or_loss(plan_type, percentage, profit_loss_type)
      end

      redirect_to trading_plans_path, notice: "Manual #{profit_loss_type.humanize} of #{percentage}% applied successfully!"
    else
      redirect_to trading_plans_path, alert: 'Please select users and enter a valid percentage.'
    end
  end
  def create
    trading_plan = TradingPlan.new(trading_plan_params)
    if trading_plan.save
      ActivityStream.create_activity_stream("Create #{User.last.email} New Trading Plans", "TradingPlans", User.last.id, @current_user, "create")
      flash[:notice] = "Trading Created Successfully"
    else
      if trading_plan.errors.full_messages.first == "TradingPlans has already been taken"
        flash[:alert] = trading_plan.errors.full_messages.first
      else
        flash[:alert] = "Something Went Wrong"
      end
    end
    redirect_to trading_plan_path
  end
  def update
    if params[:is_active].nil?
      params[:is_active] = false
    end

    trading_plan = TradingPlan.find(params[:id])
    if trading_plan.update(trading_plan_params)
      ActivityStream.create_activity_stream("Update #{trading_plan.name} Existing TradingPlans", "TradingPlans", trading_plan.id, @current_user, "edit")
      flash[:notice] = "TradingPlans Updated Successfully"
    else
      flash[:alert] = "Something Went Wrong"
    end
    redirect_to trading_plan_path
  end

  def destroy
    trading_plan = TradingPlan.find(params[:id])
    if  trading_plan.present?
      ActivityStream.create_activity_stream("Delete #{trading_plan.name} From TradingPlans", "TradingPlans", trading_plan.id, @current_user, "delete")
      menu.delete
      flash[:notice] = "TradingPlans Deleted"
    end
    redirect_to trading_plan_path
  end

  private
  def trading_plan_params
    params.permit(:name, :description, :price,:duration_in_days, :profit_percentage,:deduction_fee,:commission_rate,:is_active)
  end
  def set_module_name
    @module_name = "plans"
    @sub_module_name = "trading_plans"

  end

end
