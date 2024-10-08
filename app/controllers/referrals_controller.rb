class ReferralsController < ApplicationController
  before_action :set_permissions, only: [:index,:referral_details]
  before_action :authenticate_user!

  def index
    if current_user.user_type == "administrator"
      @referrals = User.left_joins(:purchases)
                       .where.not(referred_by: nil)
                       .select { |user| user.referred_users.count > 0 }
    else
      @referrals = User.left_joins(:purchases)
                       .where(referred_by: current_user.id)
                       .select { |user| user.referred_users.count > 0 }
    end
  end


  # Action to handle AJAX request and show referral details in the modal
  def referral_details
    
    @user = User.find(params[:id])
    @referrals = @user.referred_users.includes(:purchases)
    render partial: 'referral_details', locals: { user: @user, referrals: @referrals }
  end
end
