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
