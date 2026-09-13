extends Node2D

const WORLD_SIZE := Vector2(2200, 1400)
const LILY_POS := Vector2(1180, 660)
const INTERACT_DISTANCE := 110.0

@onready var player: CharacterBody2D = $Momo
@onready var hud_left: Label = $UI/HUDLeft
@onready var hud_right: Label = $UI/HUDRight
@onready var hint: Label = $UI/Hint
@onready var dialogue_panel: Panel = $UI/DialoguePanel
@onready var dialogue_label: Label = $UI/DialoguePanel/DialogueLabel

var coins := 500
var quiz_open := false
var quiz_completed := false

func _ready() -> void:
    RenderingServer.set_default_clear_color(Color("#9ddf70"))
    _refresh_hud()
    dialogue_panel.visible = false
    queue_redraw()

func _process(_delta: float) -> void:
    var distance := player.global_position.distance_to(LILY_POS)
    if not quiz_open:
        hint.text = "E: Nói chuyện với Lily" if distance <= INTERACT_DISTANCE else "WASD: Di chuyển  •  E: Tương tác"

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        if quiz_open:
            _close_dialogue()
        elif player.global_position.distance_to(LILY_POS) <= INTERACT_DISTANCE:
            _open_quiz()

    if quiz_open and event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_1:
            _answer_quiz(true)
        elif event.keycode == KEY_2:
            _answer_quiz(false)

func _open_quiz() -> void:
    quiz_open = true
    dialogue_panel.visible = true
    if quiz_completed:
        dialogue_label.text = "Lily: Tuyệt lắm, Momo! Hôm nay chúng ta đã học từ CARROT = CÀ RỐT.\n\nNhấn E để đóng."
    else:
        dialogue_label.text = "Lily: Chào Momo! Bài học đầu tiên nhé.\n\n'CARROT' nghĩa là gì?\n\n[1] Cà rốt        [2] Quả táo\n\nNhấn phím 1 hoặc 2."
    hint.text = "Bài học tiếng Anh"

func _answer_quiz(correct: bool) -> void:
    if quiz_completed:
        return
    if correct:
        quiz_completed = true
        coins += 50
        dialogue_label.text = "Đúng rồi! CARROT = CÀ RỐT.\n\n+50 xu  •  Quest hoàn thành!\n\nNhấn E để đóng."
        _refresh_hud()
    else:
        dialogue_label.text = "Chưa đúng. Thử lại nhé!\n\n'CARROT' nghĩa là gì?\n\n[1] Cà rốt        [2] Quả táo"

func _close_dialogue() -> void:
    quiz_open = false
    dialogue_panel.visible = false

func _refresh_hud() -> void:
    hud_left.text = "MOMO   LV 1   ♥ ♥ ♥"
    hud_right.text = "SPRING 1   ☀   08:00     %d xu" % coins

func is_walkable(position: Vector2) -> bool:
    if position.x < 70.0 or position.y < 80.0 or position.x > WORLD_SIZE.x - 70.0 or position.y > WORLD_SIZE.y - 70.0:
        return false

    var blocked := [
        Rect2(120, 120, 430, 310),
        Rect2(1510, 170, 420, 300),
        Rect2(1450, 850, 500, 330),
        Rect2(560, 850, 420, 290)
    ]
    for area in blocked:
        if area.grow(24).has_point(position):
            return false
    return true

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#8ed066"))

    # Soft grass checker pattern for a pixel-art feel.
    for y in range(0, int(WORLD_SIZE.y), 64):
        for x in range(0, int(WORLD_SIZE.x), 64):
            if ((x / 64) + (y / 64)) as int % 2 == 0:
                draw_rect(Rect2(x, y, 64, 64), Color("#94d56c"))

    # Dirt paths.
    draw_rect(Rect2(0, 585, 2200, 190), Color("#d7b57b"))
    draw_rect(Rect2(960, 0, 190, 1400), Color("#d7b57b"))
    draw_rect(Rect2(160, 520, 560, 90), Color("#d7b57b"))

    # Momo house.
    draw_rect(Rect2(120, 180, 430, 250), Color("#c6814d"))
    draw_rect(Rect2(160, 120, 350, 110), Color("#7b4c39"))
    draw_rect(Rect2(300, 300, 85, 130), Color("#6f452f"))
    draw_rect(Rect2(180, 255, 85, 70), Color("#9ed8e6"))
    draw_rect(Rect2(410, 255, 85, 70), Color("#9ed8e6"))

    # Crop field.
    draw_rect(Rect2(650, 150, 620, 320), Color("#a96f4f"))
    for row in range(4):
        for col in range(8):
            var p := Vector2(700 + col * 68, 205 + row * 66)
            draw_rect(Rect2(p.x - 8, p.y, 16, 30), Color("#4b9b49"))
            draw_rect(Rect2(p.x - 18, p.y + 14, 36, 10), Color("#6dbf54"))

    # Barn / shop building.
    draw_rect(Rect2(1510, 220, 420, 250), Color("#d86f55"))
    draw_rect(Rect2(1570, 170, 300, 90), Color("#754634"))
    draw_rect(Rect2(1680, 335, 90, 135), Color("#754634"))

    # Pond.
    draw_rect(Rect2(1450, 850, 500, 330), Color("#68b6cf"))
    draw_rect(Rect2(1490, 890, 420, 250), Color("#79c8df"))
    for x in range(1530, 1890, 90):
        draw_rect(Rect2(x, 930, 30, 12), Color("#4a9b75"))

    # Learning garden.
    draw_rect(Rect2(560, 850, 420, 290), Color("#cfa66e"))
    draw_rect(Rect2(600, 900, 340, 190), Color("#f4e3b1"))

    # Trees around the borders.
    for x in range(80, 2180, 180):
        _draw_tree(Vector2(x, 70))
        _draw_tree(Vector2(x, 1320))
    for y in range(180, 1280, 190):
        _draw_tree(Vector2(60, y))
        _draw_tree(Vector2(2140, y))

    # Lily NPC: cream cat with green scarf.
    _draw_lily(LILY_POS)

func _draw_tree(pos: Vector2) -> void:
    draw_rect(Rect2(pos.x - 12, pos.y + 26, 24, 45), Color("#7d5236"))
    draw_rect(Rect2(pos.x - 42, pos.y - 5, 84, 56), Color("#3f8c4e"))
    draw_rect(Rect2(pos.x - 30, pos.y - 28, 60, 48), Color("#56a85b"))

func _draw_lily(pos: Vector2) -> void:
    draw_rect(Rect2(pos.x - 26, pos.y - 34, 52, 58), Color("#fff1cf"))
    draw_rect(Rect2(pos.x - 20, pos.y - 50, 16, 22), Color("#fff1cf"))
    draw_rect(Rect2(pos.x + 4, pos.y - 50, 16, 22), Color("#fff1cf"))
    draw_rect(Rect2(pos.x - 14, pos.y - 12, 8, 8), Color("#4a3c35"))
    draw_rect(Rect2(pos.x + 6, pos.y - 12, 8, 8), Color("#4a3c35"))
    draw_rect(Rect2(pos.x - 29, pos.y + 16, 58, 14), Color("#5c9c57"))
    draw_rect(Rect2(pos.x - 7, pos.y + 24, 14, 24), Color("#4b844a"))
