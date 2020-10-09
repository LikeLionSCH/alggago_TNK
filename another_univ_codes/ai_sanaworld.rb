require "xmlrpc/server"
require "socket"

s = XMLRPC::Server.new(ARGV[0])
MAX_NUMBER = 16000

class MyAlggago
  $gather_stone = Array.new #모여있는 돌 저장하기 위한 배열, 전역변수

  def calculate(positions)
    #Codes here
    my_position = positions[0]
    your_position = positions[1]

    current_stone_number = 0
    index = 0
    min_length = MAX_NUMBER
    x_length = MAX_NUMBER
    y_length = MAX_NUMBER

    three_cushion(positions) #three_cushion 메소드 수행 -> gather_stone의 개수 계산하고 다음 수행

    if $gather_stone.size >= 3
      #돌 치는 메소드
      my_position.each do |my|
        $gather_stone.each do |gather_your|

          x_distance = (my[0] - gather_your[0]).abs
          y_distance = (my[1] - gather_your[1]).abs

          current_distance = Math.sqrt(x_distance * x_distance + y_distance * y_distance)

          if min_length > current_distance
            current_stone_number = index
            min_length = current_distance
            x_length = gather_your[0] - my[0]
            y_length = gather_your[1] - my[1]
          end

        end
        index = index + 1
      end
    else
      #돌 치는 메소드
      my_position.each do |my|
        your_position.each do |your|

          x_distance = (my[0] - your[0]).abs
          y_distance = (my[1] - your[1]).abs

          current_distance = Math.sqrt(x_distance * x_distance + y_distance * y_distance)
          # 네구역으로 나뉘어 상대방돌을 맞추고 좀더 안쪽으로 움직이게끔치는코드
          if min_length > current_distance
            current_stone_number = index
            min_length = current_distance

            if your[0] > 350
              x_length = your[0]-10 - my[0]

              if your[1] > 350
                y_length = your[1]-10 - my[1]
              else
                y_length = your[1]+10 - my[1]
              end

            else
              x_length = your[0]+10 - my[0]

              if your[1] > 350
                y_length = your[1]-10 - my[1]
              else
                y_length = your[1]+10 - my[1]
              end

            end

          end
        end
        index = index + 1
      end

    end


    #Return values
    message = $gather_stone.count #positions.size #메시지 - 디버깅용 메시지입니다용
    stone_number = current_stone_number #움직일 돌
    stone_x_strength = x_length * 20
    stone_y_strength = y_length * 20
    return [stone_number, stone_x_strength, stone_y_strength, message]
    $gather_stone = $gather_stone.clear
    #Codes end
  end

  def three_cushion(positions)
    #모여있는 돌이 3개 이상일 때 계산하는 코드
    #gather_stone = Array.new
    your_position = positions[1]

    your1_index = 0
    your2_index = 0

    your_position.each do |your1|
      your_position.each do |your2|

        if your1_index != your2_index
          current_item = your1
          next_item = your2

          x_distance = (current_item[0] - next_item[0]).abs
          y_distance = (current_item[1] - next_item[1]).abs

          temp_distance = Math.sqrt(x_distance * x_distance + y_distance * y_distance)

          if temp_distance < 80
            $gather_stone.push(your1)
            $gather_stone.push(your2)
          end
        end

        if your2_index == 6
          your2_index = 0
        else
          your2_index = your2_index + 1
        end

      end

      $gather_stone = $gather_stone.uniq
      your1_index = your1_index + 1

      break $gather_stone.count if $gather_stone.count >= 3
    end
  end

  def get_name
    "Team Incoder"
  end

end

s.add_handler("alggago", MyAlggago.new)
s.serve
