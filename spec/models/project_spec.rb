require 'spec_helper'

describe Project do
  it {should validate_presence_of(:name)}
  # it {should accept_nested_attributes_for(:users)}

  it 'must return all the tags' do
    project = FactoryGirl.create(:project, rails_version: "4.2.1", ruby_version: '2.2.3',
                                   database: "Mongodb", other_details: "Retrofit,GCM")
    expect(project.tags).to eq(["Ruby 2.2.3", "Rails 4.2.1", "Mongodb ", "Retrofit", "GCM"])
  end


  it "should use existing product code of company" do
    company = FactoryGirl.create(:company)
    project = FactoryGirl.create(:project)
    new_project = FactoryGirl.build(:project, name: "test", code: project.code)
    expect(new_project).to be_valid
  end

  it "should not use existing product code of other company" do
    company = FactoryGirl.create(:company)
    project = FactoryGirl.create(:project, company: company)
    new_project = FactoryGirl.build(:project, code: project.code)
    expect(new_project).to be_invalid
  end

  context 'validation - display name' do
    let!(:project) { FactoryGirl.create(:project) }

    it 'Should success' do
      expect(project.display_name).to eq('The_pediatric_network')
      expect(project.errors.count).to eq(0)
    end

    it 'should fail beacause display name contain white space' do
      project.display_name = 'The pediatric network'
      project.save

      expect(project.errors.full_messages).to eq(["Display name Name should not contain white space"])
      expect(project.errors.count).to eq(1)
    end

    it 'should update display name when project name is change' do
      project.name = 'Deal signal'
      project.display_name = ''
      project.save

      expect(project.display_name).to eq("Deal_signal")
      expect(project.errors.count).to eq(0)
    end

    it 'Should not trigger validation because display name is correct' do
      project.display_name = 'tpn'

      expect(project.errors.count).to eq(0)
    end
  end

  context 'manager name and employee name' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.create(:project) }

    it 'Should match manager name' do
      manager = FactoryGirl.create(:user)
      project = FactoryGirl.create(:project)
      project.managers << user
      project.managers << manager
      manager_names = Project.manager_names(project)
      expect(manager_names).to eq("fname lname | fname lname")
    end

    it 'Should match employee name' do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: DateTime.now)
      employee_names = Project.employee_names(project)
      expect(employee_names).to eq("fname lname")
    end
  end

  context 'add or remove team member' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.build(:project) }

    it 'Should add team member' do
      user_ids = []
      user_ids << user.id
      project.save
      params = { "project" => { "user_ids" => user_ids } }
      project.add_or_remove_team_member(params)
      user_project = UserProject.find_by(user_id: user.id, project_id: project.id)
      expect(user_project.start_date).to eq(Date.today)
    end

    describe 'Should remove team member' do
      it 'member count greater than two' do
        user_ids = []
        first_team_member = FactoryGirl.create(:user)
        second_team_member = FactoryGirl.create(:user)
        UserProject.create(user_id: first_team_member.id, project_id: project.id, start_date: DateTime.now - 1, end_date: nil)
        UserProject.create(user_id: second_team_member.id, project_id: project.id, start_date: DateTime.now - 1, end_date: nil)
        user_project = UserProject.create(user_id: user.id, project_id: project.id, start_date: DateTime.now - 1, end_date: nil)
        user_ids << first_team_member.id
        user_ids << second_team_member.id

        params = { "project" => { "user_ids" => user_ids } }
        project.add_or_remove_team_member(params)
        expect(user_project.reload.end_date).to eq(Date.today)
      end

      it 'Member count is one' do
        user_project = UserProject.create(user_id: user.id, project_id: project.id, start_date: DateTime.now - 1, end_date: nil)
        params = { "project" => { "user_ids" => [] } }
        project.add_or_remove_team_member(params)
        expect(user_project.reload.end_date).to eq(Date.today)
      end
    end

    it 'Add team member : should return false because user id nil' do
      user_ids = []
      user_ids << nil
      return_value = project.add_team_member(user_ids)
      expect(return_value).to eq(false)
    end

    it 'Remove team member : should return false because user id nil' do
      user_ids = []
      user_ids << nil
      return_value = project.remove_team_member(user_ids)
      expect(return_value).to eq(false)
    end
  end

  context 'Users' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.create(:project) }
    it 'Should give users report' do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: Date.today - 2)
      users = project.users
      expect(users.present?).to eq(true)
    end
  end
  
  context 'Get user project from project' do
    let!(:user_one) { FactoryGirl.create(:user, email: 'user1@joshsoftware.com') }
    let!(:user_two) { FactoryGirl.create(:user, email: 'user2@joshsoftware.com') }
    let!(:user_three) { FactoryGirl.create(:user, email: 'user3@joshsoftware.com') }
    let!(:user_four) { FactoryGirl.create(:user, email: 'user4@joshsoftware.com') }
    let!(:user_five) { FactoryGirl.create(:user, email: 'user5@joshsoftware.com') }
    let!(:user_six) { FactoryGirl.create(:user, email: 'user6@joshsoftware.com') }
    let!(:user_seven) { FactoryGirl.create(:user, email: 'user7@joshsoftware.com') }
    let!(:user_eight) { FactoryGirl.create(:user, email: 'user8@joshsoftware.com') }
    let!(:project) { FactoryGirl.create(:project) }

    it 'Should give users record between from date and to date' do
      UserProject.create(user_id: user_one.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: nil)
      UserProject.create(user_id: user_two.id, project_id: project.id, start_date: '06/09/2018'.to_date, end_date: nil)
      UserProject.create(user_id: user_three.id, project_id: project.id, start_date: '05/09/2018'.to_date, end_date: '15/09/2018'.to_date)
      UserProject.create(user_id: user_four.id, project_id: project.id, start_date: '08/09/2018'.to_date, end_date: '23/09/2018'.to_date)
      UserProject.create(user_id: user_five.id, project_id: project.id, start_date: '05/08/2018'.to_date, end_date: '10/09/2018'.to_date)
      UserProject.create(user_id: user_six.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: '25/08/2018'.to_date)
      UserProject.create(user_id: user_seven.id, project_id: project.id, start_date: '25/09/2018'.to_date, end_date: '30/09/2018')
      UserProject.create(user_id: user_eight.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: '10/10/2018'.to_date)

      from_date = '01/09/2018'.to_date
      to_date = '20/09/2018'.to_date
      user_projects = project.get_user_projects_from_project(from_date, to_date)
      expect(user_projects.count).to eq(6)
      expect(user_projects[0].email).to eq('user1@joshsoftware.com')
      expect(user_projects[1].email).to eq('user2@joshsoftware.com')
      expect(user_projects[2].email).to eq('user3@joshsoftware.com')
      expect(user_projects[3].email).to eq('user4@joshsoftware.com')
      expect(user_projects[4].email).to eq('user5@joshsoftware.com')
      expect(user_projects[5].email).to eq('user8@joshsoftware.com')
    end

    it 'Should not give the user record, Its less than from date and to date' do
      UserProject.create(user_id: user_six.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: '25/08/2018'.to_date)
      from_date = '01/09/2018'.to_date
      to_date = '20/09/2018'.to_date
      user_projects = project.get_user_projects_from_project(from_date, to_date)
      expect(user_projects.count).to eq(0)
    end

    it 'Should not give user record, Its greater than from date and to date' do
      UserProject.create(user_id: user_seven.id, project_id: project.id, start_date: '25/09/2018'.to_date, end_date: '30/09/2018')
      from_date = '01/09/2018'.to_date
      to_date = '20/09/2018'.to_date
      user_projects = project.get_user_projects_from_project(from_date, to_date)
      expect(user_projects.count).to eq(0)
    end

    it "Should give the record if user's project start date is less than from date and end date is nil" do
      UserProject.create(user_id: user_one.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: nil)
      from_date = '01/09/2018'.to_date
      to_date = '20/09/2018'.to_date
      user_projects = project.get_user_projects_from_project(from_date, to_date)
      expect(user_projects.count).to eq(1)
      expect(user_projects[0].email).to eq('user1@joshsoftware.com')
    end

    it "Should give the record if user's project start date is greater than from date and end date is nil" do
      UserProject.create(user_id: user_two.id, project_id: project.id, start_date: '06/09/2018'.to_date, end_date: nil)
      from_date = '01/09/2018'.to_date
      to_date = '20/09/2018'.to_date
      user_projects = project.get_user_projects_from_project(from_date, to_date)
      expect(user_projects.count).to eq(1)
      expect(user_projects[0].email).to eq('user2@joshsoftware.com')
    end

    it "Should give the record if user's project start date is greater than from date and end date is less than to date" do
      UserProject.create(user_id: user_three.id, project_id: project.id, start_date: '05/09/2018'.to_date, end_date: '15/09/2018'.to_date)
      from_date = '01/09/2018'.to_date
      to_date = '20/09/2018'.to_date
      user_projects = project.get_user_projects_from_project(from_date, to_date)
      expect(user_projects.count).to eq(1)
      expect(user_projects[0].email).to eq('user3@joshsoftware.com')
    end

    it "Should give the record if user's project start date is greater than from date and end date is greater than to date " do
      UserProject.create(user_id: user_four.id, project_id: project.id, start_date: '08/09/2018'.to_date, end_date: '23/09/2018'.to_date)
      from_date = '01/09/2018'.to_date
      to_date = '20/09/2018'.to_date
      user_projects = project.get_user_projects_from_project(from_date, to_date)
      expect(user_projects.count).to eq(1)
      expect(user_projects[0].email).to eq('user4@joshsoftware.com')
    end

    it "Should give the record if user's project start date less than from date and end date less than to date" do
      UserProject.create(user_id: user_five.id, project_id: project.id, start_date: '05/08/2018'.to_date, end_date: '10/09/2018'.to_date)
      from_date = '01/09/2018'.to_date
      to_date = '20/09/2018'.to_date
      user_projects = project.get_user_projects_from_project(from_date, to_date)
      expect(user_projects.count).to eq(1)
      expect(user_projects[0].email).to eq('user5@joshsoftware.com')
    end

    it "Should give the record if user's project start date is less than from date and end date is greater than to date" do
      UserProject.create(user_id: user_eight.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: '10/10/2018'.to_date)
      from_date = '01/09/2018'.to_date
      to_date = '20/09/2018'.to_date
      user_projects = project.get_user_projects_from_project(from_date, to_date)
      expect(user_projects.count).to eq(1)
      expect(user_projects[0].email).to eq('user8@joshsoftware.com')
    end

    it "Should not give the record because user's project start date and end date is not between from date and to date" do
      UserProject.create(user_id: user_six.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: '25/08/2018'.to_date)
      from_date = '01/09/2018'.to_date
      to_date = '20/09/2018'.to_date
      user_projects = project.get_user_projects_from_project(from_date, to_date)
      expect(user_projects.count).to eq(0)
      expect(user_projects.present?).to eq(false)
    end

    it "Should not give the record because user's project start date and end date is not between from date and to date" do
      UserProject.create(user_id: user_seven.id, project_id: project.id, start_date: '25/09/2018'.to_date, end_date: '30/09/2018')
      from_date = '01/09/2018'.to_date
      to_date = '20/09/2018'.to_date
      user_projects = project.get_user_projects_from_project(from_date, to_date)
      expect(user_projects.count).to eq(0)
      expect(user_projects.present?).to eq(false)
    end
  end
end
