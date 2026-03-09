# Flow: Nebenversion dokumentieren

## Zweck

Erstellt einen Changelog-Eintrag für Nebenversionen (1.1, 1.2, 2.1 ...) **ohne Genehmigungsprozess**.
Leser sehen weiterhin die zuletzt genehmigte Hauptversion (Content Approval).

## Versionierungsregeln

| Versionstyp | Beispiel | Genehmigung | Sichtbar für Leser |
|-------------|----------|-------------|-------------------|
| Hauptversion | 1.0, 2.0 | **Ja** → Approval-Flow | Erst nach Genehmigung |
| Nebenversion | 1.1, 1.2 | Nein | Nur Freigeber + Autor |

## Trigger

HTTP POST (kein SharePoint-Trigger) – ausgelöst durch:
- SPFx ListView Command Set: «Nebenversion dokumentieren»
- Power Apps: Process Review App

## Request Body

```json
{
  "dokumentId":             42,
  "dokumentname":           "P-001 Angebotsprozess.docx",
  "dokumentUrl":            "https://contoso.sharepoint.com/...",
  "version":                "1.1",
  "aenderungsart":          "Formale Korrektur",
  "aenderungsbeschreibung": "Tippfehler in Abschnitt 3 korrigiert",
  "erstellerEmail":         "max.muster@contoso.com",
  "prozess":                "Angebotsprozess",
  "bereich":                "Vertrieb"
}
```

## Ablauf

```
HTTP POST
    │
    ▼
Version endet auf .0?  → Fehler: Hauptversions-Flow verwenden
    │
    ▼
QMSVersion, QMSVersionTyp = "Nebenversion" am Dokument setzen
    │
    ▼
Changelog-Eintrag erstellen (kein Freigeber, kein Datum)
    │
    ▼
HTTP 200 Response mit Changelog-ID
```

## Abhängigkeiten

- `04b_Create-ChangelogList.ps1` ausgeführt
- `03_Configure-Library.ps1` ausgeführt (QMSVersionTyp-Feld vorhanden)
EOF