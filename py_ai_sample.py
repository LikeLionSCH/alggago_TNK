import sys
import math
import json


with open('temp.json') as json_file:
    json_data = json.load(json_file)

MAX_NUMBER = 16000

my_position = []
your_position = []

for key in json_data["my_position"].keys():
    my_position.append(json_data["my_position"][key])

for key in json_data["your_position"].keys():
    your_position.append(json_data["your_position"][key])
    

current_stone_number = 0
index = 0
min_length = MAX_NUMBER
x_length = MAX_NUMBER
y_length = MAX_NUMBER

'''
for my in my_position:
    for your in your_position:
        x_distance = abs(my[0] - your[0])
        y_distance = abs(my[1] - your[1])
        current_distance = math.sqrt(x_distance * x_distance + y_distance * y_distance)
        if min_length > current_distance:
            current_stone_number = index
            min_length = current_distance
            x_length = your[0] - my[0]
            y_length = your[1] - my[1]

    index = index + 1

#Return values
message = ""
stone_number = current_stone_number
stone_x_strength = x_length * 5
stone_y_strength = y_length * 5
result = [stone_number, stone_x_strength, stone_y_strength, message]

print(str(result)[1:-1].replace("'", ""))
'''




#########################
#=========start==========
#########################

# 벡터 각도 구하기
angle_list = [] #각도 리스트
angle = 45

#1사분면
# (angle,0) ~ (angle,angle)까지
for i in range(angle):
    angle_list.append([angle,i])
# (angle,angle) ~ (0,angle)까지
for i in range(angle):
    angle_list.append([angle-i, angle])
#2사분면
# (0,angle) ~ (-angle,angle)까지
for i in range(angle):
    angle_list.append([-i,angle])
# (-angle,angle) ~ (-angle,0)까지
for i in range(angle):
    angle_list.append([-angle,angle-i])
#3사분면
# (-angle,0) ~ (-angle,-angle)
for i in range(angle):
    angle_list.append([-angle, -i])
# (-angle,-angle) ~ (0,-angle)까지
for i in range(angle):
    angle_list.append([-angle+i, -angle])
#4사분면
# (0,-angle) ~ (angle,-angle)까지
for i in range(angle):
    angle_list.append([i,-angle])
# (angle,-angle) ~ (angle,0)까지
for i in range(angle):
    angle_list.append([angle,-angle+i])

#1단위로 변경
for i in range(angle*8):
    angle_list[i][0] = float(angle_list[i][0])/45
    angle_list[i][1] = float(angle_list[i][1])/45

#각 돌에 대하여 x_str, y_str 도출(크기는 신경 안쓰고 방향만)
stone_per_angle = []
for i in range(len(my_position)):
    stone_per_angle.append([])
    for j in angle_list:
        stone_per_angle[i].append([j[0]+my_position[i][0], j[1]+my_position[i][1]])






# 저 여기 있어요

x_vector = 0
y_vector = 0

pos = []
# 돌 갯수만큼 반복
for my_dol in my_position:
    for i in angle_list:
        pos.append(my_dol[0]+i[0], my_dol[1]+i[1])

    for your_dol in your_position:
        pass



# x_strength
# y_strength

# for x_strength in range(0,16000):
#     for y_strength in range(0,16000):
#         simulator(x_strength,y_strength)