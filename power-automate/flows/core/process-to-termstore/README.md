# Flow: Prozess in Term Store anlegen

## Zweck

Wenn ein neuer Prozess in der SharePoint-Liste **QMS-Prozesse** angelegt wird,
erstellt dieser Flow automatisch einen entsprechenden Term im Term Set **Prozesse**
des Term Stores. Damit steht der Prozessname als Managed Metadata in der
Dokumentenbibliothek (Spalte `QMSProzess`) zur Verfügung.

## Ablauf

```
[QMS-Prozesse] Neues Element
        │
        ▼
Term bereits vorhanden?
    │           │
   Ja          Nein
    │           │
    │           ▼
    │     Term anlegen (Graph API v2.1 / Term Store)
    │           │
    │           ▼
    │     Term-ID am Listeneintrag speichern
    │           │
    │           ▼
    │     Admin benachrichtigen (Adaptive Card)
    │
    ▼
Beenden (Succeeded) – kein Duplikat
```

## Konfiguration (Platzhalter ersetzen)

| Platzhalter | Beschreibung | Quelle |
|-------------|-------------|--------|
| `{QMS_SITE_URL}` | URL der QMS SharePoint Site | `connection.config.ps1` |
| `{SHAREPOINT_TENANT_URL}` | Tenant Root URL (ohne `/sites/...`) | `connection.config.ps1` |
| `{TERM_GROUP_ID}` | ID der Term Gruppe "QMS" | `config/termstore-ids.json` |
| `{PROZESSE_TERMSET_ID}` | ID des Term Sets "Prozesse" | `config/termstore-ids.json` |
| `{QMS_ADMIN_EMAIL}` | E-Mail des QMS-Administrators | Manuell |

## Authentifizierung

Der Flow nutzt eine **Managed Identity** (System-assigned) für den HTTP-Aufruf
an die SharePoint Term Store REST API. Alternativ: Service Principal mit
`TermStore.ReadWrite.All`-Berechtigung.

## Abhängigkeiten

- `02b_Create-TermStore.ps1` muss ausgeführt worden sein
- Term Set "Prozesse" muss existieren
- SharePoint-Verbindung im Flow konfiguriert

## Term Store API Endpunkt

```
POST /_api/v2.1/termStore/groups/{groupId}/sets/{setId}/terms
```

Dokumentation: [Microsoft Learn – Term Store REST API](https://learn.microsoft.com/en-us/sharepoint/dev/apis/term-store/term-store-rest-api)
EOF