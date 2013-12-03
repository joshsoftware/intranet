class LeaveType
  include Mongoid::Document
  NUMBER_OF_CARRY_FORWARD = 14   
  
  field :name,          type: String
  field :number_of_days,      type: Float
  field :can_carry_forward,   type: Boolean
  
  #Currently user can carry forward 14 leave out of 19
  #paid leave , it can change in future 
  field :number_of_carry_forward_p_y, type: Float, default: 14 
  
  LEAVE_TYPE = ['Sick', 'Casual', 'Privilege']
end
