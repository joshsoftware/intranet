require 'rails_helper'

RSpec.describe ResourceCategorisationService do
  context 'Resource Categorisation Report - ' do 
    before(:each) do
      @emp_one = FactoryGirl.create(:user, status: STATUS[2])
      @emp_two = FactoryGirl.create(:user, status: STATUS[2])

      @active_project = FactoryGirl.create(:project, name: 'Brand Scope')
      @free_project = FactoryGirl.create(
        :project,
        name: 'Intranet',
        type_of_project: 'Free'
      )
      @investment_project = FactoryGirl.create(
        :project,
        name: 'Hunger Terminal',
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
        project: @active_project
      )  

      @service = ResourceCategorisationService.new(@emp_one.email)
    end

    it 'should pass if response contains two reports' do
      response = @service.generate_resource_report
      expect(response.count).to eq(2)
    end

    it 'Billable Allocation - should return total allocation of billable projects' do
      total_allocation = @emp_one.user_projects.map(&:allocation).sum
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
      response = @service.investment_projects_allocation(@emp_one)

      expect(@investment_project.type_of_project).to eq('Investment')
      expect(response).to eq(90)
    end

    it 'should generate resource report as expected' do
      project_name_one = @emp_one.project_details.map { |i| i.values[1] }.join(', ')
      project_name_two = @emp_two.project_details.map { |i| i.values[1] }.join(', ')
      technical_skills_one = @emp_one.public_profile.technical_skills.join(', ') if @emp_one.public_profile.technical_skills.present?
      technical_skills_two = @emp_two.public_profile.technical_skills.join(', ') if @emp_two.public_profile.technical_skills.present?
      report = [
        { name: @emp_one.name, location: @emp_one.location, total_allocation: 80,
          billable: @user_project_one.allocation, non_billable: 0, investment: 0, bench: 80,
          technical_skills: technical_skills_one, projects: project_name_one },
        { name: @emp_two.name, location: @emp_two.location, total_allocation: 100,
          billable: 0, non_billable: @user_project_two.allocation, investment: 0, bench: 60,
          technical_skills: technical_skills_one, projects: project_name_two }
      ]
      report = report.sort_by { |k| k[:name] }
      response = @service.generate_resource_report
      expect(response[:resource_report]).to eq(report)
    end    

    it 'should generate project wise resource report as expected' do
      project_name_one = @emp_one.project_details.map { |i| i.values[1] }.join(', ')
      project_name_two = @emp_two.project_details.map { |i| i.values[1] }.join(', ')
      technical_skills_one = @emp_one.public_profile.technical_skills.join(', ') if @emp_one.public_profile.technical_skills.present?
      technical_skills_two = @emp_two.public_profile.technical_skills.join(', ') if @emp_two.public_profile.technical_skills.present?

      report = [
        { name: @emp_one.name, location: @emp_one.location, designation: @emp_one.designation.try(:name),
          billable: @user_project_one.allocation, non_billable: 0, investment: 0, project: project_name_one },
        { name: @emp_two.name, location: @emp_two.location, designation: @emp_one.designation.try(:name),
          billable: 0, non_billable: @user_project_two.allocation, investment: 0, project: project_name_two }
      ]
      report = report.sort_by { |k| k[:name] }
      response = @service.generate_resource_report
      expect(response[:project_wise_resource_report]).to eq(report)
    end 

    it 'should send mail' do
      ActionMailer::Base.deliveries = []
      @service.call
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.subject).to eq("Resource Categorisation Report - #{Date.today}")
    end
  end
end