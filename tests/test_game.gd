extends SceneTree

const State = preload("res://game/scripts/farm_state.gd")
const Store = preload("res://game/scripts/progress_store.gd")
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("run")

func check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        print("FAIL: "+message)

func run() -> void:
    var scene = load("res://game/scenes/Main.tscn").instantiate()
    scene.persistence_enabled = false
    # Gameplay assertions intentionally execute many actions in one frame.
    # Exercise audio separately with real frames so the mixer can process it.
    scene.state.sound_enabled = false
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    scene.player.set_physics_process(false)
    check(scene.player.visual.sprite_frames.get_frame_count("walk_up")==4,"Four up-facing frames")
    check(scene.world_texture.get_width()==1536,"Actual farm artwork loads")
    check(scene.npc_visuals.size()==3,"Three NPCs in the scene")
    check(scene.art.frame("items",4)!=null,"Carrot icon loads from atlas")
    check(scene.navigation.is_walkable(scene.SPAWN),"Spawn is walkable")
    check(not scene.navigation.is_walkable(Vector2(1536,800)),"Fountain blocks movement")
    check(not scene.navigation.is_walkable(Vector2(2350,1570)),"Pond blocks movement")
    var goals: Array[Vector2] = []
    for id in scene.NPC_POSITIONS:
        goals.append(scene.NPC_POSITIONS[id])
    goals.append_array(scene.plot_positions)
    for point in [Vector2(110,154),Vector2(207,229),Vector2(1420,654),Vector2(1240,934),Vector2(635,852)]:
        goals.append(point*2.0)
    var path_started := Time.get_ticks_usec()
    for i in range(100):
        scene.navigation.find_path(scene.SPAWN,scene.NPC_POSITIONS["mia"])
    print("NAVIGATION_100_CLICKS_MS=",(Time.get_ticks_usec()-path_started)/1000.0)
    for goal in goals:
        var route: PackedVector2Array = scene.navigation.find_path(scene.SPAWN,goal)
        check(not route.is_empty(),"Route to "+str(goal))
        if route.is_empty():
            continue
        var previous: Vector2 = scene.SPAWN
        for point in route:
            check(scene.navigation.can_travel(previous,point),"No corner clipping to "+str(goal)+" at "+str(point))
            previous = point
        check(previous.distance_to(goal)<1.0,"Exact destination "+str(goal))
        scene.player.position = scene.SPAWN
        scene.player.walk_to(goal)
        for i in range(2400):
            scene.player._physics_process(0.04)
            if scene.player.route.is_empty():
                break
        check(scene.player.position.distance_to(goal)<1.0,"Momo reaches %s; stopped at %s" % [goal,scene.player.position])
    scene.start_practice("writing")
    scene.submit_practice("wrong")
    check(scene.practice_index==0,"Wrong written answer does not advance")
    scene.submit_practice("  CARROT  ")
    check(scene.practice_index==1,"Writing accepts normalized correct answer")
    scene.submit_practice("carrot")
    check(scene.practice_index==1,"Repeated submission cannot skip a question")
    scene.start_practice("reading")
    for i in range(scene.lessons.size()):
        scene.practice_answer(true)
        scene.practice_question()
    check(scene.practice_index==10 and scene.state.xp==0,"Reading finishes without repeat rewards")
    scene.ui.close_dialogue()
    scene.lesson()
    var locked_at: Vector2 = scene.player.position
    Input.action_press("move_right")
    scene.player._physics_process(0.04)
    Input.action_release("move_right")
    check(scene.player.position==locked_at,"Dialogue locks movement")
    var initial_coins: int = scene.state.coins
    scene.answer(1)
    check(scene.state.learned.is_empty(),"Wrong answer gives no progress")
    scene.answer(0)
    scene.answer(0)
    check(scene.state.learned.size()==1 and scene.state.xp==2,"Repeated answer cannot duplicate XP")
    for i in range(1,scene.lessons.size()):
        scene.lesson()
        scene.answer(int(scene.current_lesson["answer"]))
    check(scene.state.learned.size()==10 and scene.state.coins==initial_coins+50,"Ten words award 50 coins once")
    scene.lesson()
    check(scene.state.coins==initial_coins+50,"Reopening completed lesson never pays twice")
    scene.ui.close_dialogue()
    check(not scene.player.locked,"Closing dialogue releases movement")
    scene.player.position = scene.SPAWN
    scene.click_world(scene.NPC_POSITIONS["mia"])
    Input.action_press("move_right")
    scene.player._physics_process(0.04)
    scene._process(0.04)
    Input.action_release("move_right")
    check(scene.player.route.is_empty(),"Keyboard cancels click route")
    check(scene.pending_npc.is_empty() and scene.pending_plot==-1,"Keyboard cancels pending interaction")

    var state := State.new()
    for plot in range(3):
        check(state.farm(plot)["ok"],"Plant seed")
        check(state.farm(plot)["ok"],"Water seed")
    state.tick(11.5)
    check(not state.farm(0)["ok"],"Unripe plants cannot be harvested")
    state.tick(0.5)
    for plot in range(3):
        check(state.farm(plot)["action"]=="harvest","Harvest ripe carrot")
    check(state.carrots==3 and state.seeds==3,"Farm cycle conserves items")
    state.turn_in_harvest()
    check(state.carrots==0 and state.coins==530 and state.harvest_rewarded,"Tom consumes exactly three carrots")
    state.turn_in_harvest()
    check(state.coins==530,"Tom reward cannot repeat")
    state.coins = 0
    state.buy_seeds()
    check(state.seeds==3 and state.coins==0,"Cannot buy without coins")
    state.coins = 1000
    state.seeds = 60
    state.buy_seeds()
    check(state.seeds==60 and state.coins==1000,"Full storage rejects purchase without payment")
    state.plots[0]["stage"] = 3
    check(not state.farm(0)["ok"] and int(state.plots[0]["stage"])==3,"Full storage preserves ripe crop")
    state.upgrade_storage()
    check(state.capacity==100 and state.coins==500,"Upgrade costs exactly 500")
    state.upgrade_storage()
    check(state.coins==500,"Upgrade cannot charge twice")
    for i in range(5):
        state.exchange_gem()
    state.buy_hat()
    check(state.hat_owned and state.hat_equipped and state.gems==0 and state.coins==450,"Hat exchange and equip")

    var known: Array = scene.lessons.map(func(item): return item["id"])
    var payload: Dictionary = scene.state.serialize(scene.SPAWN)
    var restored := State.new()
    check(restored.restore(payload,known),"Valid state restores")
    check(restored.learned.size()==10 and restored.coins==550,"Learned words and reward persist")
    var malformed := payload.duplicate(true)
    malformed["seeds"] = -2
    check(not restored.restore(malformed,known),"Reject invalid negative inventory")
    malformed = payload.duplicate(true)
    malformed["plots"][0]["stage"] = 99
    check(not restored.restore(malformed,known),"Reject invalid crop stage")
    var save := "user://automated_test_save.json"
    for suffix in ["",".bak",".tmp"]:
        if FileAccess.file_exists(save+suffix):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(save+suffix))
    check(Store.write_save(save,payload),"Write save")
    check(Store.write_save(save,payload),"Atomic replacement and backup")
    check(restored.restore(Store.read_save(save),known),"Reload from file")
    var file := FileAccess.open(save,FileAccess.WRITE)
    file.store_string("{broken")
    file.close()
    check(Store.read_save(save).is_empty(),"Malformed JSON is not accepted")
    check(restored.restore(Store.read_save(save+".bak"),known),"Previous save survives corruption")
    for suffix in ["",".bak",".tmp"]:
        if FileAccess.file_exists(save+suffix):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(save+suffix))
    scene.toggle_sound()
    await create_timer(0.1).timeout
    check(scene.music.playing,"Enabling sound starts music")
    scene.play_sound("plant")
    await create_timer(0.1).timeout
    check(scene.effects.playing,"Farm action plays its sound")
    scene.toggle_sound()
    await create_timer(0.1).timeout
    check(not scene.music.playing and not scene.effects.playing,"Muting stops music and effects")
    scene.stop_audio()
    await create_timer(0.15).timeout
    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("ENGLISH_FARM_TESTS_PASSED")
        quit(0)
    else:
        print("Failed checks: "+str(failures.size()))
        quit(1)
