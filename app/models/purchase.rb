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

  # Callbacks to update rank and record commission when approved
  after_save :update_user_rank
  after_save :calculate_and_record_commission, if: :approved?
  after_save :calculate_profit, if: :approved?

  # Calculate and store profit only when the purchase is approved
  def calculate_profit
    return unless approved? && status == 'active' && approve_at.present?

    plan = investment_plan || trading_plan || staking
    return unless plan.present?
    profit_percentage = plan.profit_percentage || 0.0
    plan_duration = if investment_plan.present? || trading_plan.present?
                      plan.duration_in_days
                    else
                      duration_in_days
                    end
    return unless plan_duration.present? && plan_duration > 0
    total_profit = (deposit_amount * profit_percentage / 100.0) * (plan_duration.to_f / 31)

    daily_profit = total_profit / plan_duration

    days_since_approval = (Date.today - approve_at.to_date).to_i

    calculated_profit = [days_since_approval, plan_duration].min * daily_profit

    if profit.present?
      profit.update(amount: calculated_profit)
    else
      self.profit = Profit.create!(user: user, purchase: self, amount: calculated_profit)
    end
  end



  # Calculate and record commission for the referring user
  def calculate_and_record_commission
    referring_user = user.referred_by_user
    return unless referring_user.present?

    # Calculate the commission amount based on the purchase
    commission_amount = referring_user.calculate_referral_commission(deposit_amount)

    # Create a new ReferralCommission record
    ReferralCommission.create!(
      user: referring_user,
      referral_user_id: user.id,  # Store the referred user's ID
      purchase: self,
      amount: commission_amount
    )
  end

  def update_user_rank
    user.assign_rank
  end

  # Custom validation to check if the deposit amount matches the plan price

end
