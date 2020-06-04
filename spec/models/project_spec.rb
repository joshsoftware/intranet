require 'spec_helper'

describe Project do
  context 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:start_date) }
    it { is_expected.to validate_presence_of(:billing_frequency) }
    it { is_expected.to validate_presence_of(:type_of_project) }
    it { is_expected.to validate_inclusion_of(:billing_frequency).to_allow(Project::BILLING_FREQUENCY_TYPES) }
    it { is_expected.to validate_inclusion_of(:type_of_project).to_allow(Project::TYPE_OF_PROJECTS) }
  end
  # it {should accept_nested_attributes_for(:users)}

  it 'must return all the tags' do
    project = FactoryGirl.create(:project)
    expect(project.tags.count).to eq(4)
  end


  it "should use existing product code of company" do
    company = FactoryGirl.create(:company)
    project = FactoryGirl.create(:project, company: company)
    new_project = FactoryGirl.build(:project,
      code: project.code,
      company: company
    )
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
      expect(project.errors.count).to eq(0)
    end

    it 'should fail beacause display name contain white space' do
      project.display_name = 'Test project'
      project.save

      expect(project.errors.full_messages).
        to eq(["Display name Name should not contain white space"])
      expect(project.errors.count).to eq(1)
    end

    it 'should update display name when project name is change' do
      project.name = 'Test project'
      project.display_name = ''
      project.save

      expect(project.display_name).to eq("Test_project")
      expect(project.errors.count).to eq(0)
    end

    it 'Should not trigger validation because display name is correct' do
      project.display_name = 'abc'

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
      expect(manager_names).to eq("#{user.name} | #{manager.name}")
    end

    it 'Should match employee name' do
      FactoryGirl.create(:user_project, user: user, project: project)
      employee_names = Project.employee_names(project)
      expect(employee_names).to eq("#{user.name}")
    end
  end

  context 'Users' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.create(:project) }
    it 'Should give users report' do
      FactoryGirl.create(:user_project,
        user: user,
        project: project,
        start_date: DateTime.now - 2
      )
      users = project.users
      expect(users.present?).to eq(true)
    end
  end

  context 'Get user project from project' do
    before {
              @users = []
              [1, 2, 3, 4, 5, 6, 7, 8].each do |n|
                @users << FactoryGirl.create(:user,
                  email: "user#{n}@#{ORGANIZATION_DOMAIN}",
                  status: STATUS[2])
              end
           }
    let!(:project) { FactoryGirl.create(:project) }

    context 'should give user record' do
      it "between 'from date' and 'to date'" do
        FactoryGirl.create(:user_project,
          user: @users[0],
          project: project,
          start_date: '01/08/2018'.to_date
        )
        FactoryGirl.create(:user_project,
          user: @users[1],
          project: project,
          start_date: '06/09/2018'.to_date
        )
        FactoryGirl.create(:user_project,
          user: @users[2],
          project: project,
          start_date: '05/09/2018'.to_date,
          end_date: '15/09/2018'.to_date
        )
        FactoryGirl.create(:user_project,
          user: @users[3],
          project: project,
          start_date: '08/09/2018'.to_date,
          end_date: '23/09/2018'.to_date
        )
        FactoryGirl.create(:user_project,
          user: @users[4],
          project: project,
          start_date: '05/08/2018'.to_date,
          end_date: '10/09/2018'.to_date
        )
        FactoryGirl.create(:user_project,
          user: @users[5],
          project: project,
          start_date: '01/08/2018'.to_date,
          end_date: '10/10/2018'.to_date
        )
        FactoryGirl.create(:user_project,
          user: @users[6],
          project: project,
          start_date: '25/09/2018'.to_date,
          end_date: '30/09/2018'.to_date
        )
        FactoryGirl.create(:user_project,
          user: @users[7],
          project: project,
          start_date: '01/08/2018'.to_date,
          end_date: '25/08/2018'.to_date
        )
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        user_projects = project.get_user_projects_from_project(from_date, to_date)
        expect(user_projects.count).to eq(6)
        [0, 1, 2, 3, 4, 5].each do |n|
          expect(user_projects[n].email).to eq("user#{n+1}@#{ORGANIZATION_DOMAIN}")
        end
      end

      it "if user's project start date is less than from date & end date is nil" do
        FactoryGirl.create(:user_project,
          user: @users[0],
          project: project,
          start_date: '01/08/2018'.to_date
        )
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        user_projects = project.get_user_projects_from_project(from_date, to_date)
        expect(user_projects.count).to eq(1)
        expect(user_projects[0].email).to eq("user1@#{ORGANIZATION_DOMAIN}")
      end

      it "if user's project start date is greater than from date & end date is nil" do
        FactoryGirl.create(:user_project,
          user: @users[1],
          project: project,
          start_date: '06/09/2018'.to_date,
          end_date: '20/09/2018'.to_date
        )
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        user_projects = project.get_user_projects_from_project(from_date, to_date)
        expect(user_projects.count).to eq(1)
        expect(user_projects[0].email).to eq("user2@#{ORGANIZATION_DOMAIN}")
      end

      it "if user's project start date is greater than from date & end date is less than to date" do
        FactoryGirl.create(:user_project,
          user: @users[2],
          project: project,
          start_date: '05/09/2018'.to_date,
          end_date: '15/09/2018'.to_date
        )
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        user_projects = project.get_user_projects_from_project(from_date, to_date)
        expect(user_projects.count).to eq(1)
        expect(user_projects[0].email).to eq("user3@#{ORGANIZATION_DOMAIN}")
      end

      it "if user's project start date is greater than from date & end date is greater than to date " do
        FactoryGirl.create(:user_project,
          user: @users[3],
          project: project,
          start_date: '08/09/2018'.to_date,
          end_date: '23/09/2018'.to_date
        )
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        user_projects = project.get_user_projects_from_project(from_date, to_date)
        expect(user_projects.count).to eq(1)
        expect(user_projects[0].email).to eq("user4@#{ORGANIZATION_DOMAIN}")
      end

      it "if user's project start date less than from date & end date less than to date" do
        FactoryGirl.create(:user_project,
          user: @users[4],
          project: project,
          start_date: '05/08/2018'.to_date,
          end_date: '10/09/2018'.to_date
        )
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        user_projects = project.get_user_projects_from_project(from_date, to_date)
        expect(user_projects.count).to eq(1)
        expect(user_projects[0].email).to eq("user5@#{ORGANIZATION_DOMAIN}")
      end

      it "if user's project start date is less than from date & end date is greater than to date" do
        FactoryGirl.create(:user_project,
          user: @users[7],
          project: project,
          start_date: '01/08/2018'.to_date,
          end_date: '10/10/2018'.to_date
        )
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        user_projects = project.get_user_projects_from_project(from_date, to_date)
        expect(user_projects.count).to eq(1)
        expect(user_projects[0].email).to eq("user8@#{ORGANIZATION_DOMAIN}")
      end
    end

    context 'Should not give the user record' do
      it 'because its less than from date and to date' do
        FactoryGirl.create(:user_project,
          user: @users[5],
          project: project,
          start_date: '01/08/2018'.to_date,
          end_date: '25/08/2018'.to_date
        )
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        user_projects = project.get_user_projects_from_project(from_date, to_date)
        expect(user_projects.count).to eq(0)
      end

      it 'because its greater than from date and to date' do
        FactoryGirl.create(:user_project,
          user: @users[6],
          project: project,
          start_date: '25/09/2018'.to_date,
          end_date: '30/09/2018'.to_date
        )
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        user_projects = project.get_user_projects_from_project(from_date, to_date)
        expect(user_projects.count).to eq(0)
      end

      it "because user's project start date & end date are not between from date & to date" do
        FactoryGirl.create(:user_project,
          user: @users[5],
          project: project,
          start_date: '01/08/2018'.to_date,
          end_date: '25/08/2018'.to_date
        )
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        user_projects = project.get_user_projects_from_project(from_date, to_date)
        expect(user_projects.count).to eq(0)
        expect(user_projects.present?).to eq(false)
      end

      it "because user's project start date & end date are not between from date & to date" do
        FactoryGirl.create(:user_project,
          user: @users[6],
          project: project,
          start_date: '25/09/2018'.to_date,
          end_date: '30/09/2018'.to_date
        )
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        user_projects = project.get_user_projects_from_project(from_date, to_date)
        expect(user_projects.count).to eq(0)
        expect(user_projects.present?).to eq(false)
      end
    end
  end

  context 'on delete project, its linked repositories should get deleted' do
    it 'validates repo count on delete project' do
      project = create(:project)
      repository = create(:repository, project: project)
      expect(project.repositories.count).to eq(1)
      expect(Repository.count).to eq(1)
      project.destroy
      expect(Repository.count).to eq(0)
    end
  end

  context 'check presence of end_date' do
    it 'when project set to inactive' do
      project = create(:project)
      project.is_active = false
      expect(project.valid?).to eq false
    end
  end

  describe '#update_user_projects' do
    context 'when project set to inactive' do
      let!(:project) { create(:project) }
      let!(:user_project) { create_list(:user_project, 2, project: project) }

      it 'set end date for each developer assigned to that project ' do
        project.update_attributes(is_active: false, end_date: Time.zone.today)

        project.reload
        expect(project.user_projects.collect(&:end_date)).not_to be_nil
        expect(project.user_projects.collect(&:end_date).uniq).to match_array([Time.zone.today])
      end
    end
  end

  # context '#add_team_members' do
  #   it 'create new team members associated with project' do
  #     project = create(:project)
  #     employee_ids = create_list(:employee, 2)
  #     project.add_team_members(employee_ids.collect(&:id))
  #     expect(project.user_projects.count).to eq 2
  #     expect(project.user_projects.pluck(:user_id)).to match_array(employee_ids.collect(&:id))
  #     expect(project.user_projects.pluck(:end_date).uniq).to eq([nil])
  #   end
  # end

  # context '#remove_team_members' do
  #   it 'set end date for removed team members of project' do
  #     project = create(:project)
  #     employee = create(:employee)
  #     project.user_projects.create!(user_id: employee.id, start_date: Time.zone.now)
  #     project.remove_team_members([employee.id.to_s])
  #     project.reload

  #     expect(project.user_projects.count).to eq 1
  #     expect(project.user_projects.first.user_id).to eq(employee.id)
  #     expect(project.user_projects.first.end_date).not_to be_nil
  #   end
  # end

  # context '#add_or_remove_team_members' do
  #   it 'create new members for project' do
  #     project = create(:project)
  #     employee_ids = create_list(:employee, 2)
  #     project.add_or_remove_team_members(employee_ids.collect(&:id))
  #     expect(project.user_projects.count).to eq 2
  #     expect(project.user_projects.pluck(:user_id)).to match_array(employee_ids.collect(&:id))
  #     expect(project.user_projects.pluck(:end_date).uniq).to eq([nil])
  #   end

  #   it 'create new team members with existing team members for project' do
  #     project = create(:project)
  #     existing_team_members = create_list(:employee, 2)
  #     existing_team_members.each do |user|
  #       project.user_projects.create!(user_id: user.id, start_date: '1/1/2001'.to_date)
  #     end
  #     expect(project.user_projects.count).to eq 2
  #     expect(project.user_projects.first.start_date).to eq('1/1/2001'.to_date)
  #     employee = create(:employee)
  #     project.add_or_remove_team_members([employee.id])
  #     expect(project.user_projects.count).to eq 3
  #   end

  #   it 'remove team members for project' do
  #     project = create(:project)
  #     existing_team_members = create_list(:employee, 2)
  #     existing_team_members.each do |user|
  #       project.user_projects.create!(user_id: user.id, start_date: '1/1/2001'.to_date)
  #     end
  #     expect(project.user_projects.count).to eq 2
  #     employee = project.users.first.id.to_s
  #     project.add_or_remove_team_members([employee])
  #     expect(project.user_projects.count).to eq 2
  #     expect(project.user_projects.where(user_id: employee).first).not_to be_nil
  #   end
  # end

  context '#team_data_to_csv' do
    let!(:user) { FactoryGirl.create(:user, status: 'approved') }
    let!(:project) { FactoryGirl.create(:project) }

    it 'Should return valid csv' do
      end_date = project.end_date.blank? ? (Date.today + 6.months).end_of_month : project.end_date
      up = FactoryGirl.create(:user_project, user: user, project: project)
      csv = Project.team_data_to_csv
      expected_csv = "Project,Project Start Date,Project End Date,Employee Name,Employee Tech Skills,Employee Other Skills,Employee Total Exp in Months,Employee Started On Project At,Days on Project\n"
      skills = [user.public_profile.try(:technical_skills)].flatten.compact.uniq.sort.reject(&:blank?).join(', ').delete("\n").gsub("\r", ' ')
      other_skills = user.try(:public_profile).try(:skills).split(',').flatten.compact.uniq.sort.reject(&:blank?).join(', ').delete("\n").gsub("\r", '')
      expected_csv << "#{project.name},#{project.start_date},#{end_date},#{user.name},\"#{skills}\",\"#{other_skills}\",#{user.experience_as_of_today},#{up.start_date},#{(Date.today - up.start_date).to_i}\n"
      expect(csv).to eq(expected_csv)
    end
  end

end
