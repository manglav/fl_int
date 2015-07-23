require 'sinatra'
require 'sequel'
require 'pry-byebug'
require 'multi_json'

db_path = 'postgres://gf8gtyxqredf9q6:zd6vgwc3i2zkpgs@hackday.czas5cnicq66.us-east-1.rds.amazonaws.com:5432/farmlogs_rtma_data'
DB = Sequel.connect(db_path)
hourly_data_tables = DB.tables.select{|table| table.to_s.start_with?("rtma_data")}


class HourlyDatum < Sequel::Model
  set_dataset hourly_data_tables.first
end

get '/data' do
  clean_params
  MultiJson.dump(params)
end

def clean_params
  whitelist_params
  cast_params
  validate_params
end

def whitelist_params
end

def cast_params
end

def validate_params
end

