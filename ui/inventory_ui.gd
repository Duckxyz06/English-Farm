extends Control

var items = []

func add_item(item):
    items.append(item)

func remove_item(item):
    items.erase(item)
