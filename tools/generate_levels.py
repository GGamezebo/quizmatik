"""Campaign levels: src/levels/{valley}/level_1..20.tres (20 = exam).

Curriculum for kids 7-10 (Russian primary school order): each valley = 19 regular levels in 4 acts
(new skill → practice → mix) + exam that climbs through every act's skill (score stages).
Pace is authored as `t` = seconds a balloon needs to reach the plane on NORMAL difficulty
(BattleDifficulty: EASY ≈ +40% time, HARD ≈ −25%); speed = TRAVEL_PX / t.

Run: python tools/generate_levels.py  (rewrites only level .tres; levels_config.gd is hand-edited).
"""
import os
import re

BASE = os.path.join(os.path.dirname(__file__), "..", "src", "levels")
SCRIPT_PATH = "res://src/common/game_config_default.gd"

LEVEL_COUNT = 20
EXAM_LEVEL = 20
HEALTH = 3
# Balloon spawn x (1380) → plane nose (~280) at 1280×720.
TRAVEL_PX = 1100.0

ADD, SUB, MUL, DIV = 1, 2, 4, 8
CARRY_ANY, CARRY_NONE, CARRY_REQUIRED = 0, 1, 2

TIMED_LEVELS = {9: 60.0, 17: 60.0}
# Guaranteed mini-boss (armor 3): early taste on L2 + L5, end of acts 2 and 3.
BOSS_LEVELS = {2, 5, 10, 15}
EXAM_BOSS_ARMOR = 6  # every plate slot = max HP
EXAM_BOSS_RAGE_HITS = 20
EXAM_QUESTIONS = 15
EXAM_STAGE_SCORES = (4, 8, 12)


def op(a, b=None, res=None):
    """First operand range, second operand range, allowed answer range (tuples)."""
    return {"a": a, "b": b, "res": res}


def lvl(t, q, ops, carry=CARRY_ANY, intro=False, **extra):
    return {"t": t, "q": q, "ops": ops, "carry": carry, "intro": intro, **extra}


def stage(t, ops, carry=CARRY_ANY):
    return {"t": t, "ops": ops, "carry": carry}


# --- Addition: within 10 → through ten (within 20) → within 100 -----------------------------
A_10 = {ADD: op((1, 9), (1, 9), (2, 10))}
A_20_CROSS = {ADD: op((2, 9), (2, 9), (11, 18))}
A_2D_1D = {ADD: op((10, 89), (2, 9), (12, 99))}
A_2D_2D_NO_CARRY = {ADD: op((10, 80), (10, 50), (20, 99))}
A_2D_2D = {ADD: op((10, 79), (10, 49), (20, 100))}

ADDITION = {
    1: lvl(18, 6, {ADD: op((1, 5), (1, 2))}, intro=True),
    2: lvl(16, 6, {ADD: op((1, 7), (1, 3), (2, 10))}),
    3: lvl(15, 7, A_10),
    4: lvl(14, 7, {ADD: op((1, 9), (1, 9), (7, 10))}),
    5: lvl(12, 8, A_10),
    6: lvl(15, 7, {ADD: op((10, 15), (1, 4), (11, 19))}, CARRY_NONE, intro=True),
    7: lvl(16, 7, {ADD: op((2, 9), (8, 9), (11, 18))}, intro=True),
    8: lvl(15, 8, A_20_CROSS),
    9: lvl(13, 0, {ADD: op((1, 9), (1, 9), (2, 18))}),
    10: lvl(13, 9, {ADD: op((2, 15), (2, 9), (5, 20))}),
    11: lvl(15, 8, {ADD: op((10, 89), (1, 9), (11, 99))}, CARRY_NONE, intro=True),
    12: lvl(17, 8, {ADD: op((11, 89), (2, 9), (20, 99))}, CARRY_REQUIRED, intro=True),
    13: lvl(17, 8, A_2D_2D_NO_CARRY, CARRY_NONE, intro=True),
    14: lvl(14, 9, A_2D_1D),
    15: lvl(20, 8, {ADD: op((11, 69), (11, 39), (30, 100))}, CARRY_REQUIRED, intro=True),
    16: lvl(18, 9, A_2D_2D),
    17: lvl(14, 0, A_2D_1D),
    18: lvl(16, 10, {ADD: op((10, 89), (2, 39), (12, 100))}),
    19: lvl(17, 10, {ADD: op((15, 79), (15, 49), (30, 100))}),
    20: [
        stage(12, {ADD: op((2, 9), (2, 9), (5, 18))}),
        stage(14, A_2D_1D),
        stage(16, A_2D_2D_NO_CARRY, CARRY_NONE),
        stage(17, A_2D_2D),
    ],
}

# --- Subtraction: within 10 → through ten → within 100; act 4 mixes + and − -------------------
S_2D_1D = {SUB: op((20, 99), (2, 9))}
S_2D_2D = {SUB: op((30, 99), (10, 59), (5, 89))}

SUBTRACTION = {
    1: lvl(16, 6, {SUB: op((2, 10), (1, 2))}, intro=True),
    2: lvl(15, 6, {SUB: op((3, 10), (1, 5), (1, 9))}),
    3: lvl(14, 7, {SUB: op((2, 10), (1, 9), (1, 9))}),
    4: lvl(13, 7, {SUB: op((10, 10), (1, 9))}),
    5: lvl(12, 8, {SUB: op((2, 10), (1, 9))}),
    6: lvl(14, 7, {SUB: op((11, 19), (1, 9), (10, 18))}, CARRY_NONE, intro=True),
    7: lvl(16, 7, {SUB: op((11, 18), (2, 9), (2, 9))}, CARRY_REQUIRED, intro=True),
    8: lvl(15, 8, {SUB: op((11, 18), (8, 9), (2, 9))}, CARRY_REQUIRED),
    9: lvl(13, 0, {SUB: op((2, 18), (1, 9), (1, 17))}),
    10: lvl(13, 9, {SUB: op((11, 20), (2, 9), (2, 18))}),
    11: lvl(15, 8, {SUB: op((20, 99), (1, 9), (11, 98))}, CARRY_NONE, intro=True),
    12: lvl(17, 8, S_2D_1D, CARRY_REQUIRED, intro=True),
    13: lvl(17, 8, {SUB: op((30, 99), (10, 60), (10, 89))}, CARRY_NONE, intro=True),
    14: lvl(14, 9, S_2D_1D),
    15: lvl(21, 8, {SUB: op((30, 99), (11, 59), (5, 88))}, CARRY_REQUIRED, intro=True),
    16: lvl(18, 9, S_2D_2D),
    17: lvl(14, 0, S_2D_1D),
    18: lvl(16, 10, {ADD: op((10, 79), (2, 29), (12, 100)), SUB: op((20, 99), (2, 29), (5, 97))}),
    19: lvl(17, 10, {**A_2D_2D, **S_2D_2D}),
    20: [
        stage(12, {SUB: op((2, 10), (1, 9), (1, 9))}),
        stage(14, {SUB: op((11, 18), (2, 9), (2, 9))}, CARRY_REQUIRED),
        stage(15, S_2D_1D),
        stage(17, {**A_2D_2D, **S_2D_2D}),
    ],
}


# --- Multiplication / division: one table at a time (2, 3, 4, 5 → 6, 7 → 8, 9) -----------------
def table(operation, rows, cols=(2, 10)):
    return {operation: op(rows, cols)}


def table_valley(operation, slow):
    """`slow` = extra seconds (division is the harder direction)."""
    t = lambda base: base + slow
    full = table(operation, (2, 9), (2, 9))
    return {
        1: lvl(t(15), 6, table(operation, (2, 2)), intro=True),
        2: lvl(t(15), 6, table(operation, (3, 3)), intro=True),
        3: lvl(t(13), 7, table(operation, (2, 3))),
        4: lvl(t(15), 7, table(operation, (4, 4)), intro=True),
        5: lvl(t(13), 7, table(operation, (5, 5)), intro=True),
        6: lvl(t(13), 8, table(operation, (2, 5))),
        7: lvl(t(16), 7, table(operation, (6, 6)), intro=True),
        8: lvl(t(16), 7, table(operation, (7, 7)), intro=True),
        9: lvl(t(12), 0, table(operation, (2, 5))),
        10: lvl(t(15), 8, table(operation, (6, 7))),
        11: lvl(t(16), 7, table(operation, (8, 8)), intro=True),
        12: lvl(t(16), 7, table(operation, (9, 9)), intro=True),
        13: lvl(t(15), 8, table(operation, (8, 9))),
        14: lvl(t(15), 9, table(operation, (6, 9), (2, 9))),
        15: lvl(t(14), 9, full),
        16: (
            lvl(t(15), 9, full, missing=0.5, missing_start=0.0)
            if operation == MUL
            else lvl(t(14), 9, {**table(MUL, (2, 9), (2, 9)), **full})
        ),
        17: lvl(t(13), 0, full),
        18: lvl(t(14), 10, table(operation, (6, 9), (6, 9))),
        19: (
            lvl(t(13), 10, table(operation, (2, 10), (2, 10)))
            if operation == MUL
            else lvl(t(13), 10, {**table(MUL, (2, 10), (2, 10)), **table(DIV, (2, 10), (2, 10))}, missing=0.4)
        ),
        20: [
            stage(t(12), table(operation, (2, 5))),
            stage(t(14), table(operation, (6, 7))),
            stage(t(14), table(operation, (8, 9))),
            stage(t(13), table(operation, (2, 10), (2, 10))),
        ],
    }


MULTIPLICATION = table_valley(MUL, 0)
DIVISION = table_valley(DIV, 2)

# --- Mix: all four operations, grade 3-4 (incl. 2-digit × 1-digit and 3-digit ± 1-digit) -------
M_AS_20 = {ADD: op((2, 9), (2, 9), (5, 18)), SUB: op((11, 18), (2, 9), (2, 9))}
M_AS_100 = {ADD: op((10, 89), (2, 9), (12, 99)), SUB: op((20, 99), (2, 9))}
M_AS_2D = {**A_2D_2D, **S_2D_2D}
M_MD_5 = {MUL: op((2, 5), (2, 10)), DIV: op((2, 5), (2, 10))}
M_MD_9 = {MUL: op((2, 9), (2, 9)), DIV: op((2, 9), (2, 9))}
M_MD_10 = {MUL: op((2, 10), (2, 10)), DIV: op((2, 10), (2, 10))}
M_MD_BIG = {MUL: op((11, 19), (2, 5), (22, 95)), DIV: op((2, 5), (11, 19))}

MIX = {
    1: lvl(14, 8, M_AS_20),
    2: lvl(14, 8, M_MD_5),
    3: lvl(14, 8, {**M_AS_20, **M_MD_5}),
    4: lvl(15, 8, M_AS_100),
    5: lvl(15, 8, M_MD_9),
    6: lvl(15, 9, {**M_AS_100, **M_MD_9}),
    7: lvl(18, 8, M_AS_2D),
    8: lvl(22, 7, M_MD_BIG, intro=True),
    9: lvl(13, 0, {**M_AS_20, **M_MD_9}),
    10: lvl(15, 10, {**M_AS_100, **M_MD_10}),
    11: lvl(17, 9, {**M_AS_2D, MUL: op((2, 9), (2, 9))}),
    12: lvl(22, 8, {MUL: op((11, 25), (2, 4), (22, 100)), DIV: op((2, 4), (11, 25))}),
    13: lvl(17, 10, {**M_AS_2D, **M_MD_10}),
    14: lvl(17, 9, {ADD: op((100, 990), (2, 9)), SUB: op((100, 999), (2, 9))}, intro=True),
    15: lvl(22, 8, {MUL: op((11, 30), (2, 5), (22, 150)), DIV: op((2, 5), (11, 30))}),
    16: lvl(17, 10, {**M_AS_100, **M_MD_9}, missing=0.5, missing_start=0.0),
    17: lvl(14, 0, {**M_AS_100, **M_MD_9}),
    18: lvl(16, 10, {**M_AS_2D, **M_MD_10}),
    19: lvl(18, 10, {**M_AS_2D, MUL: op((11, 19), (2, 5), (22, 95)), DIV: op((2, 9), (2, 12))}),
    20: [
        stage(13, {**M_AS_20, **M_MD_5}),
        stage(15, {**M_AS_100, **M_MD_9}),
        stage(17, {**M_AS_2D, **M_MD_10}),
        stage(19, {**M_AS_2D, **M_MD_BIG}),
    ],
}

VALLEYS = {
    "addition": ADDITION,
    "subtraction": SUBTRACTION,
    "multiplication": MULTIPLICATION,
    "division": DIVISION,
    "mix": MIX,
}


def speed(t: float) -> float:
    return round(TRAVEL_PX / t, 1)


def lines_count(level_id: int) -> int:
    return 3 if level_id <= 3 else 4


# `? + 3 = 7` share and the battle share before it starts (GameConfig.missing_operand_*).
def missing_operand(level_id: int, params: dict) -> tuple[float, float]:
    if "missing" in params:
        return params["missing"], params.get("missing_start", 0.0)
    if level_id == EXAM_LEVEL:
        return 0.25, 0.25
    if level_id <= 5 or params.get("intro"):
        return 0.0, 0.0
    if level_id <= 10:
        return 0.2, 0.5
    return 0.3, 0.3


# Mid-battle speed-up for fluency (none while a skill is new).
def round_coeffs(level_id: int, params: dict) -> dict:
    if level_id in TIMED_LEVELS:
        return {4: 1.1, 8: 1.2}
    q = params["q"]
    if params.get("intro") or level_id <= 4:
        return {}
    if level_id <= 10:
        return {(q + 1) // 2: 1.1}
    return {(q + 1) // 2: 1.1, round(q * 0.8): 1.2}


def bonus_gold_chance(level_id: int) -> float:
    return 0.0 if level_id == EXAM_LEVEL or level_id < 3 else 0.35


def boss_chance(level_id: int) -> float:
    if level_id == EXAM_LEVEL or level_id in BOSS_LEVELS:
        return 1.0
    if level_id < 3 or level_id in TIMED_LEVELS:
        return 0.0
    return 0.25


# --- Godot text serialization ------------------------------------------------------------------
def gd(value) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        return f"{value:.1f}" if value == int(value) else repr(round(value, 4))
    if isinstance(value, str):
        return f'"{value}"'
    if isinstance(value, tuple):
        return f"Vector2i({value[0]}, {value[1]})"
    if isinstance(value, dict):
        if not value:
            return "{}"
        return "{\n" + ",\n".join(f"{gd(k)}: {gd(v)}" for k, v in value.items()) + "\n}"
    raise TypeError(value)


def ops_fields(ops: dict, carry: int) -> dict:
    """GameConfig fields for one setup (`ops` = {op: op(...)})."""
    flags = 0
    first, second, result = {}, {}, {}
    for operation in sorted(ops):
        spec = ops[operation]
        flags |= operation
        first[operation] = spec["a"]
        if spec["b"] is not None:
            second[operation] = spec["b"]
        if spec["res"] is not None:
            result[operation] = spec["res"]
    lows = [r[0] for r in first.values()]
    highs = [r[1] for r in first.values()]
    return {
        "allowed_operations": flags,
        "min_generate_number": min(lows),
        "max_generate_number": max(highs),
        "operation_ranges": first,
        "second_operand_ranges": second,
        "result_ranges": result,
        "carry_mode": carry,
    }


def level_fields(valley: dict, level_id: int) -> dict:
    """Ordered GameConfig fields for a level (defaults omitted)."""
    params = valley[level_id]
    is_exam = level_id == EXAM_LEVEL
    fields = {}
    if is_exam:
        stages = params
        base = stages[0]
        params = {"t": base["t"], "q": EXAM_QUESTIONS, "ops": base["ops"], "carry": base["carry"]}
    setup = ops_fields(params["ops"], params["carry"])
    fields["allowed_operations"] = setup["allowed_operations"]
    fields["min_generate_number"] = setup["min_generate_number"]
    fields["max_generate_number"] = setup["max_generate_number"]
    fields["answer_lines_count"] = lines_count(level_id)
    fields["health"] = HEALTH
    fields["questions_count"] = params["q"] if params["q"] > 0 else 10
    fields["answer_speed"] = speed(params["t"])
    if is_exam:
        coeffs, ranges = {}, {}
        for score, step in zip(EXAM_STAGE_SCORES, stages[1:]):
            coeffs[score] = round(base["t"] / step["t"], 2)
            step_setup = ops_fields(step["ops"], step["carry"])
            step_setup.pop("min_generate_number")
            step_setup.pop("max_generate_number")
            ranges[score] = step_setup
        fields["answer_speed_round_coeffs"] = coeffs
        fields["generate_number_round_ranges"] = ranges
    else:
        fields["answer_speed_round_coeffs"] = {k: float(v) for k, v in round_coeffs(level_id, params).items()}
    for key in ("operation_ranges", "second_operand_ranges", "result_ranges"):
        if setup[key]:
            fields[key] = setup[key]
    if setup["carry_mode"] != CARRY_ANY:
        fields["carry_mode"] = setup["carry_mode"]
    chance, start = missing_operand(level_id, params)
    if chance > 0.0:
        fields["missing_operand_chance"] = chance
        if start > 0.0:
            fields["missing_operand_start_progress"] = start
    if level_id in TIMED_LEVELS:
        fields["time_limit_sec"] = TIMED_LEVELS[level_id]
    bonus = bonus_gold_chance(level_id)
    if bonus > 0.0:
        fields["bonus_gold_chance"] = bonus
    boss = boss_chance(level_id)
    if boss > 0.0:
        fields["boss_chance"] = boss
        if is_exam:
            fields["boss_armor"] = EXAM_BOSS_ARMOR
            fields["boss_royal"] = True
            fields["boss_rage_hits"] = EXAM_BOSS_RAGE_HITS
    if is_exam:
        fields["early_exam_questions_multiplier"] = 1.3
        fields["early_exam_answer_speed_multiplier"] = 1.15
    return fields


def existing_uid(path: str) -> str:
    if not os.path.exists(path):
        return ""
    with open(path, encoding="utf-8") as file:
        match = re.search(r'^\[gd_resource[^\]]*uid="(uid://[a-z0-9]+)"', file.read(), re.M)
    return match.group(1) if match else ""


def make_tres(valley: dict, level_id: int, uid: str) -> str:
    uid_attr = f' uid="{uid}"' if uid else ""
    lines = [
        f'[gd_resource type="Resource" script_class="GameConfig" format=3{uid_attr}]',
        "",
        f'[ext_resource type="Script" path="{SCRIPT_PATH}" id="1_script"]',
        "",
        "[resource]",
        'script = ExtResource("1_script")',
    ]
    for key, value in level_fields(valley, level_id).items():
        lines.append(f"{key} = {gd(value)}")
    return "\n".join(lines) + "\n"


def main() -> None:
    written = removed = 0
    for valley_id, valley in VALLEYS.items():
        assert sorted(valley) == list(range(1, LEVEL_COUNT + 1)), valley_id
        folder = os.path.join(BASE, valley_id)
        os.makedirs(folder, exist_ok=True)
        for level_id in range(1, LEVEL_COUNT + 1):
            path = os.path.join(folder, f"level_{level_id}.tres")
            content = make_tres(valley, level_id, existing_uid(path))
            with open(path, "w", encoding="utf-8", newline="\n") as file:
                file.write(content)
            written += 1
        for level_id in range(LEVEL_COUNT + 1, 40):
            for suffix in (".tres", ".tres.import"):
                stale = os.path.join(folder, f"level_{level_id}{suffix}")
                if os.path.exists(stale):
                    os.remove(stale)
                    removed += 1
    print(f"Wrote {written} level .tres, removed {removed} stale files")


if __name__ == "__main__":
    main()
