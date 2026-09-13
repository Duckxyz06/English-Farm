extends Node

var current_season = "spring"
var day = 1

var seasons = ["spring", "summer", "autumn", "winter"]

func change_season(new_season):
    if new_season in seasons:
        current_season = new_season

func next_day():
    day += 1
