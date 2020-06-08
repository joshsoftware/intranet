class EmployeeProjectTransferMailer < ActionMailer::Base
  default :from => 'intranet@joshsoftware.com',
          :reply_to => 'hr@joshsoftware.com'

  def employee_project_transfer_request(employee_project_transfer_id)
    get_transfer_details(employee_project_transfer_id)
    receivers = ['sethu@joshsoftware.com']
    mail(to: receivers, subject: "#{@requested_by.name} has requested for Employee Project Transfer")
  end

  def accept_transfer_request(employee_project_transfer_id)
    get_transfer_details(employee_project_transfer_id)
    receivers = [@requested_by.email]
    mail(to: receivers, subject: "Congrats! Your Employee Project Transfer Request got accepted")
  end

  def reject_transfer_request(employee_project_transfer_id)
    get_transfer_details(employee_project_transfer_id)
    receivers = [@requested_by.email]
    mail(to: receivers, subject: "Employee Project Transfer Request got rejected")
  end

  def get_transfer_details(employee_project_transfer_id)
    @employee_project_transfer = EmployeeProjectTransfer.find(employee_project_transfer_id)
    @requested_by = User.find(@employee_project_transfer.requested_by)
    @request_for = User.find(@employee_project_transfer.request_for)
    @from_project = Project.find(@employee_project_transfer.from_project)
    @to_project = Project.find(@employee_project_transfer.to_project)
  end
end
