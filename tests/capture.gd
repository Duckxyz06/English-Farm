extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func shot(scene: Node2D, path: String, at: Vector2) -> void:
    scene.player.position = at
    scene.player.get_node("Camera2D").reset_smoothing()
    await create_timer(0.25).timeout
    await RenderingServer.frame_post_draw
    var result := root.get_texture().get_image().save_png(path)
    if result != OK:
        quit(1)

func capture() -> void:
    root.size = Vector2i(1280,720)
    var scene = load("res://game/scenes/Main.tscn").instantiate()
    scene.persistence_enabled = false
    root.add_child(scene)
    await process_frame
    DirAccess.make_dir_recursive_absolute("test-output")
    await shot(scene,"test-output/01-cottage.png",scene.SPAWN)
    for i in range(8):
        scene.state.plots[i]["stage"] = i%4
    scene.refresh()
    scene.ui.notice_seconds = 0
    await shot(scene,"test-output/02-farming.png",Vector2(1580,1530))
    scene.lesson()
    await shot(scene,"test-output/03-lesson.png",Vector2(805,635))
    scene.ui.close_dialogue()
    scene.shop()
    scene.shop_action("exchange_gem")
    await shot(scene,"test-output/04-shop.png",Vector2(2380,680))
    scene.ui.close_dialogue()
    await shot(scene,"test-output/05-mia.png",Vector2(2380,730))
    scene.state.hat_owned = true
    scene.state.hat_equipped = true
    scene.refresh()
    await shot(scene,"test-output/06-hat.png",scene.SPAWN)
    scene.inventory()
    await shot(scene,"test-output/07-inventory.png",scene.SPAWN)
    for item in scene.lessons:
        scene.state.learn(item["id"],true,scene.lessons.size())
    scene.refresh()
    scene.known_words()
    await shot(scene,"test-output/08-vocabulary.png",Vector2(805,635))
    scene.stop_audio()
    await create_timer(0.15).timeout
    scene.queue_free()
    await process_frame
    print("ENGLISH_FARM_SCREENSHOTS_PASSED")
    quit(0)
