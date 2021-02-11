class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    if user.role? ROLE[:super_admin]
      can :manage, :all
    elsif user.role? ROLE[:admin]
      admin_abilities
      cannot :index, LeaveApplication
    elsif user.role? ROLE[:HR]
      hr_abilities(user.id)
    elsif user.role? ROLE[:finance]
      can [:public_profile, :private_profile, :apply_leave], User, id: user.id
      can :read, :dashboard
      can :index, HolidayList
      can :manage, Company
    elsif user.role? ROLE[:manager]
      employee_abilities(user.id)
      can :manage, Project
      can :edit, User
      can :manage, Company
      can [:public_profile, :private_profile, :apply_leave], User
      can [:index, :download_document], Attachment do |attachment|
        attachment.user_id == user_id || attachment.is_visible_to_all
      end
      can :manage, TimeSheet
      can :manage, LeaveApplication
      cannot :index, LeaveApplication
      can :resource_list, User
      can :manage, EntryPass
    elsif user.role? ROLE[:employee]
      employee_abilities(user.id)
    elsif user.role? ROLE[:consultant]
      consultant_abilities(user.id)
    elsif user.role? ROLE[:intern]
      intern_abilities(user.id)
    end
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
    can :resource_list, User
    can :manage, EntryPass
    can :read, :dashboard
  end

  def intern_abilities(user_id)
    can [:public_profile, :private_profile], User
    cannot [:resource_list, :resource_list_download, :invite_user], User
    can :read, [Policy, Attachment, Vendor]
    can [:index, :users_timesheet, :edit_timesheet, :update_timesheet, :new, :add_time_sheet], TimeSheet, user_id: user_id
    cannot [:projects_report, :individual_project_report, :export_project_report], TimeSheet
    can :manage, EntryPass, user_id: user_id
    can :read, :dashboard
    cannot :manage, HolidayList
    can :index, HolidayList
  end

  def employee_abilities(user_id)
    can [:public_profile, :private_profile, :apply_leave], User, id: user_id
    cannot [:resource_list, :resource_list_download, :invite_user], User
    can [:index, :download_document], Attachment do |attachment|
      attachment.user_id == user_id || attachment.is_visible_to_all
    end
    can :read, Policy
    cannot :manage, LeaveApplication
    can [:new, :create], LeaveApplication, user_id: user_id
    can [:edit, :update], LeaveApplication, leave_status: PENDING, user_id: user_id
    can :read, Vendor
    can [:index, :users_timesheet, :edit_timesheet, :update_timesheet, :new, :add_time_sheet], TimeSheet, user_id: user_id
    cannot [:projects_report, :individual_project_report, :export_project_report], TimeSheet
    can :manage, EntryPass, user_id: user_id
    cannot :report, EntryPass
    cannot :manage, HolidayList
    can :index, HolidayList
    can :read, :dashboard
  end

  def consultant_abilities(user_id)
    can [:public_profile, :private_profile, :apply_leave], User, id: user_id
    can :read, Policy
    cannot :manage, LeaveApplication
    can [:new, :create], LeaveApplication, user_id: user_id
    can [:edit, :update], LeaveApplication, leave_status: PENDING, user_id: user_id
    can [:index, :users_timesheet, :edit_timesheet, :update_timesheet, :new, :add_time_sheet], TimeSheet, user_id: user_id
    cannot [:projects_report, :individual_project_report], TimeSheet
    cannot :manage, EntryPass, user_id: user_id
    cannot :report, EntryPass
    cannot :read, :dashboard
  end

  def admin_abilities
    common_admin_hr
    can :edit, User
    can [:public_profile, :private_profile], User
    can :manage, :admin
    can :manage, EntryPass
  end

  def hr_abilities(user_id)
    common_admin_hr
    can [:public_profile, :private_profile, :edit, :apply_leave], User
    cannot :manage, LeaveApplication
    can :index, LeaveApplication
    can [:new, :create], LeaveApplication, user_id: user_id
    can [:edit, :update], LeaveApplication, leave_status: PENDING, user_id: user_id
    can :manage, Designation
  end
end
