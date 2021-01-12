require 'spec_helper'

RSpec.describe Company, type: :model do
  it { should have_fields(:name, :gstno, :logo, :website, :active) }
  it { should embed_many :contact_persons }
  it { should have_many :addresses }
  it { should accept_nested_attributes_for :contact_persons }
  it { should accept_nested_attributes_for :addresses }
  it { should have_many(:projects) }
  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name) }
  it { should validate_uniqueness_of(:invoice_code) }
  it { is_expected.to validate_inclusion_of(:billing_location).to_allow(COUNTRIES_ABBREVIATIONS) }
  

  it 'Should fail as invoice code length is more than 3' do
    company = FactoryGirl.build(:company, invoice_code: 'a234')
    expect(company.valid?).to be_falsy
  end

  it 'Should pass as invoice code length is maximum 3' do
    company = FactoryGirl.build(:company, invoice_code: 'a23')
    expect(company.valid?).to_not be_falsy
  end

  it "Should validate website URL" do
    company = FactoryGirl.build(:company)
    company.website = "invalid.website"
    expect(company.valid?).to be_falsy
  end

  it "should create contact_persons" do
    company = FactoryGirl.create(:company_with_contact_person)
    expect(company.contact_persons.count).to eq(1)
  end

  it "should create addresses" do
    company = FactoryGirl.create(:company)
    FactoryGirl.create(:address, company: company)
    expect(company.addresses.count).to eq(1)
  end

  it 'should return project codes in json' do
    company = FactoryGirl.create(:company)
    project1 = FactoryGirl.create(:project, company: company)
    project2 = FactoryGirl.create(:project, company: company)
    expected_json = [ project1.as_json(only: [:name,:code]),
                      project2.as_json(only: [:name,:code])]
    expect(company.project_codes).to eq(expected_json)
  end

  it 'should update projects and user_projects end date if company is inactivated' do
    company = FactoryGirl.create(:company)
    project = FactoryGirl.create(:project, company: company)
    user_project = FactoryGirl.create(:user_project, project_id: project.id)
    company.update_attributes(active: false)
    expect(company.reload.active).to eq(false)
    expect(project.reload.is_active).to eq(false)
    expect(project.end_date).to eq(Date.today)
    expect(user_project.reload.active).to eq(false)
    expect(user_project.end_date).to eq(Date.today)
  end
end
