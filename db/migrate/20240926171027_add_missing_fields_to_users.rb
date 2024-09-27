class AddMissingFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :mobile_with_country_code, :string
    add_column :users, :country, :string

  end
end
