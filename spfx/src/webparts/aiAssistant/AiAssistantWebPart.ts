import { Version } from '@microsoft/sp-core-library';
import {
  IPropertyPaneConfiguration,
  PropertyPaneTextField
} from '@microsoft/sp-property-pane';
import { BaseClientSideWebPart } from '@microsoft/sp-webpart-base';
import * as React from 'react';
import * as ReactDOM from 'react-dom';
import { CopilotService } from './services/CopilotService';
import { AiAssistant } from './components/AiAssistant';

export interface IAiAssistantWebPartProperties {
  feedbackFlowUrl: string;
}

export default class AiAssistantWebPart
  extends BaseClientSideWebPart<IAiAssistantWebPartProperties> {

  private copilotService!: CopilotService;

  public onInit(): Promise<void> {
    const userId = this.context.pageContext.user.email ?? '';
    this.copilotService = new CopilotService(
      this.properties.feedbackFlowUrl ?? '',
      userId
    );
    return super.onInit();
  }

  public render(): void {
    const userGroups: string[] = (
      (this.context.pageContext as unknown as { user?: { groups?: string[] } })
        .user?.groups ?? []
    );
    const element = React.createElement(AiAssistant, {
      copilotService: this.copilotService,
      userGroups,
      userInitials:   this.getUserInitials(),
      userId:         this.context.pageContext.user.email ?? '',
    });
    ReactDOM.render(element, this.domElement);
  }

  private getUserInitials(): string {
    const name = this.context.pageContext.user.displayName ?? '';
    const parts = name.trim().split(' ');
    if (parts.length >= 2) return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    return name.slice(0, 2).toUpperCase();
  }

  protected onDispose(): void { ReactDOM.unmountComponentAtNode(this.domElement); }
  protected get dataVersion(): Version { return Version.parse('1.0'); }

  protected getPropertyPaneConfiguration(): IPropertyPaneConfiguration {
    return {
      pages: [{
        header: { description: 'KI-Assistent Einstellungen' },
        groups: [{
          groupName: 'Konfiguration',
          groupFields: [
            PropertyPaneTextField('feedbackFlowUrl', {
              label:       'Feedback Flow URL',
              description: 'URL des Power Automate Flows zum Speichern von KI-Feedback',
              placeholder: 'https://prod-xx.westeurope.logic.azure.com/...',
              value:       this.properties.feedbackFlowUrl ?? '',
            }),
          ],
        }],
      }],
    };
  }
}
