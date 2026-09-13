extends Node

var dialogues = {
    "teacher_cat": [
        "Hello Momo!",
        "Let's practice English today!",
        "Small steps create progress."
    ]
}

func get_dialogue(npc):
    return dialogues.get(npc, [])
