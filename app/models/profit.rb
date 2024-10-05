# app/models/profit.rb
class Profit < ApplicationRecord
  belongs_to :user
  belongs_to :purchase

  validates :amount, numericality: { greater_than_or_equal_to: 0.0 }
end
