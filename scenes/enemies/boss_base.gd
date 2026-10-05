extends TestEnemy
class_name BossBase
## Gemeinsame Basis aller (Mini-)Bosse (M4b, Refactor aus LeshyBoss).
##
## Bosse sind NICHT gepoolt (einzige Instanz pro Run), deshalb eigene
## take_damage-Variante: bei Tod Aufräumen + queue_free() statt
## EnemyPoolManager.return_instance(). setup_boss() liefert die FIX-Werte
## (Balancing §6): Boss-HP/Schaden OHNE Zeit- und Regions-Multiplikator –
## die Multiplikatoren gelten als eingerechnet.
##
## hp_ratio() steht hier (nicht mehr in LeshyBoss), weil der Boss-Balken
## zwischen Haupt- und Mini-Boss hin- und herwechselt (M4b).


## Vom Tod aufzuräumende Effekte der Unterklasse (z. B. Leshys
## Terrain-Hazard). Läuft VOR dem Sieg-Callback, damit im Tree nichts
## zurückbleibt, was die Unterklasse besessen hat.
func _on_death_cleanup() -> void:
	pass


## Schaden ohne Pool-Rückgabe (M4b-Refactor: Muster vorher in LeshyBoss).
func take_damage(amount: float) -> void:
	_hp -= amount
	if _hp <= 0.0:
		_on_death_cleanup()
		if on_died.is_valid():
			on_died.call(self)
		queue_free()
	else:
		# Treffer-Feedback: kurzer weißer Blitz.
		_visual.modulate = Color(2.0, 2.0, 2.0)
		_flash_time = 0.08


## HP-Ratio 0–1 für den Boss-Balken (main._process). Public-Getter, da
## _hp bewusst privat ist.
func hp_ratio() -> float:
	return clampf(_hp / max_hp, 0.0, 1.0)


## Spawn-Setup eines Bosses: Multiplikatoren fest 1.0 (FIX-Werte §6).
func setup_boss(data: EnemyData) -> void:
	setup_from_data(data, 1.0, 1.0, false)
