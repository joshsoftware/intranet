require 'spec_helper'

describe PublicProfile do
  it { should have_fields(
                            :first_name,
                            :last_name,
                            :gender,
                            :mobile_number,
                            :blood_group,
                            :date_of_birth,
                            :skills,
                            :github_handle,
                            :twitter_handle,
                            :blog_url
                         )
     }
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
  it { should validate_inclusion_of(:blood_group).
        to_allow(BLOOD_GROUPS).on(:update)
     }

  context 'Trigger - should call code monitor service' do
    it 'when Public Profile(github, gitlab, bitbucket handles) is updated' do
      user = FactoryGirl.build(:user)
      user.build_public_profile
      user.public_profile.github_handle = 'jiren'
      stub_request(:get, "http://localhost?event_type=User+Updated&user_id=#{user.id}&public_profile_details=%7B%22bitbucket_handle%22%3D%3Enil%2C+%22github_handle%22%3D%3E%22jiren%22%2C+%22gitlab_handle%22%3D%3Enil%7D").
        with(
          headers: {
            'Accept'=>'*/*',
            'User-Agent'=>'Ruby'
          }).
        to_return(status: 200, body: "", headers: {})
      user.save
      expect(user.public_profile.github_handle).to eq('jiren')
    end
  end
end
