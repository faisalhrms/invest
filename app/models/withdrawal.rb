# app/models/withdrawal.rb
class Withdrawal < ApplicationRecord
  belongs_to :user

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[pending approved rejected] }

  def approve!
    update!(status: 'approved', processed_at: Time.current)
  end

  def reject!
    update!(status: 'rejected')
  end
end
