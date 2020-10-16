import sys
import math
import json
from collections import OrderedDict

MAX_NUMBER = 16000
STONE_DIAMETER = 25 # 반지름

# with open('temp.json') as json_file:
#     json_data = json.load(json_file)

def get_json(json_data):
    my_position = []
    your_position = []

    # 돌의 위치 정보
    for key in json_data["my_position"].keys():
        my_position.append(json_data["my_position"][key])
    for key in json_data["your_position"].keys():
        your_position.append(json_data["your_position"][key])
    
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
            for a in range(-1*STONE_DIAMETER,STONE_DIAMETER+1,10):
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
            for power in [2]:
                strength_list.append( [ (pos[0]-my_position[my_idx][0]) * power, (pos[1]-my_position[my_idx][1]) * power ] )

        # json파일로 저장
        stone["index"] = my_idx
        stone["strength"] = []
        for ls in strength_list:
            stone["strength"].append({"x":ls[0], "y":ls[1]})
        with open('stone'+str(my_idx)+'.json', 'w') as jsonFile:
            json.dump(stone, jsonFile, indent="\t")

        # 힘 리스트 정렬시켜서 리턴
        # distance = []
        # for strength in strength_list:
        #     distance.append(math.sqrt(strength[0]*strength[0] + strength[1]*strength[1]))
        # for i in range(len(distance)-2):
        #     for j in range(len(distance)-1):
        #         if distance[j]> distance[j+1]:
        #             distance[j], distance[j+1] = distance[j+1], distance[j]
        #             strength_list[j], strength_list[j+1] = strength_list[j+1], strength_list[j]
        # return strength_list