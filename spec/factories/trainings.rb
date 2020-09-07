FactoryGirl.define do
  factory :training, class: Training do
    subject { Faker::App.name }
    objectives { Faker::Lorem.paragraph(5, false, 4) }
    duration { 1 }
    date { Date.today }
    venue { 'Online' }
    video { 'www.youtube.com/wwTn7Yn' }
    blog_link { 'test-blog.com' }
    showcase_on_website { true }
  end

  factory :chapter, class: Training do
    chapter_number { 1 }
    subject { Faker::App.name }
    objectives { Faker::Lorem.paragraph(5, false, 4) }
    duration { 1 }
    date { Date.today }
    training
  end
end
