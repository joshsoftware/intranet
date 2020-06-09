FactoryGirl.define do
  factory :user do |u|
    role { 'Employee' }
    sequence(:email) { |n| "emp#{n}@#{ORGANIZATION_DOMAIN}" }
    password { Faker::Internet.password }
    employee_detail_attributes { FactoryGirl.attributes_for(:employee_detail) }
    before(:create) do |user|
      user.public_profile = FactoryGirl.create(:public_profile, user: user)
      user.private_profile = FactoryGirl.create(:private_profile, user: user)
    end
  end

  factory :super_admin, class: User, parent: :user do |u|
    role { 'Super Admin' }
    sequence(:email) { |n| "superadmin#{n}@#{ORGANIZATION_DOMAIN}" }
    password { Faker::Internet.password }
  end

  factory :admin, class: User, parent: :user do |u|
    role { 'Admin' }
    sequence(:email) { |n| "admin#{n}@#{ORGANIZATION_DOMAIN}" }
    password { Faker::Internet.password }
  end

  factory :hr, class: User, parent: :user do |u|
    role { 'HR' }
    sequence(:email) { |n| "hr#{n}@#{ORGANIZATION_DOMAIN}" }
    password { Faker::Internet.password }
  end

  factory :employee, class: User do
    role { 'Employee' }
    status { 'approved' }
    sequence(:email) { |i | Faker::Name.first_name + i.to_s + "@#{ORGANIZATION_DOMAIN}" }
    password { Faker::Internet.password }
    employee_detail_attributes { FactoryGirl.attributes_for(:employee_detail) }
  end

  factory :manager, class: User do
    role { 'Manager' }
    sequence(:email) { |n| "manager#{n}@#{ORGANIZATION_DOMAIN}" }
    password { Faker::Internet.password }
  end

  factory :user_with_designation, class: User do |u|
    role { 'Employee' }
    sequence(:email) { |n| "emp#{n}@#{ORGANIZATION_DOMAIN}" }
    password { Faker::Internet.password }
    before(:create) do |user|
      user.public_profile = FactoryGirl.create(:public_profile, user: user)
      user.private_profile = FactoryGirl.create(:private_profile, user: user)
      user.employee_detail = FactoryGirl.create(:employee_detail, user: user)
    end
  end

  factory :admin_with_designation, class: User do |u|
    role { 'Admin' }
    sequence(:email) { |n| "admin#{n}@#{ORGANIZATION_DOMAIN}" }
    password { Faker::Internet.password }
    before(:create) do |user|
      user.public_profile = FactoryGirl.create(:public_profile, user: user)
      user.private_profile = FactoryGirl.create(:private_profile, user: user)
      user.employee_detail = FactoryGirl.create(:employee_detail, user: user)
    end
  end

end
