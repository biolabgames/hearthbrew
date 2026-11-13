extends Control

signal action_requested(action: String, index: int)

func _on_action(action: String, index: int = -1):
	action_requested.emit(action, index)
