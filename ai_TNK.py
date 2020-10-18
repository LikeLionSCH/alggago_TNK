import sys
import math
import json
from collections import OrderedDict
import os
import threading

with open('simulate.rb', 'w') as simulate:
    simulate.write('''
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
            json_data["result"].push({
                "my" => @alggago.players[0].stones.map { |stone| { "x" => stone.body.p.x, "y" => stone.body.p.y} },
                "your" => @alggago.players[1].stones.map { |stone| { "x" => stone.body.p.x, "y" => stone.body.p.y } }
            })

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
    ''')

# temp.json
with open('temp.json') as json_file:
    json_data = json.load(json_file)

MAX_NUMBER = 16000

# 위치 정보 가져옴
my_position = []
your_position = []
for key in json_data["my_position"].keys():
    my_position.append(json_data["my_position"][key])
for key in json_data["your_position"].keys():
    your_position.append(json_data["your_position"][key])


# 칠 수 있는 경우의 수 json파일로 추출
def generate_json(prefix, my_position, your_position):

    # 상대돌 개수에 따라 탐색하는 범위 조절
    search_space = 5
    power_list = [2,7]
    STONE_DIAMETER = 25 # 반지름
    
    
    #json저장에 사용됨
    stone = OrderedDict() 

    # filename list
    filenames = []

    # 각 돌에 대하여 칠 수 있는 경우 검출
    for my_idx in range(len(my_position)):
        #파일스트림(?) 초기화
        stone.clear()

        # 내 돌이 상대 돌을 칠수 있는 좌표 집합
        locations_to_hit = []

        for your_idx in range(len(your_position)):
            #상대 돌 원의 둘레(절반)의 좌표의 집합을 구하여 locations_to_hit에 삽입
            for a in range(-1*STONE_DIAMETER, STONE_DIAMETER+1, search_space):
                #원의 중심과, 둘레 위의 점의 거리는 반지름을 이용하여 a,b공식화
                b1 = math.sqrt((STONE_DIAMETER*STONE_DIAMETER) - (a*a))
                b2 = -1 * b1

                # 상대 돌의 둘레 위의 점의 좌표
                pos1 = [your_position[your_idx][0]+(2*a),your_position[your_idx][1]+(2*b1)] # 내 돌의 지름까지 고려
                pos2 = [your_position[your_idx][0]+(2*a),your_position[your_idx][1]+(2*b2)]

                # 내 돌이 때릴 수 있는 범위는 반원임으로 때릴수 있는 부분만 리스트에 추가
                my_to_you = [ your_position[your_idx][0]-my_position[my_idx][0], your_position[your_idx][1]-my_position[my_idx][1]]
                if((my_to_you[0]*a + my_to_you[1]*b1) >= 0):
                    locations_to_hit.append(pos1)
                if((my_to_you[0]*a + my_to_you[1]*b2) >= 0):
                    locations_to_hit.append(pos2)
        
        #strength로 변환
        strength_list = []
        for pos in locations_to_hit:
            # 각 파워도 고려
            for power in power_list:
                strength_list.append( [ (pos[0]-my_position[my_idx][0]) * power, (pos[1]-my_position[my_idx][1]) * power ] )

        # json파일로 저장
        stone["index"] = my_idx
        stone["strength"] = []
        for ls in strength_list:
            stone["strength"].append({"x":ls[0], "y":ls[1]})
        with open(prefix+'stone'+str(my_idx)+'.json', 'w') as jsonFile:
            json.dump(stone, jsonFile, indent="\t")
        filenames.append(prefix+'stone'+str(my_idx)+'.json')

    return filenames


# get_json()함수 실행 후 simulate
generate_json('', my_position, your_position)

# 스레드 개수와 스레드 리스트
thread_count = len(my_position)
threads = []

def alggago_thread(i):
    os.system('ruby simulate.rb stone%d.json' %(i))

for i in range(thread_count):
    thread = threading.Thread(target=alggago_thread, args=(i,))
    thread.start()
    threads.append(thread)

# 메인 스레드는 각 스레드의 작업이 모두 끝날 때까지 대기
for thread in threads:
    thread.join()
    
# 시뮬레이트 결과 뽑아옴
stone_list = []
for stone in range(len(my_position)):
    stone_list.append([])

    # 시뮬 결과 가져옴
    with open('stone%d.json' %(stone)) as json_file:
        json_data = json.load(json_file)

    # 각 리스트당 정보 추가[ {stone:n, my:n, your:n, x:a, y:b}, ... ]
    for i in range(len(json_data['result'])):
        stone_list[stone].append({'stone':stone, 'my':len(json_data['result'][i]['my']), 'your': len(json_data['result'][i]['your']),
        'x': json_data['strength'][i]['x'], 'y':json_data['strength'][i]['y'], 'point': (7-len(json_data['result'][i]['my']))*-3 + (7-len(json_data['result'][i]['your']))*2})

# 각 돌마다 point순으로 정렬
for stone in stone_list:
    for i in range(len(stone)-2):
        for j in range(len(stone)-1):
            if stone[j+1]['point'] > stone[j]['point']:
                stone[j+1], stone[j] = stone[j], stone[j+1]

# 각 돌당 가장 높은 점수의 스톤 리스트에 추가
highest_point = []
for stone in range(len(stone_list)):
    for i in range(len(stone_list[stone])):
        if stone_list[stone][0]['point'] == stone_list[stone][i]['point']:
            highest_point.append(stone_list[stone][i])
        else:
            break

#스톤이 한 개 남을때까지 mini-max 알고리즘
while(len(highest_point) > 1):
    idx = 0
    turn = 1
    while(idx < len(highest_point)-1):
        #max
        if(turn > 0):
            if highest_point[idx]['point'] > highest_point[idx+1]['point']:
                highest_point.remove(highest_point[idx+1])
            else:
                highest_point.remove(highest_point[idx])
        #mini
        else:
            if highest_point[idx]['point'] > highest_point[idx+1]['point']:
                highest_point.remove(highest_point[idx])
            else:
                highest_point.remove(highest_point[idx+1])
        idx += 1
    turn *= -1

toHit = highest_point.pop()

#Return values
message = "TNK"
stone_number = toHit['stone']
stone_x_strength = toHit['x']
stone_y_strength = toHit['y']
result = [stone_number, stone_x_strength, stone_y_strength, message]

print(str(result)[1:-1].replace("'", ""))

if os.path.exists('./stone0.json'):
    os.remove('./stone0.json')
if os.path.exists('./stone1.json'):
    os.remove('./stone1.json')
if os.path.exists('./stone2.json'):
    os.remove('./stone2.json')
if os.path.exists('./stone3.json'):
    os.remove('./stone3.json')
if os.path.exists('./stone4.json'):
    os.remove('./stone4.json')
if os.path.exists('./stone5.json'):
    os.remove('./stone5.json')
if os.path.exists('./stone6.json'):
    os.remove('./stone6.json')