require 'spec_helper'

describe Vendor do
  it { should have_fields(:company, :category) }
  it { should embed_many :contact_persons }
  it { should have_one :address }
  it { should accept_nested_attributes_for :contact_persons }
  it { should accept_nested_attributes_for :address }
  it { should validate_presence_of(:company) }
  it { should validate_presence_of(:category) }
end
