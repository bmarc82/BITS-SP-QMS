# Freigabe-Workflow

## Trigger
SharePoint: Dokument-Status wechselt zu «In Prüfung»

## Ablauf

1. Freigabeanfrage an Freigeber senden (Adaptive Card in Teams + E-Mail)
2. Warten auf Entscheidung (Frist: 7 Werktage)
3. **Bei Genehmigung:**
   - Status → «Freigegeben»
   - Gültig-ab-Datum setzen
   - Freigeber eintragen
   - Alle betroffenen Personen benachrichtigen
   - Vorgängerversion archivieren
4. **Bei Ablehnung:**
   - Status → «Entwurf»
   - Ersteller mit Kommentar benachrichtigen
5. **Bei Timeout:**
   - Eskalation an Vorgesetzten
   - Erinnerung an Freigeber

## Konfiguration

- `ApprovalTimeout`: Frist in Werktagen (Standard: 7)
- `EscalationEmail`: E-Mail-Adresse für Eskalationen
