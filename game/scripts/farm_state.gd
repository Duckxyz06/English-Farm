extends RefCounted

const GROW_SECONDS := 12.0
const LESSON_REWARD := 50
const SAVE_VERSION := 1
var coins := 500
var gems := 0
var xp := 0
var seeds := 6
var carrots := 0
var capacity := 60
var hat_owned := false
var hat_equipped := false
var sound_enabled := true
var learned: Array[String] = []
var lesson_rewarded := false
var harvest_rewarded := false
var harvested_total := 0
var plots: Array[Dictionary] = []
var practice_read: Array[String] = []
var practice_written: Array[String] = []
var community_rewarded := false

func _init() -> void:
    for i in range(8):
        plots.append({"stage":0,"elapsed":0.0})

func storage_used() -> int:
    return seeds + carrots

func farm(index: int) -> Dictionary:
    if index < 0 or index >= plots.size():
        return {"ok":false,"message":"Không có luống cây ở đây."}
    var plot := plots[index]
    match int(plot["stage"]):
        0:
            if seeds < 1:
                return {"ok":false,"message":"Hết hạt giống rồi. Ghé Mia để mua thêm nhé!"}
            seeds -= 1
            plot["stage"] = 1
            return {"ok":true,"action":"plant","message":"Đã gieo hạt cà rốt. Nhấn E để tưới nước."}
        1:
            plot["stage"] = 2
            plot["elapsed"] = 0.0
            return {"ok":true,"action":"water","message":"Đã tưới! Cà rốt sẽ lớn sau 12 giây."}
        2:
            return {"ok":false,"message":"Cây đang lớn. Hãy khám phá hoặc nói chuyện với Lily."}
        3:
            if storage_used() >= capacity:
                return {"ok":false,"message":"Kho đã đầy. Bán bớt cà rốt hoặc nâng cấp kho ở Mia."}
            carrots += 1
            harvested_total += 1
            plot["stage"] = 0
            plot["elapsed"] = 0.0
            return {"ok":true,"action":"harvest","message":"+1 cà rốt! Mang 3 củ tới Tom để hoàn thành nhiệm vụ."}
    return {"ok":false,"message":""}

func tick(delta: float) -> bool:
    var changed := false
    for plot in plots:
        if int(plot["stage"]) == 2:
            plot["elapsed"] = minf(float(plot["elapsed"]) + maxf(0,delta),GROW_SECONDS)
            if float(plot["elapsed"]) >= GROW_SECONDS:
                plot["stage"] = 3
                changed = true
    return changed

func learn(word_id: String, correct: bool, total: int) -> Dictionary:
    if not correct:
        return {"correct":false,"new":false,"reward":0}
    if word_id in learned:
        return {"correct":true,"new":false,"reward":0}
    learned.append(word_id)
    xp += 2
    var reward := 0
    if learned.size() >= total and not lesson_rewarded:
        lesson_rewarded = true
        reward = LESSON_REWARD
        coins += reward
    return {"correct":true,"new":true,"reward":reward}

func turn_in_harvest() -> String:
    if harvest_rewarded:
        return "Tom: Cảm ơn Momo! Con có thể tiếp tục trồng và bán cà rốt ở cửa hàng."
    if carrots < 3:
        return "Tom: Collect three carrots — Hãy mang cho chú 3 củ cà rốt.\nCon đang có %d/3 củ. Gieo → tưới → đợi cây lớn → thu hoạch." % carrots
    carrots -= 3
    coins += 30
    xp += 20
    harvest_rewarded = true
    return "Tom: Làm tốt lắm! Con đã giao đủ 3 củ cà rốt.\n+30 xu  ·  +20 XP  ·  Nhiệm vụ hoàn thành!"

func buy_seeds() -> String:
    if coins < 20:
        return "Cần 20 xu để mua 6 hạt giống."
    if storage_used()+6 > capacity:
        return "Kho không còn đủ 6 chỗ trống."
    coins -= 20
    seeds += 6
    return "Đã mua 6 hạt giống cà rốt."

func sell_carrots() -> String:
    if carrots == 0:
        return "Chưa có cà rốt để bán."
    var income := carrots * 15
    coins += income
    carrots = 0
    return "Đã bán cà rốt, nhận %d xu." % income

func upgrade_storage() -> String:
    if capacity >= 100:
        return "Kho đã đạt cấp 2: 100 chỗ."
    if coins < 500:
        return "Cần 500 xu để nâng kho từ 60 lên 100 chỗ."
    coins -= 500
    capacity = 100
    return "Kho đã nâng lên 100 chỗ!"

func exchange_gem() -> String:
    if coins < 10:
        return "Cần 10 xu để đổi 1 ngọc."
    coins -= 10
    gems += 1
    return "Đã đổi 10 xu lấy 1 ngọc."

func buy_hat() -> String:
    if hat_owned:
        hat_equipped = not hat_equipped
        return "Đã đội mũ." if hat_equipped else "Đã cất mũ."
    if gems < 5:
        return "Cần 5 ngọc để mua mũ nông dân."
    gems -= 5
    hat_owned = true
    hat_equipped = true
    return "Momo đã có mũ nông dân!"

func serialize(player_position: Vector2) -> Dictionary:
    return {"version":SAVE_VERSION,"coins":coins,"gems":gems,"xp":xp,"seeds":seeds,"carrots":carrots,
        "capacity":capacity,"hat_owned":hat_owned,"hat_equipped":hat_equipped,"sound_enabled":sound_enabled,
        "learned":learned,"lesson_rewarded":lesson_rewarded,"harvest_rewarded":harvest_rewarded,
        "practice_read":practice_read,"practice_written":practice_written,"community_rewarded":community_rewarded,
        "harvested_total":harvested_total,"plots":plots.duplicate(true),"position":[player_position.x,player_position.y]}

func restore(data: Dictionary, known_words: Array) -> bool:
    if data.get("version") != SAVE_VERSION:
        return false
    for key in ["coins","gems","xp","seeds","carrots","capacity","harvested_total"]:
        var value: Variant = data.get(key)
        if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0 or float(value)>1000000 or float(int(value))!=float(value):
            return false
    if int(data["capacity"]) not in [60,100] or int(data["seeds"])+int(data["carrots"])>int(data["capacity"]):
        return false
    for key in ["hat_owned","hat_equipped","sound_enabled","lesson_rewarded","harvest_rewarded"]:
        if not data.get(key) is bool:
            return false
    if not data.get("learned") is Array or not data.get("plots") is Array or data["plots"].size()!=8:
        return false
    var clean_learned: Array[String] = []
    for id in data["learned"]:
        if not id is String or id not in known_words or id in clean_learned:
            return false
        clean_learned.append(id)
    if bool(data["lesson_rewarded"]) != (clean_learned.size()==known_words.size()):
        return false
    var clean_practice: Dictionary = {}
    for key in ["practice_read","practice_written"]:
        var entries: Variant = data.get(key,[])
        if not entries is Array:
            return false
        var clean: Array[String] = []
        for id in entries:
            if not id is String or id not in known_words or id in clean:
                return false
            clean.append(id)
        clean_practice[key] = clean
    var community: Variant = data.get("community_rewarded",false)
    if not community is bool:
        return false
    if community and (not data["lesson_rewarded"] or not data["harvest_rewarded"] or clean_practice["practice_read"].size()<5 or clean_practice["practice_written"].size()<5):
        return false
    var clean_plots: Array[Dictionary] = []
    for plot in data["plots"]:
        if not plot is Dictionary or not (plot.get("stage") is int or plot.get("stage") is float):
            return false
        var stage := int(plot["stage"])
        var elapsed: Variant = plot.get("elapsed")
        if stage<0 or stage>3 or float(stage)!=float(plot["stage"]) or not (elapsed is int or elapsed is float) or not is_finite(float(elapsed)) or float(elapsed)<0 or float(elapsed)>GROW_SECONDS:
            return false
        clean_plots.append({"stage":stage,"elapsed":float(elapsed)})
    for key in ["coins","gems","xp","seeds","carrots","capacity","harvested_total"]:
        set(key,int(data[key]))
    for key in ["hat_owned","hat_equipped","sound_enabled","lesson_rewarded","harvest_rewarded"]:
        set(key,data[key])
    practice_read = clean_practice["practice_read"]
    practice_written = clean_practice["practice_written"]
    community_rewarded = community
    learned = clean_learned
    plots = clean_plots
    return true

func record_practice(kind: String, id: String) -> bool:
    if kind not in ["reading","writing"]:
        return false
    var entries: Array[String] = practice_read if kind=="reading" else practice_written
    if id in entries:
        return false
    entries.append(id)
    xp += 2
    return true

func community_ready() -> bool:
    return lesson_rewarded and harvest_rewarded and practice_read.size()>=5 and practice_written.size()>=5

func claim_community() -> String:
    if community_rewarded:
        return "Bạn đã nhận bình tưới đôi. Khi tưới, cây bên phải trong cùng hàng cũng được tưới nếu đang cần nước."
    if not community_ready():
        return "Hoàn thành bài của Lily, giao cà rốt cho Tom, luyện đọc 5 từ và viết 5 từ để nhận bình tưới đôi."
    community_rewarded = true
    coins += 100
    xp += 40
    return "Dự án Vườn học tập hoàn thành! +100 xu · +40 XP.
Đã mở bình tưới đôi: tưới thêm cây bên phải trong cùng hàng."
