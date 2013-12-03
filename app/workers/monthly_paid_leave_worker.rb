class MonthlyPaidLeaveWorker
  include Sidekiq::Worker
  sidekiq_options :backtrace => true

  def perform
    User.all.each do|u|
      if u.eligible_for_leave?  
        u.assign_monthly_leave 
      end
    end 
  end
end
