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

  def get_next_year_leaves_count
    next_year_leaves = self.leave_applications.unrejected.where(
      :start_at.gte => Date.current.beginning_of_year.next_year
    )
    country = self.country
    next_year_leaves.each do |leave|
      leave_days = leave.number_of_days
      (leave.start_at..leave.end_at).each do |date|
        leave_days -= 1 if HolidayList.list(country).pluck(:holiday_date).include?(date)
      end
      leave.set(number_of_days: leave_days)
    end
    next_year_leaves.pluck(:number_of_days).sum
  end

  def set_leave_details_per_year
    leave_count = is_consultant? ? 0 : PER_MONTH_LEAVE*12
    leave_count = leave_count - get_next_year_leaves_count
    self.employee_detail.set(available_leaves: leave_count)
  end

  def eligible_for_leave?
    !!(self.private_profile.try(:date_of_joining).try(:present?) &&
    [ROLE[:admin], ROLE[:consultant], ROLE[:intern]].exclude?(self.role))
  end
end
