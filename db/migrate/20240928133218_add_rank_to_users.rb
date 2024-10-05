class AddRankToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :rank, foreign_key: true
  end
end
