import json
import math
from collections import OrderedDict

MAX = 1
MIN = 0

class Case:
    GAME_STATE_UNKNOWN = 0
    GAME_STATE_WIN = 1
    GAME_STATE_LOSE = 2
    GAME_STATE_PLAYING = 3
    GAME_STATE_DRAW = 4

    def __init__(self, score, strength, positions):
        self.score = score
        self.strength = strength
        self.positions = positions

    def game_state():
        #남아있는 상대 돌이 없고, 우리 돌이 한개 이상 있으면 승리
        if len(positions[1]) <= 0 and len(positions[0]) > 0:
            return GAME_STATE_WIN

        # 남아있는 우리 돌이 없고, 상대 돌이 한개 이상 있으면 패배
        if len(positions[0]) <= 0 and len(positions[1]) > 0:
            return GAME_STATE_LOSE

        # 둘다 돌이 없으면 무승부
        if len(positions[0]) <= 0 and len(positions[1]) <= 0:
            return GAME_STATE_DRAW

        # 그 외의 경우에는 무승부
        return GAME_STATE_PLAYING


def generate_json(prefix, my_position, your_position):
    STONE_DIAMETER = 25
    search_space = 10   #간격 느슨하게
    power_list = [5]
    
    #json저장에 사용됨
    stone = OrderedDict() 

    # 각 돌에 대하여 칠 수 있는 경우 검출
    for my_idx in range(len(my_position)):
        #파일스트림(?) 초기화
        stone.clear()

        # 내 돌이 상대 돌을 칠수 있는 좌표 집합
        locations_to_hit = []

        for your_idx in range(len(your_position)):
            #상대 돌 원의 둘레(절반)의 좌표의 집합을 구하여 locations_to_hit에 삽입
            for a in range(-1*STONE_DIAMETER, STONE_DIAMETER+1, search_space):
                b1 = math.sqrt((STONE_DIAMETER*STONE_DIAMETER) - (a*a))
                b2 = -1 * b1

                # 상대 돌의 둘레 위의 점의 좌표
                pos1 = [your_position[your_idx][0]+(2*a),your_position[your_idx][1]+(2*b1)]
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
            for power in power_list:   # 간격 느슨하게
                strength_list.append( [ (pos[0]-my_position[my_idx][0]) * power, (pos[1]-my_position[my_idx][1]) * power ] )

        # json파일로 저장
        stone["index"] = my_idx
        stone["strength"] = []
        for ls in strength_list:
            stone["strength"].append({"x":ls[0], "y":ls[1]})
        with open(prefix+'stone'+str(my_idx)+'.json', 'w') as jsonFile:
            json.dump(stone, jsonFile, indent="\t")


def simulate():
    pass


def get_high_score_cases():
    pass


def predict(positions, max_layer_count, my_turn=True, prefix=''):
    if not my_turn:
        positions[0], positions[1] = positions[1], positions[0]

    json_filenames = generate_json(prefix, positions[0], positions[1])

    simulate(json_filenames)

    cases = get_high_score_cases(json_filenames, max_layer_count)

    current_best_case = None

    for index, case in enumerate(cases, 1):
        if current_best_case is None:
            current_best_case = case

        if case.game_state() == GAME_STATE_WIN:
            case.score = 1000
            return case
        
        if case.game_state() == GAME_STATE_LOSE:
            case.score = 0
            return case

        next_turn = not my_turn
        next_prefix = prefix + f'{index}_'
        current_case = predict(next_turn, case.positions, max_layer_count, next_prefix)
        if current_case.score > current_best_case.score:
            current_best_case = current_case

    return current_best_case

best_case = predict(positions, 3)

best_case.score
best_case.strength

# GAME_STATE_UNKNOWN = 0
# GAME_STATE_WIN = 1
# GAME_STATE_LOSE = 2
# GAME_STATE_PLAYING = 3
# GAME_STATE_DRAW = 4

# def get_game_state(positions):
#     # 남아있는 상대 돌이 없고, 우리 돌이 한개 이상 있으면 승리
#     if len(positions[1]) <= 0 and len(positions[0]) > 0:
#         return GAME_STATE_WIN

#     # 남아있는 우리 돌이 없고, 상대 돌이 한개 이상 있으면 패배
#     if len(positions[0]) <= 0 and len(positions[1]) > 0:
#         return GAME_STATE_LOSE

#     # 둘다 돌이 없으면 무승부
#     if len(positions[0]) <= 0 and len(positions[1]) <= 0:
#         return GAME_STATE_DRAW

#     # 그 외의 경우에는 무승부
#     return GAME_STATE_PLAYING


# def predict(positions):
#     if get_game_state(positions) == GAME_STATE_WIN:
#         return 10
#     elif get_game_state(positions) == GAME_STATE_LOSE:
#         return 0
#     elif get_game_state(positions) == GAME_STATE_DRAW:
#         return 