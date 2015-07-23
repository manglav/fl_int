require 'sinatra'
require 'sequel'

db_path = 'postgres://gf8gtyxqredf9q6:zd6vgwc3i2zkpgs@hackday.czas5cnicq66.us-east-1.rds.amazonaws.com:5432/farmlogs_rtma_data'
DB = Sequel.connect(db_path)
DB[DB.tables.first]

get '/' do
  'Hello wofrlsd'
end
