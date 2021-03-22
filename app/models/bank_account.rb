class BankAccount
  include Mongoid::Document

  embedded_in :private_profile

  field :bank_name, type: String
  field :name_on_passbook, type: String
  field :account_number, type: String
  field :ifsc_code, type: String

  validates :bank_name, :name_on_passbook, :account_number, :ifsc_code, presence: true, if: :any_field_present?

  def any_field_present?
    bank_name.present? ||
    name_on_passbook.present? ||
    account_number.present? ||
    ifsc_code.present?
  end
end
