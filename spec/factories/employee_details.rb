FactoryGirl.define do
  factory :employee_detail do
    designation
    location { 'Pune' }
    available_leaves { 24 }
    notification_emails { ['hr@testcompany.com'] }
    skip_unassigned_project_ts_mail { false }
    source { 'Referred by Mick' }
    assessment_platform { 'Snowflake' }
    next_assessment_month { ['January', 'July'] }
  end
end
