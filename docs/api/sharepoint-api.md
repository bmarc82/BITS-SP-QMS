# SharePoint REST API – Referenz

## Basis-URL
`https://{tenant}.sharepoint.com/{site}/_api/`

## Dokumentenbibliothek
- `GET web/lists/getbytitle('QMS-Dokumente')/items` – Alle Dokumente
- `POST web/lists/getbytitle('QMS-Dokumente')/items` – Dokument-Metadaten erstellen
- `MERGE web/lists/getbytitle('QMS-Dokumente')/items({id})` – Metadaten aktualisieren

## Inhaltstypen
- `GET web/contenttypes` – Alle Inhaltstypen
- `GET web/contentTypeHub/contenttypes` – Content Type Hub

## PnP PowerShell Äquivalente
```powershell
Get-PnPListItem -List "QMS-Dokumente"
Set-PnPListItem -List "QMS-Dokumente" -Identity 1 -Values @{"Status"="Freigegeben"}
```
