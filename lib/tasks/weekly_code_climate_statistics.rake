desc 'Fetches & loads weekly CodeClimate Statistics for each repository'
task :weekly_codeclimate_statistics => :environment do
  project_ids = Project.all_active.pluck(:id)
  Repository.where(:project_id.in => project_ids).map do |repo|
    @repo_name = repo.name
    @project_name = repo.project.name
    @stat = repo.code_climate_statistics.new
    if repo.code_climate_id.present?
      @repo_url = "https://api.codeclimate.com/v1/repos/#{repo.code_climate_id}"
      repo_response = make_call(@repo_url)
      if repo_response && repo_response.success?
        @time_interval = Time.current.beginning_of_week..Time.current
        repo_details = JSON.parse(repo_response.body)
        latest_snapshot =
          repo_details['data']['relationships']['latest_default_branch_snapshot']['data']
        latest_snapshot_id = latest_snapshot && latest_snapshot['id']
        set_snapshot_details(latest_snapshot_id)
        latest_test_report =
          repo_details['data']['relationships']['latest_default_branch_test_report']['data']
        latest_test_report_id = latest_test_report && latest_test_report['id']
        set_test_report_details(latest_test_report_id)
      else
        @stat.remarks <<
          "Failed to retreive repository details for #{@project_name}'s #{@repo_name}."
      end
    else
      @stat.remarks <<
        "No code climate repo Id found for #{@project_name}'s #{@repo_name}."
    end
    @stat.save
  end;nil
end

def make_call(url)
  headers = {
    'Accept' => 'application/vnd.api+json',
    'Authorization' => "Token token=#{ENV['CODE_CLIMATE_TOKEN']}"
  }

  begin
    HTTParty.get(url, headers: headers, timeout: 20)
  rescue Timeout::Error => e
    @stat.remarks << "Error: Request Timeout for #{@project_name}'s #{@repo_name}"
    false
  end
end

def set_snapshot_details(id)
  if id.present?
    url = "#{@repo_url}/snapshots/#{id}"
    response = make_call(url)
    if response && response.success?
      details = JSON.parse(response.body)
      timestamp = details['data']['attributes']['created_at']
      created_at = DateTime.parse(timestamp)
      if @time_interval.cover? created_at
        @stat.snapshot_id = id
        @stat.snapshot_created_at = created_at
        @stat.lines_of_code = details['data']['attributes']['lines_of_code']
        @stat.total_issues = details['data']['meta']['issues_count']
        @stat.technical_debt_ratio =
          details['data']['meta']['measures']['technical_debt_ratio']['value']
        ratings = details['data']['attributes']['ratings']
        ratings.each do |rating|
          if rating['pillar'] == 'Maintainability'
            @stat.maintainability = rating['measure']['value']
            @stat.remediation_time =
              rating['measure']['meta']['remediation_time']['value']
            @stat.implementation_time =
              rating['measure']['meta']['implementation_time']['value']
          end
        end
        set_filtered_issue_details(url)
        @stat.remarks << "Successfully captured snapshot details for #{@project_name}'s #{@repo_name}."
      else
        @stat.remarks <<
          "No snapshot captured on default branch of #{@project_name}'s #{@repo_name} in time interval."
      end
    else
      @stat.remarks <<
        "Failed to retreive latest snapshot details for #{@project_name}'s #{@repo_name}."
    end
  else
    @stat.remarks <<
      "Failed to retreive latest snapshot Id for #{@project_name}'s #{@repo_name}."
  end
end

def set_filtered_issue_details(snapshot_url)
  issues_url = "#{snapshot_url}/issues"

  complexity_issues_url = "#{issues_url}?filter[categories]=Complexity"
  complexity_issues_response = make_call(complexity_issues_url)
  if complexity_issues_response && complexity_issues_response.success?
    complexity_issue_details = JSON.parse(complexity_issues_response.body)
    @stat.total_complexities = complexity_issue_details['meta']['total_count']
  end

  duplication_issues_url = "#{issues_url}?filter[categories]=Duplication"
  duplication_issues_response = make_call(duplication_issues_url)
  if duplication_issues_response && duplication_issues_response.success?
    duplication_issue_details = JSON.parse(duplication_issues_response.body)
    @stat.total_duplications = duplication_issue_details['meta']['total_count']
  end
end

def set_test_report_details(id)
  if id.present?
    url = "#{@repo_url}/test_reports/#{id}"
    response = make_call(url)
    if response && response.success?
      details = JSON.parse(response.body)
      timestamp = details['data']['attributes']['received_at']
      received_at = DateTime.parse(timestamp)
      if @time_interval.cover? received_at
        @stat.test_report_id = id
        @stat.test_report_received_at = received_at
        @stat.test_coverage = details['data']['attributes']['rating']['measure']['value']
        @stat.remarks << "Successfully captured test coverage for #{@project_name}'s #{@repo_name}."
      else
        @stat.remarks <<
          "No test report recieved on default branch of #{@project_name}'s #{@repo_name} in time interval."
      end
    else
      @stat.remarks <<
        "Failed to retreive latest test report details for #{@project_name}'s #{@repo_name}."
    end
  else
    @stat.remarks <<
      "Failed to retreive latest test coverage Id for #{@project_name}'s #{@repo_name}."
  end
end
