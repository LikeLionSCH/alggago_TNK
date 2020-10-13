# Encoding: UTF-8
require "xmlrpc/server"
require "socket"
require 'chipmunk'

HEIGHT = 700 # 바둑판 크기
TICK = 1.0/60.0 # 눈금 (1/60) -> 바둑판 60등분 
NUM_STONES = 7 # 돌 개수
STONE_DIAMETER = 50 # 돌 지름
RESTITUTION = 0.9 # 반환(?)
BOARD_FRICTION = 1.50 # 바둑판 마찰
STONE_FRICTION = 0.5 # 돌 마찰
ROTATIONAL_FRICTION = 0.04 # 회전 마찰
MAX_POWER = 700.0 # 최대 파워
MAX_NUMBER = 1600000 #
MAX_HIT = 6 #?
MAX_TIME = 17 # 최대 시간

s = XMLRPC::Server.new(ARGV[0]) # pass

class MyAlggago 
  attr_accessor :env # env -> 가상머신

  # my stones: [[pt1_pos_x, pt1_pos_y],...]
  def variation (my_stones) 
    var = 0
    if my_stones.length > 1 
      sum = my_stones.inject([0,0]) {|acc, i| [acc[0]+i[0], acc[1]+i[1]] }
      mean = [sum[0]/my_stones.length, sum[1]/my_stones.length]
      var = my_stones.inject([0,0]) { |acc, i| [ acc[0]+ (i[0]-mean[0])**2 , acc[1] + (i[1]-mean[1])**2]}.reduce(:+) / my_stones.length
    end
    return var
  end

  def calculate(positions)

    my_position = positions[0] # 내 돌의 위치
    your_position = positions[1] # 상대 돌의 위치

    # Write your own codes here
    stone_number = 0 # 돌 번호
    x_strength = 0 # x 힘
    y_strength = 0 # y 힘
    message = "" # 메세지 
    max_net_kill = -2 
    max_var = 0
    alt = []
    alt_net_kill = -2

    @env ||=  Alggago.new(positions)
    beginning_time = Time.now
    middle_time = Time.now


    for my_idx in 0..my_position.length-1
      break if max_net_kill >= MAX_HIT or middle_time - beginning_time > MAX_TIME #max_hit == 6
      # 시간 끝 Or 다 떨구면 break
      # 쓸데 없는 결과는 컷
      my = my_position[my_idx] # 내 돌의 수만큼 반복
      for your_idx in 0..your_position.length-1
        break if max_net_kill >= MAX_HIT or middle_time - beginning_time > MAX_TIME
        your = your_position[your_idx] # 적 돌의 수만큼 반복

        dist = Math.sqrt((your[0] - my[0])**2 + (your[1] - my[1])**2) # 피타고라스로 거리 구한거

        theta = Math.acos( ( your[0] - my[0] ) /dist) # acos -> 주어진 주의 아크코사인값을 숫자로 반환
        # theta = 내 돌이 상대 돌을 칠 수 있는 각도
        theta = your[1] - my[1] < 0 ? 2*Math::PI - theta : theta # 상대 돌이 우리돌보다 위에 있으면 -> 조건 거짓 
        # 상대 돌이 우리 돌보다 위에 있을 경우 -> 쎄타 = 360 - 쎄타 , 우리 돌이 더 우ㅣ에 있으면 세타
        # 360 == 2pi 
        # 상대 돌보다 우리 돌이 더 아래에 있으면 돌려서 침 

        max_alpha = Math.asin( STONE_DIAMETER / dist ) #STONE_DIAMETER / dist -> 50/돌 사이의 거리 
        # 상대 돌을 맞출 수 있는 최대 각도

        angular_offsets = (-4.0/5*max_alpha..4.0/5*max_alpha).step(max_alpha/5.0) # .step -> 인자 만큼 띄엄띄엄 범위를 준다
        # ex) (1..10).step(3) => 1 4 7 10
        # 오차를 줄임 .
        
        angular_offsets.each do | alpha | # offset 안의 각각 값들을 alpha로 사용하여 반복
          break if max_net_kill >= MAX_HIT or middle_time - beginning_time > MAX_TIME
          co = MAX_POWER / dist
          powers = (my_position.length >= NUM_STONES-1 or your_position.length >= NUM_STONES-1) ? [co] : (1.0/5*co..co).step(1.0/5*co)
          powers.each do | power |
            if max_net_kill >= MAX_HIT  or middle_time - beginning_time > MAX_TIME
              message += "Time Limit!"
              break
            end
            @env.restart(positions)
            while(1) do
              if (@env.can_throw)
                tmp_x_vec, tmp_y_vec= @env.calculate(my, [my[0]+dist*Math.cos(theta + alpha), my[1]+dist*Math.sin(theta+ alpha)], my_idx, power)
              end

              @env.update

              if( @env.turn_end )
                earn = positions[1].length - @env.players[1].stones.length
                loss = positions[0].length - @env.players[0].stones.length
                my_pos_result = @env.players[0].stones.map {|s| [s.body.p.x, s.body.p.y]}
                your_pos_result = @env.players[1].stones.map {|s| [s.body.p.x, s.body.p.y]}
                cur_var = variation(my_pos_result)

                if(earn  > max_net_kill and loss == 0)
                  max_net_kill = earn
                  stone_number = my_idx
                  x_strength, y_strength = tmp_x_vec, tmp_y_vec
                  max_var = cur_var

                elsif (earn -loss >= max_net_kill and @env.gameover and @env.loser == 1) # if i win with a suicide
                  alt = [my_idx, tmp_x_vec, tmp_y_vec , message]
                  alt_net_kill = earn - loss

                elsif ( earn == max_net_kill and loss == 0 and cur_var > max_var)
                  stone_number = my_idx
                  x_strength, y_strength = tmp_x_vec, tmp_y_vec
                  max_var = cur_var
                  #message+="Increase Var!\n"
                  #message +="earn: #{earn} loss:#{loss} max_var: #{cur_var} \n"
                end
                middle_time = Time.now
                break
              end
            end
          end
        end
      end
    end
    end_time = Time.now

    # Return values
    # if I can win the game in this turn
    if alt_net_kill == max_net_kill
      #alt[3] +="Winning Suicide!\n"
      return alt
    else
      #message += "my_idx:#{my_idx} your_idx:#{your_idx}stone_number: #{stone_number}\n strength: #{x_strength}, #{y_strength}\nmy_position: #{my_position}\n your_position: #{your_position}]\nTime elapsed #{(end_time - beginning_time)} seconds\n power: #{Math.sqrt(x_strength**2 + y_strength**2)}"
      return [stone_number, x_strength, y_strength, message]
    end

  end

  def get_name
    "MonteCarlo"
  end

end

class Alggago
  attr_reader :players, :gameover, :loser
  attr_accessor :can_throw, :turn_end

  def init_game(positions)
    @loser = -1 # invalid
    @gameover = false
    @can_throw = true
    @selected_stone = nil
    @turn_end = false

    @players.each do |player|
      player.stones.each do |stone|
        @space.remove_body(stone.body)
        @space.remove_shape(stone.shape)
      end
      player.stones.clear
    end
    @players.clear

    positions.each do | position |
      player = Player.new(position)
        player.stones.each do |stone|
          @space.add_body(stone.body)
          @space.add_shape(stone.shape)
        end
      @players << player #@players[0] = me [1] = opponent
    end
  end

  def initialize(positions)
    @space = CP::Space.new
    @players = Array.new
    init_game(positions)
  end

  def update
    @space.step(TICK)
    @can_throw = true
    @turn_end = true
    @players.each do |player|
      player.update
      player.stones.each do |stone|
        @can_throw = false if (stone.body.v.x != 0) or (stone.body.v.y != 0)
        @turn_end = false if (stone.body.v.x != 0) or (stone.body.v.y != 0)
        if stone.should_delete
          @space.remove_body(stone.body)
          @space.remove_shape(stone.shape)
          player.stones.delete stone
        end
      end
    end

    @players.each_with_index do |player, index|
      if player.stones.length <= 0 and !@gameover
        @gameover = true
        @loser = index # 0 is me and 1 is you
      end
    end
  end

  def restart(positions)
    init_game(positions)
  end

  def calculate(my, your, my_idx, power)

    x_strength = (your[0] - my[0]) * power
    y_strength = (your[1] - my[1]) * power

    reduced_x, reduced_y = reduce_speed(x_strength, y_strength)
    @players[0].stones[my_idx].body.v = CP::Vec2.new(reduced_x, reduced_y)
    return x_strength, y_strength
  end

  def reduce_speed x, y
    if x*x + y*y > MAX_POWER*MAX_POWER
      co = MAX_POWER / Math.sqrt(x*x + y*y)
      return x*co, y*co
    else
      return x, y
    end
  end
end

class Player
  attr_reader :stones
  def initialize(pos_arr)
    @stones = Array.new
    pos_arr.each { |x,y| @stones << Stone.new(x,y) }
  end

  def update
    @stones.each do |stone|
      stone.update
      if (stone.body.p.x + STONE_DIAMETER/2.0 > HEIGHT) or
                              (stone.body.p.x + STONE_DIAMETER/2.0 < 0) or
                              (stone.body.p.y + STONE_DIAMETER/2.0 > HEIGHT) or
                              (stone.body.p.y + STONE_DIAMETER/2.0 < 0)
        stone.should_delete = true
      end
    end
  end
end

class Stone
  attr_reader :body, :shape
  attr_accessor :should_delete
  def initialize( pos_x, pos_y)
    @should_delete = false
    @body = CP::Body.new(1, CP::moment_for_circle(1.0, 0, 1, CP::Vec2.new(0, 0)))

    @body.p = CP::Vec2.new( pos_x, pos_y )

    @shape = CP::Shape::Circle.new(body, STONE_DIAMETER/2.0, CP::Vec2.new(0, 0))
    @shape.e = RESTITUTION
    @shape.u = STONE_FRICTION
  end

  def update
    #update speed
    new_vel_x, new_vel_y = 0.0, 0.0
    if @body.v.x != 0 or @body.v.y != 0
      new_vel_x = get_reduced_velocity(@body.v.x, @body.v.length)
      new_vel_y = get_reduced_velocity(@body.v.y, @body.v.length)
    end
    @body.v = CP::Vec2.new(new_vel_x, new_vel_y)

  end

  private
  def get_reduced_velocity original_velocity, original_velocity_length
    if original_velocity.abs <= BOARD_FRICTION * (original_velocity.abs / original_velocity_length)
      return 0
    else
      return (original_velocity.abs / original_velocity) *
                (original_velocity.abs - BOARD_FRICTION * (original_velocity.abs / original_velocity_length))
    end
  end

end

s.add_handler("alggago", MyAlggago.new)
s.serve