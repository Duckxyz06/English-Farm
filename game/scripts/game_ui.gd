extends CanvasLayer
const MiniMap = preload("res://game/scripts/minimap.gd")
var game: Node2D
var hud: Label
var quest: Label
var hint: Label
var notice: Label
var sound_button: Button
var dialogue: PanelContainer
var content_box: VBoxContainer
var actions: Array[Callable] = []
var mode := ""
var notice_seconds := 0.0

func setup(owner_game: Node2D) -> void:
    game = owner_game
    var left := panel(Vector2(18,16),Vector2(335,100))
    var left_box := VBoxContainer.new()
    left.add_child(left_box)
    left_box.add_child(label("ENGLISH FARM · Momo",22))
    hud = label("")
    left_box.add_child(hud)
    var top := panel(Vector2(365,16),Vector2(587,100))
    var top_box := VBoxContainer.new()
    top.add_child(top_box)
    top_box.add_child(label("Một khởi đầu xanh · Mùa xuân",21))
    quest = label("",19)
    top_box.add_child(quest)
    var map := MiniMap.new()
    map.position = Vector2(1035,18)
    map.size = Vector2(224,149)
    map.map_texture = game.world_texture
    map.player = game.player
    for id in game.NPC_POSITIONS:
        map.markers.append(game.NPC_POSITIONS[id])
    map.destination_chosen.connect(game.click_world)
    add_child(map)
    var buttons := HBoxContainer.new()
    buttons.position = Vector2(18,127)
    buttons.add_theme_constant_override("separation",8)
    buttons.add_child(button("Kho [I]",game.inventory))
    sound_button = button("Âm thanh [M]",game.toggle_sound)
    buttons.add_child(sound_button)
    add_child(buttons)
    var bottom := panel(Vector2(212,646),Vector2(856,58))
    hint = label("",18)
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    bottom.add_child(hint)
    notice = label("",18)
    notice.position = Vector2(110,586)
    notice.size = Vector2(1060,48)
    notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    notice.add_theme_color_override("font_color",Color("#fff6df"))
    notice.add_theme_color_override("font_shadow_color",Color("#251d18"))
    notice.add_theme_constant_override("shadow_offset_x",2)
    notice.add_theme_constant_override("shadow_offset_y",2)
    add_child(notice)
    dialogue = panel(Vector2(250,175),Vector2(780,0))
    content_box = VBoxContainer.new()
    content_box.add_theme_constant_override("separation",10)
    dialogue.add_child(content_box)
    dialogue.visible = false

func style() -> StyleBoxFlat:
    var result := StyleBoxFlat.new()
    result.bg_color = Color("#fff3d9")
    result.border_color = Color("#78543b")
    result.set_border_width_all(5)
    result.set_corner_radius_all(6)
    result.set_content_margin_all(16)
    result.shadow_color = Color(0.15,0.12,0.09,0.35)
    result.shadow_size = 5
    return result

func panel(at: Vector2, dimensions: Vector2) -> PanelContainer:
    var result := PanelContainer.new()
    result.position = at
    result.custom_minimum_size = dimensions
    result.add_theme_stylebox_override("panel",style())
    add_child(result)
    return result

func label(text: String, font_size: int = 20) -> Label:
    var result := Label.new()
    result.text = text
    result.add_theme_color_override("font_color",Color("#483b2c"))
    result.add_theme_font_size_override("font_size",font_size)
    result.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return result

func button(text: String, action: Callable) -> Button:
    var result := Button.new()
    result.text = text
    result.custom_minimum_size.y = 35
    result.add_theme_font_size_override("font_size",18)
    result.add_theme_color_override("font_color",Color("#fff7df"))
    var normal := style()
    normal.bg_color = Color("#527b48")
    normal.set_border_width_all(2)
    normal.set_content_margin_all(6)
    result.add_theme_stylebox_override("normal",normal)
    var hover := normal.duplicate()
    hover.bg_color = Color("#689756")
    result.add_theme_stylebox_override("hover",hover)
    result.add_theme_stylebox_override("pressed",hover)
    result.pressed.connect(action)
    return result

func show_dialogue(title: String, body_text: String, options: Array, new_mode: String = "message") -> void:
    notice_seconds = 0
    notice.hide()
    game.player.locked = true
    game.player.stop()
    game.pending_npc = ""
    game.pending_plot = -1
    actions.clear()
    for child in content_box.get_children():
        content_box.remove_child(child)
        child.queue_free()
    content_box.add_child(label(title,24))
    var body := label(body_text,19)
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.custom_minimum_size.x = 730
    content_box.add_child(body)
    for i in range(options.size()):
        var action: Callable = options[i]["action"]
        actions.append(action)
        content_box.add_child(button("[%d] %s" % [i+1,options[i]["text"]],action))
    content_box.add_child(button("Đóng [Esc]",close_dialogue))
    dialogue.visible = true
    dialogue.reset_size()
    mode = new_mode

func close_dialogue() -> void:
    dialogue.visible = false
    mode = ""
    actions.clear()
    game.player.locked = false

func toast(text: String, seconds: float = 4) -> void:
    notice.text = text
    notice.visible = true
    notice_seconds = seconds

func refresh() -> void:
    var state: RefCounted = game.state
    hud.text = "%d xu  ·  %d ngọc  ·  %d XP" % [state.coins,state.gems,state.xp]
    quest.text = "Lily: %d/10 từ    ·    Tom: %s" % [state.learned.size(),"Đã giao 3 củ" if state.harvest_rewarded else "%d/3 cà rốt" % mini(state.carrots,3)]
    sound_button.text = "Âm thanh: Bật [M]" if state.sound_enabled else "Âm thanh: Tắt [M]"

func _process(delta: float) -> void:
    notice_seconds = maxf(0,notice_seconds-delta)
    if notice != null:
        notice.visible = notice_seconds>0
