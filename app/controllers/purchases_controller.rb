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
      calculate_sufficient_balance(@plan.price)
      session.delete(:plan_id)
      session.delete(:plan_type)
    else
      redirect_to login_path, alert: "Invalid plan details."
    end
  end

  def cancel
    purchase = Purchase.find_by(id: params[:id])

    if purchase && purchase.user == current_user
      ActiveRecord::Base.transaction do
        purchase.update!(approved: false, status: "cancelled")

        if purchase.profit.present?
          purchase.profit.update!(amount: 0.0)
          current_user.update(total_profit: nil, last_profit_calculation: nil)
        end

        # Calculate deduction fee for trading plan, if applicable
        deduction_fee = 0
        if purchase.trading_plan.present? && purchase.trading_plan.deduction_fee.present?
          deduction_fee = purchase.trading_plan.deduction_fee.to_f
        end

        # Calculate the refund amount by subtracting the deduction fee
        refund_amount = [purchase.deposit_amount - deduction_fee, 0].max

        # Create a deposit entry for the refund with the adjusted amount
        Deposit.create!(
          user_id: purchase.user_id,
          amount: refund_amount,
          processed_at: Time.current,
          status: "refund",
          investment_plan_id: purchase.investment_plan_id,
          trading_plan_id: purchase.trading_plan_id,
          staking_id: purchase.staking_id
        )

        # Log a separate transaction for the deduction fee if applicable
        if deduction_fee > 0
          Deposit.create!(
            user_id: purchase.user_id,
            amount: deduction_fee,
            processed_at: Time.current,
            status: "deduction_fee",
            investment_plan_id: purchase.investment_plan_id,
            trading_plan_id: purchase.trading_plan_id,
            staking_id: purchase.staking_id
          )
        end
      end

      # Log the cancellation in the transaction history with the adjusted refund amount
      plan_id = determine_plan_id(purchase)
      TransactionHistory.create_transaction(current_user, purchase.deposit_amount, "cancel plan", nil, plan_id, "refund", purchase.id)

      redirect_to dashboard_path, notice: "Purchase canceled successfully. A deduction fee of  was applied and the remaining amount has been refunded."
    else
      redirect_to dashboard_path, alert: 'Unable to find or cancel the purchase.'
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to dashboard_path, alert: "Error canceling purchase: #{e.message}"
  end



  def reject
    purchase = Purchase.find(params[:id])

    if purchase.update(status: "rejected", approved: false)
      redirect_to pending_approvals_purchases_path, notice: 'Purchase rejected and amount refunded successfully.'
    else
      redirect_to pending_approvals_purchases_path, alert: 'Error rejecting purchase.'
    end
  end

  def approve
    purchase = Purchase.find_by(id: params[:id])

    if purchase && current_user.user_type == "administrator"
      if purchase.manual_payment
        ActiveRecord::Base.transaction do
          # Approve the purchase
          purchase.update!(approved: true, status: "active")

          # Create transaction history for manual payment approval
          create_transaction_history(purchase, "Plan Purchased")
        end
        redirect_to pending_approvals_purchases_path, notice: 'Purchase approved based on manual payment verification.'
      else
        user_deposit_balance = calculate_user_balance(purchase.user_id)

        if user_deposit_balance >= purchase.deposit_amount
          # Case 1: Sufficient deposit balance
          approve_with_sufficient_balance(purchase)
        else
          # Case 2: Partial deposit + manual payment required
          shortfall_amount = purchase.deposit_amount - user_deposit_balance

          ActiveRecord::Base.transaction do
            # Deduct from the existing deposit balance
            if user_deposit_balance > 0
              existing_deposit = Deposit.where(
                user_id: purchase.user_id,
                status: ['refund', 'referral_commission'],
                investment_plan_id: purchase.investment_plan_id,
                trading_plan_id: purchase.trading_plan_id,
                staking_id: purchase.staking_id
              ).first

              if existing_deposit.present?
                existing_deposit.update!(
                  amount: existing_deposit.amount - user_deposit_balance,
                  processed_at: Time.current,
                  status: 'used for purchase'
                )
              end
            end

            Deposit.create!(
              user_id: purchase.user_id,
              amount: shortfall_amount,
              processed_at: Time.current,
              status: "active",
              investment_plan_id: purchase.investment_plan_id,
              trading_plan_id: purchase.trading_plan_id,
              staking_id: purchase.staking_id
            )

            purchase.update!(approved: true, status: "active")

            create_transaction_history(purchase, "Plan Purchased")
          end

          redirect_to pending_approvals_purchases_path, notice: 'Purchase approved with partial deposit and manual payment.'
        end
      end
    else
      redirect_to pending_approvals_purchases_path, alert: 'You are not authorized to approve purchases or purchase not found.'
    end
  end


  def approve_with_sufficient_balance(purchase)
    ActiveRecord::Base.transaction do
      existing_deposit = Deposit.where(
        user_id: purchase.user_id,
        status: ['refund','manual_deposit' ,'referral_commission']
      ).where(
        'investment_plan_id IS NULL OR investment_plan_id = ? AND trading_plan_id IS NULL OR trading_plan_id = ? AND staking_id IS NULL OR staking_id = ?',
        purchase.investment_plan_id,
        purchase.trading_plan_id,
        purchase.staking_id
      ).where.not(status: ['used for purchase', 'used for withdrawal']).first

      if existing_deposit.present?
        updated_amount = existing_deposit.amount - purchase.deposit_amount

        existing_deposit.update!(
          amount: updated_amount,
          processed_at: Time.current,
          status: updated_amount.zero? ? 'used for purchase' : 'active'  # Mark the deposit as used if fully consumed
        )

        plan_id = determine_plan_id(purchase)
        TransactionHistory.create_transaction(
          current_user,
          updated_amount,
          "Plan Purchased",
          nil,
          plan_id,
          "active",
          purchase.id
        )
        purchase.update!(approved: true, status: "active")

        redirect_to pending_approvals_purchases_path, notice: 'Purchase approved, and the amount was deducted from the existing refund or commission deposit.'
      else
        redirect_to pending_approvals_purchases_path, alert: 'No valid refund or commission found for this purchase.'
      end
    end
  end



  def pending_approvals
    @pending_purchases = Purchase.where(approved: false, status: "pending")
    render 'purchases/pending_approval'
  end

  def create
    plan_type = params[:plan_type]
    plan_id = params[:plan_id]

    # existing_purchase = current_user.purchases.where(approved: true, status: "active")
    #                                 .where("#{plan_type.foreign_key} IS NOT NULL").exists?
    #
    # if existing_purchase
    #   redirect_to dashboard_path, alert: 'You already have an active plan of this type. Please cancel the current plan before purchasing a new one.'
    #   return
    # end

    @purchase = Purchase.new(purchase_params)
    @purchase.user = current_user

    case plan_type
    when 'InvestmentPlan'
      @purchase.investment_plan_id = plan_id
    when 'TradingPlan'
      @purchase.trading_plan_id = plan_id
    when 'Staking'
      @purchase.staking_id = plan_id
      @purchase.duration_in_days = params[:duration_in_days]
    end

    @purchase.deposit_amount = params[:deposit_amount].to_f
    @purchase.manual_payment = params[:manual_payment]
    @purchase.status = "pending"

    if @purchase.save
      redirect_to dashboard_path, notice: 'Purchase successful! Please wait for admin approval.'
    else
      render :new
    end
  end

  private

  def calculate_user_balance(user_id)
    Deposit.where(user_id: user_id, status: ['refund','manual_deposit', 'referral_commission']).where.not(status: ['used for purchase', 'used for withdrawal']).sum(:amount)
  end



  def calculate_sufficient_balance(deposit_amount)
    # Get the user's current deposit balance (only 'refund' type deposits are considered)

    user_balance = calculate_user_balance(current_user.id)

    deposit_amount = deposit_amount.to_f

    # Check if the user has enough balance to cover the plan price
    if deposit_amount > user_balance
      # If user balance is less than the deposit amount, calculate the shortfall
      @shortfall_amount = deposit_amount - user_balance
      @sufficient_balance = false
    else
      # User has sufficient balance to cover the deposit amount
      @shortfall_amount = 0
      @sufficient_balance = true
    end


  end



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
    params.permit(:deposit_amount, :attachment,:wallet_address)
  end
  def create_transaction_history(purchase, transaction_type)
    plan_id = determine_plan_id(purchase)
    TransactionHistory.create_transaction(
      purchase.user,
      purchase.deposit_amount,
      transaction_type,
      nil,
      plan_id,
      "active",
      purchase.id
    )
  end
  def determine_plan_id(purchase)
    if purchase.investment_plan_id.present?
      purchase.investment_plan_id
    elsif purchase.trading_plan_id.present?
      purchase.trading_plan_id
    elsif purchase.staking_id.present?
      purchase.staking_id
    end
  end
end
