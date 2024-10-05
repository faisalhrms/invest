class PlanDurationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_module_name
  before_action :set_permissions, only: [:index, :create, :update, :destroy]

  def index
    @plan_duration = PlanDuration.all
    ActivityStream.create_activity_stream("View PlanDuration Index Page", "PlanDuration", 0, @current_user, "view")
  end

  def edit_modal
    @plan_duration = PlanDuration.find(params[:id])
    render partial: 'plan_durations/edit_modal', locals: { plan_duration: @plan_duration }
  end

  def create
    plan_duration = PlanDuration.new(plan_duration_params)
    if plan_duration.save
      ActivityStream.create_activity_stream("Create #{User.last.email} New PlanDuration", "PlanDuration", User.last.id, @current_user, "create")
      flash[:notice] = "PlanDuration Created Successfully"
    else
      if plan_duration.errors.full_messages.first == "PlanDuration has already been taken"
        flash[:alert] = plan_duration.errors.full_messages.first
      else
        flash[:alert] = "Something Went Wrong"
      end
    end
    redirect_to plan_duration_path
  end

  def update
    if params[:is_active].nil?
      params[:is_active] = false
    end
    plan_duration = PlanDuration.find(params[:id])
    if plan_duration.update(plan_duration_params)
      ActivityStream.create_activity_stream("Update #{plan_duration.plan_type} Existing PlanDuration", "PlanDuration", plan_duration.id, @current_user, "edit")
      flash[:notice] = "PlanDuration Updated Successfully"
    else
      flash[:alert] = "Something Went Wrong"
    end
    redirect_to plan_duration_path
  end

  def destroy
    plan_duration = PlanDuration.find(params[:id])
    if plan_duration.present?
      ActivityStream.create_activity_stream("Delete #{plan_duration.plan_type} From PlanDuration", "PlanDuration", plan_duration.id, @current_user, "delete")
      menu.delete
      flash[:notice] = "InvestmentPlans Deleted"
    end
    redirect_to plan_duration_path
  end

  private

  def plan_duration_params
    params.permit(:plan_id, :plan_type, :duration_in_days,:is_active)
  end

  def set_module_name
    @module_name = "plans"
    @sub_module_name = "plan_durations"

  end
end

