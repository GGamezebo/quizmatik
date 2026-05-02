extends Resource
class_name EventManager

@warning_ignore("unused_signal") 
signal ev_explosion(answer:Answer)

@warning_ignore("unused_signal") 
signal ev_player_colladed(player:Player, answer:Answer)

@warning_ignore("unused_signal") 
signal ev_health_changed(health:int)
