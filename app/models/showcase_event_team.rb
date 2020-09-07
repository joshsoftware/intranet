class ShowcaseEventTeam
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps

  field :name,                type: String
  field :proposed_solution,   type: String
  field :repository_link
  field :demo_link

  has_and_belongs_to_many :members, class_name: 'User', foreign_key: 'member_ids'
  belongs_to :showcase_event
  belongs_to :showcase_event_application
  has_many :technology_details
  accepts_nested_attributes_for :technology_details, allow_destroy: true, reject_if: :technology_details_record_is_blank?

  validates_presence_of :name, :proposed_solution, :repository_link, :demo_link
  validates :name, uniqueness: {scope: :showcase_event_id, message: "already present for Event"}

  private

  def technology_details_record_is_blank?(attributes)
    attributes[:name].blank?  and attributes[:version].blank?
  end
end
