
import math

# # 상대돌의 뭉침 점수 -> [0,2,3,4,5,6,15] 로 차등 분배 (안뭉쳐있으면 0점, 모두 뭉쳐있다면 15점)
# # 우리돌의 뭉침 점수 -> [-15,-6,-5,-4,-3,-2,0] 으로 차등 분배

# 뭉침 판별 함수
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