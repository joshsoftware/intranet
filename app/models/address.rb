class Address
  include Mongoid::Document
  field :type_of_address
  field :flat_or_house_no
  field :building_or_society_name
  field :road
  field :locality
  field :city
  field :state
  field :phone_no

  embedded_in :private_profile
end