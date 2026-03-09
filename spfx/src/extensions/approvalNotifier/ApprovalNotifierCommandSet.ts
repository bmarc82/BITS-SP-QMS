import { override } from '@microsoft/decorators';
import {
  BaseListViewCommandSet,
  Command,
  IListViewCommandSetListViewUpdatedParameters,
  IListViewCommandSetExecuteEventParameters,
  RowAccessor
} from '@microsoft/sp-listview-extensibility';
import { spfi, SPFx } from '@pnp/sp';
import * as React from 'react';
import * as ReactDOM from 'react-dom';
import { QMSDocumentService } from './services/QMSDocumentService';
import { MinorVersionPanel } from './components/MinorVersionPanel';
import { MajorVersionPanel } from './components/MajorVersionPanel';

export interface IApprovalNotifierCommandSetProperties {
  /** URL des minor-version-changelog Power Automate Flows */
  minorVersionFlowUrl: string;
}

const CMD_MINOR = 'DOCUMENT_MINOR_VERSION';
const CMD_MAJOR = 'SUBMIT_MAJOR_VERSION';

/** Erlaubte Status für Nebenversion (Dokument darf nicht in Prüfung/Freigegeben sein) */
const MINOR_ALLOWED_STATUSES = ['Entwurf', 'Freigegeben', ''];
/** Für Hauptversion: nur aus Entwurf einreichen */
const MAJOR_ALLOWED_STATUSES = ['Entwurf', ''];

export default class ApprovalNotifierCommandSet
  extends BaseListViewCommandSet<IApprovalNotifierCommandSetProperties> {

  private panelContainer!: HTMLDivElement;
  private docService!: QMSDocumentService;

  @override
  public onInit(): Promise<void> {
    const sp = spfi().using(SPFx(this.context));
    this.docService = new QMSDocumentService(sp);

    this.panelContainer = document.createElement('div');
    document.body.appendChild(this.panelContainer);

    return Promise.resolve();
  }

  @override
  public onListViewUpdated(event: IListViewCommandSetListViewUpdatedParameters): void {
    const cmdMinor = this.tryGetCommand(CMD_MINOR);
    const cmdMajor = this.tryGetCommand(CMD_MAJOR);

    const selectedCount = event.selectedRows.length;
    if (selectedCount !== 1) {
      if (cmdMinor) cmdMinor.visible = false;
      if (cmdMajor) cmdMajor.visible = false;
      return;
    }

    const row = event.selectedRows[0];
    const status: string = row.getValueByName('QMSStatus') ?? '';

    if (cmdMinor) {
      cmdMinor.visible = MINOR_ALLOWED_STATUSES.includes(status);
    }
    if (cmdMajor) {
      cmdMajor.visible = MAJOR_ALLOWED_STATUSES.includes(status);
    }
  }

  @override
  public onExecute(event: IListViewCommandSetExecuteEventParameters): void {
    const row = event.selectedRows[0];
    const itemId = parseInt(row.getValueByName('ID'), 10);
    const dokumentname: string = row.getValueByName('FileLeafRef') ?? 'Unbekannt';

    switch (event.itemId) {
      case CMD_MINOR:
        this.openMinorPanel(itemId, dokumentname, row);
        break;
      case CMD_MAJOR:
        this.openMajorPanel(itemId, dokumentname, row);
        break;
    }
  }

  private openMinorPanel(itemId: number, dokumentname: string, row: RowAccessor): void {
    const erstellerEmail: string = this.context.pageContext.user.email ?? '';

    const element = React.createElement(MinorVersionPanel, {
      isOpen: true,
      dokumentname,
      aktuelleVersion: row.getValueByName('QMSVersion') ?? '',
      erstellerEmail,
      onDismiss: () => this.unmountPanel(),
      onSubmit: async (version, aenderungsart, beschreibung) => {
        const doc = await this.docService.getDocument(itemId);
        await this.docService.documentMinorVersion(
          this.properties.minorVersionFlowUrl,
          {
            dokumentId:            itemId,
            dokumentname,
            dokumentUrl:           doc.ServerRedirectedEmbedUri ?? '',
            version,
            aenderungsart,
            aenderungsbeschreibung: beschreibung,
            erstellerEmail,
          }
        );
      },
    });
    ReactDOM.render(element, this.panelContainer);
  }

  private openMajorPanel(itemId: number, dokumentname: string, row: RowAccessor): void {
    const freigeberEmail: string =
      (row.getValueByName('QMSProzessverantwortlicher') as { EMail?: string })?.EMail ?? '';

    const element = React.createElement(MajorVersionPanel, {
      isOpen: true,
      dokumentname,
      freigeberEmail,
      onDismiss: () => this.unmountPanel(),
      onSubmit: async (version, aenderungsart, beschreibung) => {
        await this.docService.submitForMajorApproval(
          itemId, version, aenderungsart, beschreibung
        );
      },
    });
    ReactDOM.render(element, this.panelContainer);
  }

  private unmountPanel(): void {
    ReactDOM.unmountComponentAtNode(this.panelContainer);
  }

  public onDispose(): void {
    if (this.panelContainer) {
      ReactDOM.unmountComponentAtNode(this.panelContainer);
      document.body.removeChild(this.panelContainer);
    }
    super.onDispose();
  }
}
