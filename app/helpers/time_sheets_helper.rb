module TimeSheetsHelper
  def project_names
    project_names = []
    @user.project_details.each { |i| project_names << i[:name] }
    project_names
  end

  def project_data
    @user.project_details
  end
end
