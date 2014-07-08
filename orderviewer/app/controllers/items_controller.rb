class ItemsController < ApplicationController
  
  before_filter :confirm_logged_in
  
  def create
    Item.create!(params.require(:order_id).permit(:item_number, :file_1, :file_2, :product_code, :product_name, :quantity, :paper, :trim_size, :final_size, :score, :color_process, :uv_coating, :drill, :pick_out_item))
  end
  
  def show
    
  end  
  
end
