require 'sinatra/base'
require 'sinatra/param'
require 'sequel'
require 'pry-byebug'
require 'json'

db_path = 'postgres://gf8gtyxqredf9q6:zd6vgwc3i2zkpgs@hackday.czas5cnicq66.us-east-1.rds.amazonaws.com:5432/farmlogs_rtma_data'
DB = Sequel.connect(db_path)

class App < Sinatra::Base
  SHARDED_TABLES = DB.tables.select{|table| table.to_s.start_with?("rtma_data")}.sort
  SHARDED_TABLES_STR = SHARDED_TABLES.map(&:to_s)

  helpers Sinatra::Param

  before do
    content_type :json
  end

  def parse_and_validate_dates
    params["start-date"] = Date.parse(params["start-date"])
    params["end-date"] = Date.parse(params["end-date"])
    # error conditions
    # start date must be before end date
    if params["end-date"] < params["start-date"]
      halt 400, "start date is after end date"
       # start date is out of range
    elsif !(Date.parse("2014-12-01")..Date.today).include? params["start-date"]
      halt 400, "start date out of range"
    elsif params["end-date"] > Date.today
      halt 400, "end date out of range"
    end
  end

  def sharded_table_names_for_query(start_date, end_date, )
    start_table = start_date.strftime("rtma_data_2_5k_hourly_y%Y_m%m")
    end_table = end_date.strftime("rtma_data_2_5k_hourly_y%Y_m%m")
    start_index = SHARDED_TABLES_STR.index(start_table)
    end_index = SHARDED_TABLES_STR.index(end_table)
    SHARDED_TABLES[start_index..end_index]
  end

  def calc_GDD(temps)
    temps = temps.map {|x| x.to_f/100 }
    tbase = 10
    tmin = temps.min
    tmax = temps.max
    val = 0.5 * (bound(10, 30, tmin) + bound(10, 30, tmax)) - tbase
    val.round(2)
  end

  def bound(lower, upper, val)
    case
    when val < lower
      lower
    when (lower..upper)
      val
    when val > upper
      upper
    end
  end

  def single_table_query(table, grid_id, start_date, end_date)
    DB[table].
      select(:temp, :timestamp).
      where(grid_id: grid_id).
      where(timestamp: start_date..end_date).
      order(:timestamp).
      all
  end

  def format_data(rows)
    dates_with_temps = {}

    rows.each do |row|
      date = row[:timestamp].strftime('%F')
      temps = dates_with_temps[date] || []
      dates_with_temps[date] = temps.concat([row[:temp]])
    end

    dates_with_temps.each do |date,temps|
      dates_with_temps[date] = {gdd: calc_GDD(temps)}
    end

    dates_with_temps.to_json
  end

  get '/data' do
    # validate params
    param :grid_id, Integer, required: true
    param :'start-date', String, required: true, format: /\d\d\d\d-\d\d-\d\d/
    param :'end-date', String, required: true, format: /\d\d\d\d-\d\d-\d\d/

    parse_and_validate_dates

    # fetch data from tables, sharded
    rows = sharded_table_names_for_query.inject([]) do |sum, table|
      sum + single_table_query(
          table,
          params["grid_id"],
          params["start-date"],
          params["end-date"])
    end

    # format data
    format_data(rows)
  end

  run! if app_file == $0
end


