require 'spec_helper'

describe HolidayList do
  it { should have_fields(:holiday_list, :reason) }
  it { should validate_presence_of(:holiday_date) }
  it { should validate_presence_of(:reason) }
  it { should validate_uniqueness_of(:holiday_date) }
end
