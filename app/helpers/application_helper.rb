module ApplicationHelper

  def flash_class(type)
    case type
    when 'notice' then "alert alert-info"
    when 'success' then "alert alert-success"
    when 'error' then "alert alert-error"
    when 'alert' then "alert alert-error"
    end
  end

  def set_label status
    status ? 'label-success' : 'label-warning'
  end

  def can_access?(event)
    role = current_user.role
    case event
    when 'Events' then [ROLE[:consultant]].include?(role)
    when 'Documents' then [ROLE[:consultant], ROLE[:finance]].include?(role)
    when 'Newsletter' then [ROLE[:HR], ROLE[:admin], 'Super Admin'].include?(role)
    when 'Contacts' then [ROLE[:admin], 'Super Admin'].include?(role)
    when 'Manage Leave' then [ROLE[:admin], 'Super Admin', ROLE[:HR]].include?(role)
    when 'Assessments' then ROLE.except(:consultant).values.include?(role) || applicable_consultants
    when 'Repositories' then [ROLE[:admin], ROLE[:manager], ROLE[:employee], ROLE[:intern]].include?(role)
    when 'Timesheets' then [ROLE[:admin], ROLE[:manager], ROLE[:finance], ROLE[:HR]].include?(role)
    end
  end

  def applicable_consultants
    ENV['APPLICABLE_CONSULTANTS'].include?(current_user.email)
  end
end
