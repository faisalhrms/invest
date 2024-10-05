class Rank < ApplicationRecord
  has_many :users
  validates :name, :minimum_deposit, :profit_percentage, presence: true
  validates :profit_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
end
