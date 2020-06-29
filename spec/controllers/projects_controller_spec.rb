require 'spec_helper'

describe ProjectsController do

  before(:each) do
   @admin = FactoryGirl.create(:admin)
   sign_in @admin
  end

  describe "GET index" do
    before :each do
      @active_project = create(:project)
      @inactive_project = create(:project, is_active: false, end_date: Time.zone.today)
    end

    it "should list all projects" do
      get :index
      should respond_with(:success)
      should render_template(:index)
    end

    it 'return all projects' do
      xhr :get, :index,  all: true
      expect(assigns(:projects).pluck(:id)).to match_array [@active_project.id, @inactive_project.id]
    end

    it 'return all active projects' do
      xhr :get, :index
      expect(assigns(:projects).pluck(:id)).to match_array [@active_project.id]
    end

    it 'should return project csv' do
      get :index, { format: :csv }
      expect(response).to have_http_status(200)
    end
  end

  describe "GET new" do
    it "should respond with success" do
      get :new
      should respond_with(:success)
      should render_template(:new)
    end

    it "should create new project record" do
      get :new
      assigns(:project).new_record? == true
    end
  end

  describe "GET create" do
    it "should create new project" do
      post :create, { project: FactoryGirl.attributes_for(:project) }
      expect(flash[:success]).to eq("Project created Successfully")
      should redirect_to projects_path
    end

    it "should not save project without name" do
      post :create, {
        project: FactoryGirl.attributes_for(:project).merge(name: '')
      }
      assigns(:project).errors.full_messages == ["Name can't be blank"]
      should render_template(:new)
    end

    it 'create new project with manager and team members' do
      project_attributes = attributes_for(:project)
      manager = create(:manager)
      employees = create_list(:employee, 2).collect(&:id)
      project_attributes.merge!(manager_ids: [manager.id.to_s], company_id: create(:company).id,
      user_projects_attributes: [{user_id: employees.first.to_s, start_date: Date.current},
                                 {user_id: employees.last.to_s, start_date: Date.current}])
      
      post :create, { project: project_attributes }
      expect(Project.count).to eq(1)
      expect(assigns[:project].manager_ids).to eq([manager.id])
      expect(assigns[:project].user_projects.count).to eq(2)
    end
  end

  describe 'PATCH update' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.create(:project) }
    let!(:project_attributes) { create(:project, company: create(:company)) }
    let!(:manager) { create(:manager) }
    let!(:manager2) { create(:manager) }
    let!(:employees) { create_list(:employee, 2) }
    let!(:params) do
      { billing_frequency: "Adhoc", type_of_project: "Fixbid",  manager_ids: [manager.id, manager2.id],
        user_projects_attributes: [{ user_id: employees.first.id.to_s, start_date: Date.current },
                                   { user_id: employees.last.id.to_s, start_date: Date.current }]
      }
    end

    it 'Should update manager ids and managed_project_ids' do
      user_id = []
      user_id << user.id
      patch :update, id: project.id, project: { manager_ids: user_id }
      expect(project.reload.manager_ids.include?(user.id)).to eq(true)
      expect(user.reload.managed_project_ids.include?(project.id)).to eq(true)
    end

    it 'Should add team members' do
      patch :update, project: params, id: project.slug
      project.reload
      user_projects = project.user_projects
      expect(project.billing_frequency).to eq('Adhoc')
      expect(project.type_of_project).to eq('Fixbid')
      expect(user_projects.count).to eq(2)
      expect(project.manager_ids).to match_array([manager.id, manager2.id])
      expect(user_projects.approved_users.collect(&:user_id)).to include(employees.first.id)
      expect(user_projects.approved_users.collect(&:user_id)).to include(employees.last.id)
    end

    it 'Should remove team members' do
      employees.each do |employee|
        project.user_projects.create(start_date: Date.today,
                                     end_date: Date.today + 7,
                                     user_id: employee.id)
      end
      removed_member = project.user_projects.where(user_id: employees.first.id).first
      updated_params = params.merge!(
        billing_frequency: 'Monthly',
        user_projects_attributes: [{ id: removed_member.id.to_s,
                                     user_id: removed_member.user_id.to_s,
                                     end_date: DateTime.now,
                                     active: false }])

      patch :update, project: updated_params, id: project.slug
      project.reload
      inactive_users = project.user_projects.inactive_users
      expect(project.billing_frequency).to eq('Monthly')
      expect(project.user_projects.count).to eq(2)
      expect(inactive_users.count).to eq(1)
      expect(inactive_users.collect(&:user_id)).to include(employees.first.id)
    end
  end

  describe "GET show" do
    it "should find one project record" do
      project = FactoryGirl.create(:project)
      get :show, id: project.id
      expect(assigns(:project)).to eq(project)
    end

    it 'Should equal to managers' do
      user = FactoryGirl.create(:user, role: 'Manager')
      project = FactoryGirl.create(:project)
      project.managers << user
      get :show, id: project.id
      expect(assigns(:managers)).to eq(project.managers)
    end
  end

  describe "GET generate_code" do
    it "should respond with json" do
      get :generate_code, {format: :json}
      expect(response.header['Content-Type']).to include 'application/json'
    end

    it "should generate 6 digit aplphanuric code" do
      get :generate_code, {format: :json}
      parse_response = JSON.parse(response.body)
      expect(parse_response["code"].length).to be 6
    end
  end

  describe 'POST update_sequence_number' do
    it "must update project position sequence number" do
      projects = FactoryGirl.create_list(:project, 3)
      projects.init_list!
      last = projects.last
      expect(last.position).to eq(3)
      xhr :post, :update_sequence_number, id: projects.last.id, position: 1
      expect(last.reload.position).to eq(1)
    end
  end

  context 'GET export_project_report' do
    it "should send project team data report" do
      projects = FactoryGirl.create_list(:project, 3)
      Sidekiq::Extensions::DelayedMailer.jobs.clear
      xhr :get, :export_project_report
      expect(flash[:success]).to eq("You will receive project team data report to your mail shortly.")
      expect(Sidekiq::Extensions::DelayedMailer.jobs.size).to eq(1)
    end
  end

  describe 'DELETE team member' do
    let!(:project) { FactoryGirl.build(:project) }
    it 'Should delete manager' do
      user = FactoryGirl.build(:user, role: 'Manager')
      project.managers << user
      project.save
      user.save
      delete :remove_team_member, :format => :js,
        id: project.id,
        user_id: user.id,
        role: ROLE[:manager]
      expect(project.reload.manager_ids.include?(user.id)).to eq(false)
      expect(user.reload.managed_project_ids.include?(project.id)).to eq(false)
    end

    it 'Should delete employee' do
      user = FactoryGirl.create(:user)
      user_project = UserProject.create(user_id: user.id,
        project_id: project.id,
        start_date: DateTime.now - 1
      )
      project.save
      delete :remove_team_member, :format => :js,
        id: project.id,
        user_id: user.id,
        role: ROLE[:team_member]
      expect(user_project.reload.end_date).to eq(Date.today)
    end

    it 'Should delete manager who added as team member' do
      user = FactoryGirl.create(:user, role: 'Manager')
      user_project = UserProject.create(user_id: user.id,
        project_id: project.id,
        start_date: DateTime.now - 2
      )
      project.save
      delete :remove_team_member, :format => :js,
        id: project.id,
        user_id: user.id,
        role: ROLE[:team_member]
      expect(user_project.reload.end_date).to eq(Date.today)
    end

    it 'Should delete Admin who added as manager' do
      user = FactoryGirl.create(:admin)
      project.managers << user
      project.save
      delete :remove_team_member, :format => :js,
        id: project.id,
        user_id: user.id,
        role: ROLE[:manager]
      expect(project.reload.manager_ids.include?(user.id)).to eq(false)
      expect(user.reload.managed_project_ids.include?(project.id)).to eq(false)
    end

    it 'Should delete Admin who added as team member' do
      user = FactoryGirl.create(:admin)
      user_project = UserProject.create(user_id: user.id,
        project_id: project.id,
        start_date: DateTime.now - 2
      )
      project.save
      delete :remove_team_member, :format => :js,
        id: project.id,
        user_id: user.id,
        role: ROLE[:team_member]
      expect(user_project.reload.end_date).to eq(Date.today)
    end
  end

  context 'Delete timesheet if project deleted' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project_one) { FactoryGirl.create(:project) }
    let!(:project_two) { FactoryGirl.create(:project) }

    it 'Should delete timesheet' do
      UserProject.create(user_id: user.id,
        project_id: project_one.id,
        start_date: Date.today - 5
      )
      UserProject.create(user_id: user.id,
        project_id: project_two.id,
        start_date: Date.today - 5
      )
      TimeSheet.create(user_id: user.id,
        project_id: project_two.id,
        date: Date.today - 1,
        from_time: DateTime.now - 1,
        to_time: DateTime.now - 1 + 1.hours
      )
      TimeSheet.create(user_id: user.id,
        project_id: project_one.id,
        date: Date.today - 1,
        from_time: DateTime.now - 1,
        to_time: DateTime.now - 1 + 1.hours
      )
      TimeSheet.create(user_id: user.id,
        project_id: project_one.id,
        date: Date.today - 2,
        from_time: DateTime.now - 2,
        to_time: DateTime.now - 2 + 1.hours
      )
      TimeSheet.create(user_id: user.id,
        project_id: project_one.id,
        date: Date.today - 3,
        from_time: DateTime.now - 3,
        to_time: DateTime.now - 3 + 1.hours
      )
      TimeSheet.create(user_id: user.id,
        project_id: project_one.id,
        date: Date.today - 4,
        from_time: DateTime.now - 4,
        to_time: DateTime.now - 4 + 1.hours
      )
      project_one_id = project_one.id
      project_name = project_one.name
      delete :destroy, id: project_one.id

      expect(Project.all.pluck(:name).include?(project_name)).to eq(false)
      expect(TimeSheet.all.pluck(:project_id).include?(project_one_id)).
        to eq(false)
    end
  end

  describe 'Update team details' do
    it 'should add valid team member' do
      project = FactoryGirl.create(:project)
      user_one = FactoryGirl.create(:user)
      user_two = FactoryGirl.create(:user)
      user_three = FactoryGirl.create(:user)
      user_project_one = FactoryGirl.create(:user_project, user_id: user_one.id, project_id: project.id)
      user_project_two = FactoryGirl.create(:user_project, user_id: user_two.id, project_id: project.id)
      params = {:project=>
        {:user_projects_attributes=>
          {
            "0" => 
            {
              :active => "true",
              :user_id => user_three.id,
              :project_id => project.id,
              :start_date => "09/01/2020",
              :end_date => "",
              :time_sheet => "0",
              :allocation => "50",
            }
          }
        },
        :id => project.slug
      }
      expect(project.user_projects.count).to eq(2)
      patch :update, params
      project.reload
      expect(project.user_projects.count).to eq(3)
    end

    it 'should NOT add invalid team member' do
      project = FactoryGirl.create(:project)
      user_one = FactoryGirl.create(:user)
      user_two = FactoryGirl.create(:user)
      user_three = FactoryGirl.create(:user)
      user_project_one = FactoryGirl.create(:user_project, user_id: user_one.id, project_id: project.id)
      user_project_two = FactoryGirl.create(:user_project, user_id: user_two.id, project_id: project.id)
      params = {:project=>
        {:user_projects_attributes=>
          {
            "0" => 
            {
              :active => "false",
              :user_id => user_three.id,
              :project_id => project.id,
              :start_date => "09/01/2020",
              :end_date => "",
              :time_sheet => "0",
              :allocation => "50",
            }
          }
        },
        :id => project.slug
      }
      expect(project.user_projects.count).to eq(2)
      patch :update, params
      project.reload
      expect(project.user_projects.count).to eq(2)
    end

    it 'should update valid team member' do
      project = FactoryGirl.create(:project)
      user_one = FactoryGirl.create(:user)
      user_two = FactoryGirl.create(:user)
      user_three = FactoryGirl.create(:user)
      user_project_one = FactoryGirl.create(:user_project, user_id: user_one.id, project_id: project.id)
      user_project_two = FactoryGirl.create(:user_project, user_id: user_two.id, project_id: project.id)
      params = {:project=>
        {:user_projects_attributes=>
          {
            "0" => 
            {
              :id => user_project_two.id,
              :active => "true",
              :user_id => user_two.id,
              :project_id => project.id,
              :start_date => "09/01/2020",
              :end_date => "",
              :time_sheet => "0",
              :allocation => "50",
            }
          }
        },
        :id => project.slug
      }
      expect(project.user_projects.count).to eq(2)
      patch :update, params
      project.reload
      expect(project.user_projects.count).to eq(2)
      expect(project.user_projects.find_by(id: user_project_two.id).allocation).to eq(50)
    end

    it 'should NOT update invalid team member' do
      project = FactoryGirl.create(:project)
      user_one = FactoryGirl.create(:user)
      user_two = FactoryGirl.create(:user)
      user_three = FactoryGirl.create(:user)
      user_project_one = FactoryGirl.create(:user_project, user_id: user_one.id, project_id: project.id)
      user_project_two = FactoryGirl.create(:user_project, user_id: user_two.id, project_id: project.id)
      params = {:project=>
        {:user_projects_attributes=>
          {
            "0" => 
            {
              :id => user_project_two.id,
              :active => "false",
              :user_id => user_two.id,
              :project_id => project.id,
              :start_date => "09/01/2020",
              :end_date => "",
              :time_sheet => "0",
              :allocation => "50",
            }
          }
        },
        :id => project.slug
      }
      expect(project.user_projects.count).to eq(2)
      patch :update, params
      project.reload
      expect(project.user_projects.count).to eq(2)
      expect(project.user_projects.find_by(id: user_project_two.id).active).to eq(true)
    end
  end
end
