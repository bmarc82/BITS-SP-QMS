import { SPFI } from '@pnp/sp';
import '@pnp/sp/webs';
import '@pnp/sp/lists';
import '@pnp/sp/items';

export interface IReviewDocument {
  ID: number;
  FileLeafRef: string;
  QMSStatus: string;
  QMSVersion: string;
  QMSGueltigAb: string | null;
  QMSNaechstesPruefDatum: string | null;
  QMSProzessverantwortlicher: { Title: string; EMail: string } | null;
  QMSProzessart: string;
  QMSBereich: string;
  QMSISOKapitel: string;
  ServerRedirectedEmbedUri: string;
}

export type ReviewUrgency = 'overdue' | 'soon' | 'ok';

export interface IReviewDocumentWithUrgency extends IReviewDocument {
  urgency:         ReviewUrgency;
  daysUntilReview: number;
}

export class ReviewService {
  private readonly sp: SPFI;
  private readonly listName = 'QMS-Dokumente';

  constructor(sp: SPFI) {
    this.sp = sp;
  }

  /** Alle freigegebenen Dokumente mit Prüfdatum in den nächsten 90 Tagen oder überfällig */
  public async getDocumentsDueForReview(daysAhead = 90): Promise<IReviewDocumentWithUrgency[]> {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() + daysAhead);

    const raw = await this.sp.web.lists.getByTitle(this.listName).items
      .select(
        'ID', 'FileLeafRef', 'QMSStatus', 'QMSVersion',
        'QMSGueltigAb', 'QMSNaechstesPruefDatum', 'QMSISOKapitel',
        'QMSProzessart', 'QMSBereich', 'ServerRedirectedEmbedUri',
        'QMSProzessverantwortlicher/Title', 'QMSProzessverantwortlicher/EMail'
      )
      .expand('QMSProzessverantwortlicher')
      .filter(`QMSStatus eq 'Freigegeben' and QMSNaechstesPruefDatum ne null`)
      .orderBy('QMSNaechstesPruefDatum')
      .top(200)();

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    return raw
      .map(doc => {
        const reviewDate = doc.QMSNaechstesPruefDatum
          ? new Date(doc.QMSNaechstesPruefDatum)
          : null;
        const daysUntilReview = reviewDate
          ? Math.ceil((reviewDate.getTime() - today.getTime()) / 86_400_000)
          : 9999;

        const urgency: ReviewUrgency =
          daysUntilReview < 0  ? 'overdue' :
          daysUntilReview <= 30 ? 'soon'    :
          'ok';

        return { ...doc, urgency, daysUntilReview } as IReviewDocumentWithUrgency;
      })
      .filter(d => d.daysUntilReview <= daysAhead);
  }
}
