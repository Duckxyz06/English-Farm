extends Node

signal item_harvested(item_id)

func collect_crop(item_id):
    emit_signal("item_harvested", item_id)
