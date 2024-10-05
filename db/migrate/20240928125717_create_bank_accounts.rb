class CreateBankAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :bank_accounts do |t|
      t.string     :account_name
      t.string     :account_number
      t.string     :bank_name
      t.string     :iban
      t.boolean     :is_active , default: false
      t.timestamps
    end
  end
end
