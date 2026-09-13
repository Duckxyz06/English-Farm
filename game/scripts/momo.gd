extends CharacterBody2D

@export var speed := 260.0
var facing := Vector2.DOWN

func _ready() -> void:
    queue_redraw()

func _physics_process(delta: float) -> void:
    var direction := Vector2(
        Input.get_axis("move_left", "move_right"),
        Input.get_axis("move_up", "move_down")
    )

    if direction.length() > 0.05:
        direction = direction.normalized()
        facing = direction

    velocity = direction * speed
    var next_position := global_position + velocity * delta

    var parent_node := get_parent()
    if parent_node.has_method("is_walkable") and parent_node.is_walkable(next_position):
        global_position = next_position

    queue_redraw()

func _draw() -> void:
    # Pixel-art orange/white cat with green scarf, matching the project visual direction.
    draw_rect(Rect2(-22, -30, 44, 46), Color("#d98943"))
    draw_rect(Rect2(-17, -43, 13, 18), Color("#d98943"))
    draw_rect(Rect2(4, -43, 13, 18), Color("#d98943"))

    draw_rect(Rect2(-14, -24, 28, 24), Color("#fff0d2"))
    draw_rect(Rect2(-13, -18, 7, 7), Color("#403630"))
    draw_rect(Rect2(6, -18, 7, 7), Color("#403630"))
    draw_rect(Rect2(-3, -8, 6, 5), Color("#8f5e4c"))

    # Green scarf and leaf badge.
    draw_rect(Rect2(-25, 5, 50, 12), Color("#4f9a55"))
    draw_rect(Rect2(5, 14, 12, 18), Color("#3f7f45"))
    draw_rect(Rect2(-4, 7, 8, 8), Color("#d9f0a7"))

    # Body and paws.
    draw_rect(Rect2(-18, 16, 36, 31), Color("#d98943"))
    draw_rect(Rect2(-17, 38, 13, 14), Color("#fff0d2"))
    draw_rect(Rect2(4, 38, 13, 14), Color("#fff0d2"))

    # Tiny directional marker so movement direction is visible even before sprite animations arrive.
    var marker := facing.normalized() * 30.0
    draw_rect(Rect2(marker.x - 3, marker.y - 3, 6, 6), Color("#fff4b8"))
