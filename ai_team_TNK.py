import os
import json
import math
import heapq
import threading
from collections import OrderedDict


class Case:
    GAME_STATE_UNKNOWN = 0
    GAME_STATE_WIN = 1
    GAME_STATE_LOSE = 2
    GAME_STATE_PLAYING = 3
    GAME_STATE_DRAW = 4

    def __init__(self, score, strength, positions, index):
        self.score = score
        self.strength = strength
        self.positions = positions
        self.index = index

    def game_state(self):
        #남아있는 상대 돌이 없고, 우리 돌이 한개 이상 있으면 승리
        if len(self.positions[1]) <= 0 and len(self.positions[0]) > 0:
            return Case.GAME_STATE_WIN

        # 남아있는 우리 돌이 없고, 상대 돌이 한개 이상 있으면 패배
        if len(self.positions[0]) <= 0 and len(self.positions[1]) > 0:
            return Case.GAME_STATE_LOSE

        # 둘다 돌이 없으면 무승부
        if len(self.positions[0]) <= 0 and len(self.positions[1]) <= 0:
            return Case.GAME_STATE_DRAW

        # 그 외의 경우에는 무승부
        return Case.GAME_STATE_PLAYING


# 칠 수 있는 경우의 수 json파일로 추출
# 매개변수: prefix(파일 이름 접두사), my_position(), your_posotion
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
                pos1 = [your_position[your_idx][0] + (2 * a), your_position[your_idx][1] + (2 * b1)] # 내 돌의 지름까지 고려
                pos2 = [your_position[your_idx][0] + (2 * a), your_position[your_idx][1] + (2 * b2)]

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
            stone["strength"].append({"x": ls[0], "y": ls[1]})
        with open(prefix + 'stone' + str(my_idx) + '.json', 'w') as jsonFile:
            json.dump(stone, jsonFile, indent="\t")
        filenames.append(prefix + 'stone' + str(my_idx) + '.json')

    return filenames


# 만들어진 json파일로 시뮬레이션 돌리기
# 매개변수: filenames
def simulate(filenames):
    threads = []

    def alggago_thread(filename):
        os.system(f'ruby simulate.rb {filename}')

    # 스레드 개수와 스레드 리스트        
    for filename in filenames:
        thread = threading.Thread(target=alggago_thread, args=(filename,))
        thread.start()
        threads.append(thread)
    for thread in threads:
        thread.join()


def isMoongchim(my_position, your_position):
    width, height= 1000, 700
    row_cell = width / 20
    high_cell = height / 20

    # 내 돌 중 근접한 돌
    numOfNear_my = []
    for i in range(len(my_position)):
        numOfNear_my.append([])
        for j in range(len(my_position)):
            if i == j:
                pass
            else:
                # 두 돌 사이 거리가 작으면 추가
                if math.sqrt(math.pow(my_position[i]['x'] - my_position[j]['x'], 2) + math.pow(my_position[i]['y'] - my_position[j]['y'], 2)) < 2.2 * row_cell:
                    numOfNear_my[i].append(j)

    # 상대 돌 중 근접한 돌
    numOfNear_your = []
    for i in range(len(your_position)):
        numOfNear_your.append([])
        for j in range(len(your_position)):
            # 두 돌 사이 거리가 작으면 추가
            if math.sqrt(math.pow(your_position[i]['x'] - your_position[j]['x'], 2) + math.pow(your_position[i]['y'] - your_position[j]['y'], 2)) < 2.2 * row_cell:
                numOfNear_your[i].append(j)

    #근접한 돌의 '개수'(max사용위해)를 나타내는 리스트
    # 내 돌
    my_num_list = []
    for stones in numOfNear_my:
        my_num_list.append(len(stones))
    biggest = max(my_num_list)
    my_idx = my_num_list.index(biggest) # 가장 요소가 많은 인덱스
    my_num = len(numOfNear_my[my_idx])  # 뭉친 돌의 개수
    if my_num == len(my_position):
        my_point = -7
    elif my_num == 1:
        my_point = 0
    else:
        my_point = my_num * -1

    # 상대 돌
    your_num_list = []
    for stones in numOfNear_your:
        your_num_list.append(len(stones))
    biggest = max(your_num_list)
    your_idx = your_num_list.index(biggest) # 가장 요소가 많은 인덱스
    your_num = len(numOfNear_your[your_idx])  # 뭉친 돌의 개수
    if your_num == len(your_position):
        your_point = 15
    elif your_num == 1:
        your_point = 0
    else:
        your_point = your_num

    return {'my_point': my_point, "your_point": your_point}


def get_score(my_stone_num, opp_stone_num, my_stone_point, opp_stone_point):
    """ 남아있는 돌의 수를 바탕으로 점수 계산하는 함수  """
    # my_stone_num -> 남은 우리 돌의 개수 
    # opp_stone_num -> 남은 상대편 돌의 개수

    # 우리 돌을 잃으면 -3, 상대 돌을 까면 +2 => 최종 점수 계산 후 최대값 도출
    my_score = (7 - my_stone_num) * -30 + my_stone_point # 떨어진 우리 돌의 개수 * -3
    opp_score = (7 - opp_stone_num) * 20 + opp_stone_point # 떨어진 상대 돌의 개수 * +2
    
    total_score = my_score + opp_score # 최종 점수 도출

    return total_score #최종 점수 반환


# 파일 이름을 받아 최상위 3개 전략의 최고점수 및 힘, 위치값 반환
# 매개변수: filenames, count(뿌리 개수 3)
def get_high_score_cases(filenames, count):
    """ 가장 점수 높은 몇가지 케이스를 반환하는 함수 """
    # filenames -> json파일의 이름을 list로 입력
    # count -> 몇개의 케이스를 반환할지 정해주는 매개변수

    stone_info = []

    stone_index=0
    for filename in filenames:
        with open(str(filename)) as json_file:
            json_data = json.load(json_file)
        for i in range(len(json_data['result'])):
            my_stones = len(json_data['result'][i]['my']) # 내 남은 돌의 개수 계산
            your_stones = len(json_data['result'][i]['your']) # 상대 남은 돌의 개수 계산
            mc = isMoongchim(json_data['result'][i]['my'],json_data['result'][i]['your'])
            score = get_score(my_stones,your_stones,mc['my_point'],mc['your_point']) # 점수 계싼
            heapq.heappush(stone_info, (
                    (-1) * int(score), # 점수
                    stone_index, # 돌 번호
                    json_data['strength'][i]['x'], # 돌의 x 세기
                    json_data['strength'][i]['y'], # 돌의 y 세기
                    json_data['result'][i]['my'], # 내 돌의 포지션
                    json_data['result'][i]['your'], # 상대 돌의 포지션
                )
            )
            # stone_info 에 튜플 형태로 힙 push 
        stone_index += 1
    
    cases = []

    for i in range(0,count):
        #cases.append(heapq.heappop(stone_info))
        tmp = heapq.heappop(stone_info)
        case = Case(tmp[0] * (-1), [tmp[2], tmp[3]], [tmp[4], tmp[5]], tmp[1])
        cases.append(case)


    # for list in stone_info:
    #     print(list)
    # print("")
    # for list in cases:
    #     print(list)
    
    return cases


def predict(positions, max_layer_count, my_turn=True, prefix=''):
    # 상대 턴이면 (내 턴이 아니면)
    if not my_turn:
        # 내가 상대 입장이 되어 시뮬레이션하기 위해 my_position과 your_position을 교환
        positions[0], positions[1] = positions[1], positions[0]

    # 상대 돌을 칠 샘플링 데이터 파일 생성
    json_filenames = generate_json(prefix, positions[0], positions[1])

    # Thread 사용하여 샘플링 데이터를 전부 시뮬레이트
    simulate(json_filenames)

    # 시뮬레이션 한 결과값에서 가장 높은 점수를 받은 상위 n개 경우를 찾기
    cases = get_high_score_cases(json_filenames, max_layer_count)

    current_best_case = None

    # 찾은 경우의 수만큼 반복
    for index, case in enumerate(cases, 1):
        # 최고의 경우를 찾지 못했다면 현재 경우를 최고의 경우로 설정
        if current_best_case is None:
            current_best_case = case

        # 현재 케이스가 이기는 경우이면 점수를 1000점으로 설정하여 반환
        if case.game_state() == Case.GAME_STATE_WIN:
            case.score = 1000
            return case
        
        # 현재 케이스가 지는 경우이면 점수를 0점으로 설정하여 반환
        if case.game_state() == Case.GAME_STATE_LOSE:
            case.score = 0
            return case

        next_turn = not my_turn
        next_prefix = prefix + f'{index}_'

        # 현재 케이스를 하위 예측값의 최고 점수 케이스로 설정
        current_case = predict(case.positions, max_layer_count, next_turn, next_prefix)

        # 최고점수 값을 찾는다
        if current_case.score > current_best_case.score:
            current_best_case = current_case

    # 최고점을 받은 경우를 반환
    return current_best_case


def main():
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

    positions = [my_position, your_position]

    # 최고의 경우의수를 예측
    best_case = predict(positions, 3)

    #Return values
    message = "tean_TKN"
    result = [best_case.index, best_case.strength[0], best_case.strength[1], message]

    print(str(result)[1:-1].replace("'", ""))


if __name__ == '__main__':
    main()