require 'faker'

namespace :replace_sensitive_data do
    
  desc 'replace company and employees sensitive data'
  task replace_user_data: :environment do
    User.all.each do |user|

      user.employee_detail.set(
        description: 'user desciption dummy data for testing',
        joining_bonus_paid: false
      )

      user.private_profile.set(
        pan_number: Faker::Bank.iban,
        passport_number: Faker::Bank.iban,
        personal_email: Faker::Internet.email,
        previous_company: Faker::Company.name
      )

      user.private_profile.contact_persons.update_all(
        relation: '',
        name: Faker::Name.name, 
        phone_no: Faker::PhoneNumber.phone_number
      )
      
      update_address(user.private_profile)
    end

    Vendor.all.each do |vendor|
      vendor.set(company: Faker::Company.name, category: '')
      update_contact_person(vendor)
      
      vendor.address = Address.create(
        city: Faker::Address.city, 
        address: Faker::Address.full_address, 
        landline_no: Faker::PhoneNumber.cell_phone, 
        pin_code: Faker::Address.zip_code
      )
      vendor.save
    end

    Company.all.each do |company|
      update_contact_person(company)
      update_address(company)
    end

    TimeSheet.update_all(description: 'Worked on a task')
    LeaveApplication.update_all(reason: 'Sick leave', reject_reason: '')
  end
  
  desc 'remove company and employess sensitive data'
  task remove_sensitive_data: :environment do
    Attachment.destroy_all
    Policy.destroy_all
  end
end

def update_contact_person(object)
  object.contact_persons.update_all(
    name: Faker::Name.name, 
    role: Faker::Job.title, 
    phone_no: Faker::PhoneNumber.phone_number, 
    email: Faker::Internet.email
  )
end

def update_address(object)
  object.addresses.update_all(
    city: Faker::Address.city, 
    address: Faker::Address.full_address, 
    landline_no: Faker::PhoneNumber.cell_phone, 
    pin_code: Faker::Address.zip_code
  )
end