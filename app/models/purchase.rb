# app/models/purchase.rb
class Purchase < ApplicationRecord
  belongs_to :investment_plan, optional: true
  belongs_to :trading_plan, optional: true
  belongs_to :staking, optional: true
  belongs_to :user
  has_one :profit, dependent: :destroy

  has_attached_file :attachment
  validates_attachment_content_type :attachment, content_type: ['image/jpeg', 'image/png', 'application/pdf']

  validates :deposit_amount, presence: true
  after_update :check_rank_assignment, if: :approved_and_active?

  after_save :calculate_profit, if: :approved?
  after_update :create_referral_commission, if: :approved?

  # Calculate and store profit only when the purchase is approved
  def calculate_profit
    return unless approved? && status == 'active' && approve_at.present?

    plan = investment_plan || trading_plan || staking
    return unless plan.present?

    # Get the profit percentage from the plan
    profit_percentage = plan.profit_percentage || 0.0

    # Calculate the duration based on the plan type
    plan_duration = if staking.present?
                      duration_in_days
                    elsif investment_plan.present? || trading_plan.present?
                      plan.duration_in_days
                    else
                      0
                    end

    return unless plan_duration.present? && plan_duration > 0

    # Calculate total profit based on the duration and deposit amount
    total_profit = (deposit_amount * profit_percentage / 100.0) * (plan_duration.to_f / 31)
    daily_profit = total_profit / plan_duration

    # Calculate days since the plan was approved
    days_since_approval = (Date.today - approve_at.to_date).to_i

    # Calculate the accumulated profit based on the number of days elapsed since approval
    calculated_profit = [days_since_approval, plan_duration].min * daily_profit

    # Update or create the profit record
    if profit.present?
      profit.update(amount: calculated_profit)
    else
      self.profit = Profit.create!(user: user, purchase: self, amount: calculated_profit)
    end
  end




  private
  def create_referral_commission
    if user.referred_by_user.present?
      user.create_referral_commission_for_purchase(self)
    end
  end

  def approved_and_active?
    saved_change_to_approved? && approved && status == "active"
  end
  def check_rank_assignment
    user.assign_rank
  end
end
