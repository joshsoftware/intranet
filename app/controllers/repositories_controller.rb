class RepositoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_repository, only: [:repository_issues]
  @@snap_id = nil

  def overview_index
    @repositories = Repository.where(:name.nin => [nil, ''])
    if ['Employee', 'Intern'].include?(current_user.role)
      project_ids = current_user.project_ids
      @repositories = @repositories.where( project_id: { '$in': project_ids })
    end
  end

  def repository_issues
    url = "https://api.codeclimate.com/v1/repos/#{params[:repo_id]}"
    headers = { 'Accept' => 'application/vnd.api+json', 'Authorization' => "Token token=#{ENV['CODE_CLIMATE_TOKEN']}" }
    begin
      response = HTTParty.get(url, headers: headers, timeout: 20)
    rescue Timeout::Error => e
      puts "Error: Request Timeout for #{@repo.project.name}"
    end
    response = JSON.parse(response.body)['data']
    if response
      if response['attributes'] && response['attributes']['human_name']
        @repo_name = response['attributes']['human_name']
      end
      if response['relationships'] && response['relationships']['latest_default_branch_snapshot']
        @@snap_id = response['relationships']['latest_default_branch_snapshot']['data']['id']
      end
    end
    @response_body = params[:repo_id] ? get_issues : {}
  end

  def get_repo_issues
    offset = params['offset'].to_i || 0
    page = params['page']
    limit = params['limit']
    result = get_issues(page = page, limit)
    respond_to do |format|
      format.json { render json: result['data'] || {} }
    end
  end

  private

  # Recursive get_issues to fetch the paginated data from CodeClimate, where page[size] limit is 100.
  def get_issues(page = 1, limit = 100)
    query_string = "page[size]=#{limit}&page[number]=#{page}"
    url = "https://api.codeclimate.com/v1/repos/#{params[:repo_id]}/snapshots/#{@@snap_id}/issues?#{query_string}"
    headers = { 'Accept' => 'application/vnd.api+json', 'Authorization' => "Token token=#{ENV['CODE_CLIMATE_TOKEN']}" }
    begin
      response = HTTParty.get(url, headers: headers, timeout: 20)
    rescue Timeout::Error => e
      puts "Error: Request Timeout for  #{@repo.project.name}"
    end
    response = JSON.parse(response.body)
    if response && response['meta'] && response['meta']['current_page'] <= response['meta']['total_pages']
      return response
    else
      return {}
    end
  end

  def load_repository
    @repo = Repository.where(code_climate_id: params[:repo_id]).first
  end
end
