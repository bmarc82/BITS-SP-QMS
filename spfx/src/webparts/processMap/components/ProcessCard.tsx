import * as React from 'react';
import { IProcess } from '../services/ProcessService';
import styles from './ProcessMap.module.scss';

interface IProcessCardProps {
  process: IProcess;
  siteUrl: string;
}

const statusColor: Record<string, string> = {
  'Freigegeben':  '#107c10',
  'In Überarbeitung': '#f7630c',
  'Entwurf':      '#605e5c',
  'Archiviert':   '#a19f9d',
};

export const ProcessCard: React.FC<IProcessCardProps> = ({ process, siteUrl }) => {
  const color = statusColor[process.QMSStatus] ?? '#605e5c';
  const docUrl = process.FileRef ? `${siteUrl}${process.FileRef}` : '#';

  return (
    <a
      href={docUrl}
      target="_blank"
      rel="noreferrer"
      className={styles.processCard}
      title={process.QMSProzessbeschreibung ?? process.Title}
      aria-label={process.Title}
    >
      <div className={styles.cardStatusBar} style={{ backgroundColor: color }} />
      <div className={styles.cardContent}>
        {process.QMSISOKapitel && (
          <span className={styles.isoKapitel}>{process.QMSISOKapitel}</span>
        )}
        <span className={styles.processTitle}>{process.Title}</span>
        {process.QMSBereich && (
          <span className={styles.bereich}>{process.QMSBereich}</span>
        )}
        {process.QMSProzessverantwortlicher && (
          <span className={styles.verantwortlicher}>
            {process.QMSProzessverantwortlicher.Title}
          </span>
        )}
        <span className={styles.status} style={{ color }}>{process.QMSStatus}</span>
      </div>
    </a>
  );
};
