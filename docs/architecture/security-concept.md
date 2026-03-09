# Sicherheitskonzept

## Authentifizierung

Alle Automatisierungen nutzen App-Only-Authentifizierung:
- Azure AD App Registration mit Zertifikat oder Client Secret
- Client Secret wird im Admin Tool verschlüsselt gespeichert
- Kein interaktives Login in Produktionsprozessen

## Berechtigungsgruppen

| Gruppe | SharePoint Rolle | Beschreibung |
|--------|-----------------|--------------|
| QMS-Leser | Lesen | Alle Mitarbeitenden |
| QMS-Ersteller | Mitwirken | Dokumentenersteller |
| QMS-Prozessverantwortliche | Mitwirken + Genehmigen | Process Owner |
| QMS-Freigeber | Genehmigen | Qualitätsmanager |
| QMS-Administratoren | Vollzugriff | QM-Admins |

## Datenschutz

- Keine personenbezogenen Daten in Logs
- Credentials nur verschlüsselt gespeichert
- Zugriff auf AI-Agenten nur auf freigegebene Dokumente
