import { BaseClientSideWebPart } from '@microsoft/sp-webpart-base';

export default class DocumentViewerWebPart extends BaseClientSideWebPart<{}> {
  public render(): void {
    this.domElement.innerHTML = '<div>DocumentViewer</div>';
    // TODO: React-Komponente einbinden
  }
}
