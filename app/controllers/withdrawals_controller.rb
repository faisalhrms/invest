# app/controllers/withdrawals_controller.rb
class WithdrawalsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_withdrawal, only: [:approve, :reject]
  before_action :set_module_name

  def create
    withdrawal_type = params[:withdrawal_type]
    total_amount = case withdrawal_type
                   when 'profit'
                     current_user.total_withdrawable_profit
                   when 'referral_commission'
                     current_user.withdrawable_referral_commission
                   else
                     current_user.total_deposits
                   end

    if params[:amount].to_f > 0 && params[:amount].to_f <= total_amount && params[:wallet_address].present?
      withdrawal = current_user.withdrawals.create!(
        amount: params[:amount].to_f,
        wallet_address: params[:wallet_address],
        withdrawal_type: withdrawal_type,
        status: 'pending'
      )
      create_transaction_history(current_user, withdrawal.amount, "Withdrawal Requested", "pending", withdrawal.id)

      redirect_to dashboard_path, notice: "Your withdrawal request for $#{params[:amount]} to wallet address #{params[:wallet_address]} has been submitted successfully."
    else
      redirect_to dashboard_path, alert: "Invalid withdrawal amount, wallet address, or insufficient balance."
    end
  end

  def approve
    if @withdrawal.update(status: 'approved')
      adjust_deposits_for_withdrawal(@withdrawal)

      create_transaction_history(@withdrawal.user, @withdrawal.amount, "Withdrawal Approved", "approved", @withdrawal.id)

      redirect_to withdrawals_path, notice: "Withdrawal approved successfully and funds sent to wallet address #{@withdrawal.wallet_address}."
    else
      redirect_to withdrawals_path, alert: "Error approving withdrawal."
    end
  end
  def index
    @pending_withdrawals = Withdrawal.where(status: 'pending')
    render "withdrawals/index"
  end
  def reject
    if @withdrawal.update(status: 'rejected')
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
    user_deposits = withdrawal.user.deposits.where(status: ['refund','manual_deposit' ,'referral_commission']).order(:created_at)

    user_deposits.each do |deposit|
      break if remaining_amount <= 0

      if deposit.amount > remaining_amount
        deposit.update!(amount: deposit.amount - remaining_amount)
        remaining_amount = 0
      else
        remaining_amount -= deposit.amount
        deposit.update!(amount: 0, status: 'used for withdrawal')
      end
    end
  end

  def create_transaction_history(user, amount, transaction_type, status, withdrawal_id = nil)
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
