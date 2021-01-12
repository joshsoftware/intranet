require 'spec_helper'

describe EmployeeDetail do

  it { should belong_to(:designation) }

  context 'validations' do
    it { should validate_presence_of(:location) }
    it { is_expected.to validate_inclusion_of(:division).to_allow(DIVISION_TYPES.values) }
  end
end
