class FileAttachment
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps

  mount_uploader :doc, FileUploader

  field :doc
  field :type, default: 'photo'

  belongs_to :showcase_event
  belongs_to :training
end
