require "xmlrpc/server"
require "socket"
require 'chipmunk'
s = XMLRPC::Server.new(ARGV[0])

require 'gosu'
require 'singleton'
require 'slave'
require "xmlrpc/client"
require 'childprocess'
require 'rbconfig'
require 'pry'

MAX_NUMBER = 16000
WIDTH, HEIGHT = 1000, 700
TICK = 1.0/60.0
NUM_STONES = 7
PLAYER_COLOR = ["black", "white"]
STONE_DIAMETER = 50
RESTITUTION = 0.9
BOARD_FRICTION = 1.50
STONE_FRICTION = 0.5
ROTATIONAL_FRICTION = 0.04
FINGER_POWER = 3
UI_PIVOT = 100
MAX_POWER = 700.0


class MyAlggago

def update
  @space.step(TICK)
  @can_throw = true

  @players.each do |player|
    player.update
    player.stones.each do |stone|
      @can_throw = false if (stone.body.v.x != 0) or (stone.body.v.y != 0)
      if stone.should_delete
        @space.remove_body(stone.body)
        @space.remove_shape(stone.shape)
        player.number_of_stones -= 1
        player.stones.delete stone
      end
    end
  end

  @players.each do |player|
    if player.number_of_stones <= 0 and !@gameover
      @gameover = true
      @winner = if player.color == "white" then "black" else "white" end
    end
  end
end

def reduce_speed x, y
  if x*x + y*y > MAX_POWER*MAX_POWER
    co = MAX_POWER / Math.sqrt(x*x + y*y)
    return x*co, y*co
  else
    return x, y
  end
end
  def calculate(positions)

    #Codes here
    $my_position = []
    $your_position = []
    $my_position = positions[0]
    $your_position = positions[1]


      result_array = Array.new
      index = 0
      score = 0

      $my_position.each do |my|
        $your_position.each do |your|

          if @im.nil?

          @players = Array.new
          @space = CP::Space.new
          @im = Player.new($my_position)
          @ur = Player.new($your_position)
          @players << @im
          @players << @ur

          else


          @players = Array.new

          @space = CP::Space.new
          @im = Player.new($my_position)
          @ur = Player.new($your_position)
          @players << @im
          @players << @ur
          end

          x_length = 0.0
          y_length = 0.0
          x_strength = 0.0
          y_strength = 0.0
          reduced_x = 0.0
          reduced_y = 0.0

          location = [-3.5, -2, -1.5, 0, 1, 1.5, 3.5]
          location.each do |lo|
          location.each do |lo2|
          x_length = your[0] - my[0]
          y_length = your[1] - my[1]
          power = [2, 4, 7, 8, 9]
          power.each do |po|
          x_strength = ((po * x_length) + lo)
          y_strength = ((po * y_length) + lo2)
          reduced_x, reduced_y = reduce_speed(x_strength, y_strength)
          @im.stones[index].body.v = CP::Vec2.new(reduced_x, reduced_y)

          @space.step(TICK)

          @can_throw = true

          # @players.each do |player|
          #   player.update
          #   player.stones.each do |stone|
          #     @can_throw = false if (stone.body.v.x != 0) or (stone.body.v.y != 0)
          #     if stone.should_delete
          #       @space.remove_body(stone.body)
          #       @space.remove_shape(stone.shape)
          #       player.number_of_stones -= 1
          #       player.stones.delete stone
          #     end
          #   end
          # end

          @im.update
          @im.stones
          @im.stones.each do |stone|
            @can_throw = false if (stone.body.v.x != 0) or (stone.body.v.y != 0)
            if stone.should_delete
              @space.remove_body(stone.body)
              @space.remove_shape(stone.shape)
              @im.number_of_stones -= 1
              @im.stones.delete stone
            end
          end
          @ur.update
          @ur.stones
          @ur.stones.each do |stone|
            @can_throw = false if (stone.body.v.x != 0) or (stone.body.v.y != 0)
            if stone.should_delete
              @space.remove_body(stone.body)
              @space.remove_shape(stone.shape)
              @ur.number_of_stones -= 1
              @ur.stones.delete stone
            end
          end


          score = ( @im.number_of_stones^2 - @ur.number_of_stones^2 ) + 2 * po.abs + 3 * lo.abs +  2 * lo2.abs

          result_array << [index, reduced_x, reduced_y, score, po, lo, lo2]
end
end
end

      end
      index = index + 1
      end

      score = -1
      stone_number = 0
      stone_x_strength = 0.0
      stone_y_strength = 0.0
      power = 0.0
      loc = 0.0
      result_array.each do |arr|
        if arr[3] >= score
          power = arr[4]
          loc = arr[5]
          score = arr[3]
          stone_number = arr[0]
          stone_x_strength = ((arr[4] * arr[1]) + arr[5])
          stone_y_strength = ((arr[4] * arr[2]) + arr[6])

        end
      end

      return [stone_number, stone_x_strength, stone_y_strength, "#{result_array}!,#{result_array.each {|a| a[3] }}!,#{power}!,#{stone_number}, #{stone_x_strength}, #{stone_y_strength}, #{loc}, #{score}"]

  end

  def get_name
    "Wilson"
  end
end

class Stone
  attr_reader :body, :shape
  attr_accessor :should_delete
  def initialize(coordinate_x, coordinate_y)

    @should_delete = false
    @body = CP::Body.new(1, CP::moment_for_circle(1.0, 0, 1, CP::Vec2.new(0, 0)))
    @body.p = CP::Vec2.new(coordinate_x, coordinate_y)
   #@body.v = CP::Vec2.new(rand(HEIGHT)-HEIGHT/2, rand(HEIGHT)-HEIGHT/2)

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

    #update speed of angle
    new_rotational_v = 0
    new_rotational_v = get_reduced_rotational_velocity @body.w if @body.w != 0
    @body.w = new_rotational_v
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

  private
  def get_reduced_rotational_velocity velocity
    if velocity.abs <= ROTATIONAL_FRICTION
      return 0
    else
      return (velocity.abs / velocity) * (velocity.abs - ROTATIONAL_FRICTION)
    end
  end
end
class Player
  attr_reader :stones
  attr_accessor :number_of_stones

  def initialize(stones)
    @stones = Array.new
    @number_of_stones = stones.count
    stones.each do |a|
    @stones << Stone.new(a[0], a[1])
    end
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
s.add_handler("alggago", MyAlggago.new)
s.serve
