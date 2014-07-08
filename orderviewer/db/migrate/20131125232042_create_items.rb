class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.integer  :order_id
      t.integer  :item_number
      t.string   :file_1
      t.string   :file_2
      t.string   :product_code
      t.string   :product_name
      t.integer  :quantity
      t.string   :paper
      t.string   :trim_size
      t.string   :final_size
      t.string   :score
      t.string   :color_process
      t.boolean  :uv_coating
      t.boolean  :drill
      t.string   :pick_out_item
      
      t.timestamps
    end
    add_index :items, :order_id
  end
  
  def down
    drop_table :items
  end
end
