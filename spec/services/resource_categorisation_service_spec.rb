require 'rails_helper'

RSpec.describe ResourceCategorisationService do
  context 'Resource Categorisation Report - ' do 
    before(:each) do
      @employee_one = FactoryGirl.create(:user, status: STATUS[2])
      @employee_two = FactoryGirl.create(:user, status: STATUS[2])
      @active_project = FactoryGirl.create(:project, name: 'Brand Scope')
      @user_project_one = FactoryGirl.create(
        :user_project,
        user: @employee_one,
        project: @active_project,
        allocation: 80
      )
      
      @user_project_two = FactoryGirl.create(
        :user_project,
        active: true,
        billable: false,
        end_date: Date.today,
        allocation: 100,
        user: @employee_two,
        project: @active_project
      )  

      @service = ResourceCategorisationService.new(@employee_one.email)
    end
  
    it 'Billable Allocation - should return total allocation of billable projects' do
      total_allocation = @employee_one.user_projects.map(&:allocation).sum
      response = @service.billable_projects_allocation(@employee_one)

      expect(@active_project.type_of_project).to eq('T&M')
      expect(response).to eq(total_allocation)
    end

    it 'Non-Billable Allocation - should return total allocation of non-billable projects' do
      free_project = FactoryGirl.create(
        :project,
        name: 'Brand Scope',
        type_of_project: 'Free'
      )
      FactoryGirl.create(
        :user_project,
        active: true,
        billable: false,
        user: @employee_two,
        project: free_project,
        allocation: 50
      )
      response = @service.non_billable_projects_allocation(@employee_two)

      expect(response).to eq(150)
    end

    it 'Investment Allocation - should return total allocation of investment projects' do
      investment_project = FactoryGirl.create(
        :project,
        name: 'Brand Scope',
        type_of_project: 'Investment'
      )
      
      FactoryGirl.create(
        :user_project,
        user: @employee_one,
        project: investment_project,
        allocation: 90
      )
      response = @service.investment_projects_allocation(@employee_one)

      expect(investment_project.type_of_project).to eq('Investment')
      expect(response).to eq(90)
    end

    it 'should generate resource reports' do
      report = [
        { name: @employee_one.name, total_allocation: 80, billable: @user_project_one.allocation, non_billable: 0, investment: 0, bench: 80},
        { name: @employee_two.name, total_allocation: 100, billable: 0, non_billable: @user_project_two.allocation, investment:0, bench: 60}
      ]
      report = report.sort_by { |k| k[:name] }
      response = @service.generate_resource_report
      expect(response).to eq(report)
    end    

    it 'should send mail' do
      @service.call
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.subject).to eq("Resource Categorisation Report - #{Date.today}")
    end
  end
end