curl $JSONJAR_ROOT > /tmp/jsonjar.json
cat /tmp/jsonjar.json | ./jsonjar2mackerel.rb | logger -t myha2-jsonjar2mackerel
cat /tmp/jsonjar.json | ./led.rb              | logger -t myha2-led
