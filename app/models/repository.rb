class Repository
  include Mongoid::Document
  include Mongoid::Timestamps
  HOSTS = ['GitHub', 'BitBucket', 'GitLab', 'SourceForge', 'Launchpad', 'Google Cloud', 'AWS CodeCommit'].freeze
  belongs_to :project
  field :name, type: String, default: ''
  field :host, type: String
  field :url, type: String
  field :code_climate_id
  field :maintainability_badge
  field :test_coverage_badge
  field :visibility
  validates_presence_of :project
  validates_presence_of :name, :url, :host
  validates :host, inclusion: { in: HOSTS, allow_nil: false }
  validates_uniqueness_of :url
  has_many :code_climate_statistics, dependent: :destroy
  field :rollbar_access_token
  has_many :rollbar_statistics, dependent: :destroy
  validates_uniqueness_of :code_climate_id, allow_blank: true, allow_nil: true
end
