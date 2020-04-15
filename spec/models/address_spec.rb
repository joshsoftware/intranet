require 'spec_helper'

describe Address do

  it { should have_fields(:type_of_address,
                          :address,
                          :city,
                          :state,
                          :landline_no,
                          :same_as_permanent_address,
                          :pin_code
                         )
     }
  it { should have_field(:same_as_permanent_address).
    of_type(Mongoid::Boolean).with_default_value_of(false) }
  it { should belong_to :private_profile }
  it { should belong_to :company }

  it '#to_line' do
    address = FactoryGirl.create(:address,
                                  type_of_address: 'Temporary',
                                  address: 'Josh Software, iSpace Complex, Bavdhan',
                                  city: 'Pune', state: 'Maharashtra',
                                  landline_no: '1-736-084-7447',
                                  pin_code: '18557-2607')
    expected_address = " Temporary , Josh Software, iSpace Complex, Bavdhan , Pune , Maharashtra , 1-736-084-7447 , 18557-2607 "
    expect(address.to_line).to eq(expected_address)
  end
end
