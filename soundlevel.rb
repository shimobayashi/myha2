#!/usr/bin/env ruby

require 'wav-file'
require 'json'

p `arecord -D plughw:1,0 /tmp/record.wav -f S16_LE -r 8000 -c 1 -d 60`
f = open('/tmp/record.wav')

format = WavFile::readFormat(f)
dataChunk = WavFile::readDataChunk(f)
f.close
puts format

bit = 's*' if format.bitPerSample == 16 # int16_t
bit = 'c*' if format.bitPerSample == 8 # signed char
wavs = dataChunk.data.unpack(bit) # read binary
wavs_sorted = wavs.sort

values = {}
values['max'] = wavs_sorted.max
values['99'] = wavs_sorted[(wavs_sorted.size * 0.99).to_i]
values['95'] = wavs_sorted[(wavs_sorted.size * 0.95).to_i]
values['90'] = wavs_sorted[(wavs_sorted.size * 0.90).to_i]
values['80'] = wavs_sorted[(wavs_sorted.size * 0.80).to_i]
p values

# Post to mackerel
epoch = Time.now.to_i
api_key = ENV['MACKEREL_API_KEY']
json = []
values.each {|key, value|
  json << {
    name: "test.sound_level.#{key}",
    time: epoch,
    value: value,
  }
}
p json.to_json
p `curl https://mackerel.io/api/v0/services/myha2/tsdb -H 'X-Api-Key: #{api_key}' -H 'Content-Type: application/json' -X POST -d '#{json.to_json.to_s}'`
