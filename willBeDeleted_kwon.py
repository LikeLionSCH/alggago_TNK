import sys
import json

with open('temp.json') as json_file:
    json_data = json.load(json_file)

my_position = []

for key in json_data["my_position"].keys():
    my_position.append(json_data["my_position"][key])

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

