class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    if user.role? 'Super Admin'
      can :manage, :all
    elsif user.role? 'Admin'
      admin_abilities
    elsif user.role? 'HR'
      hr_abilities
    elsif user.role? 'Finance'
      can [:public_profile, :private_profile, :edit, :apply_leave], User 
    elsif user.role? 'Manager'
      can :manage, Project
      can [:public_profile, :private_profile, :apply_leave], User 
    elsif user.role? 'Employee'
      employee_abilities(user.id) 
    elsif user.role? 'Intern'
      intern_abilities   
    end
  end
  
  def common_admin_hr
    can :invite_user, User
    can :manage, [Project]
    can :manage, [Attachment, Policy]
    can :manage, Vendor
    can :manage, LeaveApplication
    can :manage, Schedule
  end
  
  def intern_abilities 
    can [:public_profile, :private_profile, :apply_leave], User
    can :read, :all
    can :read, Project 
  end
  
  def employee_abilities(user_id)
    can [:public_profile, :private_profile, :apply_leave], User, id: user_id
    can [:index, :download_document], Attachment
    can :read, Policy
    can :read, Project
    cannot :manage, LeaveApplication
    can [:new, :create], LeaveApplication, user_id: user_id
    can [:edit, :update], LeaveApplication, leave_status: 'Pending', user_id: user_id
    can :read, Vendor
  end

  def admin_abilities
    common_admin_hr
    can :edit, User
    can [:public_profile, :private_profile], User
    can :manage, :admin
  end

  def hr_abilities
    common_admin_hr
    can [:public_profile, :private_profile, :edit, :apply_leave], User
  end
end
