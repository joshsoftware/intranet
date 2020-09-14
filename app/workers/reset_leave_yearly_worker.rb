class ResetLeaveYearlyWorker
  include Sidekiq::Worker
  sidekiq_options :backtrace => true

  def get_new_year_applied_leaves(start_date, end_date)
    if start_date.year != Date.today.year
      start_date = Date.today.beginning_of_year     #start_date will be 1st JAN of new year
    end
    new_year_applied_leaves = HolidayList.number_of_working_days(start_date, end_date)
  end

  def perform
    # mapping number of leaves to user which is not rejected for this new year
    user_applied_leaves = {}
    start_of_year = Date.today.beginning_of_year
    end_of_year = Date.today.end_of_year

    LeaveApplication.unrejected.where(:end_at => start_of_year..end_of_year).each do |leave_application|
      user_id = leave_application.user_id
      start_at = leave_application.start_at
      end_at = leave_application.end_at

      new_year_applied_leaves = get_new_year_applied_leaves(start_at, end_at)

      if user_applied_leaves.key?(user_id)
        user_applied_leaves[user_id] += new_year_applied_leaves
      else
        user_applied_leaves[user_id] = new_year_applied_leaves
      end
    end

    User.approved.each do|u|
      if u.eligible_for_leave?
        if user_applied_leaves.key?(u.id)
          u.set_leave_details_per_year(user_applied_leaves[u.id])
        else
          u.set_leave_details_per_year
        end
      end
    end
  end
end
