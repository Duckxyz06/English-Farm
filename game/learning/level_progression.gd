extends Node

var level = 1
var experience = 0

var levels = {
    1: {"name":"Beginner Farm", "xp":100},
    2: {"name":"Growing Learner", "xp":500},
    3: {"name":"English Explorer", "xp":1000}
}

func add_experience(amount):
    experience += amount
    check_level()

func check_level():
    for key in levels:
        if experience >= levels[key]["xp"]:
            level = key
