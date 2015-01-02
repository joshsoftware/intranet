class Policy
  include Mongoid::Document
  include Mongoid::Slug

  field :title, type: String
  field :content, type: String
  field :is_published, type: Boolean

  validates :content, :title, presence: true
  validates :title, uniqueness: true

  slug :title

  before_save do
    UserMailer.delay.new_policy_notification(self.id) if is_published_changed? and is_published.eql?(true)
  end
end
