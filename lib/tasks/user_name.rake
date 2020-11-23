namespace :user_name do
  desc 'strip leading or trailing whitespaces and tileizing user names'
  task strip_and_titleize_user_name: :environment do
    User.all.each do |user|
      first_name = user.public_profile.first_name.strip.downcase.titleize
      last_name = user.public_profile.last_name.strip.downcase.titleize
      if user.public_profile.first_name != first_name || user.public_profile.last_name != last_name
        puts "Changing name of user.email #{user.email} - changes '#{first_name}' '#{last_name}'"
        user.public_profile.set(first_name: first_name, last_name: last_name)
      end
    end
  end
end
