# spec/support/vcr_setup.rb
require 'vcr'
VCR.configure do |c|
  #the directory where your cassettes will be saved
  c.allow_http_connections_when_no_cassette = true
  c.cassette_library_dir = 'vcr_cassettes'
  # your HTTP request service. You can also use fakeweb, webmock, and more
  c.hook_into :webmock
end