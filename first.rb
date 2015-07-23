require 'sinatra/base'
require 'sinatra/param'
require 'sequel'
require 'pry-byebug'
require 'json'

db_path = 'postgres://gf8gtyxqredf9q6:zd6vgwc3i2zkpgs@hackday.czas5cnicq66.us-east-1.rds.amazonaws.com:5432/farmlogs_rtma_data'
DB = Sequel.connect(db_path)

class HourlyDatum < Sequel::Model
  hourly_data_tables = DB.tables.select{|table| table.to_s.start_with?("rtma_data")}
  set_dataset hourly_data_tables.last
end

class App < Sinatra::Base
  helpers Sinatra::Param

  before do
    content_type :json
  end

  def validate_and_parse_dates
    params["start-date"] = Date.parse(params["start-date"])
    params["end-date"] = Date.parse(params["end-date"])
    # validate dates later
  end

  def calc_GDD(temps)
    temps = temps.map {|x| x.to_f/100 }
    tbase = 30
    tmin = temps.min
    tmax = temps.max
    val = 0.5 * (bound(10, 30, tmin) + bound(10, 30, tmax)) - 30
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

    data = HourlyDatum.
      select(:temp, :timestamp).
      where(grid_id: params["grid_id"]).
      where(timestamp: params["start-date"]...params["end-date"]).
      order(:timestamp).
      all

    final = {}

    data.each do |datum|
      date = datum.timestamp.strftime('%F')
      arr = final[date] || []
      final[date] = arr.concat([datum.temp])
    end

    final.each do |k,v|
      final[k] = {gdd: calc_GDD(v)}
    end

    final.to_json
  end

  run! if app_file == $0
end


