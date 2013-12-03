class ResetLeaveYearlyWorker
  include Sidekiq::Worker
  sidekiq_options :backtrace => true

  def perform
    User.all.each do|u|
      if u.eligible_for_leave?  
        u.set_leave_details_per_year 
      end
    end
  end
end
