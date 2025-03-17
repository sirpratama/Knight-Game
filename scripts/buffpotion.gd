extends Area2D

func buff_potion():
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		global.buff_potion_touched = true
		self.queue_free()
