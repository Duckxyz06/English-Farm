extends Node

var items = {}

func add_item(item_id:String, amount:int = 1):
    if items.has(item_id):
        items[item_id] += amount
    else:
        items[item_id] = amount

func remove_item(item_id:String, amount:int = 1):
    if items.has(item_id):
        items[item_id] -= amount
        if items[item_id] <= 0:
            items.erase(item_id)

func get_inventory():
    return items
