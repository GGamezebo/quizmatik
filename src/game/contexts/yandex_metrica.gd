class_name YandexMetrica
extends RefCounted

## Yandex Metrica counter of the Yandex Games build (owned by `YandexContext`): loads `tag.js` once and sends
## `PlatformServices.ev_track` goals as `reachGoal`. Kids' audience → no Webvisor, no click map, no link
## tracking; visit length / returns come from the counter itself. `counter_id` 0 = off (nothing loaded).

var _counter_id: int = 0


func _init(counter_id: int) -> void:
	_counter_id = counter_id
	if _counter_id <= 0 or not OS.has_feature("web"):
		_counter_id = 0
		return
	JavaScriptBridge.eval("""
(function(m,e,t,r,i,k,a){m[i]=m[i]||function(){(m[i].a=m[i].a||[]).push(arguments)};
m[i].l=1*new Date();for(var j=0;j<e.scripts.length;j++){if(e.scripts[j].src===r){return;}}
k=e.createElement(t),a=e.getElementsByTagName(t)[0],k.async=1,k.src=r,a.parentNode.insertBefore(k,a)})
(window,document,"script","https://mc.yandex.ru/metrika/tag.js","ym");
ym(%d,"init",{clickmap:false,trackLinks:false,accurateTrackBounce:true,webvisor:false});
""" % _counter_id, true)


func reach_goal(goal: StringName, params: Dictionary) -> void:
	if _counter_id <= 0:
		return
	JavaScriptBridge.eval(
		"window.ym && ym(%d,'reachGoal',%s,%s);" % [_counter_id, JSON.stringify(String(goal)), JSON.stringify(params)],
		true
	)
