require 'rails_helper'

RSpec.describe TimeSheet, type: :model do
  context 'Validation' do
    let!(:user) { FactoryGirl.create(:user) }
    # let!(:user) { user.projects.create(:project)}
    let!(:time_sheet) { FactoryGirl.build(:time_sheet) }

    before do
      user.public_profile.slack_handle = USER_ID
      user.projects.create(name: 'England Hockey', display_name: 'England_Hockey')
      user.save
      stub_request(:post, "https://slack.com/api/chat.postMessage")
    end

    it 'Should success' do
      params = {
        'user_id' => USER_ID, 
        'channel_id' => CHANNEL_ID, 
        'text' => "England_Hockey #{Date.yesterday}  6 7 abcd efghigk lmnop"
      }

      ret = time_sheet.parse_timesheet_data(params)
      expect(ret[0]).to eq(true)
    end

    it 'Should success even if project name is lower case' do
      params = {
        'user_id' => USER_ID,
        'channel_id' => CHANNEL_ID,
        'text' => "england_hockey #{Date.yesterday}  6 7 abcd efghigk lmnop"
      }

      ret = time_sheet.parse_timesheet_data(params)
      expect(ret[0]).to eq(true)
    end

    it 'Should fails because record is already present' do
      time_sheet = FactoryGirl.create(:time_sheet)
      time_sheet_test = FactoryGirl.build(:time_sheet)
      time_sheet_test.save
      expect(time_sheet_test.errors.full_messages).to eq(["From time record is already present", "To time record is already present"])
    end

    it 'Should return false because invalid timesheet command format' do
      params = {
        'user_id' => USER_ID, 
        'channel_id' => CHANNEL_ID, 
        'text' => 'England_Hockey 22-07-2018  6'
      }

      expect(time_sheet.parse_timesheet_data(params)).to eq(false)
    end

    it 'Should return false because user does not assign to this project' do
      params = {
        'user_id' => USER_ID, 
        'channel_id' => CHANNEL_ID,
        'text' => 'England 14-07-2018  6 7 abcd efgh'
      }
      expect(time_sheet.parse_timesheet_data(params)).to eq(false)
    end

    context 'Validation - date' do
      it 'Should return false because invalid date format' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => 'England_Hockey 14-2018  6 7 abcd efgh'
        }
        expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      end

      it 'Should return false because date is not within this week' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => 'England_Hockey 1/07/2018  6 7 abcd efgh'
        }
        expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      end

      it 'Should return false because date is invalid' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => 'England_Hockey 1/32/2018  6 7 abcd efgh'
        }
        expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      end

      it 'Should return false because date and time is greater than current date and time' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => "England_Hockey #{Date.today}  20:00 20:30 abcd efgh"
        }

        expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      end
    end

    context 'Validation - Time' do
      it 'Should return false because invalid from time format' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => "England_Hockey #{Date.yesterday} 15.30 16 abcd efgh"
        }
        expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      end

      it 'Should return false because invalid to time format' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => "England_Hockey #{Date.yesterday} 6 7.00 abcd efgh"
        }
        expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      end

      it 'Should return false because from time is greater than to time' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => "England_Hockey #{Date.yesterday} 8 7 abcd efgh"
        }
        expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      end
    end
  end

  context 'Api test' do
    it 'Invalid time sheet format : Should return true ' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => "\`Error :: Invalid timesheet format. Fromat should be <project_name> <date> <from_time> <to_time> <description>\`"
      }
      VCR.use_cassette 'timesheet_failure_reason_invalid_date' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        ret = JSON.parse(response.body)
        expect(ret['ok']).to eq(true)
      end
    end

    it 'Not assigned project : Should return true' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => "\`Error :: you are not working on this project. Use /projects command to view your project\`"
      }
      VCR.use_cassette 'timesheet_failure_reason_not_assign_project' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        ret = JSON.parse(response.body)
        expect(ret['ok']).to eq(true)
      end
    end

    it 'Invalid date format : Should return true' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => "\`Error :: Invalid date format. Format should be dd/mm/yyyy\`"
      }
      VCR.use_cassette 'timesheet_failure_reason_invalid_date_format' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        ret = JSON.parse(response.body)
        expect(ret['ok']).to eq(true)
      end
    end

    it 'Date range : Should return true' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => "\`Error :: Date should be in last week\`"
      }
      VCR.use_cassette 'timesheet_failure_reason__date_in_last_week' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        ret = JSON.parse(response.body)
        expect(ret['ok']).to eq(true)
      end
    end

    it 'Date range : Should return true' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => "\`Error :: Date should be in last week\`"
      }
      VCR.use_cassette 'timesheet_failure_reason__date_in_last_week' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        ret = JSON.parse(response.body)
        expect(ret['ok']).to eq(true)
      end
    end

    it 'From time should be less than to time : Should return true' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => "\`Error :: From time must be less than to time\`"
      }
      VCR.use_cassette 'timesheet_failure_reason__from_time_is_less' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        ret = JSON.parse(response.body)
        expect(ret['ok']).to eq(true)
      end
    end

    it 'From time should be less than to time : Should return true' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => "\`Error :: From time must be less than to time\`"
      }
      VCR.use_cassette 'timesheet_failure_reason__from_time_is_less' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        ret = JSON.parse(response.body)
        expect(ret['ok']).to eq(true)
      end
    end

    it 'Invalid time format : Should return true' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => "\`Error :: Invalid time format. Format should be HH:MM:SS\`"
      }
      VCR.use_cassette 'timesheet_failure_reason__invalid_time' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        ret = JSON.parse(response.body)
        expect(ret['ok']).to eq(true)
      end
    end

    it 'Record is already present : should return true' do
      text = "\` Error :: From time record is already present, To time record is already present\`"
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => text
      }
      VCR.use_cassette 'timesheet_failure_reason_record_already_present' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        ret = JSON.parse(response.body)
        expect(ret['ok']).to eq(true)
      end
    end

    it 'Should return false because invalid slack token' do
      slack_params = {
        'token' => 'abcd.efghi.gklmno',
        'channel' => CHANNEL_ID,
        'text' => "\`Error :: Invalid time format\`"
      }
      VCR.use_cassette 'timesheet_failure_reason_invalid_slack_token' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        resp = JSON.parse(response.body)
        expect(resp['ok']).to eq(false)
        expect(resp['error']).to eq('invalid_auth')
      end
    end

    it 'Should return false because invalid channel id' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => 'UU12345',
        'text' => "\`Error :: Channel not found\`"
      }
      VCR.use_cassette 'timesheet_failure_reason_invalid_channel_id' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        resp = JSON.parse(response.body)
        expect(resp['ok']).to eq(false)
        expect(resp['error']).to eq('channel_not_found')
      end
    end

    it 'Should return false because text is empty' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => ""
      }
      VCR.use_cassette 'timesheet_failure_reason_empty_text' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        resp = JSON.parse(response.body)
        expect(resp['ok']).to eq(false)
        expect(resp['error']).to eq('no_text')
      end
    end
  end
end
