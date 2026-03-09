import { SPFI } from '@pnp/sp';
import '@pnp/sp/webs';
import '@pnp/sp/lists';
import '@pnp/sp/items';

export interface IProcess {
  ID: number;
  Title: string;
  QMSProzessart: string;
  QMSBereich: string;
  QMSISOKapitel: string;
  QMSStatus: string;
  QMSProzessverantwortlicher: { Title: string; EMail: string } | null;
  QMSProzessbeschreibung: string;
  FileRef?: string;
}

export type ProzessartGroup = 'Führungsprozess' | 'Kernprozess' | 'Supportprozess';

export interface IProcessGroups {
  Führungsprozess: IProcess[];
  Kernprozess:     IProcess[];
  Supportprozess:  IProcess[];
}

export class ProcessService {
  private readonly sp: SPFI;
  private readonly listName = 'QMS-Prozesse';

  constructor(sp: SPFI) {
    this.sp = sp;
  }

  public async getAllProcesses(): Promise<IProcess[]> {
    return this.sp.web.lists.getByTitle(this.listName).items
      .select(
        'ID', 'Title', 'QMSISOKapitel', 'QMSStatus', 'QMSProzessbeschreibung',
        'QMSProzessart', 'QMSBereich',
        'QMSProzessverantwortlicher/Title', 'QMSProzessverantwortlicher/EMail'
      )
      .expand('QMSProzessverantwortlicher')
      .filter("QMSStatus ne 'Archiviert'")
      .orderBy('QMSProzessart')
      .orderBy('Title')
      .top(500)();
  }

  public groupByProzessart(processes: IProcess[]): IProcessGroups {
    const groups: IProcessGroups = {
      Führungsprozess: [],
      Kernprozess:     [],
      Supportprozess:  [],
    };
    for (const p of processes) {
      const art = p.QMSProzessart as ProzessartGroup;
      if (groups[art] !== undefined) {
        groups[art].push(p);
      } else {
        groups.Kernprozess.push(p); // Fallback
      }
    }
    return groups;
  }
}
