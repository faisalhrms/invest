class StakingController < ApplicationController

  before_action :authenticate_user!
  before_action :set_module_name
  before_action :set_permissions, only: [:index, :create, :update, :destroy]


  def index
    @staking = Staking.all
    ActivityStream.create_activity_stream("View Staking Plans Index Page", "Staking", 0, @current_user, "view")
  end

  def edit_modal
    @staking = Staking.find(params[:id])
    render partial: 'staking/edit_modal', locals: { staking: @staking}
  end

  def staking
    # Fetch all purchases for staking plans
    @staking_purchases = Purchase.joins(:user).where.not(staking_id: nil)
  end
  def create
    staking = Staking.new(staking_params)
    if staking.save
      ActivityStream.create_activity_stream("Create #{User.last.email} New Staking Plans", "Staking", User.last.id, @current_user, "create")
      flash[:notice] = "Staking Created Successfully"
    else
      if staking.errors.full_messages.first == "Staking has already been taken"
        flash[:alert] = staking.errors.full_messages.first
      else
        flash[:alert] = "Something Went Wrong"
      end
    end
    redirect_to staking_plan_path
  end
  def update
    if params[:is_active].nil?
      params[:is_active] = false
    end
    staking = Staking.find(params[:id])
    if staking.update(staking_params)
      ActivityStream.create_activity_stream("Update #{staking.name} Existing Staking", "Staking", staking.id, @current_user, "edit")
      flash[:notice] = "Staking Updated Successfully"
    else
      flash[:alert] = "Something Went Wrong"
    end
    redirect_to staking_plan_path
  end

  def destroy
    staking = Staking.find(params[:id])
    if  staking.present?
      ActivityStream.create_activity_stream("Delete #{staking.name} From Staking", "Staking", staking.id, @current_user, "delete")
      menu.delete
      flash[:notice] = "Staking Deleted"
    end
    redirect_to staking_plan_path
  end

  private
  def staking_params
    params.permit(:name, :description, :price,:duration_in_days, :profit_percentage,:is_active)
  end
  def set_module_name
    @module_name = "plans"
    @sub_module_name = "staking"

  end


end
