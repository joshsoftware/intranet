class Attachment
  include Mongoid::Document
  include Mongoid::Slug

  mount_uploader :document, FileUploader 

  field :name, type: String
  field :document, type: String
  field :is_visible_to_all, type: Boolean, default: false
  field :document_type, type: String, default: "user"
  
  slug :name
  
  belongs_to :user

  scope :user_documents, ->{where(document_type: "user")}
  scope :company_documents, ->{where(document_type: "company").asc(:name)}
  
end
