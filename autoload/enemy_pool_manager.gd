extends Node
## EnemyPoolManager (Autoload)
##
## Zentrales Object-Pooling für Gegner (Technisches Konzept §3).
## Gegner werden vorinstanziiert und zwischen active/inactive umgeschaltet,
## statt per instantiate()/queue_free() erzeugt/gelöscht zu werden –
## vermeidet GC-Spitzen und Frame-Drops auf Mobile.
##
## API:
##   register_pool(pool_id, scene, size)  – Pool anlegen/vorwärmen
##   get_instance(pool_id)                – freie Instanz holen (null = Pool erschöpft)
##   return_instance(instance)            – Instanz zurück in den Pool geben
##   count_active(pool_id)                – Anzahl aktiver Instanzen

## Harte Obergrenze aktiver Gegner (Balancing-Dokument §1).
## Der SpawnDirector darf niemals mehr als diese Zahl aktive Gegner halten.
const HARD_ENEMY_CAP := 85

## Performance-Testpuffer für Meilenstein 0 (Sicherheitspuffer, kein Dauerzustand).
const STRESS_TEST_CAP := 100

var _pools: Dictionary = {}


func register_pool(pool_id: StringName, scene: PackedScene, size: int) -> void:
	if _pools.has(pool_id):
		push_warning("EnemyPoolManager: Pool '%s' existiert bereits – wird ersetzt." % pool_id)
		release_pool(pool_id)

	var pool := {
		"scene": scene,
		"instances": [] as Array[Node2D],
		"free": [] as Array[Node2D],
	}

	for i in size:
		var instance: Node2D = scene.instantiate()
		instance.name = "%s_%d" % [pool_id, i]
		if instance.has_method("deactivate"):
			instance.deactivate()
		pool["instances"].append(instance)
		pool["free"].append(instance)

	_pools[pool_id] = pool


## Hängt alle Pool-Instanzen unter den übergebenen Node (einmalig, nach register_pool).
func attach_pool_to(pool_id: StringName, parent: Node) -> void:
	if not _pools.has(pool_id):
		push_error("EnemyPoolManager: Pool '%s' nicht registriert." % pool_id)
		return
	for instance: Node2D in _pools[pool_id]["instances"]:
		if instance.get_parent() == null:
			parent.add_child(instance)


func get_instance(pool_id: StringName) -> Node2D:
	if not _pools.has(pool_id):
		push_error("EnemyPoolManager: Pool '%s' nicht registriert." % pool_id)
		return null
	var free_list: Array = _pools[pool_id]["free"]
	if free_list.is_empty():
		return null
	var instance: Node2D = free_list.pop_back()
	if instance.has_method("activate"):
		instance.activate()
	return instance


func return_instance(instance: Node2D) -> void:
	if instance == null:
		return
	for pool_id: StringName in _pools:
		var pool: Dictionary = _pools[pool_id]
		if instance in pool["instances"]:
			if instance.has_method("deactivate"):
				instance.deactivate()
			if instance not in pool["free"]:
				pool["free"].append(instance)
			return
	push_warning("EnemyPoolManager: Instanz '%s' gehört zu keinem Pool." % instance.name)


func return_all(pool_id: StringName) -> void:
	if not _pools.has(pool_id):
		return
	for instance: Node2D in _pools[pool_id]["instances"]:
		return_instance(instance)


func count_active(pool_id: StringName) -> int:
	if not _pools.has(pool_id):
		return 0
	return _pools[pool_id]["instances"].size() - _pools[pool_id]["free"].size()


func count_free(pool_id: StringName) -> int:
	if not _pools.has(pool_id):
		return 0
	return _pools[pool_id]["free"].size()


func release_pool(pool_id: StringName) -> void:
	if not _pools.has(pool_id):
		return
	for instance: Node2D in _pools[pool_id]["instances"]:
		if is_instance_valid(instance):
			instance.queue_free()
	_pools.erase(pool_id)


func release_all_pools() -> void:
	for pool_id: StringName in _pools.keys():
		release_pool(pool_id)
