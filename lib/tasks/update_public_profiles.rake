desc 'Update the Github and Twitter handle of all users'
task :update_public_profile => :environment do

  get_public_profile_details
  puts "\n Before Update"
  puts "\n Github: "
  puts "Handle count: #{@handle[:github]}"
  puts "URL count: #{@url[:github]}"

  puts "\n Twitter: "
  puts "Handle count: #{@handle[:twitter]}"
  puts "URL count: #{@url[:twitter]}"

  @github_users.each do |user|
    regex = /(?:https?:\/\/)?(?:www\.)?github\.com\/(?:#!\/)?@?([^\/\?\s]*)/
    url = user.public_profile.github_handle
    handle = url.match(regex)[1]
    user.public_profile.set(github_handle: handle)
  end

  @twitter_users.each do |user|
    regex = /(?:https?:\/\/)?(?:www\.)?twitter\.com\/(?:#!\/)?@?([^\/\?\s]*)/
    url = user.public_profile.twitter_handle
    handle = url.match(regex)[1]
    user.public_profile.set(twitter_handle: handle)
  end

  # remove '@' form users twitter handle
  User.all.each do |user|
    twitter = user.public_profile.twitter_handle
    if twitter.present? && twitter.starts_with?('@')
      twitter = twitter.sub('@', '')
      user.public_profile.set(twitter_handle: twitter)
    end
  end

  get_public_profile_details
  puts "\n After Update"
  puts "\n Github: "
  puts "Handle count: #{@handle[:github]}"
  puts "URL count: #{@url[:github]}"

  puts "\n Twitter: "
  puts "Handle count: #{@handle[:twitter]}"
  puts "URL count: #{@url[:twitter]}"
end

def get_public_profile_details
  @handle = { github: 0, twitter: 0 }
  @url = { github: 0, twitter: 0 }
  @github_users = []
  @twitter_users = []
  User.all.each do |user|
    github = user.public_profile.github_handle
    twitter = user.public_profile.twitter_handle
    if github.present?
      if github.include?('github')
        @url[:github] += 1
        @github_users << user
      else
        @handle[:github] += 1
      end
    end

    if twitter.present?
      if twitter.include?('twitter')
        @url[:twitter] += 1
        @twitter_users << user
      else
        @handle[:twitter] += 1
      end
    end
  end
end
