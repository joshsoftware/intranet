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
  
  validates :user_id, :project_id, :start_date, :active, :allocation, presence: true
  validates :end_date, presence: {unless: "!!active || active.nil?", message: "is mandatory to mark inactive"}
end
