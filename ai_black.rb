require "xmlrpc/server"
require "socket"
require 'json'

s = XMLRPC::Server.new(ARGV[0])
MAX_NUMBER = 16000

class MyAlggago
  def calculate(positions)

    params = ""

    params += " #{positions[0].count}"
    params += " #{positions[1].count}"

    positions[0].each do |coord|
      params += " #{coord}"
    end

    positions[1].each do |coord|
      params += " #{coord}"
    end

    count = 0
    my_position_hash = {}
    positions[0].each do |coord|
      my_position_hash[count] = coord
      count += 1
    end

    count = 0
    your_position_hash = {}
    positions[1].each do |coord|
      your_position_hash[count] = coord
      count += 1
    end

    tempHash = {
        "my_position" => my_position_hash,
        "your_position" => your_position_hash
    }

    File.open("temp.json","w") do |f|
      f.write(JSON.pretty_generate(tempHash))
    end

    result_from_python = `python py_ai_sample.py`

    results = result_from_python.split(",")

    return [results[0].to_i, results[1].to_f, results[2].to_f, results.to_s]

  end

  def get_name
    "MY AI!!!"
  end
end

s.add_handler("alggago", MyAlggago.new)
s.serve
