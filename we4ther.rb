require 'sinatra'
require 'geoip'
require 'nokogiri'
require 'open-uri'
require 'uri'
set :bind, '127.0.0.1'
enable :dump_errors, :logging
$HEADER = "<!DOCTYPE HTML>
<html>
<head>
  <title>WE4THER.COM - undetermined location</title>
  <style type=\"text/css\">
    body {
      font-family: \"HelveticaNeue-Light\", \"Helvetica Neue Light\", \"Helvetica Neue\", Helvetica, Arial, \"Lucida Grande\", sans-serif;
      font-weight: 300;
      color: white;
      background-color: #646D7E;
    }
  </style>
</head>
<body>"

$FOOTER ="<br />
<br />
<small>
  Your URL bar is where the search is; try http://we4ther.com/some other location or zip or airport code
</small>
<!-- simple is beautiful -->
</body>
</html>"
	
def get_weather(some_location)
    @location = URI.escape(some_location)
    @doc = Nokogiri::XML(open("http://api.wunderground.com/auto/wui/geo/ForecastXML/index.xml?query=#{@location}"))
    @doc.xpath('/forecast/moon_phase').each do |node|
        moon = node.xpath('percentIlluminated').text
        timehour = node.xpath('current_time/hour').text
        timeminute = node.xpath('current_time/minute').text
        sunsethour = node.xpath('sunset/hour').text
        sunsetminute = node.xpath('sunset/minute').text
        sunrisehour = node.xpath('sunrise/hour').text
        sunriseminute = node.xpath('sunrise/minute').text

        @html = $HEADER.sub('undetermined location', some_location) # replace the page title from the template with the real title
=begin rant
I know, I know, I could just use a templating system. This works great for what I need it to do and it's fast and simple with few moving parts.
Fork it and implement a real templating system if that will make you happy, but it's not in line with this project ideologically.
=end rant
        @html += "<h1>Location: #{some_location}</h1>
            <ul><li>Sunrise: #{sunrisehour}:#{sunriseminute}</li>
            <li>Sunset: #{sunsethour}:#{sunsetminute}</li>
            <li>Moon visible: #{moon}%</li></ul>"
    end # moon phase stuff

    @doc.xpath('/forecast/txt_forecast').each do |node|
        currentconditions = node.xpath('forecastday/fcttext').first.text
        periodtitle = node.xpath('forecastday/title').first.text
        time = node.xpath('date').text
        @html += "<p>
            Current conditions for [the] #{periodtitle} as of #{time}:
            #{currentconditions}</p>
            <h2>Forecast:</h2><ul>"
    end # forecast text stuff

    @doc.xpath('/forecast/simpleforecast/forecastday').each do |node|
        nodeid = node.xpath('period').text
        date = node.xpath('date/pretty').text
        dayname = node.xpath('date/weekday').text
        conditions = node.xpath('conditions').text
        high = node.xpath('high/fahrenheit').text
        low = node.xpath('low/fahrenheit').text
        pop = node.xpath('pop').text
        @html += "<li>#{dayname} - #{conditions} - #{low}F to #{high}F - #{pop}% chance of rain</li>"
    end # forecast day stuff

    @html += "</ul>"
    @html += $FOOTER
    return @html
end # get_weather function

geo = GeoIP.new('GeoLiteCity.dat')

get '/google139019d784e94fcc.html' do
    return "google-site-verification: google139019d784e94fcc.html"
end # get google site verification

get '/robots.txt' do
    return "User-agent: *
            Allow: /"
end # get robots.txt

get '/' do
    begin
        x = geo.country request.ip
        puts "GeoIP said that #{request.ip} is #{x.inspect}"
        if x[:city_name].empty? # when we can't look up your ZIP
            html = $HEADER
            html += "Where is #{request.ip}?  I don't even know."
            html += $FOOTER
            return html
        else
            return get_weather("#{x[:city_name]}, #{x[:region_name]}")
        end # if postal_code.empty?
    rescue # when the wunderground API returns an error
        html = $HEADER
        html += "Maybe Wunderground just doesn't like you, or has something against #{request.ip}, but in any case I can't find you automagically, and I bet it's your fault."
        html += $FOOTER
        return html
    end # error trap
end # get /

get '/:location' do
    begin
        parsed_location = URI.decode(params[:location])
        return get_weather(parsed_location)
    rescue # when the wunderground API returns an error
        html = $HEADER
        html += "No one here knows where #{parsed_location} is, so I can't look that up."
        html += $FOOTER
        return html
    end # error trap
end # get /:location

