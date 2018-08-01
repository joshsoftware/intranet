require 'rails_helper'

RSpec.describe SlackBot, type: :model do
  context 'show_projects' do
    it 'it should response true' do
      projects = ["tpn", "Dealsignal"]
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => projects
      }

      VCR.use_cassette 'success' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"),slack_params)
        resp = JSON.parse(response.body)
        expect(resp['ok']).to eq(true)
      end
    end

    context 'failure' do
      let!(:projects) { ["tpn", "Dealsignal"] }

      it 'it should response false because auth token invalid' do
        slack_params = {
          'token' => 'abcd.123',
          'channel' => CHANNEL_ID,
          'text' => projects
        }

        VCR.use_cassette 'failure_reason_token' do
          response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"),slack_params)
          resp = JSON.parse(response.body)
          expect(resp['ok']).to eq(false)
          expect(resp['error']).to eq('invalid_auth')
        end
      end

      it 'it should response false because channel id invalid' do
        slack_params = {
          'token' => SLACK_API_TOKEN,
          'channel' => 'abcd',
          'text' => projects
        }

        VCR.use_cassette 'failure_reason_channel' do
          response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"),slack_params)
          resp = JSON.parse(response.body)
          expect(resp['ok']).to eq(false)
          expect(resp['error']).to eq('channel_not_found')
        end
      end

      it 'it should response false because text is empty' do
        projects = []
        slack_params = {
          'token' => SLACK_API_TOKEN,
          'channel' => CHANNEL_ID,
          'text' => projects
        }

        VCR.use_cassette 'failure_reason_text' do
          response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"),slack_params)
          resp = JSON.parse(response.body)
          expect(resp['ok']).to eq(false)
          expect(resp['error']).to eq('no_text')
        end
      end
    end
  end
end
