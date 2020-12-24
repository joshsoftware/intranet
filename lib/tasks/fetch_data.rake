namespace :fetch_data do
  desc 'Get email of employees who have empty attachment name or' +
       ' no document attached in attachments'
  task emp_with_nil_attachments: :environment do
    puts "Email\t Status\t Nil_Document_Count"
    User.each do |u|
      count = 0
      u.attachments.each do |a|
        count += 1 if a.name.nil? || a.name.empty? || a.document.nil?
      end
      puts "#{u.email}\t #{u.status}\t #{count}" if count > 0
    end
  end
end
