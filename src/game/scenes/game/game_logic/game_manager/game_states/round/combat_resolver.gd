class_name CombatResolver
extends RefCounted

enum HitAction {
	CORRECT,
	WRONG_SHOT,
	WRONG_COLLISION,
}

static func resolve(answer: Answer, question: QuizQuestion.Question, via_collision: bool) -> HitAction:
	if answer.value == question.correct_answer:
		return HitAction.CORRECT
	if via_collision:
		return HitAction.WRONG_COLLISION
	return HitAction.WRONG_SHOT

static func apply_correct(
	player: Player,
	game_config: GameConfig,
	base_speed: float,
	base_min_generate: int,
	base_max_generate: int,
) -> bool:
	player.score += 1
	game_config.apply_answer_speed_after_round(player.score, base_speed)
	game_config.apply_generate_number_after_round(player.score, base_min_generate, base_max_generate)
	return player.score >= game_config.questions_count

static func apply_damage(player: Player) -> bool:
	player.health -= 1
	return player.health == 0
