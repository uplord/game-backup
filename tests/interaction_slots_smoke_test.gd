extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var entity := UplordWorldEntity.new()
    entity.global_position = Vector2(1000, 500)
    root.add_child(entity)
    if entity.slot_horizontal_distance != 210.0 or entity.interaction_radius != 240.0:
        push_error("FAIL: incorrect interaction spacing")
        quit(1)
        return
    var players: Array[Node2D] = []
    var bounds := Rect2(0, 0, 2500, 1200)
    for i in range(10):
        var player := Node2D.new()
        player.position = Vector2(200 if i < 5 else 1800, 500)
        root.add_child(player)
        players.append(player)
        var slot := entity.reserve_slot(player, bounds)
        if slot < 0 or (slot < 5) != (i < 5):
            push_error("FAIL: incorrect slot assignment at player %d" % i)
            quit(1)
            return
    if entity.reserved_slot_count() != 10:
        push_error("FAIL: expected 10 reservations")
        quit(1)
        return
    var extra := Node2D.new()
    root.add_child(extra)
    if entity.reserve_slot(extra, bounds) != -1:
        push_error("FAIL: full entity accepted 11th player")
        quit(1)
        return
    entity.release_slot(players[0])
    if entity.reserve_slot(extra, bounds) != 0:
        push_error("FAIL: released slot not reused")
        quit(1)
        return
    for player in players:
        player.queue_free()
    extra.queue_free()
    entity.queue_free()
    print("PASS: ten slots, preferred side, capacity, release and reuse")
    quit(0)
