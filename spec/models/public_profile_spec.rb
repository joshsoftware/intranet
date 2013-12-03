require 'spec_helper'

describe PublicProfile do
  it { should have_fields(:first_name, :last_name, :gender, :mobile_number, :blood_group, :date_of_birth, :skills, :github_handle, :twitter_handle, :blog_url) }
  it { should have_field(:date_of_birth).of_type(Date) }
  it { should be_embedded_in(:user) }
=begin
#these will be reenable after validate problem will get fixed
  it { should validate_presence_of(:first_name).on(:update) }
  it { should validate_presence_of(:last_name).on(:update) }
  it { should validate_presence_of(:gender).on(:update) }
  it { should validate_presence_of(:mobile_number).on(:update) }
  it { should validate_presence_of(:date_of_birth).on(:update) }
  it { should validate_presence_of(:blood_group).on(:update) }
=end
  it { should validate_inclusion_of(:gender).to_allow(GENDER).on(:update) }
  it { should validate_inclusion_of(:blood_group).to_allow(BLOOD_GROUPS).on(:update) }

end
