class CodeClimateStatistic
  include Mongoid::Document
  include Mongoid::Timestamps

  field :snapshot_id,             type: String
  field :snapshot_created_at,     type: DateTime
  field :lines_of_code,           type: Integer
  field :total_issues,            type: Integer
  field :total_complexities,      type: Integer
  field :total_duplications,      type: Integer
  field :maintainability,         type: Float
  field :quality_gpa,             type: Float
  field :remediation_time,        type: Float
  field :implementation_time,     type: Float
  field :technical_debt_ratio,    type: Float
  field :test_report_id,          type: String
  field :test_report_received_at, type: DateTime
  field :test_coverage,           type: Float
  field :remarks,                 type: Array,   default: []

  belongs_to :repository
end
