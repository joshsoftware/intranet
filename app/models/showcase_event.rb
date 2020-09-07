class ShowcaseEvent
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps


  TYPES = ['Hackathon', 'Community']

  field :name,                type: String
  field :type,                type: String
  field :description,         type: String
  field :date,                type: Date
  field :venue,               type: String
  field :showcase_on_website, type: Boolean
  # video links
  field :video
  slug :name

  has_many :file_attachments, dependent: :destroy

  has_many :showcase_event_applications, dependent: :destroy
  accepts_nested_attributes_for :showcase_event_applications, allow_destroy: true

  has_many :showcase_event_teams, dependent: :destroy
  accepts_nested_attributes_for :showcase_event_teams, allow_destroy: true

  validates_presence_of :name, :description, :date, :venue, :type
  validates_uniqueness_of :name
  validates :type, inclusion: { in: TYPES, allow_nil: false }

  scope :hackathons, ->{where(type: "Hackathon").asc(:date)}
  scope :community_events, ->{where(type: "Community").asc(:date)}
  scope :showcase_on_website, ->{where(showcase_on_website: true)}

  def self.get_all_sorted_by_date
    ShowcaseEvent.all.asc(:date)
  end

  def is_hackathon?
    type == "Hackathon"
  end

  def photos
    file_attachments.where(type: 'photo').map {|photo| photo.doc.as_json[:doc]}
  end
end
