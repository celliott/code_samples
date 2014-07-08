desc "This task is for processing images on s3"
task :process_images => :environment do
  
  puts "Processing images..."

  process = ArtworksController.new
  @artworks = Artwork.where('processed != 1')
  @artworks.each do |image|
    image_hash = process.s3_download_image(image.image)
    process.resize_image(image, image_hash)
    process.marked_processed(image)
  end
  puts "done."
end