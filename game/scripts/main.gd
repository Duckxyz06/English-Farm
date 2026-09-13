extends Node2D
const Art = preload("res://game/scripts/art.gd")
const Navigation = preload("res://game/scripts/farm_navigation.gd")
const FarmState = preload("res://game/scripts/farm_state.gd")
const Store = preload("res://game/scripts/progress_store.gd")
const UI = preload("res://game/scripts/game_ui.gd")
const WORLD_SIZE := Vector2(3072,2048)
const SPAWN := Vector2(490,1824)
const NPC_POSITIONS := {"lily":Vector2(804,562),"tom":Vector2(1770,1844),"mia":Vector2(2380,624)}
const NPC_NAMES := {"lily":"Lily · Cô giáo","tom":"Tom · Người nông dân","mia":"Mia · Cửa hàng"}
var persistence_enabled := true
var save_path := "user://english_farm_progress_v1.json"
var art: RefCounted
var navigation: RefCounted
var state := FarmState.new()
var lessons: Array = []
var world_texture: Texture2D
var npc_visuals: Dictionary = {}
var plot_nodes: Array[Node2D] = []
var plot_positions: Array[Vector2] = []
var ui: CanvasLayer
var pending_npc := ""
var pending_plot := -1
var current_lesson: Dictionary = {}
var save_elapsed := 0.0
var music: AudioStreamPlayer
var effects: AudioStreamPlayer
@onready var player = $Momo

func _ready() -> void:
    RenderingServer.set_default_clear_color(Color("#314b36"))
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    navigation = Navigation.new()
    art = Art.new()
    world_texture = load("res://game/assets/farm_spring.png")
    lessons = JSON.parse_string(FileAccess.get_file_as_string("res://data/lessons.json"))
    _load_progress()
    player.configure(art,navigation)
    for i in range(8):
        plot_positions.append(Vector2([658,747,835,923][i%4],[708,807][int(i/4)])*2.0)
        var node := Node2D.new()
        node.position = plot_positions[i]
        node.z_index = int(node.position.y)
        add_child(node)
        plot_nodes.append(node)
    for id in NPC_POSITIONS:
        var column: int = ["lily","tom","mia"].find(id)
        var node := Node2D.new()
        node.position = NPC_POSITIONS[id]
        node.z_index = int(node.position.y)
        var visual: AnimatedSprite2D = art.animated("npcs",{"idle":[column,column+3]},100.0)
        node.add_child(visual)
        visual.play("idle")
        var marker := Label.new()
        marker.text = "!"
        marker.position = Vector2(-9,-132)
        marker.add_theme_font_size_override("font_size",29)
        marker.add_theme_color_override("font_color",Color("#fff2ad"))
        marker.add_theme_color_override("font_shadow_color",Color("#453326"))
        marker.add_theme_constant_override("shadow_offset_x",2)
        marker.add_theme_constant_override("shadow_offset_y",2)
        node.add_child(marker)
        npc_visuals[id] = {"node":node,"marker":marker}
        add_child(node)
    ui = UI.new()
    add_child(ui)
    ui.setup(self)
    music = AudioStreamPlayer.new()
    music.stream = load("res://game/assets/audio/farm_theme.wav")
    music.volume_db = -13
    add_child(music)
    music.finished.connect(music.play)
    effects = AudioStreamPlayer.new()
    effects.volume_db = -8
    add_child(effects)
    if state.sound_enabled:
        music.play()
    refresh()
    get_tree().auto_accept_quit = false
    ui.toast("Chào Momo! Bấm đường để di chuyển. Gặp Lily học từ mới, tới ruộng gieo hạt.",7)

func _draw() -> void:
    if world_texture != null:
        draw_texture_rect(world_texture,Rect2(Vector2.ZERO,WORLD_SIZE),false)

func _process(delta: float) -> void:
    player.z_index = int(player.position.y)
    if state.tick(delta):
        refresh()
        save_progress()
        ui.toast("Cà rốt đã lớn! Quay lại ruộng để thu hoạch.",4)
    save_elapsed += delta
    if save_elapsed>=15:
        save_elapsed = 0
        save_progress()
    if ui.dialogue.visible:
        return
    if Input.get_vector("move_left","move_right","move_up","move_down").length_squared()>0.01:
        pending_npc = ""
        pending_plot = -1
    if not pending_npc.is_empty() and player.position.distance_to(NPC_POSITIONS[pending_npc])<105:
        interact_npc(pending_npc)
        return
    if pending_plot>=0 and player.position.distance_to(plot_positions[pending_plot])<85:
        var index := pending_plot
        pending_plot = -1
        player.stop()
        farm(index)
    var near := nearby()
    ui.hint.text = near["hint"] if not near.is_empty() else "Bấm để đi  ·  WASD di chuyển  ·  E tương tác  ·  I mở kho"

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode==KEY_ESCAPE:
            ui.close_dialogue()
        elif event.keycode==KEY_I:
            if ui.dialogue.visible:
                ui.close_dialogue()
            else:
                inventory()
        elif event.keycode==KEY_M:
            toggle_sound()
        elif event.keycode==KEY_F11:
            var mode := DisplayServer.window_get_mode()
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
        elif event.keycode==KEY_E:
            if ui.dialogue.visible:
                if ui.mode=="feedback":
                    lesson()
                else:
                    ui.close_dialogue()
            else:
                var near := nearby()
                if near.has("npc"):
                    interact_npc(near["npc"])
                elif near.has("plot"):
                    farm(int(near["plot"]))
        elif ui.dialogue.visible:
            var number := int(event.keycode)-KEY_1
            if number>=0 and number<ui.actions.size():
                ui.actions[number].call()
    if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not ui.dialogue.visible:
        click_world(get_global_mouse_position())

func click_world(point: Vector2) -> void:
    if ui.dialogue.visible:
        return
    pending_npc = ""
    pending_plot = -1
    for id in NPC_POSITIONS:
        if point.distance_to(NPC_POSITIONS[id]-Vector2(0,40))<75:
            pending_npc = id
            player.walk_to(NPC_POSITIONS[id]+Vector2(0,32))
            return
    for i in range(plot_positions.size()):
        if point.distance_to(plot_positions[i]-Vector2(0,18))<58:
            pending_plot = i
            player.walk_to(plot_positions[i])
            return
    player.walk_to(point)
    if player.route.is_empty():
        ui.toast("Chọn một vị trí trên lối đi hoặc trong ruộng nhé.",3)

func nearby() -> Dictionary:
    var closest: Dictionary = {}
    var distance := 106.0
    for id in NPC_POSITIONS:
        var d: float = player.position.distance_to(NPC_POSITIONS[id])
        if d<distance:
            closest = {"npc":id,"hint":"E · Nói chuyện với "+String(NPC_NAMES[id])}
            distance = d
    for i in range(plot_positions.size()):
        var d: float = player.position.distance_to(plot_positions[i])
        if d<minf(distance,90):
            var actions := ["Gieo hạt","Tưới nước","Cây đang lớn","Thu hoạch"]
            closest = {"plot":i,"hint":"E · "+actions[int(state.plots[i]["stage"])]+"  ·  Luống %d" % (i+1)}
            distance = d
    return closest

func farm(index: int) -> void:
    var result: Dictionary = state.farm(index)
    ui.toast(result["message"],4)
    if result["ok"]:
        play_sound(String(result["action"]))
        refresh()
        save_progress()

func interact_npc(id: String) -> void:
    pending_npc = ""
    if id=="lily":
        lesson()
    elif id=="tom":
        var was_completed := state.harvest_rewarded
        ui.show_dialogue(NPC_NAMES[id],state.turn_in_harvest(),[])
        if not was_completed and state.harvest_rewarded:
            play_sound("success")
        refresh()
        save_progress()
    elif id=="mia":
        shop()

func lesson() -> void:
    current_lesson = {}
    for item in lessons:
        if item["id"] not in state.learned:
            current_lesson = item
            break
    if current_lesson.is_empty():
        ui.show_dialogue("Lily · Bài học đầu tiên","Momo đã học đủ 10 từ! +50 xu đã được cộng một lần.\nDùng “seed”, “water”, “harvest” khi chăm ruộng nhé.",[{"text":"Ôn lại 10 từ","action":known_words}])
        return
    var options: Array = []
    for i in range(current_lesson["choices"].size()):
        options.append({"text":current_lesson["choices"][i],"action":answer.bind(i)})
    ui.show_dialogue("Lily · Từ %d/10" % (state.learned.size()+1),"“%s” nghĩa là gì?\nVí dụ: %s" % [current_lesson["word"],current_lesson["example"]],options,"question")

func answer(index: int) -> void:
    if ui.mode!="question":
        return
    var correct := index==int(current_lesson["answer"])
    var result := state.learn(String(current_lesson["id"]),correct,lessons.size())
    if not correct:
        ui.toast("Chưa đúng. Đọc câu ví dụ rồi thử lại nhé!",4)
        return
    var message := "%s = %s\n%s\n+2 XP" % [current_lesson["word"],current_lesson["meaning"],current_lesson["example"]]
    if int(result["reward"])>0:
        message += "  ·  +50 xu  ·  Hoàn thành bài học!"
    ui.show_dialogue("Đúng rồi, Momo!",message,[{"text":"Tiếp tục [E]","action":lesson}],"feedback")
    play_sound("success")
    refresh()
    save_progress()

func shop(message: String = "") -> void:
    var intro := "6 hạt giống: 20 xu  ·  Bán cà rốt: 15 xu/củ\nKho %d/%d  ·  %d xu  ·  %d ngọc" % [state.storage_used(),state.capacity,state.coins,state.gems]
    if not message.is_empty():
        intro = message+"\n"+intro
    ui.show_dialogue("Mia · Cửa hàng",intro,[
        {"text":"Mua 6 hạt giống · 20 xu","action":shop_action.bind("buy_seeds")},
        {"text":"Bán toàn bộ cà rốt","action":shop_action.bind("sell_carrots")},
        {"text":"Nâng kho lên 100 chỗ · 500 xu","action":shop_action.bind("upgrade_storage")},
        {"text":"Đổi 10 xu → 1 ngọc","action":shop_action.bind("exchange_gem")},
        {"text":"Đội / cất mũ" if state.hat_owned else "Mua mũ nông dân · 5 ngọc","action":shop_action.bind("buy_hat")}],"shop")

func shop_action(action: String) -> void:
    var message: String = state.call(action)
    refresh()
    save_progress()
    shop(message)

func inventory() -> void:
    ui.show_dialogue("Kho của Momo","Sức chứa %d/%d  ·  %d xu  ·  %d ngọc\nHạt cà rốt: %d  ·  Cà rốt: %d\nBình tưới và cuốc luôn sẵn dùng." % [state.storage_used(),state.capacity,state.coins,state.gems,state.seeds,state.carrots],[{"text":"Sổ từ vựng đã học (%d/10)" % state.learned.size(),"action":known_words}])
    var icons := HBoxContainer.new()
    icons.add_theme_constant_override("separation",18)
    for id in [0,4,6,7,8,14]:
        icons.add_child(art.icon(id,55))
    ui.content_box.add_child(icons)

func known_words() -> void:
    var text := ""
    for item in lessons:
        if item["id"] in state.learned:
            text += "%s — %s\n" % [item["word"],item["meaning"]]
    ui.show_dialogue("Sổ từ vựng của Momo",text if not text.is_empty() else "Gặp Lily trước cổng trường để bắt đầu bài học.",[])

func refresh() -> void:
    ui.refresh()
    player.hat.visible = state.hat_equipped
    for id in npc_visuals:
        npc_visuals[id]["marker"].text = "✓" if (id=="lily" and state.lesson_rewarded) or (id=="tom" and state.harvest_rewarded) else ("…" if id=="mia" else "!")
    for i in range(plot_nodes.size()):
        for child in plot_nodes[i].get_children():
            plot_nodes[i].remove_child(child)
            child.queue_free()
        var stage := int(state.plots[i]["stage"])
        if stage==0:
            var label: Label = ui.label("＋",23)
            label.position = Vector2(-14,-18)
            label.add_theme_color_override("font_color",Color("#dec999"))
            plot_nodes[i].add_child(label)
        else:
            plot_nodes[i].add_child(art.sprite("items",stage,69.0))
            if stage==1:
                var label: Label = ui.label("E · Tưới",15)
                label.position = Vector2(-30,5)
                label.add_theme_color_override("font_color",Color("#ffedbc"))
                plot_nodes[i].add_child(label)

func play_sound(name: String) -> void:
    if state.sound_enabled:
        effects.stream = load("res://game/assets/audio/"+name+".wav")
        effects.play()

func toggle_sound() -> void:
    state.sound_enabled = not state.sound_enabled
    if music != null:
        if state.sound_enabled:
            music.play()
        else:
            music.stop()
            effects.stop()
    refresh()
    save_progress()

func _load_progress() -> void:
    player.position = SPAWN
    if not persistence_enabled:
        return
    var known: Array = lessons.map(func(item): return item["id"])
    for path in [save_path,save_path+".bak"]:
        var data: Dictionary = Store.read_save(path)
        if data.is_empty() or not state.restore(data,known):
            continue
        var point: Variant = data.get("position",[])
        if point is Array and point.size()==2 and (point[0] is int or point[0] is float) and (point[1] is int or point[1] is float):
            var saved := Vector2(float(point[0]),float(point[1]))
            if saved.is_finite() and navigation.is_walkable(saved):
                player.position = saved
        break

func save_progress() -> void:
    if persistence_enabled and not Store.write_save(save_path,state.serialize(player.position)):
        ui.toast("Chưa lưu được tiến độ. Kiểm tra dung lượng hoặc quyền ghi.",5)

func _notification(what: int) -> void:
    if what==NOTIFICATION_WM_CLOSE_REQUEST:
        save_progress()
        get_tree().quit()
