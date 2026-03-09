import { Version } from '@microsoft/sp-core-library';
import {
  IPropertyPaneConfiguration,
  PropertyPaneTextField
} from '@microsoft/sp-property-pane';
import { BaseClientSideWebPart } from '@microsoft/sp-webpart-base';
import { spfi, SPFx } from '@pnp/sp';
import * as React from 'react';
import * as ReactDOM from 'react-dom';
import { ProcessService } from './services/ProcessService';
import { ProcessMap } from './components/ProcessMap';

export interface IProcessMapWebPartProperties {
  title: string;
}

export default class ProcessMapWebPart
  extends BaseClientSideWebPart<IProcessMapWebPartProperties> {

  private processService!: ProcessService;

  public onInit(): Promise<void> {
    const sp = spfi().using(SPFx(this.context));
    this.processService = new ProcessService(sp);
    return super.onInit();
  }

  public render(): void {
    const element = React.createElement(ProcessMap, {
      processService: this.processService,
      siteUrl:        this.context.pageContext.web.absoluteUrl,
      title:          this.properties.title ?? 'Prozesslandkarte',
    });
    ReactDOM.render(element, this.domElement);
  }

  protected onDispose(): void {
    ReactDOM.unmountComponentAtNode(this.domElement);
  }

  protected get dataVersion(): Version {
    return Version.parse('1.0');
  }

  protected getPropertyPaneConfiguration(): IPropertyPaneConfiguration {
    return {
      pages: [{
        header: { description: 'Einstellungen' },
        groups: [{
          groupName: 'Anzeige',
          groupFields: [
            PropertyPaneTextField('title', {
              label:       'Titel',
              value:       this.properties.title ?? 'Prozesslandkarte',
              placeholder: 'Prozesslandkarte',
            }),
          ],
        }],
      }],
    };
  }
}
