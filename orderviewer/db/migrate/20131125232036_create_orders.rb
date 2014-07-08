class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.string   :order_number
      t.integer  :item_count
      t.string   :status
      t.string   :ship_method
      t.string   :ship_to_full_name
      t.string   :ship_to_first_name
      t.string   :ship_to_last_name
      t.string   :ship_to_company
      t.string   :ship_to_addr1
      t.string   :ship_to_addr2
      t.string   :ship_to_city
      t.string   :ship_to_state
      t.string   :ship_to_zip
      t.string   :ship_to_phone
      
      t.timestamps
    end
  end
  
  def down
    drop_table :orders
  end
end