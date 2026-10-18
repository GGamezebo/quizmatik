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
	apply_streak(player, game_config)
	if game_config.is_staged():
		return false  # difficulty follows time (`EndlessDirector`); endless never won by count, magister by timer
	game_config.apply_answer_speed_after_round(player.score, base_speed)
	game_config.apply_generate_number_after_round(player.score, base_min_generate, base_max_generate)
	return not game_config.is_timed() and player.score >= game_config.questions_count

## +1 streak; every `streak_heal_every` in a row restores a heart up to `streak_heal_max_health`.
## Staged battles (endless, magister) never heal by streak — only heart balloons.
static func apply_streak(player: Player, game_config: GameConfig) -> void:
	player.streak += 1
	if game_config.is_staged():
		return
	var every: int = game_config.streak_heal_every
	if every > 0 and player.streak % every == 0 and player.health < game_config.streak_heal_max_health:
		player.health += 1

static func apply_damage(player: Player) -> bool:
	player.streak = 0
	player.health -= 1
	return player.health == 0
