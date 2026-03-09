# SPFx Webparts

Moderne SharePoint Framework Webparts und Extensions für QMS M365.

## Webparts

| Webpart | Beschreibung |
|---------|-------------|
| processMap | Prozesslandkarte mit Filter und Statusfarbkodierung |
| documentViewer | Dokumentenansicht mit vollständigen Metadaten |
| reviewDashboard | Fällige Reviews und Statusübersicht |
| myProcesses | «Meine Prozesse» für Process Owner |
| statusBadge | Statusanzeige-Badge |
| aiAssistant | KI-Assistent eingebettet in SharePoint |

## Extensions

| Extension | Typ | Beschreibung |
|-----------|-----|-------------|
| documentMetadata | Field Customizer | Metadaten-Darstellung |
| approvalNotifier | ListView Command Set | Freigabe-Aktion aus Listenansicht |

## Setup

```bash
npm install
gulp serve
```

## Deploy

```bash
gulp bundle --ship
gulp package-solution --ship
# .sppkg in App Catalog hochladen
```
