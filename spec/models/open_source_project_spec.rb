require 'spec_helper'

describe OpenSourceProject do
  context 'Validations' do
    it 'should success' do
      open_source_project = FactoryGirl.create(:open_source_project)
      expect(open_source_project.valid?).to eq(true)
    end

    it 'should fail because Name is nil' do
      open_source_project = FactoryGirl.build(:open_source_project, name: nil)
      expect(open_source_project.valid?).to eq(false)
      expect(open_source_project.errors.full_messages).to eq(["Name can't be blank"])
    end

    it 'should fail because Url is nil' do
      open_source_project = FactoryGirl.build(:open_source_project, url: nil)
      expect(open_source_project.valid?).to eq(false)
      expect(open_source_project.errors.full_messages).to eq(["Url can't be blank"])
    end

    it 'should fail because Description is nil' do
      open_source_project = FactoryGirl.build(:open_source_project, description: nil)
      expect(open_source_project.valid?).to eq(false)
      expect(open_source_project.errors.full_messages).to eq(["Description can't be blank"])
    end

    it 'should fail because Name is duplicate' do
      open_source_project1 = FactoryGirl.create(:open_source_project, name: 'Shoptok')
      expect(open_source_project1.valid?).to eq(true)
      open_source_project2 = FactoryGirl.build(:open_source_project, name: 'Shoptok')
      expect(open_source_project2.valid?).to eq(false)
      expect(open_source_project2.errors.full_messages).to eq(["Name is already taken"])
    end

    it 'should fail because Url is duplicate' do
      open_source_project = FactoryGirl.create(:open_source_project, url: 'shoptok.com')
      expect(open_source_project.valid?).to eq(true)
      open_source_project2 = FactoryGirl.build(:open_source_project, url: 'shoptok.com')
      expect(open_source_project2.valid?).to eq(false)
      expect(open_source_project2.errors.full_messages).to eq(["Url is already taken"])
    end
  end

  it {should accept_nested_attributes_for(:technology_details)}

  it 'must return all the tags' do
    open_source_project = FactoryGirl.create(:open_source_project)
    FactoryGirl.create(:technology_detail, open_source_project: open_source_project)
    expect(open_source_project.tags.count).to eq(1)
  end

  it 'must return all records ordered by name' do
    project1 = FactoryGirl.create(:open_source_project, name: 'Beta')
    project2 = FactoryGirl.create(:open_source_project, name: 'Alpha')
    open_source_projects = OpenSourceProject.get_all_sorted_by_name
    expect(open_source_projects[0]).to eq(project2)
    expect(open_source_projects[1]).to eq(project1)
  end

  it "should return records to be displayed on website" do
    project1 = FactoryGirl.create(:open_source_project)
    project2 = FactoryGirl.create(:open_source_project, showcase_on_website: true)
    open_source_projects = OpenSourceProject.showcase_on_website
    expect(open_source_projects.count).to eq(1)
    expect(open_source_projects[0]).to eq(project2)
  end
end
