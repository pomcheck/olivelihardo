# Projekt: 3D-Game "Furniture Hates You" (Schulprojekt KSWE)

## Tech-Stack & Engine:
- Godot 4.x mit GDScript (strikt typisiert, `@onready`, `@export`, Signale, Autoloads).
- Externe Bearbeitung über VS Code / Git-Versionierung.

## Artstyle, Kamera & Shader:
- Stylized Comic-/Cel-Shading Look (Toon-Shader mit diskreten Schattierungsstufen und Outline-Effekt).
- Top-Down / isometrische Verfolgerkamera (Third-Person): Blickt von schräg oben herab, folgt dem Spieler flüssig ohne Wandkollisions-Clipping.
- Player-Visuals: Menschlich proportionierte Stilisierung (Kopf, Torso, Gliedmassen), dunkler Hautton (`Color(0.24, 0.15, 0.10, 1.0)`), blaues T-Shirt, dunkle Hose.
- Prozedurale Laufanimation (Watscheln/Bobbing via Tween oder Gliedmassen-Rotationen).

## Leveldesign (Möbelhaus-Plateaus & Treppen):
- Grosses rechteckiges Areal mit hohen Aussenwänden.
- Innenaufteilung durch hohe Lagerregale und Raumteiler, sodass Kamera nie durch Aussenwände verdeckt wird.
- Mehrere vertikale Ebenen (Plateaus) im Stil von gestuften Terrassen mit Treppen und Rampen (wie im Referenzbild).
- Alle statischen Objekte (Regale, Treppenkanten, Tische) besitzen exakt anliegende `CollisionShape3D`-Knoten (kein Durchfallen, kein Klemmen).
- Checkpoints entlang des Weges bis zur Exit-Zone (Notausgang).

## Audio & Sounddesign:
- Prozedurale/synthetisierte Soundeffekte via `AudioStreamWAV` oder `AudioStreamPlayer3D` für:
  * Schritte / Laufen
  * Aggro-Schrei / Wackeln erwachender Möbel
  * Spezifische Angriffs-Sounds (Whoosh, Slam, Kissen-Puff)
  * Kill-Treffer und Respawn
  * Hintergrund-Synthesizer-Musikloop (prozedural oder Chiptune-Stream).

## Sterbe- & Respawn-Sequenz (Death FX):
- Bei Treffer: Sofortige rote Bildschirm-Aufblitzung (`ColorRect` flash red) + Spielerfigur-Material flasht rot.
- Kamera-Shake (Trauma-System).
- Weicher Fade-out zu Schwarz (`fade_to_black`).
- Zurücksetzen an den letzten Checkpoint mit Fade-in aus dem Schwarz.

## OOP-Gegner-Architektur:
- `FurnitureEnemy` (Basisklasse `CharacterBody3D`): State-Machine (SLEEPING, AWAKENING, ATTACKING, COOLDOWN), Erkennung, Gravitation, Signale.
- Subklassen:
  1. `ChasingChair` (Bürostuhl: schneller Verfolger)
  2. `FlyingArmchair` (Sessel: hebt ab, stürzt von oben herab)
  3. `ExpandingSofa` (Sofa: skaliert sich massiv auf und versperrt Gänge)
  4. `SpinningStool` (Drehhocker: wirbelt rotierend im Raum)
  5. `CushionMortarSofa` (Kissen-Mörser: ballistische Kissen-Projektile)
  6. `TeleportingRecliner` (Teleport-Sessel: taucht hinter Spieler auf)
  7. `FoldingTrapChair` (Klappstuhl: schnappt blitzartig zu)
- Persistenz: Highscore-Speicherung via `DatabaseManager`.