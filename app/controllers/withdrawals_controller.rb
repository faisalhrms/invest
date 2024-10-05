# app/controllers/withdrawals_controller.rb
class WithdrawalsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_withdrawal, only: [:approve, :reject]
  before_action :set_module_name

  def create
    # Withdraw based on the total deposits available
    total_deposit_amount = current_user.total_deposits

    # Check if a valid amount is specified and not greater than total deposits
    if params[:amount].to_f > 0 && params[:amount].to_f <= total_deposit_amount
      withdrawal = current_user.withdrawals.create!(
        amount: params[:amount].to_f,
        withdrawal_type: 'deposit', # Changed to indicate it is a deposit withdrawal
        status: 'pending'
      )

      # Create a transaction history record for the withdrawal request
      create_transaction_history(current_user, withdrawal.amount, "Withdrawal Requested", "pending", withdrawal.id)

      redirect_to dashboard_path, notice: "Your withdrawal request for $#{params[:amount]} has been submitted successfully."
    else
      redirect_to dashboard_path, alert: "Invalid withdrawal amount or insufficient balance."
    end
  end

  def index
    @pending_withdrawals = Withdrawal.where(status: 'pending')
    render "withdrawals/index"
  end

  def approve
    if @withdrawal.update(status: 'approved')
      adjust_deposits_for_withdrawal(@withdrawal)

      # Create a transaction history record for the approved withdrawal
      create_transaction_history(@withdrawal.user, @withdrawal.amount, "Withdrawal Approved", "approved", @withdrawal.id)

      redirect_to withdrawals_path, notice: "Withdrawal approved successfully."
    else
      redirect_to withdrawals_path, alert: "Error approving withdrawal."
    end
  end

  def reject
    if @withdrawal.update(status: 'rejected')

      # Create a transaction history record for the rejected withdrawal
      create_transaction_history(@withdrawal.user, @withdrawal.amount, "Withdrawal Rejected", "rejected", @withdrawal.id)

      redirect_to withdrawals_path, alert: "Withdrawal rejected successfully."
    else
      redirect_to withdrawals_path, alert: "Error rejecting withdrawal."
    end
  end

  private

  def set_withdrawal
    @withdrawal = Withdrawal.find(params[:id])
  end

  def adjust_deposits_for_withdrawal(withdrawal)
    remaining_amount = withdrawal.amount
    user_deposits = withdrawal.user.deposits.where(status: ['refund', 'referral_commission']).order(:created_at)
    
    user_deposits.each do |deposit|
      break if remaining_amount <= 0

      if deposit.amount > remaining_amount

        # If the deposit amount is more than the remaining amount, deduct the remaining amount from the deposit
        deposit.update!(amount: deposit.amount - remaining_amount)
        remaining_amount = 0
      else
        # If the deposit amount is less than or equal to the remaining amount, mark it as fully used for withdrawal
        remaining_amount -= deposit.amount
        deposit.update!(amount: 0, status: 'used for withdrawal')
      end
    end
  end

  def create_transaction_history(user, amount, transaction_type, status, withdrawal_id = nil)
    # Create a new transaction history record
    TransactionHistory.create!(
      user_id: user.id,
      amount: amount,
      transaction_type: transaction_type,
      status: status,
      withdrawal_id: withdrawal_id,
      transaction_date: Time.current
    )
  end

  def set_module_name
    @module_name = "withdraw"
  end
end
