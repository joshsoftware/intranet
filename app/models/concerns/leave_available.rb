module LeaveAvailable
  extend ActiveSupport::Concern
  
  def assign_leave(event)
    doj = self.private_profile.date_of_joining
    self.employee_detail || self.build_employee_detail
    if (self.employee_detail.available_leaves == 0 || event == 'DOJ Updated') &&
       self.leave_applications.count == 0
      self.employee_detail.available_leaves = is_consultant? ? 0 : calculate_leave(doj)
    end
  end
 
  def calculate_leave(date_of_joining)
    leaves = (13 - date_of_joining.month) * PER_MONTH_LEAVE
    leaves = leaves - 1 if date_of_joining.day > 15
    leaves
  end

  def set_leave_details_per_year
    leave_count = is_consultant? ? 0 : PER_MONTH_LEAVE*12
    self.employee_detail.set(:available_leaves, leave_count)
  end
  
  def eligible_for_leave?
    !!(self.private_profile.try(:date_of_joining).try(:present?) && ['Admin', 'Intern'].exclude?(self.role))
  end  
end 
