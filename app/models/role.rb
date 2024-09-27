class Role < ApplicationRecord
  has_many  :permissions
  validates  :name, presence: true, uniqueness: true
  has_many :users
end
