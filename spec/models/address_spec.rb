require 'spec_helper'

describe Address do
  
  it { should have_fields(:type_of_address, :address, :city, :state, :landline_no, :same_as_permanent_address, :pin_code) }
  it { should have_field(:same_as_permanent_address).of_type(Boolean).with_default_value_of(false) }
  it { should belong_to :private_profile }

end
