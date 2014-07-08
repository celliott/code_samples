class CreateHabits < ActiveRecord::Migration
    def change
      create_table :habits do |t|
        t.string "name"
        t.integer "user_id"
        t.timestamps
      end
    add_index("habits", "user_id")  
    end

    def down
      drop_table :habits
    end
  end