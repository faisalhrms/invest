class PlanTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :package

  # Paperclip attachment for storing the uploaded file
  has_attached_file :attachment
  validates_attachment_content_type :attachment, content_type: /\Aimage\/.*\z/

  validate :single_active_plan_per_user, on: :create

  private

  # Custom validation to ensure a user can only have one active plan
  def single_active_plan_per_user
    if user.plan_transactions.joins(:package).where(packages: { status: 'active' }).exists?
      errors.add(:base, 'You already have an active plan. You cannot purchase another one.')
    end
  end
end
