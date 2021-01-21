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

  it 'Should pass as invoice code is unique with scope billing location' do
    company1 = FactoryGirl.create(:company, invoice_code: 'abc', billing_location: COUNTRIES_ABBREVIATIONS[0])
    company2 = FactoryGirl.build(:company, invoice_code: 'abc', billing_location: COUNTRIES_ABBREVIATIONS[1])
    expect(company2.valid?).to_not be_falsy
  end

  it 'Should fail as invoice code is not unique with scope billing location' do
    company1 = FactoryGirl.create(:company, invoice_code: 'abc', billing_location: COUNTRIES_ABBREVIATIONS[0])
    company2 = FactoryGirl.build(:company, invoice_code: 'abc', billing_location: COUNTRIES_ABBREVIATIONS[0])
    expect(company2.valid?).to be_falsy
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

  context 'billing_location_report' do
    before do
      @company1 = FactoryGirl.create(:company)
      @company2 = FactoryGirl.create(:company, billing_location: COUNTRIES_ABBREVIATIONS[1])
      @project1 = FactoryGirl.create(:project, company: @company1)
      @project2 = FactoryGirl.create(:project, company: @company2)
      @user1 = FactoryGirl.create(:user)
      @user2 = FactoryGirl.create(:user)
      @user_project1 = FactoryGirl.create(:user_project, project_id: @project1.id, user_id: @user1.id)
      @user_project2 = FactoryGirl.create(:user_project, project_id: @project2.id, user_id: @user2.id)

      #should not consider inactive companies, projects and user_projects
      @company3 = FactoryGirl.create(:company, billing_location: COUNTRIES_ABBREVIATIONS[1])
      @project3 = FactoryGirl.create(:project, company: @company2, is_active: false, end_date: Date.today)
      @user_project3 = FactoryGirl.create(:user_project, project_id: @project3.id, user_id: @user2.id, active: false, end_date: Date.today)
    end

    it 'should list records where company billing location matches with the given argument' do
      csv = Company.billing_location_report(COUNTRIES_ABBREVIATIONS[0])

      expected_csv = "Company Name,Company Status,Project Name,Employee ID,Employee Name,Billable(Y/N),Allocation(hrs)\n"
      expected_csv << "#{@company1.name},#{@company1.active ? 'Active' : 'Inactive'},#{@project1.name},#{@user1.employee_detail.try(:employee_id).try(:rjust, 3, '0')},#{@user1.name},#{@user_project1.billable ? 'Yes' : 'No'},#{@user_project1.allocation}\n"
      expect(csv).to eq(expected_csv)
    end
  end

end
