extends Control
signal map_open_requested
signal point_selected(point: Vector2)
const WORLD_SIZE := Vector2(3072,2048)
const FRAME = preload("res://game/assets/ui/map_frame.png")
var map_texture: Texture2D
var player: Node2D
var markers: Array[Dictionary] = []
var expanded := false
var selected_point := Vector2.INF
var preview_route := PackedVector2Array()
var zoom := 1.0
var center := WORLD_SIZE*0.5
var last_position := Vector2.INF
var redraw_elapsed := 0.0

func map_rect() -> Rect2:
    return Rect2(size*Vector2(0.076,0.117),size*Vector2(0.849,0.76))

func view_rect() -> Rect2:
    var extent := WORLD_SIZE/zoom
    center = center.clamp(extent*0.5,WORLD_SIZE-extent*0.5)
    return Rect2(center-extent*0.5,extent)

func world_to_map(point: Vector2) -> Vector2:
    var area := map_rect()
    var view := view_rect()
    return area.position+(point-view.position)/view.size*area.size

func map_to_world(point: Vector2) -> Vector2:
    var area := map_rect()
    var view := view_rect()
    return view.position+(point-area.position)/area.size*view.size

func reset_view() -> void:
    zoom = 1.0
    center = WORLD_SIZE*0.5
    queue_redraw()

func set_zoom(value: float, anchor: Vector2 = Vector2.INF) -> void:
    var area := map_rect()
    var at := area.get_center() if not anchor.is_finite() else anchor
    var before := map_to_world(at)
    zoom = clampf(value,1.0,2.5)
    center = before-(at-area.get_center())/area.size*(WORLD_SIZE/zoom)
    view_rect()
    queue_redraw()

func _process(delta: float) -> void:
    if not is_visible_in_tree():
        return
    redraw_elapsed += delta
    if redraw_elapsed>=0.1 and is_instance_valid(player):
        redraw_elapsed = 0.0
        if player.global_position!=last_position:
            last_position = player.global_position
            queue_redraw()

func _draw() -> void:
    if map_texture == null:
        return
    draw_texture_rect(FRAME,Rect2(Vector2.ZERO,size),false)
    var area := map_rect()
    var view := view_rect()
    draw_texture_rect_region(map_texture,area,Rect2(view.position/WORLD_SIZE*map_texture.get_size(),view.size/WORLD_SIZE*map_texture.get_size()))
    if preview_route.size()>1:
        for i in range(1,preview_route.size()):
            var a := world_to_map(preview_route[i-1])
            var b := world_to_map(preview_route[i])
            if area.has_point(a) and area.has_point(b):
                draw_line(a,b,Color("#fff1a6"),2.5,true)
    for marker in markers:
        var at := world_to_map(marker["position"])
        if not area.grow(-7).has_point(at):
            continue
        var color: Color = marker.get("color",Color("#ffe3a1"))
        draw_circle(at,7 if expanded else 4,Color("#3c2c20"))
        draw_circle(at,5 if expanded else 2.5,color)
        if expanded:
            var text: String = marker["label"]
            var font := get_theme_default_font()
            var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
            var text_at := Vector2(clampf(at.x-width*0.5,area.position.x+4,area.end.x-width-4),clampf(at.y-14,area.position.y+20,area.end.y-5))
            draw_string_outline(font,text_at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,16,4,Color("#33271f"))
            draw_string(font,text_at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#fff5db"))
    if selected_point.is_finite():
        var at := world_to_map(selected_point)
        if area.grow(-10).has_point(at):
            draw_arc(at,10,0,TAU,24,Color("#ffda58"),3,true)
    if is_instance_valid(player):
        var at := world_to_map(player.global_position)
        if area.grow(-6).has_point(at):
            draw_circle(at,6,Color("#fff6db"))
            draw_circle(at,4,Color("#ee8e35"))

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if not expanded and event.button_index==MOUSE_BUTTON_LEFT:
            map_open_requested.emit()
            accept_event()
        elif expanded and map_rect().has_point(event.position):
            if event.button_index==MOUSE_BUTTON_LEFT:
                point_selected.emit(map_to_world(event.position))
            elif event.button_index==MOUSE_BUTTON_WHEEL_UP:
                set_zoom(zoom+0.25,event.position)
            elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
                set_zoom(zoom-0.25,event.position)
            accept_event()
    elif expanded and event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_RIGHT:
        center -= event.relative/map_rect().size*(WORLD_SIZE/zoom)
        view_rect()
        queue_redraw()
        accept_event()
