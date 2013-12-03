module LeaveAvailable
  extend ActiveSupport::Concern
  
  included do
    has_many :leave_details
  end  
   
  def calculate_remaining_leave(total_leave) 
    ((total_leave * (12 - (self.private_profile.date_of_joining.month - 1)))/12).ceil 
  end

  def assign_leave
    leave_details = self.leave_details.find_or_initialize_by(year: Date.today.year)
    #Logic is that casual and sick leave are 6 per years and paid leave calculated per month
    leave_details.available_leave["Sick"] = leave_details.available_leave["Casual"] = calculate_remaining_leave(SICK_LEAVE) if self.private_profile.date_of_joining.year == Date.today.year 
    leave_details.save
  end   
  
  def total_leave_carry_forward
    doj = self.private_profile.date_of_joining
    (doj.month == (Date.today.year - 1))? ((CAN_CARRY_FORWARD/12.to_d).to_d * (12 - (doj.month - 1))).to_s : CAN_CARRY_FORWARD
  end 
 
  def privilege_leave_yearly(available_leave, current_leave_details) 
    no_carry_over_leave = available_leave["CurrentPrivilege"].to_d - total_leave_carry_forward
    total_paid_leave = available_leave["TotalPrivilege"]  
    current_leave_details.available_leave["TotalPrivilege"] = no_carry_over_leave >= 0 ? (total_paid_leave.to_d - no_carry_over_leave).to_s : total_paid_leave.to_s
  end
 
  def set_leave_details_per_year
    available_leave = self.leave_details.where(year: Date.today.year - 1 ).first.available_leave
    current_leave_details = self.leave_details.build(year: Date.today.year) 
    current_leave_details.available_leave["Sick"] = current_leave_details.available_leave["Casual"] = SICK_LEAVE
    privilege_leave_yearly(available_leave, current_leave_details)
    current_leave_details.save 
  end
  
  def assign_monthly_leave
    available_leave = self.leave_details.where(year: Date.today.year).first.monthly_paid_leave()
    available_leave.save 
  end 
    
  def get_leave_detail(year)
    leave_details.where(year: year).first   
  end
 
  def eligible_for_leave?
    !! self.private_profile.date_of_joining.present?
  end  
end 
