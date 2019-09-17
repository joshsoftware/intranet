require 'spec_helper'

describe PrivateProfile do
  
  it { should have_fields(
                          :pan_number,
                          :personal_email,
                          :passport_number,
                          :qualification,
                          :date_of_joining,
                          :previous_work_experience,
                          :previous_company
                         )
     }
  it { should have_field(:date_of_joining).of_type(Date) }
  it { should have_many :addresses }
  it { should embed_many :contact_persons }
  it { should be_embedded_in(:user) }
  it { should accept_nested_attributes_for(:addresses) }
  it { should accept_nested_attributes_for(:contact_persons) }
  it { should validate_numericality_of(:previous_work_experience) }
  it { should validate_presence_of(:date_of_joining).on(:update) }

  context 'While updating user, should not update user' do
    let!(:user) { FactoryGirl.create(:user) }

    before do
      user.status = 'approved'
      private_profile = user.private_profile
      private_profile.date_of_joining = ''
    end

    after do
      expect(user.save).to eq(false)
      expect(user.generate_errors_message).to eq(
        "Private profile is invalid  Date of joining can't be blank"
      )
    end

    it 'because joining date is not present, role is employee' do
      user.role = 'Employee'
    end

    it 'because joining date is not present, role is HR' do
      user.role = 'HR'
    end
  end

  context 'validation should not trigger' do
    let!(:user){ FactoryGirl.create(:user) }

    before do
      user.role = 'Intern'
      user.private_profile.date_of_joining = ''
    end

    after do
      expect(user.save).to eq(true)
      expect(user.valid?).to eq(true)
    end

    it 'is not employee' do
      expect(user.role).to_not be('Employee')
    end

    it 'is not HR' do
      expect(user.role).to_not be('HR')
    end
  end

  it 'Validation should not trigger on create' do
    user = FactoryGirl.create(:user)

    expect(user.valid?).to eq(true)
  end

  context 'While updating user, should update user' do
    let!(:user){ FactoryGirl.create(:user) }

    after do
      expect(user.save).to eq(true)
      expect(user.generate_errors_message).to eq('  ')
    end

    it 'because joining date is present, role is employee' do
      user.role = 'Employee'
    end

    it 'because joining date is present, role is HR' do
      user.role = 'HR'
    end
  end

end
