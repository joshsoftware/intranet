require 'spec_helper'

describe HolidayList do
  context '#validation' do
    it { should have_fields(:holiday_date, :reason, :holiday_type, :country) }
    it { should validate_presence_of(:holiday_date) }
    it { should validate_presence_of(:reason) }
    it { should validate_presence_of(:country) }
    it { should validate_presence_of(:holiday_type) }
    it { is_expected.to validate_inclusion_of(:holiday_type).to_allow(HolidayList::HOLIDAY_TYPES) }
  end

  context 'Weekends' do
    it 'Do not create on saturday' do
      holiday = FactoryGirl.build(:holiday,
        holiday_date: '07/09/2019',
        reason: 'Test')
      holiday.valid?
      expect(holiday.errors[:holiday_date]).to eq(['Cannot create holiday on Saturday or Sunday'])
    end

    it 'Do not create on sunday' do
      holiday = FactoryGirl.build(:holiday,
        holiday_date: '08/09/2019',
        reason: 'Test')
      holiday.valid?
      expect(holiday.errors[:holiday_date]).to eq(['Cannot create holiday on Saturday or Sunday'])
    end
  end

  it 'should return next working day' do
    date = '26/06/2020'.to_date
    next_date = HolidayList.next_working_day(date, COUNTRIES[0])
    expect(next_date).to eq('29/06/2020'.to_date)
  end
end
