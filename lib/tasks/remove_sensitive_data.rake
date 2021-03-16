require 'faker'

namespace :sensitive_data_update do
    
  desc 'update company, project and employess related sensitive data update or remove'
  task update_user_data: :environment do
    User.all.each do |user|

			description = 'user desciption dummy data for testing'   
			user.employee_detail.set(description: description, joining_bonus_paid: false)

      user.private_profile.set(
				pan_number: Faker::Bank.iban,
				passport_number: Faker::Bank.iban,
				personal_email: Faker::Internet.email,
				previous_company: Faker::Company.name
			)
      
			user.private_profile.addresses.each do |user_address|
				user_address.set(
					city: Faker::Address.city, 
					address: Faker::Address.full_address, 
					landline_no: Faker::PhoneNumber.cell_phone, 
					pin_code: Faker::Address.zip_code
				) 
      end
    end

		# remove only personal documents
		# Attachment.where(:is_visible_to_all => 'false').each do |record|
		# 	record.delete
		# end

		# destroy all the user personal documents.
		Attachment.destroy_all

		# destroy all the policies 
		Policy.destroy_all

		# change time_sheet description of all employees.
		TimeSheet.update_all(description: 'Worked on a task')

		# change reason of leave application because it's personal
		LeaveApplication.update_all(reason: 'Sick leave', reject_reason: '')
  end
end