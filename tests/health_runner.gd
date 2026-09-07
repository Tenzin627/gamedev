extends Node
func _ready() -> void:
    GameSession.set_value(&"slice.welcomed",true)
    var health: Node = Node.new()
    health.set_script(load("res://tests/project_health_check.gd"))
    add_child(health)
    for i: int in range(60): await get_tree().process_frame
    get_tree().quit()
