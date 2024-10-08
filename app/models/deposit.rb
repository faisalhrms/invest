class Deposit < ApplicationRecord
  belongs_to :user
  belongs_to :investment_plan, optional: true
  belongs_to :trading_plan, optional: true
  belongs_to :staking, optional: true
  has_attached_file :attachment
  validates_attachment :attachment, content_type: { content_type: ["image/jpeg", "image/png", "application/pdf"] }
  before_save :calculate_profit
  private

  def calculate_profit
    return if status == "refund" || status == "deduction_fee"
    plan = investment_plan || trading_plan || staking
    return unless plan.present?

    profit_percentage = plan.profit_percentage || 0.0
    plan_duration = if investment_plan_id.present? || trading_plan_id.present?
                      plan.duration_in_days
                    else
                      duration_in_days
                    end

    # Calculate profit based on the plan's duration and deposit amount
    if plan_duration.present? && plan_duration > 0
      self.calculated_profit = (amount * profit_percentage / 100.0) * (plan_duration.to_f / 30)
    else
      self.calculated_profit = (amount * profit_percentage) / 100.0
    end

    # Determine profit eligibility based on the plan type
    if new_record?
      self.profit_eligible = trading_plan_id.present? || staking_id.present? ? false : true
    else
      self.profit_eligible = eligible_for_profit?(plan_duration)
    end
  end

  # Helper method to determine if the deposit is eligible for profit
  def eligible_for_profit?(plan_duration)
    # For trading and staking plans, profit eligibility is based on plan duration days
    if trading_plan_id.present? || staking_id.present?
      return false unless plan_duration.present? && created_at.present?
      (Date.today - created_at.to_date).to_i >= plan_duration
    else
      # For investment plans, profit is always eligible
      true
    end
  end
end
