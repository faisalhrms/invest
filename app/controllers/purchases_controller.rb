class PurchasesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_module_name
  before_action :set_permissions, only: [:create]

  def new
    plan_id = params[:plan_id] || session[:plan_id]
    plan_type = params[:plan_type] || session[:plan_type]
    if plan_id && plan_type
      @plan = find_plan(plan_id, plan_type)
      @purchase = Purchase.new
      session.delete(:plan_id)
      session.delete(:plan_type)
    else
      redirect_to login_path, alert: "Invalid plan details."
    end
  end
  def cancel
    purchase = Purchase.find(params[:plan_id])

    if purchase
      purchase.update(approved: false,status: "cancelled")
      redirect_to dashboard_path, notice: 'Purchase canceled successfully.'
    else
      redirect_to dashboard_path, alert: 'Unable to find or cancel the purchase.'
    end
  end
  def reject
    purchase = Purchase.find(params[:id])

    if purchase.update(status: nil,approved: false)
      redirect_to pending_approvals_purchases_path, notice: 'Purchase canceled successfully.'
    else
      redirect_to pending_approvals_purchases_path, alert: 'Error canceling purchase.'
    end
    end
  def approve
    purchase = Purchase.find(params[:id])

    if purchase.update(approved: true)
      redirect_to pending_approvals_purchases_path, notice: 'Purchase approved successfully.'
    else
      redirect_to pending_approvals_purchases_path, alert: 'Error approving purchase.'
    end
  end

  def pending_approvals
    @pending_purchases = Purchase.where(approved: false,status: "pending")
    render 'purchases/pending_approval'
  end

  def create


    @purchase = Purchase.new(purchase_params)
    @purchase.user = current_user

    case params[:plan_type]
    when 'InvestmentPlan'
      @purchase.investment_plan_id = params[:plan_id]
    when 'TradingPlan'
      @purchase.trading_plan_id = params[:plan_id]
    when 'Staking'
      @purchase.staking_id = params[:plan_id]
    end

    @purchase.deposit_amount = params[:deposit_amount].to_f
    @purchase.status = "pending"

    if @purchase.save
      redirect_to dashboard_path, notice: 'Purchase successful! Please wait for admin approval.'
    else
      render :new
    end
  end

  private

  def find_plan(plan_id = params[:plan_id], plan_type = params[:plan_type])
    case plan_type
    when 'InvestmentPlan'
      InvestmentPlan.find(plan_id)
    when 'TradingPlan'
      TradingPlan.find(plan_id)
    when 'Staking'
      Staking.find(plan_id)
    else
      raise "Invalid Plan Type"
    end
  end

  def set_module_name
    @module_name = "purchases"
    @sub_module_name = "pending_approvals"

  end
  def purchase_params
    params.require(:purchase).permit(:deposit_amount, :attachment, :payment_method)
  end
end
