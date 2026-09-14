extends RefCounted

static func read_save(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path,FileAccess.READ)
    if file == null or file.get_length()>65536:
        return {}
    var parser := JSON.new()
    var error := parser.parse(file.get_as_text())
    file.close()
    if error != OK or not parser.data is Dictionary:
        return {}
    return parser.data

static func write_save(path: String, data: Dictionary) -> bool:
    var temporary := path+".tmp"
    var file := FileAccess.open(temporary,FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(data))
    file.flush()
    var error := file.get_error()
    file.close()
    if error != OK:
        return false
    var destination := ProjectSettings.globalize_path(path)
    var backup := destination+".bak"
    if FileAccess.file_exists(path):
        if FileAccess.file_exists(path+".bak"):
            if DirAccess.remove_absolute(backup) != OK:
                return false
        if DirAccess.rename_absolute(destination,backup) != OK:
            return false
    if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),destination) != OK:
        if FileAccess.file_exists(path+".bak"):
            DirAccess.rename_absolute(backup,destination)
        return false
    return true
