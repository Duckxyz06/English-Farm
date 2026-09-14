extends Control
signal destination_chosen(point: Vector2)
var map_texture: Texture2D
var player: Node2D
var markers: Array[Vector2] = []

var last_position := Vector2.INF
var redraw_elapsed := 0.0

func _process(delta: float) -> void:
    redraw_elapsed += delta
    if redraw_elapsed>=0.1 and is_instance_valid(player):
        redraw_elapsed = 0.0
        if player.global_position!=last_position:
            last_position = player.global_position
            queue_redraw()

func _draw() -> void:
    if map_texture == null:
        return
    draw_texture_rect(map_texture,Rect2(Vector2.ZERO,size),false)
    for point in markers:
        draw_circle(point/Vector2(3072,2048)*size,3,Color("#fff5bc"))
    if is_instance_valid(player):
        var at := player.global_position/Vector2(3072,2048)*size
        draw_circle(at,5,Color("#392d23"))
        draw_circle(at,3.5,Color("#ffc45b"))

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
        destination_chosen.emit(event.position/size*Vector2(3072,2048))
        accept_event()
