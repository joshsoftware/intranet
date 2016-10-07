# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :public_profile do |p|
    first_name "fname"
    last_name "lname"
    gender "Male"
    mobile_number "1234567890"
    blood_group "A+"
    date_of_birth Date.today
    github_handle "abhishekbose87"
    blog_url "rishionrails.wordpress.com"
    blog_feed_url "rishionrails.wordpress.com/feed"
  end
end
