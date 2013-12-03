class Address
  include Mongoid::Document
  field :type_of_address
  field :address
  field :city
  field :state
  field :landline_no
  field :same_as_permanent_address, type: Boolean, default: false
  field :pin_code

  belongs_to :private_profile
  belongs_to :leave_application
  belongs_to :vendor
end
