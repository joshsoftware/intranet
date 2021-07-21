require 'faker'

namespace :replace_sensitive_data do
    
  desc 'replace company and employees sensitive data'
  task replace_user_data: :environment do
    User.all.each do |user|

      if !user.private_profile.nil?
        user.private_profile.set(
          pan_number: Faker::Bank.iban,
          passport_number: Faker::Bank.iban,
          personal_email: Faker::Internet.email,
        )

        user.private_profile.contact_persons.update_all(
          relation: 'Friend',
          name: Faker::Name.name, 
          phone_no: Faker::PhoneNumber.phone_number
        )
      end
    end

    Company.all.each do |company|
      update_contact_person(company)
    end

    LeaveApplication.update_all(reason: 'Sick leave', reject_reason: '')
  end
  
  desc 'remove company and employess sensitive data'
  task remove_sensitive_data: :environment do
    Attachment.destroy_all
    Policy.destroy_all
  end
end

def update_contact_person(object)
  if !object.contact_persons.nil?
    object.contact_persons.update_all(
      name: Faker::Name.name, 
      role: Faker::Job.title, 
      phone_no: Faker::PhoneNumber.phone_number, 
      email: Faker::Internet.email
    )
  end
end
