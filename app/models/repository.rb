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

  after_create do
    call_monitor_service('created')
  end

  before_destroy do
    call_monitor_service('destroyed')
  end

  # before_save do
  #   # for change in url, name, host
  #   if persisted? and (changes.keys & ['url', 'name', 'host']).length > 0
  #     call_monitor_service('updated')
  #   end
  # end

  private

  def call_monitor_service(event)
    CodeMonitoringWorker.perform_async(monitor_service_params(event))
  end

  def monitor_service_params(event)
    data = {
      event_type:         '',
      repository_id:      id.to_s,
      repository_url:     url,
      project_id:         project_id.to_s,
      repository_details: self.as_json(repository_fields)
    }
    case event
    when 'created'
      data[:event_type] = 'Repository Added'
    when 'destroyed'
      data[:event_type] = 'Repository Removed'
      data[:project_id] = project_id_was.to_s
      data.delete(:repository_details)
    # when 'updated'
    #   data[:event_type] = 'Repository Update'
    end
    data
  end

  def repository_fields
    {
      only: [
        :name, :host, :code_climate_id, :maintainability_badge,
        :test_coverage_badge, :visibility, :rollbar_access_token
      ]
    }
  end
end
