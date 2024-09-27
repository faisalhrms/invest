class ReferralsController < ApplicationController
  before_action :set_permissions, only: [:index]
  before_action :authenticate_user!


  def index
    if current_user.user_type == "administrator"
      @referrals = User.left_joins(:purchases).where.not(referred_by: nil).distinct
    else
      @referrals = User.left_joins(:purchases).where(referred_by: current_user.id).distinct
    end
  end


end
