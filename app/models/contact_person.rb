class ContactPerson
  include Mongoid::Document
  field :relation
  field :role
  field :name
  field :phone_no
  field :email

  embedded_in :private_profile
  embedded_in :vender
  
  #validates :phone_no, length: { is: 10 }, numericality: { only_integer: true }, allow_blank: true
end
