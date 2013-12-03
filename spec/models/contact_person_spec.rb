require 'spec_helper'

describe ContactPerson do
  
  it { should have_fields(:relation, :name, :phone_no) }
  it { should be_embedded_in :private_profile }
  
end
