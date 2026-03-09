import { BaseClientSideWebPart } from '@microsoft/sp-webpart-base';

export default class AiAssistantWebPart extends BaseClientSideWebPart<{}> {
  public render(): void {
    this.domElement.innerHTML = '<div>AiAssistant</div>';
    // TODO: React-Komponente einbinden
  }
}
