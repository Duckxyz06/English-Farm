extends Control
const MapCanvas = preload("res://game/scripts/minimap.gd")
var ui: CanvasLayer
var game: Node2D
var canvas: Control
var heading: Label
var description: Label
var route_note: Label
var go_button: Button
var selected := Vector2.INF
var selected_id := ""
var pois: Array[Dictionary] = []

func setup(owner_ui: CanvasLayer) -> void:
    ui = owner_ui
    game = ui.game
    size = Vector2(1280,720)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var dim := ColorRect.new()
    dim.color = Color(0.06,0.09,0.05,0.78)
    dim.size = size
    add_child(dim)
    var board := Panel.new()
    board.position = Vector2(20,18)
    board.size = Vector2(1240,684)
    board.add_theme_stylebox_override("panel",ui.style())
    add_child(board)
    var title: Label = ui.label("BẢN ĐỒ NÔNG TRẠI",25)
    title.position = Vector2(42,31)
    add_child(title)
    var close: Button = ui.button("Đóng [B / Esc]",ui.close_map)
    close.position = Vector2(1077,28)
    close.size.x = 157
    add_child(close)
    canvas = MapCanvas.new()
    canvas.position = Vector2(38,64)
    canvas.size = Vector2(810,603)
    canvas.expanded = true
    canvas.map_texture = game.world_texture
    canvas.player = game.player
    canvas.point_selected.connect(select_point)
    add_child(canvas)
    var side := VBoxContainer.new()
    side.position = Vector2(872,83)
    side.size = Vector2(350,580)
    side.add_theme_constant_override("separation",12)
    add_child(side)
    heading = ui.label("Chọn một địa điểm",23)
    heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    side.add_child(heading)
    description = ui.label("",18)
    description.custom_minimum_size = Vector2(345,174)
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    side.add_child(description)
    route_note = ui.label("",16)
    route_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    route_note.custom_minimum_size.y = 42
    side.add_child(route_note)
    go_button = ui.button("Đi đến đây",go_to_selected)
    side.add_child(go_button)
    var zoom_bar := HBoxContainer.new()
    zoom_bar.add_theme_constant_override("separation",6)
    zoom_bar.add_child(ui.button("−",func(): canvas.set_zoom(canvas.zoom-0.25)))
    zoom_bar.add_child(ui.button("+",func(): canvas.set_zoom(canvas.zoom+0.25)))
    zoom_bar.add_child(ui.button("Toàn cảnh",canvas.reset_view))
    side.add_child(zoom_bar)
    side.add_child(ui.label("Chọn nhanh",18))
    var shortcuts := GridContainer.new()
    shortcuts.columns = 2
    shortcuts.add_theme_constant_override("h_separation",10)
    shortcuts.add_theme_constant_override("v_separation",6)
    side.add_child(shortcuts)
    pois = [
        {"id":"lily","label":"Lily · Trường","position":game.NPC_POSITIONS["lily"],"color":Color("#b7e8fb")},
        {"id":"tom","label":"Tom","position":game.NPC_POSITIONS["tom"],"color":Color("#ffcc78")},
        {"id":"mia","label":"Mia · Cửa hàng","position":game.NPC_POSITIONS["mia"],"color":Color("#eec0fa")},
        {"id":"farm","label":"Ruộng","position":Vector2(1570,1510),"color":Color("#bbeb8d")},
        {"id":"home","label":"Nhà Momo","position":game.SPAWN},
        {"id":"square","label":"Quảng trường","position":Vector2(1536,1116)},
        {"id":"bridge","label":"Cầu suối","position":Vector2(220,308)},
        {"id":"pond","label":"Bến hồ","position":Vector2(2555,1390)}]
    canvas.markers = pois
    for poi in pois:
        var shortcut: Button = ui.button(poi["label"],select_poi.bind(String(poi["id"])))
        shortcut.custom_minimum_size.x = 166
        shortcuts.add_child(shortcut)
    var help: Label = ui.label("Lăn chuột: phóng to · Giữ chuột phải: kéo bản đồ",16)
    help.position = Vector2(130,666)
    add_child(help)
    hide()

func open() -> void:
    canvas.reset_view()
    show()
    select_poi("lily" if not game.state.lesson_rewarded else "farm")

func select_poi(id: String) -> void:
    for poi in pois:
        if poi["id"]==id:
            selected_id = id
            selected = poi["position"]
            heading.text = poi["label"]
            update_info()
            return

func select_point(point: Vector2) -> void:
    var threshold: float = 90.0/canvas.zoom
    for poi in pois:
        if point.distance_to(poi["position"])<threshold:
            select_poi(poi["id"])
            return
    selected_id = ""
    selected = point
    heading.text = "Điểm đã chọn"
    update_info()

func update_info() -> void:
    var state: RefCounted = game.state
    match selected_id:
        "lily":
            description.text = "Cô giáo Lily\nHọc từ: %d/10 · +2 XP/từ\nHoàn thành bài đầu: +50 xu.\nGóc luyện tập có đọc hiểu và gõ từ, kèm nghĩa tiếng Việt." % state.learned.size()
        "tom":
            description.text = "Người nông dân Tom\n"+("Đã giao đủ 3 cà rốt.\nBạn có thể tiếp tục trồng và bán cho Mia." if state.harvest_rewarded else "Giao 3 cà rốt: %d/3\nPhần thưởng: 30 xu + 20 XP.\nGieo → tưới → đợi cây lớn → thu hoạch." % mini(state.carrots,3))
        "mia":
            description.text = "Hạt giống: 6 hạt / 20 xu\nCà rốt: bán 15 xu/củ\nNâng kho: 500 xu\nĐổi ngọc và mua mũ cho Momo.\nKho hiện tại: %d/%d" % [state.storage_used(),state.capacity]
        "farm":
            var ripe := 0
            var thirsty := 0
            for plot in state.plots:
                if int(plot["stage"])==3: ripe += 1
                if int(plot["stage"])==1: thirsty += 1
            description.text = "8 luống cà rốt\n%d cây cần tưới · %d cây thu hoạch được\nCó %d hạt giống.\nBấm luống để tự đi tới; E để chăm cây." % [thirsty,ripe,state.seeds]
        "home":
            description.text = "Nhà của Momo ở phía tây nam.\nSân nhà là điểm bắt đầu.\nTiến độ tự lưu; bạn có thể quay lại bất cứ lúc nào.\nNội thất chưa mở trong bản này."
        "square":
            description.text = "Trung tâm nông trại\nMở Sổ mục tiêu [J] để xem công việc và dự án chung.\nKết hợp học từ, trồng cây và giúp Tom để nhận bình tưới đôi."
        "bridge":
            description.text = "Cây cầu bên thác nước.\nLối nối từ trường đã mở.\nBạn có thể đi dạo tới giữa cầu; khu rừng phía xa chưa mở."
        "pond":
            description.text = "Bến gỗ phía bắc hồ.\nĐi theo lối bên phải quảng trường.\nMomo có thể đứng trên bến; chưa có hoạt động câu cá."
        _:
            description.text = "Chọn một chấm có tên để xem thông tin.\nBấm Đi đến đây để Momo tự tìm đường.\nCông trình, mặt nước và cây rậm không thể đi xuyên qua."
    var route: PackedVector2Array = game.navigation.find_path(game.player.position,selected)
    canvas.preview_route = PackedVector2Array([game.player.position])
    canvas.preview_route.append_array(route)
    go_button.disabled = route.is_empty()
    if route.is_empty():
        route_note.text = "Chưa có lối đi tới điểm này. Chọn trên đường hoặc một địa điểm có tên."
        canvas.selected_point = selected
    else:
        canvas.selected_point = route[route.size()-1]
        route_note.text = "Đường màu vàng là lối đi dự kiến."
        if canvas.selected_point.distance_to(selected)>25:
            route_note.text = "Điểm này có vật cản; Momo sẽ dừng ở mép lối đi gần nhất."
    canvas.queue_redraw()

func go_to_selected() -> void:
    if go_button.disabled or not selected.is_finite():
        return
    var destination := selected
    ui.close_map()
    game.click_world(destination)
