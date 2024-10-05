class BankAccountDetailsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_module_name
  before_action :set_permissions, only: [:index, :create, :update, :destroy]


  def index
    @bank_account = BankAccount.all
    ActivityStream.create_activity_stream("View BankAccount Index Page", "BankAccount", 0, @current_user, "view")
  end

  def edit_modal
    @bank_account = BankAccount.find(params[:id])
    render partial: 'bank_account_details/edit_modal', locals: { bank_account: @bank_account}
  end


  def create
    bank_account = BankAccount.new(bank_account_params)
    if bank_account.save
      ActivityStream.create_activity_stream("Create #{User.last.email} New BankAccount", "BankAccount", User.last.id, @current_user, "create")
      flash[:notice] = "BankAccount Created Successfully"
    else
      if bank_account.errors.full_messages.first == "BankAccount has already been taken"
        flash[:alert] = bank_account.errors.full_messages.first
      else
        flash[:alert] = "Something Went Wrong"
      end
    end
    redirect_to bank_account_path
  end
  def update
    if params[:is_active].nil?
      params[:is_active] = false
    end
    bank_account = BankAccount.find(params[:id])
    if bank_account.update(bank_account_params)
      ActivityStream.create_activity_stream("Update #{bank_account.name} Existing BankAccount", "BankAccount", bank_account.id, @current_user, "edit")
      flash[:notice] = "BankAccount Updated Successfully"
    else
      flash[:alert] = "Something Went Wrong"
    end
    redirect_to bank_account_path
  end

  def destroy
    bank_account = BankAccount.find(params[:id])
    if  bank_account.present?
      ActivityStream.create_activity_stream("Delete #{bank_account.name} From BankAccount", "BankAccount", bank_account.id, @current_user, "delete")
      menu.delete
      flash[:notice] = "BankAccount Deleted"
    end
    redirect_to bank_account_path
  end

  private
  def bank_account_params
    params.permit(:account_name, :account_number, :bank_name,:iban, :is_active)
  end
  def set_module_name
    @module_name = "authentication"
    @sub_module_name = "bank_account"

  end

end
