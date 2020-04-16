class HolidayList
  include Mongoid::Document
  field :holiday_date, type: Date
  field :reason, type: String
  field :holiday_type, type: String
  field :country, type: String

  MANDATORY = 'MANDATORY'
  OPTIONAL = 'OPTIONAL'
  HOLIDAY_TYPES = [MANDATORY, OPTIONAL]

  validates :holiday_date, :reason, :country, :holiday_type, presence: true
  validates :holiday_type, inclusion: { in: HOLIDAY_TYPES }
  validate :check_weekend?
  validate :check_duplicate?

  scope :list, -> (country) { where(country: country)}

  def self.is_holiday?(date, country)
    is_weekend?(date) ||
    HolidayList.list(country).pluck(:holiday_date).include?(date)
  end

  def self.is_optional_holiday?(date)
    HolidayList.where(
      holiday_date: date,
      holiday_type: OPTIONAL
    ).exists?
  end

  def self.is_weekend?(date)
    date.strftime('%A').eql?('Saturday') ||
    date.strftime('%A').eql?('Sunday')
  end

  def self.next_working_day(date, country_name)
    date = date + 1
    while HolidayList.is_holiday?(date, country_name)
      date = date.next
    end
    date
  end

  def check_weekend?
    if holiday_date.present? && HolidayList.is_weekend?(holiday_date)
      errors.add(:holiday_date, 'Cannot create holiday on Saturday or Sunday')
    end
  end

  def check_duplicate?
    if holiday_date_changed? || country_changed?
      if holiday_date.present? && HolidayList.is_holiday?(holiday_date, country)
        errors.add(:country, "Cannot create duplicate holiday for #{country}")
      end
    end
  end
end
