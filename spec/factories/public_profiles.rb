FactoryGirl.define do
  factory :public_profile do |p|
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    gender { Faker::Gender.binary_type }
    mobile_number { Faker::Number.number(10) }
    blood_group { "A+" }
    skills { "Badminton,Cricket" }
    technical_skills { ["Angular", "NodeJs", "Python", "React", "UI"] }
    date_of_birth { Date.today }
    github_handle { Faker::Internet.username }
    gitlab_handle { Faker::Internet.username }
    bitbucket_handle { Faker::Internet.username }
    blog_url { Faker::Internet.url }
  end
end
