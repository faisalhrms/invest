class DepositsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_module_name
  before_action :set_permissions, only: [:index, :create, :approve_deposit, :reject_deposit]

  def index
    if current_user.user_type == "administrator"
      @deposits = Deposit.where(status: 'manual_deposit').or(Deposit.where(status: 'pending'))
    else
      @deposits = current_user.deposits.where(status: 'manual_deposit').or(current_user.deposits.where(status: 'pending'))
    end
    ActivityStream.create_activity_stream("View Deposit Index Page", "Deposit", 0, current_user, "view")
  end

  def create
    deposit = current_user.deposits.build(deposit_params)  # Associate the deposit with the current user
    deposit.status = 'pending'  # Set the initial status to pending

    if deposit.save
      ActivityStream.create_activity_stream("Create #{deposit.user.email} New Deposit", "Deposit", deposit.user.id, current_user, "create")
      flash[:notice] = "Deposit Created Successfully"
    else
      flash[:alert] = deposit.errors.full_messages.first || "Something Went Wrong"
    end
    redirect_to deposit_path
  end

  # Custom approve action
  def approve_deposit
    deposit = Deposit.find(params[:id])

    if deposit.update(status: 'manual_deposit')
      TransactionHistory.create!(
        user: deposit.user,
        amount: deposit.amount,
        transaction_type: "Manual Deposit",
        status: 'approved',
        deposit_id: deposit.id
      )
      ActivityStream.create_activity_stream("Approved Deposit for #{deposit.user.email}", "Deposit", deposit.user.id, current_user, "approve")
      flash[:notice] = "Deposit Approved Successfully"
    else
      flash[:alert] = "Failed to Approve Deposit"
    end

    redirect_to deposit_path
  end

  # Custom reject action
  def reject_deposit
    deposit = Deposit.find(params[:id])

    if deposit.update(status: 'rejected')  # Update the status to rejected
      ActivityStream.create_activity_stream("Rejected Deposit for #{deposit.user.email}", "Deposit", deposit.user.id, current_user, "reject")
      flash[:notice] = "Deposit Rejected Successfully"
    else
      flash[:alert] = "Failed to Reject Deposit"
    end

    redirect_to deposit_path
  end

  private

  def deposit_params
    params.permit(:amount, :wallet_address, :attachment)
  end

  def set_module_name
    @sub_module_name = "deposits"
  end
end
