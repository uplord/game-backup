extends Node
## Structured, bounded diagnostic messages. Never log credentials or tokens.
signal entry_added(entry: Dictionary)
enum Level {DEBUG, INFO, WARNING, ERROR}
const LEVEL_NAMES := ["DEBUG", "INFO", "WARN", "ERROR"]
const MAX_ENTRIES := 250
var minimum_level: Level = Level.INFO
var _entries: Array[Dictionary] = []

func write(level: Level, category: String, message: String, context: Dictionary = {}) -> void:
    if level < minimum_level:
        return
    var record: Dictionary = {
        "time_ms": Time.get_ticks_msec(),
        "level": LEVEL_NAMES[level],
        "category": category,
        "message": message,
        "context": context.duplicate(true)
    }
    _entries.append(record)
    if _entries.size() > MAX_ENTRIES:
        _entries.pop_front()
    var line := "[%s][%s] %s" % [record["level"], category, message]
    if level == Level.ERROR:
        printerr(line)
    elif level == Level.WARNING:
        push_warning(line)
    else:
        print(line)
    entry_added.emit(record.duplicate(true))

func info(category: String, message: String, context: Dictionary = {}) -> void:
    write(Level.INFO, category, message, context)

func warn(category: String, message: String, context: Dictionary = {}) -> void:
    write(Level.WARNING, category, message, context)

func error(category: String, message: String, context: Dictionary = {}) -> void:
    write(Level.ERROR, category, message, context)

func entries() -> Array[Dictionary]:
    return _entries.duplicate(true)

func clear() -> void:
    _entries.clear()
