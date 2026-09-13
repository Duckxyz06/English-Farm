extends Node

var quests = {
    "first_english_lesson": {
        "title":"Bài học đầu tiên",
        "completed":false,
        "reward":50
    }
}

func complete_quest(id:String):
    if quests.has(id):
        quests[id]["completed"] = true
        return quests[id]["reward"]
    return 0
