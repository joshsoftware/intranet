module LeaveAvailable
  extend ActiveSupport::Concern
  
  def assign_leave
  end   
  
  def set_leave_details_per_year
  end
  
  def eligible_for_leave?
    !!(self.private_profile.try(:date_of_joining).try(:present?) && ['Admin', 'Intern'].exclude?(self.role))
  end  
end 
