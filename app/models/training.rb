class Training
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps

  TYPES = ['Hackathon', 'Community']

  field :subject,             type: String
  field :objectives,          type: String
  field :date,                type: Date
  field :venue,               type: String
  field :showcase_on_website, type: Boolean, default: false
  field :chapter_number,      type: Integer
  # duration in days
  field :duration,            type: Integer
  field :video
  field :blog_link

  slug :subject

  has_many :file_attachments, dependent: :destroy
  accepts_nested_attributes_for :file_attachments

  has_many :chapters, class_name: 'Training', dependent: :destroy, order: "chapter_number ASC"
  belongs_to :training
  accepts_nested_attributes_for :chapters, allow_destroy: true, reject_if: :chapter_record_is_blank?

  has_and_belongs_to_many :trainers, class_name: 'User'
  belongs_to :training

  validates_presence_of :subject, :objectives, :duration
  validates_presence_of :chapter_number, unless: 'training_id.nil?'
  validates :chapter_number, uniqueness: { scope: :training, message: "already present" }, unless: 'training_id.nil?'
  scope :showcase_on_website, -> {training_only.where(showcase_on_website: true)}
  # training_only is for those records who are not chapters as the training has a self association
  scope :training_only, -> {where(training_id: nil)}

  def chapter_record_is_blank?(attributes)
    attributes[:subject].blank?  and attributes[:objective].blank? and attributes[:duration].blank? and attributes[:chapter_number].blank?
  end

  def duration_to_display
    "#{duration} #{'day'.pluralize(duration)}"
  end

  def photos
    file_attachments.where(type: 'photo').map {|photo| photo.doc.as_json[:doc]}
  end

  def ppts
    file_attachments.where(type: 'ppt').map {|ppt| {url: ppt.doc.url}}
  end
end
