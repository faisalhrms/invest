class AddColumnsInTeamLeaders < ActiveRecord::Migration[7.1]
  def change
    add_column :team_leaders, :team_members, :integer
    add_column :team_leaders, :user_capital, :decimal
    add_column :team_leaders, :total_earnings, :decimal
  end
end
