#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'base64'
require 'RMagick'
require 'json'

puts 'read settings...'

settings = JSON.parse(STDIN.read)
p settings
exit -1 if settings['sleep'] == '0'

puts 'captureing...'

image_list = Magick::ImageList.new
while true
  blob = `fswebcam --skip 10 --resolution 160x120 --png 0 --greyscale --no-banner --quiet -`
  redo if blob == ''

  img = Magick::Image.from_blob(blob).first
  img.delay = 25
  image_list.push img

  break if image_list.size >= 6
  sleep 30
end
image_list.iterations = 0
image_list = image_list.quantize(64)
image_list = image_list.optimize_layers(Magick::OptimizeLayer)
image_list = image_list.deconstruct
image_list.write('/var/tmp/webcam2vimage.gif') #XXX to_blob を呼ぶとクラッシュするのでtmpfsに書き出す

puts 'uploading...'

res = Net::HTTP.post_form(
  URI.parse("#{ENV['VIMAGE_ROOT']}images/new"),
  {
    title: Time.now.to_s,
    url: nil,
    tags: ['webcam2vimage'].join(' '),
    base64: Base64::encode64(open('/var/tmp/webcam2vimage.gif').read),
  }
)
p res
