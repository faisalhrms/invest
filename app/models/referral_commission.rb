# app/models/referral_commission.rb
class ReferralCommission < ApplicationRecord
  belongs_to :user  # The user who earned the commission (referring user)
  belongs_to :referral_user, class_name: 'User', foreign_key: 'referral_user_id', optional: true  # The referred user
  belongs_to :purchase, optional: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
end
