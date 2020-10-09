################################################################################
# Encoding: UTF-8
require 'gosu'
require 'chipmunk'
require 'singleton'
require 'slave'
require "xmlrpc/client"
require 'childprocess'
require 'rbconfig'


################################################################################
## Mocked Engine
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

class AlggagoPhysics < Gosu::Window
  def init;
    super(WIDTH, HEIGHT, false)
    @delete_stones = Array.new
  end

  def set_config(my_stones, your_stones)
    @players    = Array.new
    @space      = CP::Space.new
    @board      = Board.instance

    @winner         = @me    # cos I'm the best
    @gameover       = false
    @is_moving      = false
    @selected_stone = nil

    # It's always my turn first
    @my_turn = true

    @me = MockedPlayer.new(my_stones)
    @you = MockedPlayer.new(your_stones)

    [@me, @you].each do |player|
      player.stones.each do |my_stone|
        @space.add_body(my_stone.body)
        @space.add_shape(my_stone.shape)
      end
    end
  end

  def simulate_move(number, x_strength, y_strength)
    # If we need to generalise ,make it is_my_turn? my_turn = true
    reduced_x, reduced_y = reduce_speed(x_strength, y_strength)
    @me.stones[number].body.v = CP::Vec2.new(reduced_x, reduced_y)

    @is_moving = true
    while @is_moving; update end

    # Always
    return [@me.stone_positions, @you.stone_positions]
  end

  def update
    @space.step(TICK)
    @is_moving = false
    [@me, @you].each do |player|
      player.update
      player.stones.each do |stone|
        @is_moving = true if (stone.body.v.x != 0) or (stone.body.v.y != 0)
        if stone.should_delete
          @space.remove_body(stone.body)
          @space.remove_shape(stone.shape)
          player.stones.delete stone
        end
      end
    end

    [@me, @you].each do |player|
      if player.stones.length <= 0 and !@gameover
        @gameover = true
        @winner = player
      end
    end
  end

  def needs_cursor?; false end
  def reduce_speed x, y
    if x*x + y*y > MAX_POWER*MAX_POWER
      co = MAX_POWER / Math.sqrt(x*x + y*y)
      return x*co, y*co
    else
      return x, y
    end
  end
end

class Board;
  include Singleton
end

class MockedPlayer
  attr_reader :stones
  def initialize(position)
    @stones = Array.new
    position.each do |x, y|
      @stones << MockedStone.new(x, y)
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

  def stone_positions; return @stones.map {|s| [s.body.p.x, s.body.p.y]} end
end

class MockedStone
  attr_reader :body, :shape
  attr_accessor :should_delete

  def initialize(x, y)
    @should_delete = false

    @body = CP::Body.new(1, CP::moment_for_circle(1.0, 0, 1, CP::Vec2.new(0, 0)))
    @body.p = CP::Vec2.new(x, y)
    reset(x, y)

    @shape = CP::Shape::Circle.new(body, STONE_DIAMETER/2.0, CP::Vec2.new(0, 0))


    @shape.e = RESTITUTION
    @shape.u = STONE_FRICTION

    reset(x, y)
  end

  def reset(x, y)
    @body.p.x = x
    @body.p.y = y
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



################################################################################
# Code
require "xmlrpc/server"
require "socket"

s = XMLRPC::Server.new(ARGV[0])
MAX_NUMBER = 16000

MIN_SCORE = -50

# TODO finish
BOARD_SIZE = HEIGHT

TIME_OUT = 10                   # 10 seconds in seconds
#TIME_OUT_LENIENCY = 0.25        # 0.25 seconds in advance
TIME_OUT_LENIENCY = 0.35        # 0.25 seconds in advance

TIME_OUT_THRESHOLD = TIME_OUT - TIME_OUT_LENIENCY #

class MyAlggago
  def initialize
    @alggago_physics = AlggagoPhysics.new(WIDTH, HEIGHT)
    @my_color = 1
  end

  def calculate(positions)
    start_time = Time.now

    #Codes here
    # initialise max_score
    max_score = MIN_SCORE

    #debug
    #max_scores = []
    #times_updated = 0

    my_position = positions[0]
    your_position = positions[1]

    # adaptive search_param, depending on the stage of the game
    # the fewer the pieces, the more in-depth search you can do
    # TODO set maximum search number >> set search_param more efficiently?
    search_my = false
    if my_position.length * your_position.length > 30
      search_param = 3
      strength_param = 1
    elsif my_position.length * your_position.length > 15
      search_param = 4
      strength_param = 2
    else
      search_param = 10
      strength_param = 3
      search_my = true
    end

    # TODO tweak as appropriate
    #strong_f = 1.25
    strong_f = 1.5
    weak_f = 0.9


    current_stone_number = 0
    index = 0

    x_length = MAX_NUMBER
    y_length = MAX_NUMBER

    my_position.each do |my|
      your_position.each do |your|

        # get the distances b/w each my/opponent piece, in x, y coords
        x_len = your[0] - my[0]
        y_len = your[1] - my[1]

        # make use of STONE_DIAMETER
        # search in-depth at coordinates AROUND the target piece

        # hit param approach with strength variation
        # theta = angle towards the opponent piece
        theta = Math.atan2(y_len, x_len)
        # unit lengths for the perpendicular to the line b/w my & opponent centres, of length STONE_DIAMETER
        x_unit = Math.sin(theta) * STONE_DIAMETER
        y_unit = Math.cos(theta) * STONE_DIAMETER

        # TODO search crowded place only?
        # TODO minimax tree search?
        # TODO ... modularise & calculate again for select few?
        # TODO change so that denser search towards edges
        # vary direction slightly around the central vector b/w the two stone centres
        for i in 1-search_param...search_param
          x_test = x_len + x_unit*i/search_param
          y_test = y_len + y_unit*i/search_param

          # vary the strength slightly
          for j in 0..strength_param
            # try stronger
            move = [index, x_test*5*(strong_f**j), y_test*5*(strong_f**j)]
            predicted_board = predict(my_position, your_position, move)
            predicted_score = get_score_abs(predicted_board[0], predicted_board[1])

            # if new maximum score found, update relevant parameters
            if max_score < predicted_score
              current_stone_number = index
              x_length = x_test*(strong_f**j)
              y_length = y_test*(strong_f**j)
              max_score = predicted_score
              #max_scores << max_score
              #times_updated += 1
            end
            # try weaker
            move = [index, x_test*5*(weak_f**j), y_test*5*(weak_f**j)]
            predicted_board = predict(my_position, your_position, move)
            predicted_score = get_score_abs(predicted_board[0], predicted_board[1])

            # if new maximum score found, update relevant parameters
            if max_score < predicted_score
              current_stone_number = index
              x_length = x_test*(strong_f**j)
              y_length = y_test*(strong_f**j)
              max_score = predicted_score
              #max_scores << max_score
              #times_updated += 1
            end
          end


        end

        if Time.now - start_time > TIME_OUT_THRESHOLD then break end

      end

      if search_my
        my_position.each do |your|

          # get the distances b/w each my/opponent piece, in x, y coords
          x_len = your[0] - my[0]
          y_len = your[1] - my[1]

          # make use of STONE_DIAMETER
          # search in-depth at coordinates AROUND the target piece

          # hit param approach with strength variation
          # theta = angle towards the opponent piece
          theta = Math.atan2(y_len, x_len)
          # unit lengths for the perpendicular to the line b/w my & opponent centres, of length STONE_DIAMETER
          x_unit = Math.sin(theta) * STONE_DIAMETER
          y_unit = Math.cos(theta) * STONE_DIAMETER

          # TODO search crowded place only?
          # TODO minimax tree search?
          # TODO ... modularise & calculate again for select few?
          # TODO change so that denser search towards edges
          # vary direction slightly around the central vector b/w the two stone centres
          for i in 1-search_param...search_param
            x_test = x_len + x_unit*i/search_param
            y_test = y_len + y_unit*i/search_param

            # vary the strength slightly
            for j in 0..strength_param
              # try stronger
              move = [index, x_test*5*(strong_f**j), y_test*5*(strong_f**j)]
              predicted_board = predict(my_position, your_position, move)
              predicted_score = get_score_abs(predicted_board[0], predicted_board[1])

              # if new maximum score found, update relevant parameters
              if max_score < predicted_score
                current_stone_number = index
                x_length = x_test*(strong_f**j)
                y_length = y_test*(strong_f**j)
                max_score = predicted_score
                #max_scores << max_score
                #times_updated += 1
              end
              # try weaker
              move = [index, x_test*5*(weak_f**j), y_test*5*(weak_f**j)]
              predicted_board = predict(my_position, your_position, move)
              predicted_score = get_score_abs(predicted_board[0], predicted_board[1])

              # if new maximum score found, update relevant parameters
              if max_score < predicted_score
                current_stone_number = index
                x_length = x_test*(strong_f**j)
                y_length = y_test*(strong_f**j)
                max_score = predicted_score
                #max_scores << max_score
                #times_updated += 1
              end
            end

          end

          if Time.now - start_time > TIME_OUT_THRESHOLD then break end

        end
      end

      index = index + 1
    end

    #Return values
    stone_number = current_stone_number
    stone_x_strength = x_length * 5
    stone_y_strength = y_length * 5

    move = [stone_number, stone_x_strength, stone_y_strength]
    predicted_outcome = predict(my_position, your_position, move)
    #message = predicted_outcome
    message = positions.size

    return [stone_number, stone_x_strength, stone_y_strength, message]
  end

  def get_name; "But sir, you've already lost!!" end

  # Predict resulting board state after a move
  # Adapted from alggago.rb
  #
  #   @param my_positions   [Array]    My position
  #   @param your_positions [Array]    Opponent's
  #   @param move           [Array]    Which stone to move by how much
  #     [0] stone index, [1] strength (x) [2] strength (y) [3] message
  #
  #   @return [Array] (0) my (1) opponent
  def predict(my_positions, your_positions, move)
    @alggago_physics.set_config(my_positions, your_positions)
    @alggago_physics.simulate_move(*move) # [return]
  end

  # function to esitmate the "advantage score"
  # absolute version; just piece count
  def get_score_abs (my, your)
    return my.length - your.length
  end


end

s.add_handler("alggago", MyAlggago.new)
s.serve=