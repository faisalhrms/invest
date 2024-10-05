class AddManualPaymentToPurchases < ActiveRecord::Migration[7.1]
  def change
    add_column :purchases, :manual_payment, :boolean, default: false
  end
end
