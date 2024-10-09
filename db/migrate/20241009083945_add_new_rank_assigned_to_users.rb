class AddNewRankAssignedToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :new_rank_assigned, :boolean
  end
end
