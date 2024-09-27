class Purchase < ApplicationRecord
  belongs_to :investment_plan, optional: true
  belongs_to :trading_plan, optional: true
  belongs_to :staking, optional: true
  belongs_to :user

  # Paperclip or ActiveStorage attachment for payment proof
  has_attached_file :attachment
  validates_attachment_content_type :attachment, content_type: ['image/jpeg', 'image/png', 'application/pdf']

  validates :deposit_amount, presence: true
  validate :validate_deposit_amount

  # Custom validation to check if the deposit amount matches the plan price
  def validate_deposit_amount
    if investment_plan.present? && deposit_amount != investment_plan.price.to_f
      errors.add(:deposit_amount, "must be exactly #{investment_plan.price}")
    elsif trading_plan.present? && deposit_amount != trading_plan.price.to_f
      errors.add(:deposit_amount, "must be exactly #{trading_plan.price}")
    elsif staking.present? && deposit_amount != staking.price.to_f
      errors.add(:deposit_amount, "must be exactly #{staking.price}")
    end
  end
end
