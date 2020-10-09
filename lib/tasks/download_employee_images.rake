# run - rake download_employee_images['destination_folder_path']
require 'open-uri'

desc 'Download all employees images'
task :download_employee_images, [:location] => [:environment] do |task, args|
  employees_default_images = []
  User.approved.each do |user|
    if user.public_profile.image_url.include?('default_photo')
      employees_default_images << user.email
      next
    end

    domain = 'https://' + ENV['DOMAIN_NAME']
    image_path = user.public_profile.image_url
    file_name = "#{user.employee_detail.employee_id}_#{user.name}" +
                ".#{user.public_profile.image.file.extension.downcase}" 
    file = open(domain + image_path)
    IO.copy_stream(file, "#{args.location}/#{file_name}")
  end

  puts "\n Below Employee's don't have their profile images: "
  puts employees_default_images
end
