import * as React from 'react';
import { Spinner, SpinnerSize, MessageBar, MessageBarType } from '@fluentui/react';
import { ProcessService, IProcess, IProcessGroups } from '../services/ProcessService';
import { ProcessCard } from './ProcessCard';
import styles from './ProcessMap.module.scss';

interface IProcessMapProps {
  processService: ProcessService;
  siteUrl: string;
  title: string;
}

interface IProcessMapState {
  groups: IProcessGroups | null;
  isLoading: boolean;
  error: string | null;
}

type ProzessartConfig = {
  key:       keyof IProcessGroups;
  label:     string;
  iconClass: string;
};

const PROZESSART_ORDER: ProzessartConfig[] = [
  { key: 'Führungsprozess', label: 'Führungsprozesse',  iconClass: 'fuehrung' },
  { key: 'Kernprozess',     label: 'Kernprozesse',       iconClass: 'kern'     },
  { key: 'Supportprozess',  label: 'Supportprozesse',    iconClass: 'support'  },
];

export class ProcessMap extends React.Component<IProcessMapProps, IProcessMapState> {

  constructor(props: IProcessMapProps) {
    super(props);
    this.state = { groups: null, isLoading: true, error: null };
  }

  public async componentDidMount(): Promise<void> {
    try {
      const processes = await this.props.processService.getAllProcesses();
      const groups = this.props.processService.groupByProzessart(processes);
      this.setState({ groups, isLoading: false });
    } catch (e) {
      this.setState({
        error: `Fehler beim Laden der Prozesse: ${(e as Error).message}`,
        isLoading: false,
      });
    }
  }

  public render(): React.ReactElement {
    const { groups, isLoading, error } = this.state;

    if (isLoading) {
      return (
        <div className={styles.processMapRoot}>
          <div className={styles.loading}>
            <Spinner size={SpinnerSize.large} label="Prozesse werden geladen..." />
          </div>
        </div>
      );
    }

    if (error) {
      return (
        <div className={styles.processMapRoot}>
          <MessageBar messageBarType={MessageBarType.error}>{error}</MessageBar>
        </div>
      );
    }

    const totalCount = groups
      ? PROZESSART_ORDER.reduce((sum, c) => sum + groups[c.key].length, 0)
      : 0;

    return (
      <div className={styles.processMapRoot}>
        <div className={styles.title}>
          {this.props.title} ({totalCount} Prozesse)
        </div>

        {PROZESSART_ORDER.map(({ key, label, iconClass }) => {
          const procs: IProcess[] = groups?.[key] ?? [];
          if (procs.length === 0) return null;
          return (
            <section key={key} className={styles.prozessartSection}>
              <div className={styles.prozessartHeader}>
                <div className={`${styles.prozessartIcon} ${styles[iconClass]}`} />
                <h3>{label}</h3>
                <span className={styles.count}>{procs.length}</span>
              </div>
              <div className={styles.cardGrid}>
                {procs.map(p => (
                  <ProcessCard key={p.ID} process={p} siteUrl={this.props.siteUrl} />
                ))}
              </div>
            </section>
          );
        })}

        {totalCount === 0 && (
          <div className={styles.empty}>Keine Prozesse gefunden.</div>
        )}
      </div>
    );
  }
}
