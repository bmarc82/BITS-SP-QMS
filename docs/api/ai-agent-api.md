# KI-Agenten API – Dokumentation

## Copilot Studio

Agenten werden als Topics und Actions in Microsoft Copilot Studio konfiguriert.

## Azure AI Foundry

Für erweiterte Agenten (Prozess-Optimierer) wird Azure AI Foundry genutzt.

## Schnittstellen

### Document Assistant
- Input: Freitext (Prozessbeschreibung)
- Output: Strukturiertes Prozessdokument (Markdown / Word)
- Wissensquelle: QMS-Dokumentenbibliothek (freigegebene Dokumente)

### Review Advisor
- Input: Dokument-ID (SharePoint)
- Output: Analysebericht mit Lücken und ISO-Bezügen

### Audit Prep Agent
- Input: ISO-Kapitel
- Output: Nachweisliste mit verlinkten Dokumenten
