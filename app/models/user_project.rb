class UserProject
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :start_date, type: Date
  field :end_date, type: Date, default: nil
  field :time_sheet, type: Boolean, default: false
  field :active, type:Boolean, default: true
  field :allocation, type: Integer, default: 100
  
  belongs_to :user
  belongs_to :project
  
  validates :start_date, presence: {message: "Team member start date cannot be blank"}
  validates :end_date, presence: {unless: "active", message: "End date is mandatory to mark inactive"} 
  validates :user_id, :project_id, presence: true
end
