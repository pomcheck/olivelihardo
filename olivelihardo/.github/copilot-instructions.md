# Projekt: 3D-Game "Trees Hate You" (Schulprojekt KSWE)

## Tech-Stack & Engine:
- Godot 4.x mit GDScript (strikt typisiert, keine Godot 3 Syntax).
- Externe Bearbeitung über VS Code / Git-Versionierung.

## Spielkonzept & Perspektive:
- 3D-Comedy-Survival im Stil von "Trees Hate You".
- Top-Down / isometrische Verfolgerkamera von oben (Third-Person).
- Der Spieler (dunkler Hautton, blaues Shirt) bewegt sich über ein Terrain mit mehreren Höhenebenen.
- Bäume stehen schlafend in der Welt und wachen erst auf (Aggro-Radius), wenn der Spieler sich nähert, um ihn aktiv zu jagen.
- Treffer führt zu Game Over.

## Code- & Architektur-Regeln:
- Modulare Klassen (OOP).
- Signal-basierte Kommunikation (Player -> HUD).
- Persistente Speicherung via DatabaseManager (user://highscores.dat).
- Änderungen immer im JOURNAL.md dokumentieren und Git-Commit-Vorschläge auf Englisch liefern.