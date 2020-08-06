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
  
  validate :document_size

  def document_size
    if document.present? && document.content_type.present?
      if document.content_type.include?('image') && document.size > 3.megabytes
        errors[:image] << name + ' should be less than 3MB'
      elsif document.content_type == 'application/pdf' && document.size > 5.megabytes
        errors[:pdf] << name + ' should be less than 5MB'
      end
    else
      errors[:document] << 'should be present'
    end
  end
end
