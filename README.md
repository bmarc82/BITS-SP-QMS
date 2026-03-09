# QMS M365

> **ISO 9001:2015-konformes Qualitätsmanagementsystem auf Microsoft 365**  
> Modular erweiterbar · Vollständig automatisiert · KI-integriert  
> Version: 1.0 | Status: In Entwicklung | Gültig ab: 09.03.2026

## Überblick

Das Projekt implementiert ein vollständiges QMS als deploybare Lösung auf Microsoft 365. Es besteht aus acht Hauptmodulen, die unabhängig voneinander entwickelt, getestet und ausgerollt werden können.

## Module

| Modul | Beschreibung |
|-------|-------------|
| [Admin Tool](admin-tool/) | Grafische Oberfläche für Installation, Konfiguration und Wartung |
| [PowerShell](powershell/) | Provisionierung und Wartung der M365-Infrastruktur |
| [SPFx](spfx/) | Webparts und Extensions für SharePoint |
| [Power Automate](power-automate/) | Automatisierte Workflows und Benachrichtigungen |
| [Power Apps](power-apps/) | Mobile Apps für QMS-Aufgaben |
| [Teams](teams/) | Teams-Integration mit Tabs, Bot und Messaging Extension |
| [Adaptive Cards](adaptive-cards/) | Interaktive Benachrichtigungskarten |
| [KI-Agenten](ai-agents/) | Intelligente Unterstützung bei QMS-Dokumenten |

## Schnellstart

1. Admin Tool starten und Tenant-Verbindung konfigurieren
2. PowerShell-Skripte in nummerierter Reihenfolge ausführen
3. SPFx-Lösung deployen
4. Power Automate Flows importieren
5. Teams App publizieren
