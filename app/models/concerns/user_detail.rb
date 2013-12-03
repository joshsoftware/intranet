module UserDetail
  extend ActiveSupport::Concern
  
  included do
    field :dob_day, type: Integer
    field :dob_month, type: Integer   
    field :doj_day, type: Integer
    field :doj_month, type: Integer

    embeds_one :public_profile, cascade_callbacks: true
    embeds_one :private_profile, cascade_callbacks: true
    embeds_one :employee_detail, cascade_callbacks: true
     
    accepts_nested_attributes_for :private_profile, reject_if: :all_blank, allow_destroy: true 
    accepts_nested_attributes_for :public_profile, reject_if: :all_blank, allow_destroy: true
    accepts_nested_attributes_for :employee_detail, reject_if: :all_blank, :allow_destroy => true
  end
  
  module ClassMethods    
    def from_omniauth(auth)
      if auth.info.email.include? "joshsoftware.com"
        user = User.where(email: auth.info.email).first
        create_public_profile_if_not_present(user, auth)
        user
      else
        false
      end
    end

    def create_public_profile_if_not_present(user, auth)
      if user && !user.public_profile?
        user.build_public_profile(first_name: auth.info.first_name, last_name: auth.info.last_name).save
        user.update_attributes(provider: auth.provider, uid: auth.uid)
      end
    end

    def send_birthdays_wish
      user_ids = User.approved.where(dob_month: Date.today.month, dob_day: Date.today.day).map(&:id)
      UserMailer.birthday_wish(user_ids).deliver if user_ids.present?
    end

    def send_year_of_completion
      users = User.approved.where(doj_month: Date.today.month, doj_day: Date.today.day)
      user_ids = users.map(&:id)
      UserMailer.year_of_completion_wish(user_ids).deliver unless user_ids.blank?
    end
  end
end 
