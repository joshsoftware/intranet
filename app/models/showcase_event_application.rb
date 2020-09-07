class ShowcaseEventApplication
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps

  field :name,          type: String
  field :description,   type: String
  field :domain

  belongs_to :showcase_event
  has_many :showcase_event_teams, dependent: :destroy

  validates_presence_of :name, :description, :domain
  validates :name, uniqueness: {scope: :showcase_event_id, message: "already present for Event"}
end
