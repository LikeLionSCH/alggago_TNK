require 'json'
require 'chipmunk'


class SimulateInfo
    attr_accessor :filename, :index, :sample_strength

    def initialize(filename)
        # 시뮬레이션 데이터 파일 읽기
        file = File.read(filename)
        json_data = JSON.parse(file)

        @filename = filename
        @index = json_data["index"]
        @sample_strength = json_data["strength"]
    end
end


class Simulator
    def initialize(info)
        @info = info

        # 게임 현황 데이터 파일 읽기
        file = File.read('temp.json')
        json_data = JSON.parse(file)

        # 데이터 파일로부터 내 돌과 상대 돌의 위치정보 추출
        my_positions = Array.new
        your_positions = Array.new

        for key in json_data["my_position"].keys do
            my_positions.push(json_data["my_position"][key])
        end

        for key in json_data["your_position"].keys do
            your_positions.push(json_data["your_position"][key])
        end

        @positions = [my_positions, your_positions]

        # 모든 돌의 위치정보로 가상 게임을 생성
        @alggago = Alggago.new(@positions)
    end

    def run
        # 입력파일에 결과를 추가하기 위해 json 파일 열기
        file = File.read(@info.filename)
        json_data = JSON.parse(file)
        json_data["result"] = []

        # 모든 샘플 데이터를 테스트
        for strength in @info.sample_strength do
            @alggago.init_game(@positions)

            # 테스트 케이스 계산 후 돌에 물리값 적용
            @alggago.calculate(@info.index, strength["x"], strength["y"])

            # 모든 돌이 멈출 때 까지 물리엔진 갱신
            while !@alggago.turn_end do
                @alggago.update
            end

            # 결과 데이터를 hash에 저장
            json_data["result"].push({"my" => @alggago.players[0].stones.length, "your" => @alggago.players[1].stones.length})

            # 돌의 개수가 줄어든 시뮬레이션 결과가 있으면 해당 결과 출력
            # if @alggago.players[0].stones.length < 7 or @alggago.players[1].stones.length < 7
            #     puts("black(AI): #{@alggago.players[0].stones.length}, white(User): #{@alggago.players[1].stones.length}")
            # end
        end

        # 전체 시뮬레이션 결과를 파일로 출력
        File.write("./#{@info.filename}", JSON.pretty_generate(json_data))
    end
end


HEIGHT = 700
TICK = 1.0/60.0
STONE_DIAMETER = 50
RESTITUTION = 0.9
BOARD_FRICTION = 1.50
STONE_FRICTION = 0.5
ROTATIONAL_FRICTION = 0.04
MAX_POWER = 700.0


class Alggago
    attr_reader :players
    attr_accessor :turn_end
  
    def initialize(positions)
        @space = CP::Space.new
        @players = Array.new
        init_game(positions)
    end

    def init_game(positions)
        @turn_end = false
        @selected_stone = nil
    
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
            @players.push(player)
        end
    end
  
    def update
        @space.step(TICK)
        @turn_end = true
        @players.each do |player|
            player.update
            player.stones.each do |stone|
                @turn_end = false if (stone.body.v.x != 0) or (stone.body.v.y != 0)
                if stone.should_delete
                    @space.remove_body(stone.body)
                    @space.remove_shape(stone.shape)
                    player.stones.delete(stone)
                end
            end
        end
    end
  
    def calculate(index, x_strength, y_strength)
        if @players[0].stones.length <= index
            puts("Error: calculate() - stone index is out of bounds")
            return
        end

        reduced_x, reduced_y = reduce_speed(x_strength, y_strength)
        @players[0].stones[index].body.v = CP::Vec2.new(reduced_x, reduced_y)
    end
  
    def reduce_speed(x, y)
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

    def initialize(positions)
        @stones = Array.new
        positions.each { |x, y| @stones.push(Stone.new(x, y)) }
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

    def initialize(x, y)
        @should_delete = false
        @body = CP::Body.new(1, CP::moment_for_circle(1.0, 0, 1, CP::Vec2.new(0, 0)))
    
        @body.p = CP::Vec2.new(x, y)
    
        @shape = CP::Shape::Circle.new(body, STONE_DIAMETER/2.0, CP::Vec2.new(0, 0))
        @shape.e = RESTITUTION
        @shape.u = STONE_FRICTION
    end
  
    def update
        new_vel_x, new_vel_y = 0.0, 0.0
        if @body.v.x != 0 or @body.v.y != 0
            new_vel_x = get_reduced_velocity(@body.v.x, @body.v.length)
            new_vel_y = get_reduced_velocity(@body.v.y, @body.v.length)
        end
        @body.v = CP::Vec2.new(new_vel_x, new_vel_y)

        new_rotational_v = 0
        new_rotational_v = get_reduced_rotational_velocity(@body.w) if @body.w != 0
        @body.w = new_rotational_v
    end
  
    private
    def get_reduced_velocity(original_velocity, original_velocity_length)
        if original_velocity.abs <= BOARD_FRICTION * (original_velocity.abs / original_velocity_length)
            return 0
        else
            return (original_velocity.abs / original_velocity) *
                    (original_velocity.abs - BOARD_FRICTION * (original_velocity.abs / original_velocity_length))
        end
    end

    private
    def get_reduced_rotational_velocity(velocity)
        if velocity.abs <= ROTATIONAL_FRICTION
            return 0
        else
            return (velocity.abs / velocity) * (velocity.abs - ROTATIONAL_FRICTION)
        end
    end
end

if ARGV.length != 1
    puts "ERROR: Invalid Arguments!"
end

simulate_info = SimulateInfo.new(ARGV[0])
simulator = Simulator.new(simulate_info)
simulator.run