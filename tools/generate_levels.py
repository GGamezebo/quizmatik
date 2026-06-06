import os

BASE = os.path.join(os.path.dirname(__file__), "..", "src", "levels")
SCRIPT_PATH = "res://src/common/game_config_default.gd"
CONFIG_PATH = os.path.join(os.path.dirname(__file__), "..", "src", "common", "levels", "levels_config.gd")

LEVEL_COUNT = 17
EXAM_LEVEL = 17

HEALTH = 3
MIN_QUESTIONS = 5
MAX_QUESTIONS = 18

BLOCKS = [
    {"id": "addition", "name": "Долина Сложения", "unlock_name": "is_unlocked_by_default", "unlock_args": [], "ops": 1},
    {"id": "subtraction", "name": "Долина Вычитания", "unlock_name": "is_unlocked_by_exam", "unlock_args": ["addition"], "ops": 2},
    {"id": "multiplication", "name": "Долина Умножения", "unlock_name": "is_unlocked_by_exam", "unlock_args": ["subtraction"], "ops": 4},
    {"id": "division", "name": "Долина Деления", "unlock_name": "is_unlocked_by_exam", "unlock_args": ["multiplication"], "ops": 8},
    {"id": "mix", "name": "Долина Смешения", "unlock_name": "is_unlocked_by_exam", "unlock_args": ["division"], "ops": 15},
]

# 4 этапа × 4 уровня + экзамен. HP всегда 3, вопросы 5→18.
# Лёгкость ранних уровней — за счёт скорости, линий и диапазона чисел.
LEVEL_CURVE = {
    # Этап 1 — разминка: 5–6 вопросов, 3 линии, медленно
    1: {"q": 5, "spd": 65, "lines": 3},
    2: {"q": 5, "spd": 72, "lines": 3},
    3: {"q": 6, "spd": 78, "lines": 3},
    4: {"q": 6, "spd": 88, "lines": 3},
    # Этап 2 — числа: 7–8 вопросов, переход к 4 линиям
    5: {"q": 7, "spd": 88, "lines": 3},
    6: {"q": 7, "spd": 98, "lines": 3},
    7: {"q": 8, "spd": 102, "lines": 4},
    8: {"q": 8, "spd": 108, "lines": 4},
    # Этап 3 — выносливость и скорость: 9–12 вопросов
    9: {"q": 9, "spd": 112, "lines": 4},
    10: {"q": 10, "spd": 120, "lines": 4},
    11: {"q": 11, "spd": 128, "lines": 4},
    12: {"q": 12, "spd": 138, "lines": 4},
    # Этап 4 — мастерство: 13–16 вопросов, ускорение ←/→
    13: {"q": 13, "spd": 148, "lines": 4, "acc_min": 0.75, "acc_max": 1.4},
    14: {"q": 14, "spd": 160, "lines": 4, "acc_min": 0.75, "acc_max": 1.4},
    15: {"q": 15, "spd": 172, "lines": 4, "acc_min": 0.65, "acc_max": 1.65},
    16: {"q": 16, "spd": 182, "lines": 4, "acc_min": 0.65, "acc_max": 1.65},
    # Экзамен — 18 вопросов, скорость чуть ниже пика
    17: {"q": 18, "spd": 170, "lines": 4, "acc_min": 0.65, "acc_max": 1.65},
}


def number_range(block_id: str, level_id: int) -> tuple[int, int]:
    if block_id in ("addition", "subtraction"):
        if level_id <= 4:
            return 1, 4
        if level_id <= 8:
            return 1, 6
        if level_id <= 12:
            return 1, 9
        if level_id <= 16:
            return 2, 10
        return 1, 12
    if block_id in ("multiplication", "division"):
        if level_id <= 4:
            return 2, 3
        if level_id <= 8:
            return 2, 5
        if level_id <= 12:
            return 2, 7
        if level_id <= 16:
            return 2, 9
        return 2, 10
    if level_id <= 4:
        return 2, 4
    if level_id <= 8:
        return 2, 6
    if level_id <= 12:
        return 2, 8
    return 2, 10


def make_tres(block: dict, level_id: int) -> str:
    params = LEVEL_CURVE[level_id]
    min_n, max_n = number_range(block["id"], level_id)
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
    ]
    if "acc_min" in params:
        lines.append(f'player_acceleration_min = {params["acc_min"]}')
        lines.append(f'player_acceleration_max = {params["acc_max"]}')
        lines.append("player_acceleration_speed = 1.0")
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
        '\t\t\t\tassert(false, "[Loader] Файл конфигурации не найден по пути: " + full_path)',
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
