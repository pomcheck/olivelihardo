# Projekt: 3D-Game "Furniture Hates You" / "Chairs Hate Me" (Schulprojekt KSWE)

## Tech-Stack & Engine:
- Godot 4.x mit GDScript (strikt typisiert, Godot-4-Syntax: instantiate(), @onready, @export).
- Externe Code-Bearbeitung in VS Code, Versionskontrolle via Git / GitHub.

## Spielkonzept & Setting:
- 3D-Comedy-Survival in einem labyrinthischen Möbelhaus (IKEA-Stil).
- Top-Down / isometrische Verfolgerkamera von oben (Third-Person).
- Es gibt harmlose Möbel (Tische, Regale, Schränke, Teppiche, Lampen) als Hindernisse / Deckung.
- Aggressive Möbel (Sessel, Bürostühle, Klappstühle, Sofas) "hassen" den Spieler:
  * Sie tarnen sich als normale Möbel und wachen auf, wenn man ihnen zu nahe kommt.
  * Modulares Angriffssystem mit unterschiedlichen Verhaltensweisen/Mechanismen pro Möbel-Typ.
- Ziel: Durch die Möbelhaus-Abteilungen zum Notausgang (Exit-Zone) navigieren, ohne erwischt zu werden.
- Player MUSS Schwarz sein (dark skin + blue t shirt)

## Architektur & OOP-Vorgaben:
- Basisklasse `FurnitureEnemy` (erbt von `CharacterBody3D`):
  * Beinhaltet State-Machine: SLEEPING, AWAKENING, ATTACKING, COOLDOWN.
  * Handhabt Spielererkennung, Schwerkraft und Signalgebung bei Treffer.
- Spezifische Subklassen erben von `FurnitureEnemy` und überschreiben die Angriffslogik:
  1. `ChasingChair` (Bürostuhl): Rollt schnell und direkt auf den Spieler zu.
  2. `FlyingArmchair` (Flugsessel): Hebt per Tween ab und stürzt wie eine Bombe auf den Spieler herab.
  3. `ExpandingSofa` (Expanding Sofa): Bläht sich auf die 3-4-fache Grösse auf und sperrt Gänge ab.
  4. `SpinningStool` (Drehhocker): Wirbelt mit hoher Rotationsgeschwindigkeit im Raum herum.
  5. `CushionMortarSofa` (Kissen-Mörser): Schiesst explosive Kissen-Projektile.
  6. `TeleportingRecliner` (Fernsehsessel): Teleportiert sich hinter den Spieler, wenn dieser wegschaut.
  7. `FoldingTrapChair` (Klappstuhl): Schnappt bei Betreten wie eine Bärenfalle zu.
- Datenbank: Speicherung von Highscores & Überlebenszeiten via `DatabaseManager`.
- UI: HUD mit Überlebenszeit, Abteilungsanzeige und Game-Over-Screen.
- Dokumentation: Jeder Meilenstein wird im JOURNAL.md dokumentiert mit passender Git-Commit-Nachricht.
