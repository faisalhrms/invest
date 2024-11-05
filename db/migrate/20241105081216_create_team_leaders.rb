class CreateTeamLeaders < ActiveRecord::Migration[7.1]
  def change
    create_table :team_leaders do |t|
      t.string :member_name
      t.string :country
      t.date :date
      t.decimal :investment_amount

      t.timestamps
    end
  end
end
