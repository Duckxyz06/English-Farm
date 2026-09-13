extends Node

var crops = {}

func plant_crop(id, position):
    crops[position] = {
        "id": id,
        "stage": 0,
        "ready": false
    }

func grow_crop(position):
    if crops.has(position):
        crops[position]["stage"] += 1
        if crops[position]["stage"] >= 3:
            crops[position]["ready"] = true

func harvest(position):
    if crops.has(position) and crops[position]["ready"]:
        var item = crops[position]["id"]
        crops.erase(position)
        return item
    return null
