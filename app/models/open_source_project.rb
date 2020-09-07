class OpenSourceProject
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps

  mount_uploader :image, FileUploader
  mount_uploader :case_study, FileUploader

  field :name,                type: String
  field :image
  field :description,         type: String
  field :showcase_on_website, type: Boolean, default: false
  field :case_study
  field :url
  slug :name

  has_many :technology_details
  accepts_nested_attributes_for :technology_details, allow_destroy: true, reject_if: :technology_details_record_is_blank?

  has_and_belongs_to_many :users

  validates_presence_of :name, :description, :url
  validates_uniqueness_of :url, :name

  scope :showcase_on_website, ->{where(showcase_on_website: true).asc(:name)}

  def self.get_all_sorted_by_name
    OpenSourceProject.all.asc(:name)
  end

  def tags
    tags = []
    technology_details.each do |technology_detail|
      tags << "#{technology_detail.name} #{technology_detail.version}"
    end
    tags.compact.flatten.sort
  end

  private

  def technology_details_record_is_blank?(attributes)
    attributes[:name].blank?  and attributes[:version].blank?
  end
end
