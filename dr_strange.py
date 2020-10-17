MAX = 1
MIN = 0

def predict(prefix, my_turn, positions):
    if not my_turn:
        positions[0], positions[1] = positions[1], positions[0]

    generate_json(prefix, positions[0], positions[1])
    simulate()

    if get_game_state() == GAME_STATE_WIN:
        return 1000
    
    if get_game_state() == GAME_STATE_LOSE:
        return -1000

    score1, score2, score3 = get_scores(MAX if my_turn else MIN, 3)

    predict(prefix + '_1', not my_turn, score1.positions)
    predict(prefix + '_2', not my_turn, score2.positions)
    predict(prefix + '_3', not my_turn, score3.positions)

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