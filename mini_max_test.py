import sys
import math
import json
from collections import OrderedDict
import os
import threading

# temp.json
with open('temp.json') as json_file:
    json_data = json.load(json_file)

MAX_NUMBER = 16000
STONE_DIAMETER = 25 # 반지름

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
    if len(your_position) >= 5:
        search_space = 5
    elif len(your_position) <= 2:
        search_space = 1
    else:
        search_space = 2
    
    
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
                # 상대 돌의 좌표를 x,y로 둔다면, 원의 둘레 위의 한 점은 x+a, y+b로 표현 가능 
            for a in range(-1*STONE_DIAMETER, STONE_DIAMETER+1, search_space):
                #원의 중심과, 둘레 위의 점의 거리는 반지름을 이용하여 a,b공식화
                    # 루트(a^2 + b^2) = 반지름
                    # a^2 + b^2 = 반지름^2
                    # b^2 = 반지름^2 - a^2
                    # b = +,- 루트(반지름^2 - a^2)
                b1 = math.sqrt((STONE_DIAMETER*STONE_DIAMETER) - (a*a))
                b2 = -1 * b1

                # 상대 돌의 둘레 위의 점의 좌표
                pos1 = [your_position[your_idx][0]+(2*a),your_position[your_idx][1]+(2*b1)] # 내 돌의 지름까지 고려
                pos2 = [your_position[your_idx][0]+(2*a),your_position[your_idx][1]+(2*b2)]

                # 내 돌이 때릴 수 있는 범위는 반원임으로 때릴수 있는 부분만 리스트에 추가
                    # 벡터(내위치->상대위치)와 (a,b)이 이루는 각이 둔각이면 못때림
                    # 백터 (a,b의), (x,y) 내적(=(a*x)+(b*y))이 음수이면 둔각
                my_to_you = [ your_position[your_idx][0]-my_position[my_idx][0], your_position[your_idx][1]-my_position[my_idx][1]]
                if((my_to_you[0]*a + my_to_you[1]*b1) >= 0):
                    locations_to_hit.append(pos1)
                if((my_to_you[0]*a + my_to_you[1]*b2) >= 0):
                    locations_to_hit.append(pos2)
        
        #strength로 변환
        strength_list = []
        for pos in locations_to_hit:
            # 각 파워도 고려
            for power in [2,7]:
                strength_list.append( [ (pos[0]-my_position[my_idx][0]) * power, (pos[1]-my_position[my_idx][1]) * power ] )

        # json파일로 저장
        stone["index"] = my_idx
        stone["strength"] = []
        for ls in strength_list:
            stone["strength"].append({"x":ls[0], "y":ls[1]})
        with open(prefix+'stone'+str(my_idx)+'.json', 'w') as jsonFile:
            json.dump(stone, jsonFile, indent="\t")


# get_json()함수 실행 후 simulate
generate_json('',my_position, your_position)

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
    
# print("Finished Simulating with Multi Threading")


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


'''
알고리즘1. 내돌-상대돌 개수 분석
'''
# # 돌 당 최고 인덱스
# best_idx = []
# for stone in range(len(my_position)):
#     # 스톤별 최고의 인덱스 리스트에 추가
#     best = 0
#     for i in range(1, len(stone_list[stone])):
#         if stone_list[stone][i]['my'] - stone_list[stone][i]['your'] > stone_list[stone][best]['my'] - stone_list[stone][best]['your']:
#             best = i
#     best_idx.append(best)

# # 최고의 돌 결정
# best_stone = 0
# for i in range(1, len(best_idx)):
#     if stone_list[i][best_idx[i]]['my'] - stone_list[i][best_idx[i]]['your'] > stone_list[best_stone][best_idx[best_stone]]['my'] - stone_list[best_stone][best_idx[best_stone]]['your']:
#         best_stone = i

#Return values
# message = "tean_TKN"
# stone_number = best_stone
# stone_x_strength = stone_list[best_stone][best_idx[best_stone]]['x']
# stone_y_strength = stone_list[best_stone][best_idx[best_stone]]['y']
# result = [stone_number, stone_x_strength, stone_y_strength, message]


'''
알고리즘2. mini max 알고리즘
'''
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
message = "tean_TKN"
stone_number = toHit['stone']
stone_x_strength = toHit['x']
stone_y_strength = toHit['y']
result = [stone_number, stone_x_strength, stone_y_strength, message]


'''
알고리즘3. 점수
'''
# # 돌 당 최고 인덱스
# best_idx = []
# for stone in range(len(my_position)):
#     # 스톤별 최고의 인덱스 리스트에 추가
#     best = 0
#     for i in range(1, len(stone_list[stone])):
#         if stone_list[stone][i]['point'] > stone_list[stone][best]['point']:
#             best = i
#     best_idx.append(best)

# # 최고의 돌 결정
# best_stone = 0
# for i in range(1, len(best_idx)):
#     if stone_list[i][best_idx[i]]['point'] > stone_list[best_stone][best_idx[best_stone]]['point']:
#         best_stone = i

# #Return values
# message = "tean_TKN"
# stone_number = best_stone
# stone_x_strength = stone_list[best_stone][best_idx[best_stone]]['x']
# stone_y_strength = stone_list[best_stone][best_idx[best_stone]]['y']
# result = [stone_number, stone_x_strength, stone_y_strength, message]


print(str(result)[1:-1].replace("'", ""))