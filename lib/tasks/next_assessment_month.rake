require 'csv'

desc "store next_assessment_month in employee_detail.rb"
task :next_assessment_month, [:filename] => :environment do |t, args|
  csv = CSV.read(Rails.root.join("tmp/#{args[:filename]}"), skip_blanks: true)
  store_employee_next_assessment_month(csv) if csv
end

def store_employee_next_assessment_month(csv)
  headers = csv[0]
  count_failed = count_passed = 0
  csv[1..-1].each do |row|
    employee_email = row[3].strip
    @employee = User.where(email: employee_email).first
    unless @employee.blank?
      first_month_from_csv = row[12].strip
      second_month_from_csv = row[13].strip
      assessment_platform = !row[8].nil? ? row[8].strip : 'None'

      emp_assmt_months = [first_month_from_csv.titlecase, second_month_from_csv.titlecase]
      @employee.employee_detail.update_attributes(next_assessment_month: emp_assmt_months, assessment_platform: assessment_platform)
      if @employee.save
        count_passed += 1
      end
      print "#{@employee.employee_detail.employee_id} for #{@employee.name}. \n"
      print "#{emp_assmt_months} for #{@employee.name}. \n"
      print "#{assessment_platform} for #{@employee.name}. \n"
      print "\n\n"
    else
      print "Employee with email:  #{employee_email} not found. \n"
      count_failed += 1
    end
  end
  puts "\n\nTotal entries = #{count_passed + count_failed}."
  puts "\nTotal entries updated successfully = #{count_passed}."
  puts "\nTotal entries failed = #{count_failed}."
end
