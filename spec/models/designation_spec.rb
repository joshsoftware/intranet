require 'rails_helper'

RSpec.describe Designation do

  it { should be_mongoid_document }

  it { should have_field(:name) }

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name) }
end
