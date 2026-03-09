import { SPFI } from '@pnp/sp';
import '@pnp/sp/webs';
import '@pnp/sp/lists';
import '@pnp/sp/items';

export interface IQMSDocument {
  ID: number;
  FileLeafRef: string;
  QMSStatus: string;
  QMSVersion: string;
  QMSVersionTyp: string;
  QMSAenderungsart: string;
  QMSAenderungsbeschreibung: string;
  QMSProzessverantwortlicher: { EMail: string; Title: string };
  ServerRedirectedEmbedUri: string;
}

export interface IMinorVersionPayload {
  dokumentId: number;
  dokumentname: string;
  dokumentUrl: string;
  version: string;
  aenderungsart: string;
  aenderungsbeschreibung: string;
  erstellerEmail: string;
}

export class QMSDocumentService {
  private readonly sp: SPFI;
  private readonly listName = 'QMS-Dokumente';

  constructor(sp: SPFI) {
    this.sp = sp;
  }

  public async getDocument(itemId: number): Promise<IQMSDocument> {
    return this.sp.web.lists.getByTitle(this.listName).items.getById(itemId)
      .select(
        'ID', 'FileLeafRef', 'QMSStatus', 'QMSVersion', 'QMSVersionTyp',
        'QMSAenderungsart', 'QMSAenderungsbeschreibung',
        'QMSProzessverantwortlicher/EMail', 'QMSProzessverantwortlicher/Title',
        'ServerRedirectedEmbedUri'
      )
      .expand('QMSProzessverantwortlicher')();
  }

  /** Setzt QMSStatus auf "In Prüfung" und QMSVersionTyp auf "Hauptversion" */
  public async submitForMajorApproval(
    itemId: number,
    version: string,
    aenderungsart: string,
    aenderungsbeschreibung: string
  ): Promise<void> {
    await this.sp.web.lists.getByTitle(this.listName).items.getById(itemId).update({
      QMSStatus:                'In Prüfung',
      QMSVersionTyp:            'Hauptversion',
      QMSVersion:               version,
      QMSAenderungsart:         aenderungsart,
      QMSAenderungsbeschreibung: aenderungsbeschreibung,
    });
  }

  /** Ruft den minor-version-changelog Flow auf (HTTP POST) */
  public async documentMinorVersion(
    flowUrl: string,
    payload: IMinorVersionPayload
  ): Promise<{ changelogId: number }> {
    const response = await fetch(flowUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    if (!response.ok) {
      const text = await response.text();
      throw new Error(`Flow-Aufruf fehlgeschlagen (${response.status}): ${text}`);
    }
    return response.json();
  }
}
