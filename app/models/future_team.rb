class FutureTeam
  include Mongoid::Document

  field :customer,                    type: String
  field :years_of_experience,         type: Float
  field :skills,                      type: Array
  field :number_of_open_positions,    type: Integer
  field :requirement_received_on,     type: Date
  field :required_by_date,            type: Date
  field :current_status,              type: String
  field :proposed_candidates,         type: Array, default: []

  STATUS = ["Open", "Proposed", "Closed"]
  TECHNICAL_SKILLS = ["Android", "Angular", "Delivery Management", "Design", "DevOps",
    "Go", "iOS", "Ionic", "NodeJs", "PHP", "Python", "QA-Automation", "QA-Manual", "ROR",
    "React", "UI", "UX"]

  validates :customer, :years_of_experience, :number_of_open_positions, :required_by_date,
            :requirement_received_on, :skills, :current_status, presence: true
  validates :years_of_experience, length: {in: 1..3}
  validates :number_of_open_positions, numericality: {only_integer: true}, length: {in: 1..2}
  validates :current_status, inclusion: {in: STATUS}

  validate :validate_required_by_date, on: [:create, :update]
  validate :validate_requirement_received_on, on: [:create, :update]
  validate :validate_skills, on: [:create, :update]

  scope :pending, ->{where(:current_status.ne => 'Closed')}
  scope :closed, ->{where(:current_status => 'Closed')}

  def self.to_csv()
    attributes = ["customer", "years_of_experience", "skills", "number_of_open_positions", "requirement_received_on", "required_by_date", "current_status", "proposed_candidates"]
    CSV.generate(headers: true) do |csv|
      csv << attributes.collect(&:titleize)

      all.each do |team|
        record = []

        attributes.each do |attr|
          if attr == 'skills'
            record.push(team.skills.join(' | '))
          elsif attr == 'proposed_candidates'
            record.push(team.get_proposed_candidates)
          else
            record.push(team.send(attr))
          end
        end

        csv << record
      end
    end
  end

  def get_proposed_candidates
    candidates = []
    if(self[:proposed_candidates])
      self[:proposed_candidates].each do |candidate|
        candidates.push(User.find(candidate).name)
      end
      candidates = candidates.join(' | ')
    else
      candidates = nil
    end
    candidates
  end

  # getting the record in readble format, which can be used for reporting and listing of requirements
  def get_readable_record
    {
      id: self.id,
      customer: self.customer,
      years_of_experience: self.years_of_experience,
      skills: self.skills.join(' | '),
      number_of_open_positions: self.number_of_open_positions,
      requirement_received_on: self.requirement_received_on,
      required_by_date: self.required_by_date,
      current_status: self.current_status,
      proposed_candidates: self.get_proposed_candidates
    }
  end

  private

  def validate_required_by_date
    if self.required_by_date_changed?
      errors.add(:base, "Select a valid requird by date") and return if self.required_by_date < Date.today
    end
  end

  def validate_requirement_received_on
    if self.requirement_received_on_changed?
      errors.add(:base, "Select a valid requirement received on date") and return if self.requirement_received_on > Date.today
    end
  end

  def validate_skills
    return if !self.skills
    self.skills.each do |skill|
      errors.add(:base, "Skills should be from the list") and return if !TECHNICAL_SKILLS.include?(skill)
    end
  end
end
