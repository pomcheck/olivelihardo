21-10-2026
Ziele:

Was haben wir gemacht:

Probleme und Lösungen:

Nächste Schritte:

## 02-11-2026 - Meilenstein 1: Bestenlisten-Datenbank

Die Bestenliste wird als JSON in `user://highscores.dat` gespeichert. `DatabaseManager` validiert Einträge, sortiert nach Score und Überlebenszeit und ist als Autoload verfügbar.

Vorgeschlagener Commit: `feat: add persistent highscore storage`

## 02-11-2026 - Meilenstein 2: EnemyTree und Spawner

Eine eigene EnemyTree-Szene verfolgt Spieler der Gruppe `player`, berücksichtigt Schwerkraft und wechselt zufällig zwischen normaler Größe und Sprint-/Wachstumsphasen. Der Spawner erzeugt Gegner in variablen Abständen an den Arenarändern.

Vorgeschlagener Commit: `feat: add chasing tree enemies and arena spawner`

## 02-11-2026 - Meilenstein 3: Spieler-Status und HUD

Der Spieler meldet Score, Schaden und Tod über Signale. Das HUD zeigt Überlebenszeit und Score, erlaubt das Speichern eines Namens in der Bestenliste und bietet einen Neustart; Hauptszene und Autoload sind verdrahtet.

Vorgeschlagener Commit: `feat: add survival HUD and game over flow`

## 02-11-2026 - Szenen-Verdrahtung

Player explizit der Gruppe `player` zugeordnet; HUD, EnemySpawner und ein startbereiter EnemyTree in `main.tscn` eingebunden. Treffer laufen über `take_damage()` und aktualisieren Gesundheits-/Trefferanzeige im HUD. Der DatabaseManager-Autoload ist in `project.godot` vorhanden.

Vorgeschlagener Commit: `feat: wire main scene gameplay components`

## 02-11-2026 - Isometrische Kamera und Spielermodell

Die Maussteuerung der Kamera wurde entfernt und durch eine feste, schräge Verfolgerkamera ersetzt. WASD bewegt den Spieler entlang der Weltachsen; das sichtbare Modell dreht sich weich zur Laufrichtung. Torso, Kopf, Arme und Beine mit Hautton- und Kleidungsfarben ergänzt.

Vorgeschlagener Commit: `refactor: switch to isometric top-down camera and add player mesh`

## 02-11-2026 - Bodenhaftung, Baum-States und Höhenlevel

Die Spielerkapsel sitzt nun mit ihrer Unterkante am Player-Ursprung; die Beine beginnen auf Bodenhöhe und die normale Schwerkraft/Floor-Snap-Behandlung bleibt aktiv. EnemyTree verwendet SLEEPING/AWAKENING/CHASING, wacht per Tween bei Annäherung auf und prüft beim Verfolgen den Boden voraus. Das flache Feld wurde durch zwei erhöhte Plateaus, Rampen, Engstellen, Felsen, eine Zielzone mit roter Fahne und strategisch platzierte Bäume ersetzt. Spawnpunkte liegen auf den begehbaren Flächen.

Vorgeschlagener Commit: `feat: add multi-level terrain and distance-based tree aggro system`

## 02-11-2026 - Statische Bäume und Map-Dekoration

Den Laufzeit-Spawner aus der Hauptszene entfernt; alle Bäume sind nun direkt platziert. Zwei Bäume verfolgen den Spieler nach dem Aufwachen, zwei bleiben dauerhaft fixiert. Mehrere Fels-Meshes ergänzen die Start-, Rampen- und Plateau-Bereiche; ausserdem den Player-Root auf Y=0 korrigiert.

Vorgeschlagener Commit: `feat: place tree enemies and add rock decorations`