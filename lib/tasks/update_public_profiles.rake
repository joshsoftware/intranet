namespace :update_public_profile_data do
  desc 'Update technical skills of all employees by mapping of '+
       'previous technical skills set to new technical skill set'
  task map_technical_skills: :environment do
    mapping_set = {
      'React' => 'ReactJs',
      'Rails' => 'Ruby',
      'ROR' => 'Ruby',
      'Django' => 'Python',
      'Laravel' => 'PHP',
      'Hibernet' => 'Java',
      'Spring Boot' => 'Java',
      'Design' => 'UI/UX',
      'UI' => 'UI/UX',
      'UX' => 'UI/UX'
    }

    puts 'Email  |  Previous Techincal Skills  |  Current Techincal Skills  |  Skills'
    User.employees.nin('public_profile.technical_skills': nil).each do |user|
      technical_skills = user.public_profile.technical_skills
      other_skills = user.public_profile.try(:skills)
      other_skills = other_skills.try(:downcase).try(:split, ', ') || []
      core_skills = technical_skills.map do |tech_skill|
        if mapping_set.key?(tech_skill)
          if !other_skills.include?(tech_skill.downcase) &&
             ['django', 'laravel', 'hibernet', 'spring boot'].include?(tech_skill.downcase)
            other_skills.append(tech_skill)
          end
          mapping_set[tech_skill]
        else
          tech_skill
        end
      end
      core_skills = core_skills.uniq
      other_skills = other_skills.join(', ').titleize
      if technical_skills != core_skills
        puts "#{user.email}  |  #{technical_skills}  |  #{core_skills}  |  #{other_skills}"
        user.public_profile.set(technical_skills: core_skills, skills: other_skills)
      end
    end
  end

  desc 'Move technical skills other than core technical skill set to skills of all employees'
  task move_other_skills: :environment do
    TECHNICAL_SKILLS_SET = LANGUAGE + FRAMEWORK + OTHER
    puts 'Email  |  Previous Techincal Skills  |  Current Techincal Skills  |  Current Skill'
    User.employees.nin('public_profile.technical_skills': nil).each do |user|
      technical_skills = user.public_profile.technical_skills
      skills = user.public_profile.skills.try(:split, ', ') || []
      other_skills = technical_skills - TECHNICAL_SKILLS_SET
      if other_skills.present?
        core_technical_skills = technical_skills & TECHNICAL_SKILLS_SET
        skills += other_skills
        puts "#{user.email}  |  #{technical_skills}  |  #{core_technical_skills}  |  #{skills}"
        user.public_profile.set(technical_skills: core_technical_skills, skills: skills.try(:join, ', '))
      end
    end
  end

  desc 'Update technical skills of all employees to have maximum 3 technical skills'
  task max_three_technical_skills: :environment do
    puts 'Email  |  Previous Techincal Skills  |  Current Techincal Skills  |  Current Skill'
    User.employees.where('public_profile.technical_skills.3' => { '$exists': true }).each do |user|
      technical_skills = user.public_profile.technical_skills
      skills = user.public_profile.skills.try(:split, ', ') || []
      skills += technical_skills[3..technical_skills.length]
      core_technical_skills = technical_skills[0..2]
      puts "#{user.email}  |  #{technical_skills}  |  #{core_technical_skills}  |  #{skills}"
      user.public_profile.set(technical_skills: core_technical_skills, skills: skills.try(:join, ', '))
    end
  end

  desc 'Update the Github and Twitter handle of all users'
  task update_public_profile: :environment do

    get_public_profile_details
    puts "\n Before Update"
    puts "\n Github: "
    puts "Handle count: #{@handle[:github]}"
    puts "URL count: #{@url[:github]}"

    puts "\n Twitter: "
    puts "Handle count: #{@handle[:twitter]}"
    puts "URL count: #{@url[:twitter]}"

    @github_users.each do |user|
      regex = /(?:https?:\/\/)?(?:www\.)?github\.com\/(?:#!\/)?@?([^\/\?\s]*)/
      url = user.public_profile.github_handle
      handle = url.match(regex)[1]
      user.public_profile.set(github_handle: handle)
    end

    @twitter_users.each do |user|
      regex = /(?:https?:\/\/)?(?:www\.)?twitter\.com\/(?:#!\/)?@?([^\/\?\s]*)/
      url = user.public_profile.twitter_handle
      handle = url.match(regex)[1]
      user.public_profile.set(twitter_handle: handle)
    end

    # remove '@' form users twitter handle
    User.all.each do |user|
      twitter = user.public_profile.twitter_handle
      if twitter.present? && twitter.starts_with?('@')
        twitter = twitter.sub('@', '')
        user.public_profile.set(twitter_handle: twitter)
      end
    end

    get_public_profile_details
    puts "\n After Update"
    puts "\n Github: "
    puts "Handle count: #{@handle[:github]}"
    puts "URL count: #{@url[:github]}"

    puts "\n Twitter: "
    puts "Handle count: #{@handle[:twitter]}"
    puts "URL count: #{@url[:twitter]}"
  end

  def get_public_profile_details
    @handle = { github: 0, twitter: 0 }
    @url = { github: 0, twitter: 0 }
    @github_users = []
    @twitter_users = []
    User.all.each do |user|
      github = user.public_profile.github_handle
      twitter = user.public_profile.twitter_handle
      if github.present?
        if github.include?('github')
          @url[:github] += 1
          @github_users << user
        else
          @handle[:github] += 1
        end
      end

      if twitter.present?
        if twitter.include?('twitter')
          @url[:twitter] += 1
          @twitter_users << user
        else
          @handle[:twitter] += 1
        end
      end
    end
  end
end
