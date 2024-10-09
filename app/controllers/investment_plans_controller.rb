class InvestmentPlansController < ApplicationController
  before_action :authenticate_user!
  before_action :set_module_name
  before_action :set_permissions, only: [:index, :create, :update, :destroy]


  def index
    @investment_plan = InvestmentPlan.all
    ActivityStream.create_activity_stream("View Investment Plans Index Page", "InvestmentPlans", 0, @current_user, "view")
  end

  def edit_modal
    @investment_plan = InvestmentPlan.find(params[:id])
    render partial: 'investment_plans/edit_modal', locals: { investment_plan: @investment_plan}
  end

  def investment
    # Fetch all purchases for investment plans
    @investment_purchases = Purchase.joins(:user).where.not(investment_plan_id: nil)
  end
  def create
    investment_plan = InvestmentPlan.new(investment_plan_params)
    if investment_plan.save
      ActivityStream.create_activity_stream("Create #{User.last.email} New Investment Plans", "InvestmentPlans", User.last.id, @current_user, "create")
      flash[:notice] = "User Created Successfully"
    else
      if investment_plan.errors.full_messages.first == "InvestmentPlans has already been taken"
        flash[:alert] = investment_plan.errors.full_messages.first
      else
        flash[:alert] = "Something Went Wrong"
      end
    end
    redirect_to investment_plan_path
  end
  def update
    if params[:is_active].nil?
      params[:is_active] = false
    end
    investment_plan = InvestmentPlan.find(params[:id])
    if investment_plan.update(investment_plan_params)
      ActivityStream.create_activity_stream("Update #{investment_plan.name} Existing InvestmentPlans", "InvestmentPlans", investment_plan.id, @current_user, "edit")
      flash[:notice] = "InvestmentPlans Updated Successfully"
    else
      flash[:alert] = "Something Went Wrong"
    end
    redirect_to investment_plan_path
  end

  def destroy
    investment_plan = InvestmentPlan.find(params[:id])
    if  investment_plan.present?
      ActivityStream.create_activity_stream("Delete #{investment_plan.name} From InvestmentPlans", "InvestmentPlans", investment_plan.id, @current_user, "delete")
      menu.delete
      flash[:notice] = "InvestmentPlans Deleted"
    end
    redirect_to investment_plan_path
  end

  private
  def investment_plan_params
    params.permit(:name, :description, :price, :profit_percentage, :duration_in_days,:commission_rate,:is_active)
  end
  def set_module_name
    @module_name = "plans"
    @sub_module_name = "investment_plans"

  end

end
