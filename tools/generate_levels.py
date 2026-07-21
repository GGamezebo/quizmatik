import os

BASE = os.path.join(os.path.dirname(__file__), "..", "src", "levels")
SCRIPT_PATH = "res://src/common/game_config_default.gd"
CONFIG_PATH = os.path.join(os.path.dirname(__file__), "..", "src", "common", "levels", "levels_config.gd")

LEVEL_COUNT = 17
EXAM_LEVEL = 17

HEALTH = 3

BLOCKS = [
    {"id": "addition", "name": "Долина Сложения", "unlock_name": "is_unlocked_by_default", "unlock_args": [], "ops": 1},
    {"id": "subtraction", "name": "Долина Вычитания", "unlock_name": "is_unlocked_by_exam", "unlock_args": ["addition"], "ops": 2},
    {"id": "multiplication", "name": "Долина Умножения", "unlock_name": "is_unlocked_by_exam", "unlock_args": ["subtraction"], "ops": 4},
    {"id": "division", "name": "Долина Деления", "unlock_name": "is_unlocked_by_exam", "unlock_args": ["multiplication"], "ops": 8},
    {"id": "mix", "name": "Долина Смешения", "unlock_name": "is_unlocked_by_exam", "unlock_args": ["division"], "ops": 15},
]

# 4 acts x 4 levels + exam. HP always 3, questions 5-18.
# Base speed is moderate; answer_speed_round_coeffs ramps difficulty mid-battle.
LEVEL_CURVE = {
    # Act 1 — warmup, no or mild in-battle acceleration
    1: {"q": 5, "spd": 58, "lines": 3, "round_coeffs": {}},
    2: {"q": 5, "spd": 62, "lines": 3, "round_coeffs": {}},
    3: {"q": 6, "spd": 65, "lines": 3, "round_coeffs": {4: 1.1}},
    4: {"q": 6, "spd": 70, "lines": 3, "round_coeffs": {4: 1.15}},
    # Act 2 — numbers grow, first real speed ramps
    5: {"q": 7, "spd": 72, "lines": 3, "round_coeffs": {4: 1.1, 6: 1.2}},
    6: {"q": 7, "spd": 78, "lines": 3, "round_coeffs": {4: 1.15, 7: 1.25}},
    7: {"q": 8, "spd": 80, "lines": 4, "round_coeffs": {4: 1.15, 7: 1.25}},
    8: {"q": 8, "spd": 85, "lines": 4, "round_coeffs": {4: 1.2, 8: 1.3}},
    # Act 3 — endurance; speed ramps at ~40%, ~70%, and final round
    9: {"q": 9, "spd": 88, "lines": 4, "round_coeffs": {4: 1.15, 7: 1.3, 9: 1.4}},
    10: {"q": 10, "spd": 92, "lines": 4, "round_coeffs": {4: 1.2, 7: 1.3, 10: 1.45}},
    11: {"q": 11, "spd": 96, "lines": 4, "round_coeffs": {4: 1.2, 8: 1.35, 11: 1.45}},
    12: {"q": 12, "spd": 100, "lines": 4, "round_coeffs": {4: 1.2, 8: 1.35, 12: 1.5}},
    # Act 4 — plane acceleration + stronger mid-battle ramps
    13: {"q": 13, "spd": 95, "lines": 4, "round_coeffs": {5: 1.2, 9: 1.35, 13: 1.5}, "acc_min": 0.75, "acc_max": 1.4},
    14: {"q": 14, "spd": 98, "lines": 4, "round_coeffs": {5: 1.2, 9: 1.35, 14: 1.5}, "acc_min": 0.75, "acc_max": 1.4},
    15: {"q": 15, "spd": 100, "lines": 4, "round_coeffs": {5: 1.25, 10: 1.4, 15: 1.55}, "acc_min": 0.65, "acc_max": 1.65},
    16: {"q": 16, "spd": 102, "lines": 4, "round_coeffs": {5: 1.25, 10: 1.45, 16: 1.6}, "acc_min": 0.65, "acc_max": 1.65},
    # Exam — long fight with steady escalation
    17: {
        "q": 18,
        "spd": 95,
        "lines": 4,
        "round_coeffs": {6: 1.15, 12: 1.3, 15: 1.45, 18: 1.55},
        "acc_min": 0.65,
        "acc_max": 1.65,
        "early_exam_questions_multiplier": 1.5,
        "early_exam_answer_speed_multiplier": 1.25,
    },
}


# Addition: both operands grow with level so late stages yield e.g. 22+87.
# min rises too so hard levels are not diluted by tiny sums.
ADDITION_NUMBER_RANGE = {
    # Act 1 — single digits / small tens
    1: (1, 5),
    2: (1, 7),
    3: (1, 9),
    4: (2, 12),
    # Act 2 — teens → low twenties
    5: (2, 16),
    6: (3, 20),
    7: (4, 25),
    8: (5, 32),
    # Act 3 — solid two-digit
    9: (6, 40),
    10: (8, 48),
    11: (10, 58),
    12: (12, 68),
    # Act 4 — large two-digit
    13: (15, 78),
    14: (18, 85),
    15: (20, 92),
    16: (22, 97),
    # Exam — start mid; generate_number_round_ranges ramps during battle
    17: (5, 25),
}

# score → (min, max); same thresholds as exam answer_speed_round_coeffs
ADDITION_EXAM_NUMBER_ROUND_RANGES = {
    6: (10, 40),
    12: (15, 60),
    15: (20, 80),
    18: (25, 99),
}


def number_range(block_id: str, level_id: int) -> tuple[int, int]:
    if block_id == "addition":
        return ADDITION_NUMBER_RANGE[level_id]
    if block_id == "subtraction":
        if level_id <= 4:
            return 1, 4
        if level_id <= 8:
            return 1, 7
        if level_id <= 12:
            return 1, 9
        if level_id <= 16:
            return 2, 12
        return 1, 15
    if block_id in ("multiplication", "division"):
        if level_id <= 4:
            return 2, 3
        if level_id <= 8:
            return 2, 6
        if level_id <= 12:
            return 2, 8
        if level_id <= 16:
            return 2, 10
        return 2, 12
    if level_id <= 4:
        return 2, 4
    if level_id <= 8:
        return 2, 7
    if level_id <= 12:
        return 2, 9
    return 2, 12


def format_round_coeffs_tres(round_coeffs: dict) -> list[str]:
    if not round_coeffs:
        return ["answer_speed_round_coeffs = {}"]
    lines = ["answer_speed_round_coeffs = {"]
    for round_num in sorted(round_coeffs.keys()):
        coeff = round_coeffs[round_num]
        if coeff == int(coeff):
            lines.append(f"{round_num}: {int(coeff)}.0,")
        else:
            lines.append(f"{round_num}: {coeff},")
    lines.append("}")
    return lines


def format_number_round_ranges_tres(ranges: dict) -> list[str]:
    if not ranges:
        return []
    lines = ["generate_number_round_ranges = {"]
    for score in sorted(ranges.keys()):
        min_n, max_n = ranges[score]
        lines.append(f"{score}: {{")
        lines.append(f'"min_generate_number": {min_n},')
        lines.append(f'"max_generate_number": {max_n},')
        lines.append("},")
    lines.append("}")
    return lines


def make_tres(block: dict, level_id: int) -> str:
    params = LEVEL_CURVE[level_id]
    min_n, max_n = number_range(block["id"], level_id)
    round_coeffs = params.get("round_coeffs", {})
    number_round_ranges = {}
    if block["id"] == "addition" and level_id == EXAM_LEVEL:
        number_round_ranges = ADDITION_EXAM_NUMBER_ROUND_RANGES
    lines = [
        '[gd_resource type="Resource" script_class="GameConfig" load_steps=2 format=3]',
        "",
        f'[ext_resource type="Script" path="{SCRIPT_PATH}" id="1_script"]',
        "",
        "[resource]",
        'script = ExtResource("1_script")',
        f'allowed_operations = {block["ops"]}',
        f"min_generate_number = {min_n}",
        f"max_generate_number = {max_n}",
        f'answer_lines_count = {params["lines"]}',
        f"health = {HEALTH}",
        f'questions_count = {params["q"]}',
        f'answer_speed = {float(params["spd"])}',
        *format_round_coeffs_tres(round_coeffs),
        *format_number_round_ranges_tres(number_round_ranges),
    ]
    if "acc_min" in params:
        lines.append(f'player_acceleration_min = {params["acc_min"]}')
        lines.append(f'player_acceleration_max = {params["acc_max"]}')
        lines.append("player_acceleration_speed = 1.0")
    if "early_exam_questions_multiplier" in params:
        lines.append(f'early_exam_questions_multiplier = {params["early_exam_questions_multiplier"]}')
        lines.append(f'early_exam_answer_speed_multiplier = {params["early_exam_answer_speed_multiplier"]}')
    return "\n".join(lines) + "\n"


def format_unlock_args(args: list[str]) -> str:
    if not args:
        return "[]"
    return "[" + ", ".join(f'"{a}"' for a in args) + "]"


def make_levels_config() -> str:
    containers = []
    for block in BLOCKS:
        level_entries = []
        for level_id in range(1, LEVEL_COUNT + 1):
            entry = f'\t\t\t\t{{ "level_id": {level_id}, "config": \'level_{level_id}\''
            if level_id == EXAM_LEVEL:
                entry += ", 'is_exam': true"
            entry += " },"
            level_entries.append(entry)
        args = format_unlock_args(block["unlock_args"])
        container = "\n".join([
            "\t\t{",
            f'\t\t\t"container_id": "{block["id"]}",',
            f'\t\t\t"name": "{block["name"]}",',
            '\t\t\t"unlock_condition": {',
            f'\t\t\t\t"name": "{block["unlock_name"]}",',
            f"\t\t\t\t\"args\": {args},",
            "\t\t\t},",
            '\t\t\t"levels": [',
            *level_entries,
            "\t\t\t]",
            "\t\t}",
        ])
        containers.append(container)

    return "\n".join([
        "class_name LevelsConfig",
        "extends Resource",
        "",
        '@export_dir var levels_dir = "res://src/levels"',
        "",
        "var levels = {",
        '   "containers": [',
        ",\n".join(containers),
        "\t],",
        "}",
        "",
        "func _init() -> void:",
        '\tfor container in levels["containers"]:',
        '\t\tvar container_id: String = container["container_id"]',
        '\t\tfor level_data in container["levels"]:',
        '\t\t\tvar config_name = level_data["config"]',
        '\t\t\tvar file_name = config_name + ".tres"',
        '\t\t\tvar full_path = levels_dir.path_join(container_id).path_join(file_name)',
        "",
        "\t\t\tif ResourceLoader.exists(full_path):",
        '\t\t\t\tlevel_data["config"] = ResourceLoader.load(full_path)',
        '\t\t\t\tprint("[Loader] Level config loaded successfully for level", level_data["level_id"], ": ", full_path)',
        "\t\t\telse:",
        '\t\t\t\tassert(false, "[Loader] Level config not found: " + full_path)',
        "",
        "func find_container_in_config(container_id: String) -> Dictionary:",
        '\tif not levels.has("containers") or not (levels["containers"] is Array):',
        '\t\tpush_error("[ProgressManager] Error: Invalid level configuration format.")',
        "\t\treturn {}",
        "",
        '\tfor container in levels["containers"]:',
        '\t\tif container.get("container_id") == container_id:',
        "\t\t\treturn container",
        "",
        '\tpush_warning("[ProgressManager] Warning: Container \'" + container_id + "\' not found in configuration.")',
        "\treturn {}",
        "",
        "func get_level_config(container_id: String, level_id: int) -> GameConfig:",
        "\tvar container: Dictionary = find_container_in_config(container_id)",
        "\tif container.is_empty():",
        "\t\treturn null",
        "",
        '\tfor level in container["levels"]:',
        '\t\tif level.get("level_id") == level_id:',
        "\t\t\treturn level['config']",
        "",
        '\tpush_warning("[ProgressManager] Warning: Level \'" + str(level_id) + "\' not found in container \'" + container_id + "\'.")',
        "\treturn null",
        "",
        "func is_level_exam(container_id: String, level_id: int) -> bool:",
        "\tvar container: Dictionary = find_container_in_config(container_id)",
        "\tif container.is_empty():",
        "\t\treturn false",
        "",
        '\tfor level in container["levels"]:',
        '\t\tif level.get("level_id") == level_id:',
        "\t\t\treturn level.get('is_exam', false)",
        "",
        '\tpush_warning("[ProgressManager] Warning: Level \'" + str(level_id) + "\' not found in container \'" + container_id + "\'.")',
        "\treturn false",
        "",
    ])


def main() -> None:
    tres_count = 0
    removed_count = 0
    for block in BLOCKS:
        folder = os.path.join(BASE, block["id"])
        os.makedirs(folder, exist_ok=True)
        for level_id in range(1, LEVEL_COUNT + 1):
            path = os.path.join(folder, f"level_{level_id}.tres")
            with open(path, "w", encoding="utf-8", newline="\n") as file:
                file.write(make_tres(block, level_id))
            tres_count += 1
        for level_id in range(LEVEL_COUNT + 1, 25):
            stale = os.path.join(folder, f"level_{level_id}.tres")
            if os.path.exists(stale):
                os.remove(stale)
                removed_count += 1

    with open(CONFIG_PATH, "w", encoding="utf-8", newline="\n") as file:
        file.write(make_levels_config())

    print(f"Created {tres_count} level .tres files")
    print(f"Removed {removed_count} stale level files")
    print(f"Updated {CONFIG_PATH}")


if __name__ == "__main__":
    main()
