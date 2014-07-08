# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


Order.create(order_number: '131119000002', processed: 'true', ship_method: 'FDX_GROUND', ship_to_first_name: 'Chad', ship_to_last_name: 'Little', ship_to_company: 'Phacility', ship_to_addr1: '4054 Ben Lomond Dr', ship_to_addr2: '', ship_to_city: 'Palo Alto', ship_to_state: 'CA', ship_to_zip: '94306', ship_to_phone: '')

Order.create(order_number: '131119000003', processed: 'true', ship_method: 'FDX_GROUND', ship_to_first_name: 'Chris', ship_to_last_name: 'Elliott', ship_to_company: '', ship_to_addr1: '369 Pacific St', ship_to_addr2: 'Apt #1a', ship_to_city: 'Brooklyn', ship_to_state: 'NY', ship_to_zip: '11217', ship_to_phone: '(646) 461-0662')

Item.create(order_id: "1", item_number: "1", file_1: "131119000002.1.A.jpg", file_2: "131119000002.1.B.jpg", product_code: "HPYBNUC", product_name: "Business Cards, Hang Tags", quantity: "50", paper: "130# Solar White Uncoated Cover", trim_size: "3.5 x 2.0", final_size: "3.5 x 2.0", score: "none", color_process: "4/4", pick_out_item: "none", uv_coating: "N", drill: "none")

Item.create(order_id: "1", item_number: "2", file_1: "131119000002.2.A.jpg", file_2: "131119000002.2.B.jpg", product_code: "HPYBNUC", product_name: "Business Cards, Hang Tags", quantity: "50", paper: "130# Solar White Uncoated Cover", trim_size: "3.5 x 2.0", final_size: "3.5 x 2.0", score: "none", color_process: "4/4", pick_out_item: "none", uv_coating: "N", drill: "none")

Item.create(order_id: "2", item_number: "1", file_1: "131119000002.2.A.jpg", file_2: "131119000002.2.B.jpg", product_code: "HPYBNUC", product_name: "Business Cards, Hang Tags", quantity: "50", paper: "130# Solar White Uncoated Cover", trim_size: "3.5 x 2.0", final_size: "3.5 x 2.0", score: "none", color_process: "4/4", pick_out_item: "none", uv_coating: "N", drill: "none")