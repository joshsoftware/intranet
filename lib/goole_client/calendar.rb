require 'google/api_client'
require 'date'
require 'openssl'
class GoogleClient
  def self.connect
    account_email = '663367146304-kcdkinutmtcln66r67qm2db7qj5h10na@developer.gserviceaccount.com' 
    key_file = "#{Dir.pwd}/privatekey.p12"
    key_secret = 'notasecret' 
    client = Google::APIClient.new()

    key = Google::APIClient::KeyUtils.load_from_pkcs12(key_file, key_secret)

    client.authorization = Signet::OAuth2::Client.new(
      :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
      :audience => 'https://accounts.google.com/o/oauth2/token',
      :scope => 'https://www.googleapis.com/auth/calendar',
      :issuer => account_email,
      :signing_key => key)

# # Request a token for our service account
    
    @event = {
    'summary' => 'Pramod BirthDay',
    'location' => 'Pune DanceBar',
     'description' => 'desc',
    'start' => {
      'dateTime' => DateTime.now # Date with :- offset so (yyyy-mm-dd T hh:mm:ss.000-offset)
    },
    'end' => {
      'dateTime' => DateTime.now + 2.hour # Date with :- offset so (yyyy-mm-dd T hh:mm:ss.000-offset)
    }
  }    

    client.authorization.fetch_access_token!
    service = client.discovered_api('calendar', 'v3')
    result = client.execute(api_method: service.events.insert, 
                   parameters: {'calendarId' => 'primary'},
                   body: JSON.dump(@event),
                   :headers => {'Content-Type' => 'application/json'})
  end 
end 
GoogleClient.connect
