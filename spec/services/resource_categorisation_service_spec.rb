require 'rails_helper'

RSpec.describe ResourceCategorisationService do
  context 'Employee Categorisation Report - ' do
    before(:each) do
      @emp_one = FactoryGirl.create(:user, status: STATUS[:approved])
      @emp_two = FactoryGirl.create(:user, status: STATUS[:approved])
      @emp_three = FactoryGirl.create(:user, status: STATUS[:approved])

      @active_project = FactoryGirl.create(:project, name: 'Brand Scope')
      @active_project_two = FactoryGirl.create(:project, name: 'Quick Insure')
      @devops_project = FactoryGirl.create(:project, name: 'DevOps Work')
      @free_project = FactoryGirl.create(
        :project,
        name: 'Intranet',
        type_of_project: 'Free'
      )
      @investment_project = FactoryGirl.create(
        :project,
        name: 'OnCoT',
        type_of_project: 'Investment'
      )

      @user_project_one = FactoryGirl.create(
        :user_project,
        user: @emp_one,
        project: @active_project,
        allocation: 80
      )

      @user_project_two = FactoryGirl.create(
        :user_project,
        active: true,
        billable: false,
        allocation: 100,
        user: @emp_two,
        project: @active_project_two
      )

      @user_project_three = FactoryGirl.create(
        :user_project,
        active: true,
        billable: false,
        allocation: 160,
        user: @emp_three,
        project: @devops_project
      )

      @user_project_four = FactoryGirl.create(
        :user_project,
        active: true,
        billable: true,
        allocation: 20,
        user: @emp_three,
        project: @active_project_two
      )

      @service = ResourceCategorisationService.new(@emp_one.email)
    end

    it 'should pass if response contains two reports' do
      response = @service.generate_resource_report
      expect(response.count).to eq(2)
    end

    it 'Billable Allocation - should return total allocation of billable projects' do
      total_allocation = @emp_one.user_projects.map(&:allocation).sum
      @service.get_total_allocation(@emp_one)
      response = @service.billable_projects_allocation(@emp_one)

      expect(@active_project.type_of_project).to eq('T&M')
      expect(response).to eq(total_allocation)
    end

    it 'Non-Billable Allocation - should return total allocation of non-billable projects' do
      FactoryGirl.create(
        :user_project,
        active: true,
        billable: false,
        user: @emp_two,
        project: @free_project,
        allocation: 50
      )
      @service.get_total_allocation(@emp_one)
      response = @service.non_billable_projects_allocation(@emp_two)

      expect(response).to eq(150)
    end

    it 'Investment Allocation - should return total allocation of investment projects' do
      FactoryGirl.create(
        :user_project,
        user: @emp_one,
        project: @investment_project,
        allocation: 90
      )
      @service.get_total_allocation(@emp_one)
      response = @service.investment_projects_allocation(@emp_one)

      expect(@investment_project.type_of_project).to eq('Investment')
      expect(response).to eq(90)
    end

    it 'should generate resource report as expected' do
      technical_skills_one = @emp_one.public_profile.try('technical_skills').slice(0,3)
      technical_skills_two = @emp_two.public_profile.try('technical_skills').slice(0,3)
      technical_skills_three = @emp_three.public_profile.try('technical_skills').slice(0,3)
      report = {
        resource_report: {
          records: [
            {
              id: @emp_one.employee_detail.try(:employee_id).try(:rjust, 3, '0'),
              name: @emp_one.name,
              location: @emp_one.location,
              designation: @emp_one.designation.try(:name),
              level: @service.get_level(@emp_one),
              total_allocation: 160,
              billable: @user_project_one.allocation,
              non_billable: 0,
              investment: 0,
              shared: 0,
              bench: 80,
              technical_skills: technical_skills_one,
              exp_in_months: @emp_one.experience_as_of_today,
              projects: @service.get_project_names(@emp_one)
            },
            {
              id: @emp_two.employee_detail.try(:employee_id).try(:rjust, 3, '0'),
              name: @emp_two.name,
              location: @emp_two.location,
              designation: @emp_two.designation.try(:name),
              level: @service.get_level(@emp_two),
              total_allocation: 160,
              billable: 0,
              non_billable: @user_project_two.allocation,
              investment: 0,
              shared: 0,
              bench: 60,
              exp_in_months: @emp_two.experience_as_of_today,
              technical_skills: technical_skills_two,
              projects: @service.get_project_names(@emp_two)
            }
          ]
        }
      }
      report = report[:resource_report][:records].sort_by { |k,v| k[:name] }
      report << {
        id: @emp_three.employee_detail.try(:employee_id).try(:rjust, 3, '0'),
        name: @emp_three.name,
        location: @emp_three.location,
        designation: @emp_three.designation.try(:name),
        level: @service.get_level(@emp_three),
        total_allocation: 180,
        billable: 20,
        non_billable: 160,
        investment: 0,
        shared: 0,
        bench: 0,
        exp_in_months: @emp_three.experience_as_of_today,
        technical_skills: technical_skills_three,
        projects: @service.get_project_names(@emp_three)
      }

      total_count = {
        :billable=>[0, 2, 1], :non_billable=>[1, 1, 1],
        :investment=>[0, 0, 3], :shared=>[0, 0, 3], :bench=>[0, 2, 1]
      }

      @service.load_projects
      response = @service.generate_resource_report
      expect(response[:resource_report][:records]).to eq(report)
      expect(response[:resource_report][:total_count]).to eq(total_count)
    end

    it 'should generate project wise resource report as expected' do
      report = {
        project_wise_resource_report: {
          records: [
            {
              code: @active_project.code,
              project: @active_project.name,
              type_of_project: @active_project.type_of_project,
              billing_frequency: @active_project.billing_frequency,
              emp_id: @emp_one.employee_detail.try(:employee_id).try(:rjust, 3, '0'),
              name: @emp_one.name,
              location: @emp_one.location,
              designation: @emp_one.designation.try(:name),
              billable: @user_project_one.allocation,
              non_billable: 0,
              investment: 0,
              shared: 0,
              bench: 80
            },
            {
              code: @devops_project.code,
              project: @devops_project.name,
              type_of_project: @devops_project.type_of_project,
              billing_frequency: @devops_project.billing_frequency,
              emp_id: @emp_three.employee_detail.try(:employee_id).try(:rjust, 3, '0'),
              name: @emp_three.name,
              location: @emp_three.location,
              designation: @emp_three.designation.try(:name),
              billable: 0,
              non_billable: @user_project_three.allocation,
              investment: 0,
              shared: 0,
              bench: 0
            },
            {
              code: @active_project_two.code,
              project: @active_project_two.name,
              type_of_project: @active_project_two.type_of_project,
              billing_frequency: @active_project_two.billing_frequency,
              emp_id: @emp_two.employee_detail.try(:employee_id).try(:rjust, 3, '0'),
              name: @emp_two.name,
              location: @emp_two.location,
              designation: @emp_two.designation.try(:name),
              billable: 0,
              non_billable: @user_project_two.allocation,
              investment: 0,
              shared: 0,
              bench: 60
            },
            {
              code: @active_project_two.code,
              project: @active_project_two.name,
              type_of_project: @active_project_two.type_of_project,
              billing_frequency: @active_project_two.billing_frequency,
              emp_id: @emp_three.employee_detail.try(:employee_id).try(:rjust, 3, '0'),
              name: @emp_three.name,
              location: @emp_three.location,
              designation: @emp_three.designation.try(:name),
              billable: @user_project_four.allocation,
              non_billable: 0,
              investment: 0,
              shared: 0,
              bench: 0
            }
          ]
        }
      }

      total_count = {
        :billable => [0, 2, 2], :non_billable => [1, 1, 2],
        :investment => [0, 0, 4], :shared=>[0, 0, 4], :bench => [0, 2, 2]
      }

      report = report[:project_wise_resource_report][:records].sort_by { |k,v| k[:project] }
      response = @service.generate_resource_report
      expect(response[:project_wise_resource_report][:records]).to eq(report)
      expect(response[:project_wise_resource_report][:total_count]).to eq(total_count)
    end

    it 'should send mail' do
      ActionMailer::Base.deliveries = []
      @service.call
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.subject).to eq("Employee Categorisation Report - #{Date.today}")
    end
  end
end