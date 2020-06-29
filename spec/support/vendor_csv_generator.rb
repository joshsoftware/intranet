module VendorCsvGenerator
  def generate_valid_csv(vendor, email = nil, is_change = false)
    if is_change
      contact_person = vendor.contact_persons.last
      contact_person[:email] = email
    else
      contact_person = FactoryGirl.attributes_for(:contact_person)
    end
    CSV.open("valid_vendors.csv", "w") do |csv|
      csv << ["not sure what 0th field is", :name, :company, :category, :role, :phone_no, :email]
      csv << ["not sure what 0th field is", contact_person[:name], vendor[:company], vendor[:category], contact_person[:role], contact_person[:phone_no], contact_person[:email]]
    end
  end

  def generate_invalid_csv(vendor)
    contact_person = FactoryGirl.attributes_for(:contact_person)
    CSV.open("valid_vendors.csv", "w") do |csv|
      csv << ["not sure what 0th field is", :name, :company, :category, :role, :phone_no, :email]
      csv << ["not sure what 0th field is", contact_person[:name], vendor[:company], vendor[:category], contact_person[:role], contact_person[:email]]
    end
  end
end
