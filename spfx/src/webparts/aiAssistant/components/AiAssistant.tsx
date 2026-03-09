import * as React from 'react';
import { Spinner, SpinnerSize } from '@fluentui/react';
import {
  CopilotService,
  IAgentConfig,
  IChatMessage,
  AgentId,
  AGENT_CONFIGS
} from '../services/CopilotService';
import styles from './AiAssistant.module.scss';

interface IAiAssistantProps {
  copilotService: CopilotService;
  userGroups:     string[];
  userInitials:   string;
  userId:         string;
}

interface IAiAssistantState {
  activeAgent:    IAgentConfig | null;
  messages:       IChatMessage[];
  inputText:      string;
  isTyping:       boolean;
  availableAgents: IAgentConfig[];
}

export class AiAssistant extends React.Component<IAiAssistantProps, IAiAssistantState> {
  private chatEndRef = React.createRef<HTMLDivElement>();
  private inputRef   = React.createRef<HTMLTextAreaElement>();

  constructor(props: IAiAssistantProps) {
    super(props);
    const availableAgents = props.copilotService.getAvailableAgents(props.userGroups);
    this.state = {
      activeAgent:     availableAgents[0] ?? null,
      messages:        [],
      inputText:       '',
      isTyping:        false,
      availableAgents,
    };
  }

  private scrollToBottom(): void {
    this.chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }

  public componentDidUpdate(): void {
    this.scrollToBottom();
  }

  private handleAgentSwitch = (agent: IAgentConfig): void => {
    this.setState({
      activeAgent: agent,
      messages:    [],
      inputText:   '',
      isTyping:    false,
    });
  };

  private handleInputKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>): void => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      this.handleSend();
    }
  };

  private handleSend = async (): Promise<void> => {
    const { inputText, activeAgent, messages } = this.state;
    if (!inputText.trim() || !activeAgent || this.state.isTyping) return;

    const userMsg: IChatMessage = {
      id:        this.props.copilotService.generateMessageId(),
      role:      'user',
      content:   inputText.trim(),
      timestamp: new Date(),
    };

    this.setState({
      messages:  [...messages, userMsg],
      inputText: '',
      isTyping:  true,
    });

    try {
      // In Produktion: Bot Framework Direct Line API aufrufen
      // Hier: Simulation für Entwicklung / Demo
      const response = await this.simulateAgentResponse(activeAgent, inputText.trim());
      const assistantMsg: IChatMessage = {
        id:        this.props.copilotService.generateMessageId(),
        role:      'assistant',
        content:   response.content,
        timestamp: new Date(),
        citations: response.citations,
        feedback:  null,
      };
      this.setState(prev => ({
        messages: [...prev.messages, assistantMsg],
        isTyping: false,
      }));
    } catch {
      const errorMsg: IChatMessage = {
        id:        this.props.copilotService.generateMessageId(),
        role:      'assistant',
        content:   'Es ist ein Fehler aufgetreten. Bitte versuchen Sie es erneut.',
        timestamp: new Date(),
      };
      this.setState(prev => ({
        messages: [...prev.messages, errorMsg],
        isTyping: false,
      }));
    }
  };

  /** Platzhalter für Bot Framework Direct Line Integration */
  private async simulateAgentResponse(
    agent: IAgentConfig,
    _input: string
  ): Promise<{ content: string; citations?: IChatMessage['citations'] }> {
    await new Promise(r => setTimeout(r, 1200));

    const responses: Record<AgentId, string> = {
      'document-assistant': `Ich helfe Ihnen gerne beim Erstellen eines strukturierten QMS-Dokuments.\n\nBitte beschreiben Sie den Prozess in eigenen Worten:\n- Was ist der Zweck des Prozesses?\n- Welche Schritte gibt es?\n- Wer ist beteiligt?\n\n*Hinweis: In der Produktion verbindet sich dieser Assistent mit dem Microsoft Copilot Studio Bot via Direct Line API.*`,
      'review-advisor':     `Ich analysiere das angegebene Dokument auf:\n\n✅ Vollständigkeit (Pflichtabschnitte)\n✅ ISO 9001:2015-Konformität\n✅ Konsistenz mit dem QMS\n✅ Aktualität\n\nBitte nennen Sie den Dokumentnamen oder fügen Sie den Link ein.\n\n*Hinweis: In der Produktion verbindet sich dieser Assistent mit dem Microsoft Copilot Studio Bot via Direct Line API.*`,
      'audit-prep-agent':   `Ich bereite Ihre Audit-Unterlagen strukturiert vor.\n\nIch kann:\n• Kapitelabdeckungsmatrix erstellen (alle ISO 9001:2015 Kapitel)\n• Fehlende Nachweise identifizieren\n• Audit-Fragenkatalog generieren\n\nFür welchen Auditscope soll ich starten?\n\n*Hinweis: In der Produktion verbindet sich dieser Assistent mit dem Microsoft Copilot Studio Bot via Direct Line API.*`,
      'process-optimizer':  `Ich analysiere Prozesse anhand des PDCA-Zyklus und erstelle Verbesserungsvorschläge.\n\nBitte teilen Sie mit:\n• Welcher Prozess soll analysiert werden?\n• Welche KPIs oder Probleme liegen vor?\n\n*Hinweis: In der Produktion verbindet sich dieser Assistent mit dem Microsoft Copilot Studio Bot via Direct Line API.*`,
    };

    return {
      content: responses[agent.id] ?? 'Wie kann ich Ihnen helfen?',
    };
  }

  private handleFeedback = async (msgId: string, feedback: 'positive' | 'negative'): Promise<void> => {
    this.setState(prev => ({
      messages: prev.messages.map(m =>
        m.id === msgId ? { ...m, feedback } : m
      ),
    }));
    const msg = this.state.messages.find(m => m.id === msgId);
    if (!msg || !this.state.activeAgent) return;
    await this.props.copilotService.submitFeedback({
      agentId:   this.state.activeAgent.id,
      messageId: msgId,
      feedback,
      userId:    this.props.userId,
      timestamp: new Date().toISOString(),
    });
  };

  private formatTime(date: Date): string {
    return date.toLocaleTimeString('de-CH', { hour: '2-digit', minute: '2-digit' });
  }

  public render(): React.ReactElement {
    const { activeAgent, messages, inputText, isTyping, availableAgents } = this.state;
    const { userInitials } = this.props;

    if (availableAgents.length === 0) {
      return (
        <div className={styles.assistantRoot}>
          <div className={styles.welcomeBox}>
            <div className={styles.welcomeIcon}>🔒</div>
            <h3>Kein Zugriff</h3>
            <p>Sie haben keine Berechtigung für die QMS KI-Agenten.<br />
               Wenden Sie sich an den QMS-Administrator.</p>
          </div>
        </div>
      );
    }

    return (
      <div className={styles.assistantRoot}>

        {/* Agent selector */}
        <div className={styles.agentBar}>
          {availableAgents.map(agent => (
            <button
              key={agent.id}
              className={`${styles.agentBtn} ${activeAgent?.id === agent.id ? styles.active : ''}`}
              onClick={() => this.handleAgentSwitch(agent)}
              title={agent.description}
            >
              <span className={styles.agentIcon}>{agent.icon}</span>
              {agent.displayName}
            </button>
          ))}
        </div>

        {/* Chat area */}
        <div className={styles.chatArea}>

          {messages.length === 0 && activeAgent && (
            <div className={styles.welcomeBox}>
              <div className={styles.welcomeIcon}>{activeAgent.icon}</div>
              <h3>{activeAgent.displayName}</h3>
              <p>{activeAgent.description}</p>
            </div>
          )}

          {messages.map(msg => (
            <div key={msg.id} className={`${styles.message} ${styles[msg.role]}`}>
              <div className={`${styles.avatar} ${styles[msg.role]}`}>
                {msg.role === 'user' ? userInitials : activeAgent?.icon ?? '🤖'}
              </div>
              <div>
                <div className={styles.bubble}>
                  {msg.content.split('\n').map((line, i) => (
                    <React.Fragment key={i}>{line}{i < msg.content.split('\n').length - 1 && <br />}</React.Fragment>
                  ))}
                </div>
                {msg.citations && msg.citations.length > 0 && (
                  <div className={styles.citations}>
                    <h4>Quellen</h4>
                    {msg.citations.map((c, i) => (
                      <a key={i} href={c.url} target="_blank" rel="noreferrer">
                        📄 {c.title}
                      </a>
                    ))}
                  </div>
                )}
                {msg.role === 'assistant' && (
                  <div className={styles.bubbleMeta}>
                    <span>{this.formatTime(msg.timestamp)}</span>
                    <div className={styles.feedbackBtns}>
                      <button
                        className={msg.feedback === 'positive' ? styles.active : ''}
                        onClick={() => this.handleFeedback(msg.id, 'positive')}
                        title="Hilfreich"
                      >👍</button>
                      <button
                        className={msg.feedback === 'negative' ? styles.active : ''}
                        onClick={() => this.handleFeedback(msg.id, 'negative')}
                        title="Nicht hilfreich"
                      >👎</button>
                    </div>
                  </div>
                )}
              </div>
            </div>
          ))}

          {isTyping && (
            <div className={`${styles.message} ${styles.assistant}`}>
              <div className={`${styles.avatar} ${styles.assistant}`}>
                {activeAgent?.icon ?? '🤖'}
              </div>
              <div className={styles.typingIndicator}>
                <span /><span /><span />
              </div>
            </div>
          )}

          <div ref={this.chatEndRef} />
        </div>

        {/* Input area */}
        <div className={styles.inputArea}>
          <textarea
            ref={this.inputRef}
            className={styles.inputField}
            value={inputText}
            onChange={e => this.setState({ inputText: e.target.value })}
            onKeyDown={this.handleInputKeyDown}
            placeholder={`Nachricht an ${activeAgent?.displayName ?? 'Assistent'}... (Enter zum Senden, Shift+Enter für neue Zeile)`}
            disabled={isTyping}
            rows={1}
          />
          <button
            className={styles.sendBtn}
            onClick={this.handleSend}
            disabled={!inputText.trim() || isTyping}
            title="Senden"
          >
            {isTyping ? <Spinner size={SpinnerSize.small} /> : '➤'}
          </button>
        </div>

        <div className={styles.disclaimer}>
          KI-Ausgaben sind Vorschläge und ersetzen keine fachliche Überprüfung.
          Nur freigegebene QMS-Dokumente werden als Wissensquelle verwendet.
        </div>
      </div>
    );
  }
}
