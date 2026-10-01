extends Node
## Telemetrie (Playtesting-Dokument §4): lokale Events für Balancing-Analysen.
##
## Format: eine JSON-Zeile pro Event unter `user://telemetry/session_<id>.jsonl`
##   {"ts": <ms seit Epoch>, "session": "<id>", "event": "<name>", ...props}
## Die Session-ID ist der Zeitstempel des Spielstarts – jede Spielinstanz
## schreibt eine eigene Datei (keine Konflikte bei parallelen Läufen).
##
## Design-Regeln:
## - Fail-silent: Telemetrie darf den Spielbetrieb nie stören. Schlägt das
##   Öffnen der Datei fehl, deaktiviert sie sich selbst (nur eine Warnung).
## - Kein Puffer: jede Zeile wird sofort auf die Platte geschrieben – bei einem
##   Absturz geht kein Event verloren. Das Volumen ist lokal und gering.
## - Autoload-Reihenfolge: VOR MetaProgress registrieren, weil MetaProgress
##   `talent_purchased` trackt (project.godot [autoload]).
##
## Nicht verdrahtbare Events (§4, hier bewusst ausgelassen, Commit-Vermerk):
## `perun_spawn`/`perun_defeated` (Perun-Boss nicht implementiert) und
## `double_evolved` (Doppel-Evolutionen kommen in M4).

## Verzeichnis für alle Session-Dateien.
const TELEMETRY_DIR := "user://telemetry/"

## Gesamtzahl geschriebener Events (für Tests/Debug).
var event_count := 0

var _enabled := false
var _file: FileAccess = null
var _session := ""


func _ready() -> void:
	_session = str(int(Time.get_unix_time_from_system() * 1000.0))
	# Zielverzeichnis anlegen (unabhängig vom Arbeitssystem globalisieren).
	var dir_path := ProjectSettings.globalize_path(TELEMETRY_DIR)
	if not DirAccess.dir_exists_absolute(dir_path):
		var err := DirAccess.make_dir_recursive_absolute(dir_path)
		if err != OK and not DirAccess.dir_exists_absolute(dir_path):
			push_warning("Telemetry: %s nicht anlegbar (Fehler %d) – deaktiviert." % [dir_path, err])
			return
	var path := "%ssession_%s.jsonl" % [TELEMETRY_DIR, _session]
	_file = FileAccess.open(path, FileAccess.WRITE)
	if _file == null:
		push_warning("Telemetry: %s nicht schreibbar (Fehler %d) – deaktiviert." % [
			path, FileAccess.get_open_error()])
		return
	_enabled = true


## Schreibt ein Event. `props` enthält die Event-spezifischen Felder (§4);
## StringName-Werte werden für JSON normalisiert. Tue niemals etwas außer
## Zeile schreiben – kein Signal, keine Logik, kein Fehler nach außen.
func track(event: StringName, props: Dictionary = {}) -> void:
	if not _enabled or _file == null:
		return
	var line := {
		"ts": int(Time.get_unix_time_from_system() * 1000.0),
		"session": _session,
		"event": String(event),
	}
	for key: Variant in props:
		var value: Variant = props[key]
		# JSON.stringify kann StringName/NodePath nicht abbilden.
		if value is StringName or value is NodePath:
			value = String(value)
		line[String(key)] = value
	_file.store_line(JSON.stringify(line))
	_file.flush()
	event_count += 1


## Gibt die aktuelle Session-ID zurück (Tests: Datei-Nachweis).
func session_id() -> String:
	return _session


## Gibt die Datei der aktuellen Session zurück (Tests: Pfad-Nachweis).
func session_path() -> String:
	return "%ssession_%s.jsonl" % [TELEMETRY_DIR, _session]


func _exit_tree() -> void:
	if _file != null:
		_file.close()
		_file = null
