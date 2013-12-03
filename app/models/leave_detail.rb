class LeaveDetail
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::History::Trackable

  belongs_to :user
  
  field :year,            type: Integer
  
  field :available_leave,     type: Hash, default: {"Sick" => 0, "Casual" => 0, "CurrentPrivilege" => 0, "TotalPrivilege" => 0}
  track_history  
 
  before_save do
    self.available_leave["Sick"] = self.available_leave["Sick"].to_i
    self.available_leave["Casual"] = self.available_leave["Casual"].to_i
    self.available_leave["CurrentPrivilege"] = self.available_leave["CurrentPrivilege"].to_d.to_s
    self.available_leave["TotalPrivilege"] = self.available_leave["TotalPrivilege"].to_d.to_s
  end
  
  def validate_doj_month
    (self.user.private_profile.date_of_joining.month != (Date.today.month-1))
  end
  
  def validate_doj_days
    ((self.user.private_profile.date_of_joining.month == (Date.today.month-1)) && (self.user.private_profile.date_of_joining.day <= 15))
  end 
   
  def monthly_paid_leave
    if validate_doj_month || validate_doj_days
      self.available_leave["CurrentPrivilege"] = (self.available_leave["CurrentPrivilege"].to_d + 1.5).to_s
      self.available_leave["TotalPrivilege"] =  (self.available_leave["TotalPrivilege"].to_d + 1.5).to_s
    end
    self 
  end
  
  def validate_leave(name, number_of_day)
    if name == "Privilege"
      name = "TotalPrivilege"
    end
    ((self.available_leave[name].to_d - number_of_day).to_d >= 0).blank? ? true: false          
  end
  
  def add_rejected_leave(leave_type: "Sick", no_of_leave: 1)
    if leave_type != "Privilege"
      self.available_leave[leave_type] = self.available_leave[leave_type] + no_of_leave.to_i 
    else
      self.available_leave["CurrentPrivilege"] =  (self.available_leave["CurrentPrivilege"].to_d +  no_of_leave.to_d).to_s
      self.available_leave["TotalPrivilege"] = (self.available_leave["TotalPrivilege"].to_d + no_of_leave.to_d).to_s
    end
    self.save
  end 
   
  def deduct_available_leave(leave_type: "Sick", no_of_leave: 1)
    if leave_type != "Privilege"
      self.available_leave[leave_type] = self.available_leave[leave_type] - no_of_leave
    else
      self.available_leave["CurrentPrivilege"] = (self.available_leave["CurrentPrivilege"].to_d - no_of_leave.to_d).to_s if self.available_leave["CurrentPrivilege"] != 0 
      self.available_leave["TotalPrivilege"] =  (self.available_leave["TotalPrivilege"].to_d - no_of_leave.to_d).to_s
    end 
    self.save 
  end 
end
