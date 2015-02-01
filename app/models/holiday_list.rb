class HolidayList
  include Mongoid::Document
  field :holiday_date, type: Date
  field :reason, type: String

  validates :holiday_date, :reason, presence: true
end
