class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    if user.role? 'Super Admin'
      can :manage, :all
    elsif user.role? 'Admin'
      common_admin_devops
      admin_abilities
    elsif user.role? 'HR'
      hr_abilities
    elsif user.role? 'Finance'
      can [:public_profile, :private_profile, :edit, :apply_leave], User
    elsif user.role? 'Manager'
      employee_abilities(user.id)
      can :manage, Project
      can :edit, User
      can :manage, Company
      can [:public_profile, :private_profile, :apply_leave], User
      can :manage, TimeSheet
      can :manage, LeaveApplication
    elsif user.role? 'Employee'
      employee_abilities(user.id)
    elsif user.role? 'Intern'
      intern_abilities(user.id)
    elsif user.role? 'DevOps'
      common_admin_devops
    end
    can :register_vpn, User
  end

  def common_admin_hr
    can :invite_user, User
    can :manage, [Project]
    can :manage, [Attachment, Policy]
    can :manage, Vendor
    can :manage, LeaveApplication
    can :manage, Schedule
    can :manage, Company
    can :manage, TimeSheet
    can :manage, HolidayList
  end

  def common_admin_devops
    can [:register_vpn, :revoke_vpn], User
  end

  def intern_abilities(user_id)
    can [:public_profile, :private_profile], User
    can :read, [Policy, Attachment, Vendor]
    can :read, Project
    can [:index, :users_timesheet, :edit_timesheet, :update_timesheet, :new, :add_time_sheet], TimeSheet, user_id: user_id
  end

  def employee_abilities(user_id)
    can [:public_profile, :private_profile, :apply_leave], User, id: user_id
    can [:index, :download_document], Attachment do |attachment|
      attachment.user_id == user_id || attachment.is_visible_to_all
    end
    can :read, Policy
    can :read, Project
    cannot :manage, LeaveApplication
    can [:new, :create], LeaveApplication, user_id: user_id
    can [:edit, :update], LeaveApplication, leave_status: 'Pending', user_id: user_id
    can :read, Vendor
    can [:index, :users_timesheet, :edit_timesheet, :update_timesheet, :new, :add_time_sheet], TimeSheet, user_id: user_id
    cannot [:projects_report, :individual_project_report], TimeSheet
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
    cannot :index, LeaveApplication
    cannot :update, LeaveApplication
  end
end
