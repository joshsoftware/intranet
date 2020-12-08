# run - rake update_relieving_date['file_path']
desc 'Update employees relieving dates'
task :update_relieving_date, [:location] => [:environment] do |task, args|
  csv_data = CSV.read(args.location, headers: true)
  puts "\t Email \t Previous DOR \t Current DOR "
  csv_data.each do |row|
    user = User.find_by(email: row['Email'])
    if row['Date of Relieving'].present? && row['Role'] != 'Intern'
      print " #{user.email} \t #{user.employee_detail.date_of_relieving || 'nil'} \t "
      date = row['Date of Relieving'].to_date
      user.employee_detail.set(date_of_relieving: date)
      print "#{user.employee_detail.date_of_relieving} \n"
    elsif row['Date of Relieving'].nil? && row['Role'] == 'Need to delete account'
      puts "Email - #{user.email} deleted account"
      user.delete
    end
  end
end
