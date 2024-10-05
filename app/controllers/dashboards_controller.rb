class DashboardsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def index
    @transaction_histories = current_user.transaction_histories.order(created_at: :desc)
  end


end
