class EntryPass
  include Mongoid::Document
  include Mongoid::Paranoia

  field :date, type: Date
  field :details, type: String
  belongs_to :user

  validates :date, presence: true, uniqueness: {scope: :user_id, message: "already selected"}
  validate :validate_daily_limit
  validates :details, presence: true

  def self.to_csv(records)
    attributes = %w{Date Name EmployeeID Email}
    CSV.generate(headers: true) do |csv|
      csv << attributes
      records.each do |entry_pass|
        user = entry_pass.user
        csv << [entry_pass.date, user.try(:name), user.try(:employee_id), user.try(:email)]
      end
    end
  end

  def validate_daily_limit
    if EntryPass.where({date: self.date}).count >= DAILY_OFFICE_ENTRY_LIMIT
      errors.add(:date, "Maximum number of employees allowed to work from office is reached")
    end
  end
end

