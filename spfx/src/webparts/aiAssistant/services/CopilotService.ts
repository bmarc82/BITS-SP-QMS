export type AgentId =
  | 'document-assistant'
  | 'review-advisor'
  | 'audit-prep-agent'
  | 'process-optimizer';

export interface IAgentConfig {
  id:          AgentId;
  displayName: string;
  description: string;
  icon:        string;
  botFrameworkUrl: string;
  allowedGroups: string[];
}

export interface IChatMessage {
  id:        string;
  role:      'user' | 'assistant' | 'system';
  content:   string;
  timestamp: Date;
  citations?: ICitation[];
  feedback?:  'positive' | 'negative' | null;
}

export interface ICitation {
  title:     string;
  url:       string;
  snippet:   string;
  relevance: number;
}

export interface IFeedbackPayload {
  agentId:   AgentId;
  messageId: string;
  feedback:  'positive' | 'negative';
  comment?:  string;
  userId:    string;
  timestamp: string;
}

export const AGENT_CONFIGS: IAgentConfig[] = [
  {
    id:              'document-assistant',
    displayName:     'Dokumenten-Assistent',
    description:     'Hilft beim Erstellen strukturierter ISO 9001:2015-Prozessdokumente',
    icon:            '📋',
    botFrameworkUrl: '{BOT_URL_DOCUMENT_ASSISTANT}',
    allowedGroups:   ['QMS-Ersteller', 'QMS-Prozessverantwortliche', 'QMS-Freigeber', 'QMS-Administratoren'],
  },
  {
    id:              'review-advisor',
    displayName:     'Review-Berater',
    description:     'Analysiert Dokumente vor dem Review auf Vollständigkeit und Normkonformität',
    icon:            '🔍',
    botFrameworkUrl: '{BOT_URL_REVIEW_ADVISOR}',
    allowedGroups:   ['QMS-Prozessverantwortliche', 'QMS-Freigeber', 'QMS-Administratoren'],
  },
  {
    id:              'audit-prep-agent',
    displayName:     'Audit-Vorbereitung',
    description:     'ISO-Kapitel-Mapping, Nachweislisten und Audit-Fragenkataloge',
    icon:            '✅',
    botFrameworkUrl: '{BOT_URL_AUDIT_PREP}',
    allowedGroups:   ['QMS-Freigeber', 'QMS-Administratoren'],
  },
  {
    id:              'process-optimizer',
    displayName:     'Prozess-Optimierer',
    description:     'PDCA-Analyse, KVP-Vorschläge und Prozessverbesserungen',
    icon:            '⚡',
    botFrameworkUrl: '{BOT_URL_PROCESS_OPTIMIZER}',
    allowedGroups:   ['QMS-Prozessverantwortliche', 'QMS-Freigeber', 'QMS-Administratoren'],
  },
];

export class CopilotService {
  private readonly feedbackFlowUrl: string;
  private readonly userId: string;

  constructor(feedbackFlowUrl: string, userId: string) {
    this.feedbackFlowUrl = feedbackFlowUrl;
    this.userId = userId;
  }

  public getAvailableAgents(userGroups: string[]): IAgentConfig[] {
    return AGENT_CONFIGS.filter(agent =>
      agent.allowedGroups.some(g => userGroups.includes(g))
    );
  }

  public generateMessageId(): string {
    return `msg_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
  }

  public async submitFeedback(payload: IFeedbackPayload): Promise<void> {
    if (!this.feedbackFlowUrl || this.feedbackFlowUrl.startsWith('{')) return;
    await fetch(this.feedbackFlowUrl, {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body:    JSON.stringify({ ...payload, userId: this.userId }),
    });
  }
}
