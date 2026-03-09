import { Version } from '@microsoft/sp-core-library';
import {
  IPropertyPaneConfiguration,
  PropertyPaneTextField,
  PropertyPaneSlider
} from '@microsoft/sp-property-pane';
import { BaseClientSideWebPart } from '@microsoft/sp-webpart-base';
import { spfi, SPFx } from '@pnp/sp';
import * as React from 'react';
import * as ReactDOM from 'react-dom';
import { ReviewService } from './services/ReviewService';
import { ReviewDashboard } from './components/ReviewDashboard';

export interface IReviewDashboardWebPartProperties {
  title:     string;
  daysAhead: number;
}

export default class ReviewDashboardWebPart
  extends BaseClientSideWebPart<IReviewDashboardWebPartProperties> {

  private reviewService!: ReviewService;

  public onInit(): Promise<void> {
    const sp = spfi().using(SPFx(this.context));
    this.reviewService = new ReviewService(sp);
    return super.onInit();
  }

  public render(): void {
    const element = React.createElement(ReviewDashboard, {
      reviewService: this.reviewService,
      title:         this.properties.title ?? 'Überprüfungs-Dashboard',
      daysAhead:     this.properties.daysAhead ?? 90,
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
              value:       this.properties.title ?? 'Überprüfungs-Dashboard',
              placeholder: 'Überprüfungs-Dashboard',
            }),
            PropertyPaneSlider('daysAhead', {
              label:   'Vorschau-Zeitraum (Tage)',
              min:     14,
              max:     180,
              step:    7,
              value:   this.properties.daysAhead ?? 90,
              showValue: true,
            }),
          ],
        }],
      }],
    };
  }
}
