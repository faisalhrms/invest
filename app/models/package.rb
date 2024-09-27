class Package < ApplicationRecord
  validates :name, presence: true
  validates :description, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: %w(active inactive), message: "%{value} is not a valid status" }
  has_many :plan_transactions

  has_attached_file :attachment
  validates_attachment_content_type :attachment, content_type: /\Aimage\/.*\z/, if: -> { attachment.present? }
end
