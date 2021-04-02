require 'spec_helper'

describe EmployeeDetail do

  it { should belong_to(:designation) }

  context 'validations' do
    let!(:user) { FactoryGirl.create(:user) }
    it { should validate_presence_of(:location) }
    it { is_expected.to validate_inclusion_of(:division).to_allow(DIVISION_TYPES.values) }

    before do
      @private_profile = user.private_profile
      @employee_detail = user.employee_detail
    end

    it 'sholud be greter than date of joining' do
      @private_profile.date_of_joining = Date.tomorrow
      @employee_detail.date_of_relieving = Date.today
      expect(user.valid?).to be_falsy
      expect(@employee_detail.errors.full_messages).to eq(
        ['Date of relieving should be greater than date of joining.']
      )
    end

    it 'should pass because date of relieving is past date' do
      @private_profile.date_of_joining = Date.today
      @employee_detail.date_of_relieving = Date.tomorrow
      expect(user.valid?).to_not be_falsy
    end

    it 'sholud be greter than Internship Start Date' do
      user.role = 'Intern'
      @private_profile.internship_start_date = Date.tomorrow
      @private_profile.internship_end_date = Date.tomorrow + 1
      @employee_detail.date_of_relieving = Date.today
      expect(user.valid?).to be_falsy
      expect(@employee_detail.errors.full_messages).to eq(
        ['Date of relieving should be greater than Internship Start Date.']
      )
    end

    it 'should pass because internship end date is past date' do
      user.role = 'Intern'
      @private_profile.date_of_joining = Date.today
      @employee_detail.date_of_relieving = Date.tomorrow
      @private_profile.internship_end_date = Date.tomorrow + 2
      expect(user.valid?).to_not be_falsy
    end
  end
end
