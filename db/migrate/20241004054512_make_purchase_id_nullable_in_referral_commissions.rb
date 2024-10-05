class MakePurchaseIdNullableInReferralCommissions < ActiveRecord::Migration[7.1]
  def change
    change_column_null :referral_commissions, :purchase_id, true

  end
end
