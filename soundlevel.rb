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

value = wavs.max

# Post to mackerel
epoch = Time.now.to_i
api_key = ENV['MACKEREL_API_KEY']
json = [{
  name: 'room.raw_sound_level',
  time: epoch,
  value: value,
}]
p json.to_json
p `curl https://mackerel.io/api/v0/services/myha2/tsdb -H 'X-Api-Key: #{api_key}' -H 'Content-Type: application/json' -X POST -d '#{json.to_json.to_s}'`
