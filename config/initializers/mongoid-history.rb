Mongoid::History.tracker_class_name = :history_tracker
Mongoid::History.current_user_method = :current_user
Rails.env == 'development' and require_dependency(Mongoid::History.tracker_class_name.to_s)
