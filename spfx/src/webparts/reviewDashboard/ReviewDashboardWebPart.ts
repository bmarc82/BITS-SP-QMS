import { BaseClientSideWebPart } from '@microsoft/sp-webpart-base';

export default class ReviewDashboardWebPart extends BaseClientSideWebPart<{}> {
  public render(): void {
    this.domElement.innerHTML = '<div>ReviewDashboard</div>';
    // TODO: React-Komponente einbinden
  }
}
