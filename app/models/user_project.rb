class UserProject
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :user_id
  field :start_date, type: Date
  field :end_date, type: Date, default: nil
  field :time_sheet, type: Boolean
  field :active, type:Boolean, default: true
  field :allocation
  

  belongs_to :user
  belongs_to :project
  validates :start_date, :user_id, :project_id, presence: true
end
