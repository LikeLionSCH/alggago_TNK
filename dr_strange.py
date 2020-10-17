MAX = 1
MIN = 0

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


def generate_json():
    pass


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