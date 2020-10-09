require "xmlrpc/server"
require "socket"

s = XMLRPC::Server.new(ARGV[0])
MAX_NUMBER = 16000

class MyAlggago
  def calculate(positions)

    #Codes here
    my_position = positions[0]
    your_position = positions[1]

    current_stone_number = 0
    index = 0
    min2_length = MAX_NUMBER
    min_length = MAX_NUMBER
    x_length = MAX_NUMBER
    y_length = MAX_NUMBER
    diff = MAX_NUMBER
    a = 0
    b = 0
    c = 0
    d = 0

    while a <= (your_position.count - 2)
      b=a+1
      while b <= (your_position.count - 1)
        diff = Math.sqrt((your_position[a][0] - your_position[b][0]) * (your_position[a][0] - your_position[b][0]) + (your_position[a][1] - your_position[b][1]) * (your_position[a][1] - your_position[b][1]))
        if min2_length > diff
          c = a
          d = b
          min2_length = diff
        end
        b = b+1
      end
      a = a + 1
    end

    avg_x = (your_position[c][0] + your_position[d][0]) / 2
    avg_y = (your_position[c][1] + your_position[d][1]) / 2
    
      
    if diff <= 123
      my_position.each do |my|
        x_distance = (my[0] - avg_x).abs
        y_distance = (my[1] - avg_y).abs
            
        current_distance = Math.sqrt(x_distance * x_distance + y_distance * y_distance)

        if min_length > current_distance
          current_stone_number = index
          min_length = current_distance
          x_length = avg_x - my[0]
          y_length = avg_y - my[1]
        end
          
        index = index + 1
      end
    else
      my_position.each do |my|
        your_position.each do |your|

          x_distance = (my[0] - your[0]).abs
          y_distance = (my[1] - your[1]).abs
        
          current_distance = Math.sqrt(x_distance * x_distance + y_distance * y_distance)

          if min_length > current_distance
            current_stone_number = index
            min_length = current_distance
            x_length = your[0] - my[0]
            y_length = your[1] - my[1]
          end
        end  
        index = index + 1
      end
    end
    
    #Return values
    message = positions.size
    stone_number = current_stone_number
    stone_x_strength = x_length * 5
    stone_y_strength = y_length * 5
    return [stone_number, stone_x_strength, stone_y_strength, message, c, d]

    #Codes end
  end

  def get_name
    "MY AI!!!"
  end
end

s.add_handler("alggago", MyAlggago.new)
s.serve