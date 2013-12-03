require 'spec_helper'

describe LeaveApplication do
  it { should have_fields(:start_at, :end_at, :reason, :contact_number, :reject_reason, :leave_status) }
  it { should belong_to(:user) }
  it { should belong_to(:leave_type) }
  it { should validate_presence_of(:start_at) }
  it { should validate_presence_of(:end_at) }
  it { should validate_presence_of(:reason) }
  it { should validate_presence_of(:contact_number) }
  it { should validate_numericality_of(:contact_number) }
end
