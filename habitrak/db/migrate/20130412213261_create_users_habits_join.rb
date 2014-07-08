class CreateUsersHabitsJoin < ActiveRecord::Migration
  def change
    create_table :users_habits do |t|
      t.integer "habit_id"
      t.integer "user_id"
      t.timestamps
    end
  add_index :users_habits, ["habit_id", "user_id"]
  end
  
  def down
    drop_table :users_habits
  end
end