class CreatePlanDurations < ActiveRecord::Migration[7.1]
  def change
    create_table :plan_durations do |t|
      t.integer   :plan_id
      t.string   :plan_type
      t.integer   :duration_in_days
      t.string "slug", default: ""
      t.boolean "is_active", default: false
      t.timestamps
    end
  end
end
