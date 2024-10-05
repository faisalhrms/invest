class AddReferralUserId < ActiveRecord::Migration[7.1]
  def change
    add_reference :referral_commissions, :referral_user, foreign_key: { to_table: :users }

  end
end
