require 'json'
require 'rest-client'

path = `sh tracelog #{ARGV[0]}`

hops = []

path.split("\n").each do |line|
  hop = {}
  vals = line.split(" ")
  hop[:radius] = 5 
  hop[:hostname] = vals[0]
  hop[:ip] = vals[1]
  if hop[:hostname] == "no" and hop[:ip] == "reply"
    hop[:latitude] = 0
    hop[:longitude] = 0
  else
    dets = JSON.parse(RestClient.get "http://freegeoip.net/json/#{hop[:ip]}")
    hop[:country] = dets["country_name"]
    hop[:region] = dets["region_name"]
    hop[:city] = dets["city"]
    hop[:latitude] = dets["latitude"]
    hop[:longitude] = dets["longitude"]
  end
  hops.push hop
end

last_hop = {}

last_latitude = nil
last_longitude = nil
scalar = 1

hops.each do |hop|

  if hop[:latitude] == last_latitude and hop[:longitude] == last_longitude
    # shift hop's longitude for rendering purposes
    last_latitude = hop[:latitude]
    last_longitude = hop[:longitude]
    hop[:longitude] += (2 * scalar)
    scalar += 1
  else
    last_latitude = hop[:latitude]
    last_longitude = hop[:longitude]
    scalar = 1
  end

  
  if hop == hops.first
    hop[:fillKey] = "host"
    hop[:radius] = 10
  elsif hop == hops.last
    hop[:radius] = 10
    hop[:fillKey] = "dest"
  else
    hop[:fillKey] = "hop"
  end
  last_hop = hop
end

arcs = []

hops.zip(hops[1..hops.length]).each do |arc|
  if arc[1] != nil
    arcs.push({:origin =>  {:latitude => arc[0][:latitude], :longitude => arc[0][:longitude]},
               :destination => {:latitude => arc[1][:latitude], :longitude => arc[1][:longitude]}})
  end   
end

puts "var bubbles = #{hops.to_json};"
puts "var arcs = #{arcs.to_json};"
