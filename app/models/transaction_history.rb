class TransactionHistory < ApplicationRecord
  belongs_to :purchase, optional: true
  belongs_to :withdrawal, optional: true
  belongs_to :referral_commission, optional: true
  belongs_to :user

  def affects_withdrawable_balance?
    %w[deposit refund].include?(transaction_type) || (transaction_type == 'withdrawal' && status != 'approved')
  end

  def self.create_transaction(current_user, amount, transaction_type, plan_type,plan_id,status,purchase_id)
    TransactionHistory.create(:user_id => current_user.id, :amount => amount, :transaction_type => transaction_type, :plan_type => plan_type,
                              :plan_id => plan_id, :status => status, :purchase_id => purchase_id)
  end

end
