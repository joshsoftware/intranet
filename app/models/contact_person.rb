class ContactPerson
  include Mongoid::Document
  field :relation
  field :role
  field :name
  field :phone_no
  field :email

  embedded_in :private_profile
  embedded_in :vendor
  embedded_in :company
end
