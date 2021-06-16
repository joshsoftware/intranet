class Asset
  include Mongoid::Document
  include Mongoid::Timestamps

  mount_uploader :after_image, FileUploader
  mount_uploader :before_image, FileUploader

  field :name, type: String, default: ''
  field :type, type: String, default: ASSET_TYPES.values.first
  field :model, type: String, default: ''
  field :serial_number, type: String, default: ''
  field :date_of_issue, type: Date, default: Date.today
  field :date_of_return, type: Date
  field :valid_till, type: Date
  field :recovered, type: Boolean, default: false

  field :before_image, type: String
  field :after_image, type: String

  belongs_to :user

  validates :type, :name, :date_of_issue, :recovered, presence: true
  validates :date_of_return, presence: true, if: 'recovered || after_image.present?'
  validates :type, inclusion: { in: ASSET_TYPES.values}
  validate :custom_validations

  def custom_validations
    field_validation
    image_validation
    if errors.blank?
      errors.add(
        :date_of_return,
        'should be greater or equal to date of issue'
      ) if date_of_return && date_of_issue > date_of_return
      errors.add(
        :valid_till,
        'should be greater or equal to date of issue'
      ) if valid_till && date_of_issue > valid_till
    end
  end

  def field_validation
    case type
    when ASSET_TYPES[:hardware]
      errors.add(:model, 'should be present') unless model.present?
      errors.add(:before_image, 'should be present') unless before_image.present?
      errors.add(
        :after_image,
        'should be present'
      ) if date_of_return.present? && !after_image.present?
    when ASSET_TYPES[:software]
      errors.add(:serial_number, 'should be present') unless serial_number.present?
    end
  end

  def image_validation
    [before_image, after_image].each do |image|
      errors.add(image, 'should be less than 3MB') if image.size > 3.megabytes
    end
  end
end
