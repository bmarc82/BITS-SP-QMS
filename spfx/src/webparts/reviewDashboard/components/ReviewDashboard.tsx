import * as React from 'react';
import {
  Spinner, SpinnerSize, MessageBar, MessageBarType,
  Dropdown, IDropdownOption, SearchBox
} from '@fluentui/react';
import {
  ReviewService,
  IReviewDocumentWithUrgency,
  ReviewUrgency
} from '../services/ReviewService';
import styles from './ReviewDashboard.module.scss';

interface IReviewDashboardProps {
  reviewService: ReviewService;
  title: string;
  daysAhead: number;
}

interface IReviewDashboardState {
  documents:     IReviewDocumentWithUrgency[];
  filtered:      IReviewDocumentWithUrgency[];
  isLoading:     boolean;
  error:         string | null;
  filterUrgency: string;
  searchText:    string;
}

const URGENCY_FILTER_OPTIONS: IDropdownOption[] = [
  { key: 'all',     text: 'Alle anzeigen' },
  { key: 'overdue', text: 'Überfällig' },
  { key: 'soon',    text: 'Fällig in 30 Tagen' },
  { key: 'ok',      text: 'OK (>30 Tage)' },
];

function formatDate(iso: string | null): string {
  if (!iso) return '–';
  return new Date(iso).toLocaleDateString('de-CH', {
    day: '2-digit', month: '2-digit', year: 'numeric'
  });
}

function dayLabel(days: number): string {
  if (days < 0)  return `${Math.abs(days)} Tage überfällig`;
  if (days === 0) return 'Heute fällig';
  return `in ${days} Tagen`;
}

export class ReviewDashboard extends React.Component<IReviewDashboardProps, IReviewDashboardState> {

  constructor(props: IReviewDashboardProps) {
    super(props);
    this.state = {
      documents:     [],
      filtered:      [],
      isLoading:     true,
      error:         null,
      filterUrgency: 'all',
      searchText:    '',
    };
  }

  public async componentDidMount(): Promise<void> {
    try {
      const documents = await this.props.reviewService.getDocumentsDueForReview(
        this.props.daysAhead
      );
      this.setState({ documents, filtered: documents, isLoading: false });
    } catch (e) {
      this.setState({
        error:     `Fehler beim Laden: ${(e as Error).message}`,
        isLoading: false,
      });
    }
  }

  private applyFilters(
    documents: IReviewDocumentWithUrgency[],
    urgency: string,
    search: string
  ): IReviewDocumentWithUrgency[] {
    return documents.filter(doc => {
      const matchUrgency = urgency === 'all' || doc.urgency === urgency;
      const matchSearch  = !search ||
        doc.FileLeafRef.toLowerCase().includes(search.toLowerCase()) ||
        (doc.QMSBereich ?? '').toLowerCase().includes(search.toLowerCase()) ||
        (doc.QMSProzessverantwortlicher?.Title ?? '').toLowerCase().includes(search.toLowerCase());
      return matchUrgency && matchSearch;
    });
  }

  private onFilterChange = (urgency: string): void => {
    this.setState(prev => ({
      filterUrgency: urgency,
      filtered: this.applyFilters(prev.documents, urgency, prev.searchText),
    }));
  };

  private onSearchChange = (search: string): void => {
    this.setState(prev => ({
      searchText: search,
      filtered: this.applyFilters(prev.documents, prev.filterUrgency, search),
    }));
  };

  public render(): React.ReactElement {
    const { filtered, documents, isLoading, error, filterUrgency } = this.state;

    if (isLoading) {
      return (
        <div className={styles.dashboardRoot}>
          <div className={styles.loading}>
            <Spinner size={SpinnerSize.large} label="Dokumente werden geladen..." />
          </div>
        </div>
      );
    }

    if (error) {
      return (
        <div className={styles.dashboardRoot}>
          <MessageBar messageBarType={MessageBarType.error}>{error}</MessageBar>
        </div>
      );
    }

    const counts = {
      overdue: documents.filter(d => d.urgency === 'overdue').length,
      soon:    documents.filter(d => d.urgency === 'soon').length,
      ok:      documents.filter(d => d.urgency === 'ok').length,
    };

    return (
      <div className={styles.dashboardRoot}>

        <div className={styles.header}>
          <h2>{this.props.title}</h2>
        </div>

        {/* Summary Badges */}
        <div className={styles.summaryBadges}>
          {(['overdue', 'soon', 'ok'] as ReviewUrgency[]).map(u => (
            <div
              key={u}
              className={`${styles.badge} ${styles[u]}`}
              style={{ cursor: 'pointer' }}
              onClick={() => this.onFilterChange(filterUrgency === u ? 'all' : u)}
              role="button"
              tabIndex={0}
            >
              <span className={styles.badgeCount}>{counts[u]}</span>
              <span className={styles.badgeLabel}>
                {u === 'overdue' ? 'Überfällig' : u === 'soon' ? 'Fällig ≤30 Tage' : 'OK'}
              </span>
            </div>
          ))}
        </div>

        {/* Filter bar */}
        <div className={styles.filterBar}>
          <Dropdown
            options={URGENCY_FILTER_OPTIONS}
            selectedKey={filterUrgency}
            onChange={(_, o) => this.onFilterChange(o?.key as string ?? 'all')}
            styles={{ root: { minWidth: 180 } }}
          />
          <SearchBox
            placeholder="Dokument, Bereich oder Verantwortliche/r suchen..."
            onChange={(_, v) => this.onSearchChange(v ?? '')}
            styles={{ root: { minWidth: 280 } }}
          />
        </div>

        {/* Table */}
        {filtered.length === 0 ? (
          <div className={styles.empty}>Keine Dokumente gefunden.</div>
        ) : (
          <table className={styles.table}>
            <thead>
              <tr className={styles.tableHeader}>
                <th></th>
                <th>Dokument</th>
                <th>Version</th>
                <th>Bereich</th>
                <th>ISO-Kapitel</th>
                <th>Verantwortliche/r</th>
                <th>Gültig ab</th>
                <th>Nächste Prüfung</th>
                <th>Fälligkeit</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map(doc => (
                <tr key={doc.ID} className={styles.tableRow}>
                  <td>
                    <span
                      className={`${styles.urgencyDot} ${styles[doc.urgency]}`}
                      title={dayLabel(doc.daysUntilReview)}
                    />
                  </td>
                  <td>
                    <a
                      href={doc.ServerRedirectedEmbedUri ?? '#'}
                      target="_blank"
                      rel="noreferrer"
                      className={styles.docLink}
                    >
                      {doc.FileLeafRef}
                    </a>
                  </td>
                  <td>{doc.QMSVersion ?? '–'}</td>
                  <td>{doc.QMSBereich ?? '–'}</td>
                  <td>{doc.QMSISOKapitel ?? '–'}</td>
                  <td>{doc.QMSProzessverantwortlicher?.Title ?? '–'}</td>
                  <td>{formatDate(doc.QMSGueltigAb)}</td>
                  <td>{formatDate(doc.QMSNaechstesPruefDatum)}</td>
                  <td>
                    <span className={`${styles.daysBadge} ${styles[doc.urgency]}`}>
                      {dayLabel(doc.daysUntilReview)}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    );
  }
}
