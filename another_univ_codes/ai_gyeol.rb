require "xmlrpc/server"
require "socket"

s = XMLRPC::Server.new(ARGV[0])
MAX_NUMBER = 16000

class MyAlggago
  def calculate(positions)

    # Write your own codes here
    my_position = positions[0]
    your_position = positions[1]
    your_position2 = positions[1]
    current_stone_number = 0
    index = 0
    
    
    min_length = MAX_NUMBER
    x_length = MAX_NUMBER
    y_length = MAX_NUMBER
    min2 = MAX_NUMBER

    near_stone_number_1 = 0
    near_stone_number_2 = 0
    near_stone_number = 0 



    # 가까운 상대 두알 찾기
    if your_position.count != 1
      your_position.each do |your1|
        your_position2.each do |your2|

          x_distance = (your1[0] - your2[0]).abs
          y_distance = (your1[1] - your2[1]).abs
          
          current_distance = Math.sqrt(x_distance * x_distance + y_distance * y_distance)

          if min2 > current_distance && current_distance > 0
            near_stone_number_1 = your1
            near_stone_number_2 = your2
            min2 = current_distance
            # x_length = your2[0] - your1[0]
            # y_length = your2[1] - your1[1]
          end
        end
      end
     
      my_position.each do |my|
        
        x_distance = (my[0] - near_stone_number_1[0]).abs
        y_distance = (my[1] - near_stone_number_1[1]).abs
        
        current_distance = Math.sqrt(x_distance * x_distance + y_distance * y_distance)
        
        x_distance = (my[0] - near_stone_number_2[0]).abs
        y_distance = (my[1] - near_stone_number_2[1]).abs 
        
        current_distance2 = Math.sqrt(x_distance * x_distance + y_distance * y_distance)
        if current_distance > current_distance2
          near_stone_number = near_stone_number_2
        else
          near_stone_number = near_stone_number_1
        end
        if min_length > current_distance
          current_stone_number = index
          min_length = current_distance
          x_length = near_stone_number[0] - my[0]
          y_length = near_stone_number[1] - my[1]
        end
        index = index +1
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



   
    # my_position.each do |my|
    #   your_position.each do |your|

    #     x_distance = (my[0] - your[0]).abs
    #     y_distance = (my[1] - your[1]).abs
        
    #     current_distance = Math.sqrt(x_distance * x_distance + y_distance * y_distance)

    #     if min_length > current_distance
    #       current_stone_number = index
    #       min_length = current_distance
    #       x_length = your[0] - my[0]
    #       y_length = your[1] - my[1]
    #     end
    #   end
    #   index = index + 1
    # end
    # End of codes

    # Return values
    message = get_name
    stone_number = current_stone_number
    stone_x_strength = x_length * 7
    stone_y_strength = y_length * 7
    return [stone_number, stone_x_strength, stone_y_strength, message]

  end

  def get_name
    "GYEOL AI!!!" # Set your name or team name
  end
end

s.add_handler("alggago", MyAlggago.new)
s.serve