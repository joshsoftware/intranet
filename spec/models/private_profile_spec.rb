require 'spec_helper'

describe PrivateProfile do
  
  it { should have_fields(
                          :pan_number,
                          :personal_email,
                          :passport_number,
                          :qualification,
                          :date_of_joining,
                          :end_of_probation,
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
      user.status = STATUS[:approved]
      private_profile = user.private_profile
      private_profile.date_of_joining = ''
    end

    after do
      expect(user.save).to eq(false)
      expect(user.generate_errors_message).to eq(
        "Date of joining can't be blank"
      )
    end

    it 'because joining date is not present, role is employee' do
      user.role = 'Employee'
    end

    it 'because joining date is not present, role is HR' do
      user.role = 'HR'
    end
  end

  context 'Validation of joining date' do
    let!(:user) { FactoryGirl.create(:user) }

    before do
      @private_profile = user.private_profile
    end

    it 'should fails because joining date is future date' do
      @private_profile.date_of_joining = Date.tomorrow
      expect(user.valid?).to be_falsy
      expect(@private_profile.errors.full_messages).to eq(
        ['Date of joining should not a date from future.']
      )
    end

    it 'should pass because joining date is current date or past date' do
      expect(user.valid?).to_not be_falsy 
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
      expect(user.generate_errors_message.blank?).to eq(true)
    end

    it 'because joining date is present, role is employee' do
      user.role = 'Employee'
    end

    it 'because joining date is present, role is HR' do
      user.role = 'HR'
    end
  end

  context 'probation period notification' do
    let!(:user) { FactoryGirl.create(:user, status: STATUS[:approved]) }
    let!(:hr_user) { FactoryGirl.create(:user, role: ROLE[:HR], status: STATUS[:approved])}
    before do
      ActionMailer::Base.deliveries = []
    end
    it 'send mail before 7 days when probation period ends' do
      private_profile = FactoryGirl.create(:private_profile, user: user,
        end_of_probation: Date.today + 7)
      PrivateProfile.notify_probation_end
      expect(ActionMailer::Base.deliveries[0].subject).to eq('Action Required: Probation period of employees ending soon')
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it 'dont send mail if no any user is having probation end date after 7 days' do
      PrivateProfile.notify_probation_end
      expect(ActionMailer::Base.deliveries.count).to eq(0)
    end
  end

end
