extends Resource

class_name SeedItem

@export var seed_id:String
@export var crop_name:String
@export var growth_days:int = 3

func create_crop():
    return {
        "id": seed_id,
        "days": growth_days
    }
