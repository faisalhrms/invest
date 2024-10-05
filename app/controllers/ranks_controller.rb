class RanksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_module_name
  before_action :set_permissions, only: [:index, :create, :update, :destroy]


  def index
    @rank = Rank.all
    ActivityStream.create_activity_stream("View Rank Index Page", "Rank", 0, @current_user, "view")
  end

  def edit_modal
    @rank = Rank.find(params[:id])
    render partial: 'ranks/edit_modal', locals: { rank: @rank}
  end


  def create
    rank = Rank.new(rank_params)
    if rank.save
      ActivityStream.create_activity_stream("Create #{User.last.email} New Rank", "Rank", User.last.id, @current_user, "create")
      flash[:notice] = "Rank Created Successfully"
    else
      if rank.errors.full_messages.first == "BankAccount has already been taken"
        flash[:alert] = rank.errors.full_messages.first
      else
        flash[:alert] = "Something Went Wrong"
      end
    end
    redirect_to rank_path
  end
  def update
    if params[:is_active].nil?
      params[:is_active] = false
    end
    rank = Rank.find(params[:id])
    if rank.update(rank_params)
      ActivityStream.create_activity_stream("Update #{rank.name} Existing Rank", "Rank", rank.id, @current_user, "edit")
      flash[:notice] = "Rank Updated Successfully"
    else
      flash[:alert] = "Something Went Wrong"
    end
    redirect_to rank_path
  end

  def destroy
    rank = BankAccount.find(params[:id])
    if  rank.present?
      ActivityStream.create_activity_stream("Delete #{rank.name} From Rank", "Rank", rank.id, @current_user, "delete")
      menu.delete
      flash[:notice] = "Rank Deleted"
    end
    redirect_to rank_path
  end

  private
  def rank_params
    params.permit(:name, :minimum_deposit, :profit_percentage)
  end
  def set_module_name
    @module_name = "purchases"
    @sub_module_name = "ranks"

  end

end
