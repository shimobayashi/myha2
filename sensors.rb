#!/usr/bin/env ruby

require 'json'

bme280 = `python /home/pi/works/myha2/bme280.py`
bme280 = JSON.parse(bme280)
p bme280

temperature = bme280.find{|i| i['name'] == 'room.temperature'}['value']
humidity = bme280.find{|i| i['name'] == 'room.humidity'}['value']
p temperature, humidity
discomfort_index = 0.81 * temperature + 0.01 * humidity * (0.99 * temperature - 14.3) + 46.3
p discomfort_index

# Post to mackerel
epoch = Time.now.to_i
api_key = ENV['MACKEREL_API_KEY']
json = bme280.clone
json << {
  name: 'room.discomfort_index',
  time: epoch,
  value: discomfort_index,
}
p json.to_json
p `curl https://mackerel.io/api/v0/services/myha2/tsdb -H 'X-Api-Key: #{api_key}' -H 'Content-Type: application/json' -X POST -d '#{json.to_json.to_s}'`

# Post to jsonjar
p `curl #{ENV['JSONJAR_ROOT']}?discomfort_index=#{discomfort_index}`
