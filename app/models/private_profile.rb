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
  field :tshirt_size
  field :previous_work_experience, :type => Integer #in months

  embedded_in :user
  embeds_many :contact_persons
  has_many :addresses, autosave: true

  validates :date_of_joining, presence: true, if: :check_status_and_role?, on: :update
  validates :previous_work_experience,:allow_blank => true, numericality: { only_integer: true }

  accepts_nested_attributes_for :addresses
  accepts_nested_attributes_for :contact_persons

  before_save do
    if self.date_of_joining_changed?
      user = self.user
      if date_of_joining_changed?
        user.assign_leave if user.eligible_for_leave?
        user.set_details("doj", self.date_of_joining)
      end
    end
  end

  def check_status_and_role?
    return true if date_of_joining.blank? &&
                   (user.role == ROLE[:employee] ||
                   user.role == ROLE[:HR]) &&
                   user.status == STATUS[STATUS.find_index('approved')]

    return false
  end
  
  #validates_presence_of :qualification, :date_of_joining, :personal_emailid, :on => :update
end
