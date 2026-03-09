# Review-Erinnerung

## Trigger
Täglich um 08:00 Uhr (Scheduled)

## Ablauf

1. Alle Prozesse mit `QMSNaechstesPruefDatum` abrufen
2. Prüfen, ob Fristdatum innerhalb von 60, 30 oder 7 Tagen
3. Entsprechende Erinnerungs-Adaptive-Card senden
4. Bei Überschreitung: Eskalation an Vorgesetzten
