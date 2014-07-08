class AddOrderCreatedToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :order_created, :datetime
    add_column :orders, :date_processed, :boolean, :default => false
  end
end
