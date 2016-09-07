#!/usr/bin/env ruby

require 'json'

settings = JSON.parse(STDIN.read)
p settings

# Send to mackerel
epoch = Time.now.to_i
api_key = ENV['MACKEREL_API_KEY']
json = [
  {
    name: 'myself.sleep',
    time: epoch,
    value: settings['sleep'].to_i,
  },
  {
    name: 'myself.home',
    time: epoch,
    value: settings['home'].to_i,
  },
  {
    name: 'myself.time_to_sleep',
    time: epoch,
    value: settings['time_to_sleep'].to_i,
  },
  {
    name: 'aircon.on_cooler_27',
    time: epoch,
    value: settings['aircon_on_cooler_27'].to_i,
  },
  {
    name: 'aircon.on_heater_25',
    time: epoch,
    value: settings['aircon_on_heater_25'].to_i,
  },
]

# Calc for beacon1
temperature = settings['beacon1_temperature'].to_f
humidity = settings['beacon1_humidity'].to_f
discomfort_index = 0.81 * temperature + 0.01 * humidity * (0.99 * temperature - 14.3) + 46.3
json << {
    name: 'beacon1.temperature',
    time: epoch,
    value: temperature.round(1),
}
json << {
    name: 'beacon1.humidity',
    time: epoch,
    value: humidity.round(1),
}
json << {
    name: 'beacon1.discomfort_index',
    time: epoch,
    value: discomfort_index.round(1),
}

# Post to mackerel.io
p `curl https://mackerel.io/api/v0/services/myha2/tsdb -H 'X-Api-Key: #{api_key}' -H 'Content-Type: application/json' -X POST -d '#{json.to_json}'`
