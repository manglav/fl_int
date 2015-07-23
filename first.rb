require 'sinatra/base'
require 'sinatra/param'
require 'sequel'
require 'pry-byebug'
require 'json'

db_path = 'postgres://gf8gtyxqredf9q6:zd6vgwc3i2zkpgs@hackday.czas5cnicq66.us-east-1.rds.amazonaws.com:5432/farmlogs_rtma_data'
DB = Sequel.connect(db_path)

class App < Sinatra::Base
  helpers Sinatra::Param

  before do
    content_type :json
  end

  hourly_data_tables = DB.tables.select{|table| table.to_s.start_with?("rtma_data")}.sort
  tables_str = hourly_data_tables.map(&:to_s)

  def validate_and_parse_dates
    params["start-date"] = Date.parse(params["start-date"])
    params["end-date"] = Date.parse(params["end-date"])
    # error conditions
    # start date must be before end date
    if params["end-date"] < params["start-date"]
      halt 400, "start date is after end date"
       # start date is
    elsif !(Date.parse("2014-12-01")..Date.today).include? params["start-date"]
      halt 400, "out of range"
    end
  end

  def get_indexes(start_date, end_date, tables)
    start_table = start_date.strftime("rtma_data_2_5k_hourly_y%Y_m%m")
    end_table = end_date.strftime("rtma_data_2_5k_hourly_y%Y_m%m")
    start_index = tables.index(start_table)
    end_index = tables.index(end_table)
    [start_index, end_index]
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


  get '/data' do
    param :grid_id, Integer, required: true
    param :'start-date', String, required: true, format: /\d\d\d\d-\d\d-\d\d/
    param :'end-date', String, required: true, format: /\d\d\d\d-\d\d-\d\d/

    validate_and_parse_dates

    start_table_index, end_table_index = get_indexes(params["start-date"], params["end-date"], tables_str)

    data = []

    hourly_data_tables[start_table_index..end_table_index].each do |table|

    data.concat(DB[table].
      select(:temp, :timestamp).
      where(grid_id: params["grid_id"]).
      where(timestamp: params["start-date"]..params["end-date"]).
      order(:timestamp).
      all)

    end

    final = {}

    data.each do |datum|
      date = datum[:timestamp].strftime('%F')
      arr = final[date] || []
      final[date] = arr.concat([datum[:temp]])
    end

    final.each do |k,v|
      final[k] = {gdd: calc_GDD(v)}
    end

    final.to_json
  end

  run! if app_file == $0
end


