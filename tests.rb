ENV['RACK_ENV'] = 'test'

require './first.rb'  # <-- your sinatra app
require 'rspec'
require 'rack/test'

describe 'The FarmLogs App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "fetches data" do
    get '/data'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('Hello World')
  end
end
