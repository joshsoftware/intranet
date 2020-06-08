require 'rails_helper'

RSpec.describe EmployeeProjectTransfer, type: :model do
  it { should have_fields(
                            :requested_date, :request_for, :requested_by, :start_date,
                            :from_project, :request_reason, :to_project
                         )
     }
  it { should have_field(:status).of_type(String).
        with_default_value_of(PENDING)
     }

  before do
    @candidate = FactoryGirl.create(:user)
    @admin = FactoryGirl.create(:admin)
    @super_admin = FactoryGirl.create(:super_admin)
    @project1 = FactoryGirl.create(:project)
    user_project = FactoryGirl.create(:user_project, user: @candidate, project: @project1)
    @project2 = FactoryGirl.create(:project)
  end

  context 'Validate date' do
    it "should have start_date less_than_or_equal_to end_date" do
      request = FactoryGirl.build(:employee_project_transfer,
                                  requested_by: @admin.id, request_for: @candidate.id,
                                  from_project: @project1.id.to_s, to_project: @project2.id.to_s,
                                  start_date: Date.today, end_date: Date.yesterday
                                )
      request.save
      expect(request.errors.messages[:end_date]).to eq(["should not be less than start date."])
    end
  end

  context 'Validate Projects' do
    it 'should have from_project in projects list' do
      project3 = FactoryGirl.create(:project)
      request = FactoryGirl.build(:employee_project_transfer,
                                  requested_by: @admin.id, request_for: @candidate.id,
                                  from_project: @project2.id.to_s, to_project: project3.id.to_s
                                )
      request.save
      expect(request.errors.messages[:from_project]).to eq(["requested employee is not in given from project."])
    end

    it 'should not have to_project in projects list' do
      project3 = FactoryGirl.create(:project)
      user_project = FactoryGirl.create(:user_project, user: @candidate, project: project3)
      request = FactoryGirl.build(:employee_project_transfer,
                                   requested_by: @admin.id, request_for: @candidate.id,
                                   from_project: @project1.id.to_s, to_project: project3.id.to_s
                                 )
      request.save
      expect(request.errors.messages[:to_project]).to eq(["requested employee is already in to project."])
    end

    it 'should not save request for same candidate from same project' do
      FactoryGirl.create(:employee_project_transfer,
                          requested_by: @admin.id, request_for: @candidate.id,
                          from_project: @project1.id.to_s, to_project: @project2.id.to_s
                        )
      project3 = FactoryGirl.create(:project)
      request = FactoryGirl.build(:employee_project_transfer,
                                   requested_by: @admin.id, request_for: @candidate.id,
                                   from_project: @project1.id.to_s, to_project: project3.id.to_s
                                 )
      request.save
      expect(request.errors.messages[:from_project]).to eq(["the unrejected request for candidate from project is already present"])
    end
  end
end
