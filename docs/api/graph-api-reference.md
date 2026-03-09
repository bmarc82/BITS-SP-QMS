# Microsoft Graph API – Referenz

## Verwendete Endpunkte

### Sites / SharePoint
- `GET /sites/{site-id}` – Site-Informationen
- `GET /sites/{site-id}/lists` – Listen einer Site
- `POST /sites/{site-id}/lists/{list-id}/items` – Element erstellen

### Users
- `GET /users/{user-id}` – Benutzerinformationen
- `GET /me/memberOf` – Gruppenmitgliedschaften

### Teams
- `POST /teams/{team-id}/channels/{channel-id}/messages` – Nachricht senden
- `GET /teams/{team-id}/installedApps` – Installierte Apps

## Berechtigungen (App-Only)

- `Sites.Read.All`
- `Sites.ReadWrite.All`
- `User.Read.All`
- `Group.ReadWrite.All`
