class AddReferredByToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :referred_by, :integer
  end
end
