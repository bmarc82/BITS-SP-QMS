import { BaseClientSideWebPart } from '@microsoft/sp-webpart-base';

export default class ProcessMapWebPart extends BaseClientSideWebPart<{}> {
  public render(): void {
    this.domElement.innerHTML = '<div>ProcessMap</div>';
    // TODO: React-Komponente einbinden
  }
}
