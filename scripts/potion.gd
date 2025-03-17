extends Area2D

func potion():
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		global.potions_touched = true
		self.queue_free()
