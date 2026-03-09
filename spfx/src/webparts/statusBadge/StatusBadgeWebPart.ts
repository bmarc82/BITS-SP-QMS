import { BaseClientSideWebPart } from '@microsoft/sp-webpart-base';

export default class StatusBadgeWebPart extends BaseClientSideWebPart<{}> {
  public render(): void {
    this.domElement.innerHTML = '<div>StatusBadge</div>';
    // TODO: React-Komponente einbinden
  }
}
