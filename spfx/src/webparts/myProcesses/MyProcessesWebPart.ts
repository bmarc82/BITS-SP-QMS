import { BaseClientSideWebPart } from '@microsoft/sp-webpart-base';

export default class MyProcessesWebPart extends BaseClientSideWebPart<{}> {
  public render(): void {
    this.domElement.innerHTML = '<div>MyProcesses</div>';
    // TODO: React-Komponente einbinden
  }
}
