require 'spec_helper'

describe PrivateProfile do
  
  it { should have_fields(:pan_number, :personal_email, :passport_number, :qualification, :date_of_joining, :work_experience, :previous_company) }
  it { should have_field(:date_of_joining).of_type(Date) }
  it { should have_many :addresses }
  it { should embed_many :contact_persons }
  it { should be_embedded_in(:user) }
  it { should accept_nested_attributes_for(:addresses) }
  it { should accept_nested_attributes_for(:contact_persons) }
=begin
  it { should validate_presence_of(:qualification).on(:update) }
  it { should validate_presence_of(:date_of_joining).on(:update) }
  it { should validate_presence_of(:personal_email).on(:update) }
=end
end
  
