class ReferralsController < ApplicationController
  before_action :set_permissions, only: [:index,:referral_details]
  before_action :authenticate_user!

  def index
    if current_user.user_type == "administrator"
      params[:filter] ||= 'all'

      @referrals = User.includes(:purchases, :referred_by_user)


      # Apply filters
      case params[:filter]
      when 'bought_packages'
        @referrals = @referrals.joins(:purchases).distinct
      when 'via_referrals'
        # Base query already includes users referred by someone and who have referrals
        @referrals = @referrals
      when 'no_plan'
        @referrals = @referrals.left_joins(:purchases)
                               .where(purchases: { id: nil })
      else
        @referrals = User.joins(:referred_users)
                         .where.not(referred_by: nil)
                         .distinct
                         .includes(:purchases, :referred_by_user)
      end

    else
      # For non-admin users, set @referrals as specified and hide filters
      @referrals = User.joins(:referred_users)
                       .where(referred_by: current_user.id)
                       .distinct
                       .includes(:purchases, :referred_by_user)
      # No filters to apply for non-admins
    end
  end





  # Action to handle AJAX request and show referral details in the modal
  def referral_details
    
    @user = User.find(params[:id])
    @referrals = @user.referred_users.includes(:purchases)
    render partial: 'referral_details', locals: { user: @user, referrals: @referrals }
  end
end
