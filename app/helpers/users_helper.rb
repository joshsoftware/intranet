module UsersHelper

  # months to years calculation
  def convert_months_to_years_and_months(months)
    months = 0 unless months
    years = months / 12
    months = months.modulo(12)
    if years > 0 and months > 0
      "#{years} #{'Year'.pluralize(years)}, #{months} #{'Month'.pluralize(months)}"
    elsif years > 0
      "#{years} #{'Year'.pluralize(years)}"
    elsif months > 0
      "#{months} #{'Month'.pluralize(months)}"
    else
      "-"
    end
  end

  def current_org_experience(user)
    if user.private_profile.try(:date_of_joining).present?
      date_of_joining = user.private_profile.date_of_joining
      today  = Date.today
      # get number of completed months
      months = (today.year - date_of_joining.year) * 12
      # if current months is not completed then reduce by 1
      months += today.month - date_of_joining.month - (today.day >= date_of_joining.day ? 0 : 1)
      months
    end
  end
end
