extends CharacterBody2D
@export var speed := 310.0
var navigation: RefCounted
var visual: AnimatedSprite2D
var hat: Sprite2D
var direction := "down"
var locked := false
var route := PackedVector2Array()

func configure(art: RefCounted, nav: RefCounted) -> void:
    navigation = nav
    visual = art.animated("momo",{"walk_down":[0,1,2,3],"walk_left":[4,5,6,7],"walk_right":[8,9,10,11],"walk_up":[12,13,14,15],"idle_down":[0],"idle_left":[4],"idle_right":[8],"idle_up":[12]},86.0)
    add_child(visual)
    visual.play("idle_down")
    hat = art.sprite("items",14,47.0)
    hat.position = Vector2(0,-67)
    hat.visible = false
    add_child(hat)
    $Camera2D.limit_right = 3072
    $Camera2D.limit_bottom = 2048

func walk_to(target: Vector2) -> void:
    if not locked and navigation != null:
        route = navigation.find_path(global_position,target)

func stop() -> void:
    route.clear()
    velocity = Vector2.ZERO
    if visual != null:
        visual.play("idle_"+direction)

func _move(displacement: Vector2, slide: bool) -> bool:
    if navigation.can_travel(global_position,global_position+displacement):
        global_position += displacement
        return true
    if slide:
        for axis in [Vector2(displacement.x,0),Vector2(0,displacement.y)]:
            if navigation.can_travel(global_position,global_position+axis):
                global_position += axis
    return false

func _physics_process(delta: float) -> void:
    if navigation == null or visual == null:
        return
    if locked:
        stop()
        return
    var previous := global_position
    var manual := Input.get_vector("move_left","move_right","move_up","move_down")
    var budget := speed * minf(delta,0.05)
    if manual.length_squared()>0.01:
        route.clear()
        _move(manual*budget,true)
    else:
        while budget>0.01 and not route.is_empty():
            var target := route[0]
            var distance := global_position.distance_to(target)
            if distance<0.001:
                global_position = target
                route.remove_at(0)
                continue
            var step := minf(distance,budget)
            if not _move(global_position.direction_to(target)*step,false):
                route.clear()
                break
            budget -= step
            if step>=distance:
                global_position = target
                route.remove_at(0)
    var motion := global_position-previous
    velocity = motion/maxf(delta,0.001)
    if motion.length_squared()>0.01:
        if absf(motion.x)>absf(motion.y):
            direction = "right" if motion.x>0 else "left"
        else:
            direction = "down" if motion.y>0 else "up"
        visual.play("walk_"+direction)
    else:
        visual.play("idle_"+direction)
