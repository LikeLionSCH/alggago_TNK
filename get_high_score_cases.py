import json
import math
import heapq

def get_high_score_cases(filenames,count):
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
            #isMoongchim(json_data['result'][i]['my'],json_data['result'][i]['your'])
            score = get_score(my_stones,your_stones) # 점수 계싼
            heapq.heappush( 
                stone_info,(
                    score, # 점수
                    stone_index, # 돌 번호
                    json_data['strength'][i]['x'], # 돌의 x 세기
                    json_data['strength'][i]['y'], # 돌의 y 세기
                    json_data['result'][i]['my'], # 내 돌의 포지션
                    json_data['result'][i]['your'], # 상대 돌의 포지션
                )
            )
            # stone_info 에 튜플 형태로 힙 push 
        stone_index += 1
    
    case = []
    for i in range(0,count):
        case.append(heapq.heappop(stone_info))


    # for list in stone_info:
    #     print(list)
    # print("")
    # for list in case:
    #     print(list)

    return case
    


def isMoongchim(my_position, your_position):
    width,  height= 1000, 700
    row_cell = width/20
    high_cell = height/20

    # 내 돌 중 근접한 돌
    numOfNear_my = []
    for i in range(len(my_position)):
        numOfNear_my.append([])
        for j in range(len(my_position)):
            if i == j:
                pass
            else:
                # 두 돌 사이 거리가 작으면 추가
                if math.sqrt(math.pow(my_position[i][0] - my_position[j][0], 2) + math.pow(my_position[i][1] - my_position[j][1], 2)) < 2*row_cell:
                    numOfNear_my[i].append(j)

    # 상대 돌 중 근접한 돌
    numOfNear_your = []
    for i in range(len(your_position)):
        numOfNear_your.append([])
        for j in range(len(your_position)):
            # 두 돌 사이 거리가 작으면 추가
            if math.sqrt(math.pow(your_position[i][0] - your_position[j][0], 2) + math.pow(your_position[i][1] - your_position[j][1], 2)) < 2.5*row_cell:
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
        my_point = my_num*-1

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

    print(my_point)
    print(your_point)
    return {'my_point': my_point, "your_point": your_point}


# def get_score(my_stone_num,opp_stone_num,my_stone_point,opp_stone_point):
#     """ 남아있는 돌의 수를 바탕으로 점수 계산하는 함수  """
#     # my_stone_num -> 남은 우리 돌의 개수 
#     # opp_stone_num -> 남은 상대편 돌의 개수

#     # 우리 돌을 잃으면 -3, 상대 돌을 까면 +2 => 최종 점수 계산 후 최대값 도출
#     my_score = (7 - my_stone_num) * -30 + my_stone_point # 떨어진 우리 돌의 개수 * -3
#     opp_score = (7 - opp_stone_num) * 20 + opp_stone_point # 떨어진 상대 돌의 개수 * +2
    
#     total_score = my_score + opp_score # 최종 점수 도출

#     return total_score #최종 점수 반환

def get_score(my_stone_num,opp_stone_num):
    """ 남아있는 돌의 수를 바탕으로 점수 계산하는 함수  """
    # my_stone_num -> 남은 우리 돌의 개수 
    # opp_stone_num -> 남은 상대편 돌의 개수

    # 우리 돌을 잃으면 -3, 상대 돌을 까면 +2 => 최종 점수 계산 후 최대값 도출
    my_score = (7 - my_stone_num) * -30 # 떨어진 우리 돌의 개수 * -3
    opp_score = (7 - opp_stone_num) * 20# 떨어진 상대 돌의 개수 * +2
    
    total_score = my_score + opp_score # 최종 점수 도출

    return total_score #최종 점수 반환







""" codes for test """
filenames = []
filenames.append("stone0.json")
filenames.append("stone1.json")
filenames.append("stone2.json")
filenames.append("stone3.json")
filenames.append("stone4.json")
filenames.append("stone5.json")
filenames.append("stone6.json")

get_high_score_cases(filenames,3)