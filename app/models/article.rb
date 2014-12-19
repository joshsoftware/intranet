class Article
  include Mongoid::Document
  field :title, type: String
  field :content, type: String
  field :is_published, type: Boolean

  validates :content, :title, presence: true
  validates :title, uniqueness: true

end
