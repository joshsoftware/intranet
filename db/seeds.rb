# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#

admin = User.new(email: "Administrator@joshsoftware.com", password: "josh123", role: "Admin", status: "approved")
hr = User.new(email: "testhr@joshsoftware.com", password: "josh123", role: "HR", status: "approved")
employee = User.new(email: "testemployee@joshsoftware.com", password: "josh123", role: "HR", status: "approved")
admin.build_public_profile(first_name: "Josh", last_name: "Admin")
hr.build_public_profile(first_name: "Josh", last_name: "HR")
employee.build_public_profile(first_name: "Josh", last_name: "Emp")
hr.build_private_profile(date_of_joining: Date.parse('1-1-2015'))
employee.build_private_profile(date_of_joining: Date.parse('1-1-2015'))
admin.save
hr.save
employee.save
