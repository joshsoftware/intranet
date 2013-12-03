class PrivateProfile
  include Mongoid::Document
  
  field :pan_number
  field :personal_email
  field :passport_number
  field :qualification
  field :date_of_joining, :type => Date
  field :work_experience
  field :previous_company
  field :bonusly_auth_token

  embedded_in :user
  embeds_many :contact_persons
  has_many :addresses, autosave: true

  accepts_nested_attributes_for :addresses
  accepts_nested_attributes_for :contact_persons
  
  before_save do
    if self.date_of_joining_changed?
      user = self.user
      user.assign_leave
      user.set_details("doj", self.date_of_joining)
    end
  end
  
  #validates_presence_of :qualification, :date_of_joining, :personal_emailid, :on => :update
end
