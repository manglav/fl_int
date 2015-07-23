ENV['RACK_ENV'] = 'test'

require './first.rb'
require 'rspec'
require 'rack/test'

describe 'The FarmLogs App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe '#parse_and_validate_dates' do
    it "doesn't allow an end date before a start date"
    it "doesn't allow a start date before 2014-01"
    it "doesn't allow an end date after today"
  end

  describe '#sharded_table_names_for_query' do
    it "returns the sharded table names for a given date range"
  end

  describe '#calc_GDD' do
    it "calculates the growing degree day for an array of hourly temperatures"
  end

  describe '#bound' do
    it "bounds a value between an lower and upper min/max"
  end

  describe '#single_table_query' do
    it "queries a table for the temperatures given a grid_id, and date bounds"
  end

  describe '#group_by_date' do
    it "iterates over the row(hash) and accumulates the temperature for each date"
  end

  describe '#format_data' do
    it 'groups the rows by dates, and collects the temperatures and calculates GDD'
  end

  it "fetches the data" do
    get '/data?grid_id=1908377&start-date=2014-12-01&end-date=2015-07-01'
    expect(last_response).to be_ok
  end
end
