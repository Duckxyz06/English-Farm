extends Node

func interact(target):
    if target.has_method("talk"):
        target.talk()
    elif target.has_method("collect"):
        target.collect()
