extends RefCounted

var data: Dictionary
var textures: Dictionary = {}
var material := ShaderMaterial.new()

func _init() -> void:
    data = JSON.parse_string(FileAccess.get_file_as_string("res://game/assets/atlas.json"))
    material.shader = load("res://game/assets/color_key.gdshader")
    for key in data:
        textures[key] = load(data[key]["path"])

func frame(sheet: String, index: int) -> AtlasTexture:
    var info: Dictionary = data[sheet]
    var box: Array = info["frames"][index]
    var canvas := Vector2(info["canvas"][0], info["canvas"][1])
    var size := Vector2(box[2], box[3])
    var result := AtlasTexture.new()
    result.atlas = textures[sheet]
    result.region = Rect2(box[0], box[1], box[2], box[3])
    result.margin = Rect2(Vector2((canvas.x - size.x) * 0.5, canvas.y - size.y), canvas - size)
    return result

func sprite(sheet: String, index: int, height: float) -> Sprite2D:
    var result := Sprite2D.new()
    result.texture = frame(sheet, index)
    result.material = material
    result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    result.scale = Vector2.ONE * height / result.texture.get_height()
    result.offset.y = -result.texture.get_height() * 0.5
    return result

func animated(sheet: String, groups: Dictionary, height: float) -> AnimatedSprite2D:
    var result := AnimatedSprite2D.new()
    var frames := SpriteFrames.new()
    frames.remove_animation("default")
    for name in groups:
        frames.add_animation(name)
        frames.set_animation_speed(name, 8.0 if String(name).begins_with("walk") else 1.0)
        for index in groups[name]:
            frames.add_frame(name, frame(sheet, index))
    result.sprite_frames = frames
    result.material = material
    result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    var canvas_height := float(data[sheet]["canvas"][1])
    result.scale = Vector2.ONE * height / canvas_height
    result.offset.y = -canvas_height * 0.5
    return result

func icon(index: int, size: int = 38) -> TextureRect:
    var result := TextureRect.new()
    result.texture = frame("items", index)
    result.material = material
    result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    result.custom_minimum_size = Vector2(size, size)
    result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    result.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return result
