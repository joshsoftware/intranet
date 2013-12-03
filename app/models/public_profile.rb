class PublicProfile
  include Mongoid::Document
  include Mongoid::Slug

  mount_uploader :image, FileUploader 

  field :first_name, default: ''
  field :last_name, default: ''
  field :gender
  field :mobile_number
  field :blood_group
  field :date_of_birth, :type => Date
  field :skills
  field :skype_id
  field :pivotal_tracker_id
  field :github_handle
  field :twitter_handle
  field :blog_url
  field :image

  #validates_attachment :photo, :content_type => { :content_type => "image/jpg" }

  embedded_in :user
  
  #validates_presence_of :first_name, :last_name, :gender, :mobile_number, :date_of_birth, :blood_group, :on => :update
  validates :gender, inclusion: { in: GENDER }, allow_blank: true, :on => :update
  validates :blood_group, inclusion: { in: BLOOD_GROUPS }, allow_blank: true, :on => :update
    
  before_save do
    #We need to manually set the slug because user does not have field 'name' in its model and delegated to public_profile
    user.set_slug
    self.user.set_details("dob", self.date_of_birth) if self.date_of_birth_changed? #set the dob_day and dob_month
  end
  
  def name
    "#{first_name} #{last_name}"  
  end

end
