class PackagesController < ApplicationController
  before_action :set_package, only: [:show, :update, :destroy]
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, :only => :list

  def list
    @packages = Package.all
    respond_to do |format|
      format.json { render json: @packages, status: :ok }
    end
  end

    def active_plan
      # Find the last plan transaction for the current user where the associated package has status 'active'
      @active_plan = PlanTransaction.joins(:package)
                                    .where(user: current_user)
                                    .last

      if @active_plan
        # Include both the package and plan transaction details in the response
        render json: {
          plan: @active_plan.package,
          plan_transaction: {
            id: @active_plan.id,
            deposit_amount: @active_plan.deposit_amount,
            status: @active_plan.status,
            created_at: @active_plan.created_at,
            updated_at: @active_plan.updated_at
          }
        }, status: :ok
      else
        render json: { message: 'No active plan found' }, status: :ok
      end
    end

  def pending_requests
    @pending_requests = PlanTransaction.joins(:package, :user)
                                       .where(status: 'pending')
                                       .select('packages.name as package_name, users.full_name as requester_name, plan_transactions.deposit_amount, plan_transactions.created_at as submitted_date, plan_transactions.id, plan_transactions.status')

    render json: @pending_requests, status: :ok
  end

  # PUT /packages/:id/approve
  def approve
    @plan_transaction = PlanTransaction.find(params[:id])

    if @plan_transaction.update(status: 'active')
      render json: { message: 'Plan approved successfully', success: true }, status: :ok
    else
      render json: { message: 'Failed to approve plan', success: false }, status: :unprocessable_entity
    end
  end

  # PUT /packages/:id/reject
  def reject
    @plan_transaction = PlanTransaction.find(params[:id])

    if @plan_transaction.update(status: 'rejected')
      render json: { message: 'Plan rejected successfully', success: true }, status: :ok
    else
      render json: { message: 'Failed to reject plan', success: false }, status: :unprocessable_entity
    end
  end

  def cancel_plan
    @active_plan = Package.find_by(id: params[:id])
    if @active_plan
      @active_plan.plan_transactions.destroy_all
      render json: { message: 'Plan cancelled successfully', success: true }, status: :ok
    else
      render json: { error: 'No active plan found' }, status: :not_found
    end
  end
  # GET /packages/:id
  def show
    @package  =  Package.all
    respond_to do |format|
      format.json { render json: @package, status: :ok }
    end
  end

  # POST /packages
  def create
    @package = Package.new(package_params)
    if @package.save
      render json: { message: 'Package created successfully', package: @package }, status: :created
    else
      render json: { errors: @package.errors.full_messages }, status: :unprocessable_entity
    end


  end

  # PUT /packages/:id
  def update
    if @package.update(package_params)
      render json: { message: 'Package updated successfully', package: @package }, status: :ok
    else
      render json: { errors: @package.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /packages/:id
  def destroy
    if @package.destroy
      render json: { message: 'Package deleted successfully' }, status: :ok
    else
      render json: { errors: 'Failed to delete the package' }, status: :unprocessable_entity
    end
  end


  private

  def set_package
    @package = Package.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { error: 'Package not found' }, status: :not_found }
    end
  end

  def package_params
    params.require(:package).permit(:name, :description, :price, :status)
  end
end
