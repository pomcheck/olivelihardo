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

## 02-11-2026 - Sichtlinie, Hindernisvermeidung und Checkpoint

Jagd-Bäume wachen nur innerhalb ihres Sichtkegels und bei freier Sicht auf. Beim Verfolgen umrunden sie Wände und meiden Abgründe; Treffer werden ebenfalls per Sichtlinie geprüft. Fixbäume sind ungefährlich und erhalten eine hellere Färbung. Die rote Flagge setzt nun einen Checkpoint, an dem der Spieler nach einem Treffer wieder erscheint.

Vorgeschlagener Commit: `feat: add tree vision, obstacle avoidance, and checkpoint respawn`

## 02-11-2026 - FurnitureEnemy OOP-Architektur

Neue `FurnitureEnemy`-Basisklasse mit Zustandsmaschine, Spielererkennung, Aufwach-Tween, Gravitation, Kontakt und Cooldown. Fünf Subklassen implementieren Verfolgungsstuhl, fliegenden Sessel, expandierendes Sofa, wirbelnden Hocker und Klappstuhl-Falle; für alle gibt es eigene Mesh-/Kollisionsszenen. Die Möbel sind in der Hauptszene platziert.

Vorgeschlagener Commit: `feat: implement FurnitureEnemy base class and 5 specialized attack subclasses`

## 02-11-2026 - Respawn, Möbelhaus-Level und entschärfte Angriffe

Treffer respawnen den Spieler am Checkpoint oder Start statt Game Over auszulösen. Möbel sind nur während aktiver Angriffe gefährlich, kehren danach zur Ausgangsposition zurück und müssen erneut getriggert werden; der Bürostuhl entschärft sich nach Annäherung auf etwa drei Meter. Die Abteilungen wurden mit 2,5-m-Wänden, Rampen, Betten, Regalen, Küchen- und Kassenmöbeln, Teppichen, Lampen und Beschriftungen ausgestaltet.

Vorgeschlagener Commit: `fix: add safe respawns and detailed furniture store level`

## 02-11-2026 - Start-/Pausenmenü und Laufanimation

Die bisherigen Score-, Zeit-, Health-, Checkpoint- und Bestenlistenanzeigen aus dem HUD entfernt. Ein zentrierter Death Count, ein Startmenü beim ersten Laden sowie ein thematisches Escape-Pausenmenü mit echter Scene-Pause hinzugefügt. Arme und Beine des Players schwingen über Gelenkpivots mit einer prozeduralen Laufanimation.

Vorgeschlagener Commit: `feat: add start pause menus death counter and player run animation`

## 02-11-2026 - Emote-Rad und Schleichen

F öffnet ein pausierendes Emote-Rad mit Groove-, Spin-, Wave- und Bounce-Tanz; die Auswahl spielt eine kurze Player-Animation ab. Linke Shift-Taste aktiviert den Schleichmodus mit reduziertem Tempo, abgesenkter Figur und kleinerer Kapsel.

Vorgeschlagener Commit: `feat: add dance emote wheel and left-shift sneaking`