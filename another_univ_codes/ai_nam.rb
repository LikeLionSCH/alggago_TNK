require "xmlrpc/server"
require "socket"
require "matrix"

s = XMLRPC::Server.new(ARGV[0])
MAX_NUMBER = 16000

class MyAlggago
  def calculate(positions)

    #Codes here
    my_position = positions[0]
    your_position = positions[1]

    x_length = MAX_NUMBER
    y_length = MAX_NUMBER

    weight_list = calculate_weight_list(your_position)
    targeted_index = weight_list.index(weight_list.max)
    targeted_stone = your_position[targeted_index]

    shooting_index = select_shooting_index(my_position, targeted_stone)
    shooting_stone = my_position[shooting_index]

    while targeted_stone != obstacle(shooting_stone, targeted_stone, your_position) do
      targeted_stone = obstacle(shooting_stone, targeted_stone, your_position)
    end

    x_length = targeted_stone[0] - shooting_stone[0]
    y_length = targeted_stone[1] - shooting_stone[1]

    #Return values
    message = positions.size
    stone_x_strength = if distance(targeted_stone, shooting_stone) < 300 then x_length * 50 else x_length * 5 end
    stone_y_strength = if distance(targeted_stone, shooting_stone) < 300 then y_length * 50 else y_length * 5 end
    return [shooting_index, stone_x_strength, stone_y_strength, message]

  end

  def get_name
    "Call me just NAM"
  end

  def calculate_weight_list(your_position)
    result = []
    your_position.each do |p|
      weight = 0
      your_position.each do |pp|
        if p != pp 
          weight += 1/distance(p, pp)
        end
      end
      result.push(weight)
    end

    return result
  end

  def select_shooting_index(my_position, targeted_stone)
    result = 0
    my_position.each_with_index do |p,i|
      if distance(my_position[result], targeted_stone) > distance(p, targeted_stone)
        result = i
      end
    end

    return result
  end

  def distance(p1, p2)
    return Math.sqrt((p1[0]-p2[0])**2 + (p1[1]-p2[1])**2)
  end

  def obstacle(shooting_stone, targeted_stone, your_position)
    your_position.each do |p|
      if is_obstacle(shooting_stone, targeted_stone, p)
        return p
      end
    end

    return targeted_stone
  end

  def is_obstacle(shooting_stone, targeted_stone, obstacle_stone)
    if (targeted_stone == obstacle_stone) or (distance(shooting_stone, targeted_stone) < distance(shooting_stone, obstacle_stone)) or ((shooting_stone[0] < targeted_stone[0]) and (shooting_stone[0] > obstacle_stone[0])) or ((shooting_stone[0] > targeted_stone[0]) and (shooting_stone[0] < obstacle_stone[0]))
      return false
    end

    x_length = (shooting_stone[0] - targeted_stone[0]).abs
    y_length = (shooting_stone[1] - targeted_stone[1]).abs
    denominator = Math.sqrt(x_length**2 + y_length**2)

    det_ab = Matrix[shooting_stone, targeted_stone].determinant
    det_bc = Matrix[targeted_stone, obstacle_stone].determinant
    det_ca = Matrix[obstacle_stone, shooting_stone].determinant
    numerator = (det_ab + det_bc + det_ca).abs

    return 50 > numerator/denominator
  end
end

s.add_handler("alggago", MyAlggago.new)
s.serve