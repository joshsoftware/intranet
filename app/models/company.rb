class Company
  include Mongoid::Document
  include Mongoid::Slug

  mount_uploader :logo, FileUploader

  field :name, type: String
  field :gstno, type: String
  field :invoice_code, type: String
  field :logo, type: String
  field :website, type: String
  field :active, type: Boolean, default: true
  field :billing_location, type: String, default: COUNTRIES_ABBREVIATIONS[0]

  has_many :projects, dependent: :destroy
  embeds_many :contact_persons
  has_many :addresses, dependent: :destroy

  accepts_nested_attributes_for :addresses, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :contact_persons, allow_destroy: true, reject_if: :all_blank

  slug :name

  validates :name, uniqueness: true, presence: true
  validates :billing_location, inclusion: { in: COUNTRIES_ABBREVIATIONS }
  validates :invoice_code, uniqueness: true, length: {maximum: 3}, allow_blank: true
  validate :website_url

  after_save do
    update_projects_end_date unless active
  end

  def website_url
    return true if website.nil? || website.empty?
    url = URI.parse(website) rescue false
    is_valid = url.kind_of?(URI::HTTP) || url.kind_of?(URI::HTTPS)
    errors.add(:website, "Invalid Website URL") unless is_valid
  end

  def project_codes
    projects.as_json(only: [:name,:code])
  end

  def self.to_csv
    attributes = %w{Name GST_No Website ContactPerson ContactEmail Projects}
    CSV.generate(headers: true) do |csv|
      csv << attributes
      all.each do |company|
        project = company.projects.map(&:name).join(" \n")
        contact_name = company.contact_persons.map(&:name).join(" \n")
        contact_email = company.contact_persons.map(&:email).join(" \n")
        csv << [company.name, company.try(:gstno), company.try(:website), contact_name, contact_email, project]
      end
    end
  end

  def update_projects_end_date
    projects.where(is_active: true).each do |project|
      project.update_attributes(end_date: Date.today, is_active: false)
    end
  end
end
