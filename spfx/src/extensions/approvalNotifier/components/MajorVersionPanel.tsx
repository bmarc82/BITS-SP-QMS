import * as React from 'react';
import {
  Panel, PanelType, PrimaryButton, DefaultButton,
  TextField, Dropdown, IDropdownOption, Spinner, SpinnerSize,
  MessageBar, MessageBarType, Stack, Text, Label
} from '@fluentui/react';

export interface IMajorVersionPanelProps {
  isOpen: boolean;
  dokumentname: string;
  freigeberEmail: string;
  onDismiss: () => void;
  onSubmit: (version: string, aenderungsart: string, beschreibung: string) => Promise<void>;
}

const aenderungsartOptions: IDropdownOption[] = [
  { key: 'Inhaltliche Änderung',  text: 'Inhaltliche Änderung' },
  { key: 'Prozessänderung',       text: 'Prozessänderung' },
  { key: 'Reorganisation',        text: 'Reorganisation' },
  { key: 'Normative Anpassung',   text: 'Normative Anpassung (ISO-Update)' },
];

export const MajorVersionPanel: React.FC<IMajorVersionPanelProps> = (props) => {
  const [version, setVersion]             = React.useState('');
  const [aenderungsart, setAenderungsart] = React.useState('');
  const [beschreibung, setBeschreibung]   = React.useState('');
  const [isSubmitting, setIsSubmitting]   = React.useState(false);
  const [error, setError]                 = React.useState('');
  const [success, setSuccess]             = React.useState(false);

  React.useEffect(() => {
    if (props.isOpen) {
      setVersion('');
      setAenderungsart('');
      setBeschreibung('');
      setError('');
      setSuccess(false);
    }
  }, [props.isOpen]);

  const versionValid = /^\d+\.0$/.test(version);

  const handleSubmit = async (): Promise<void> => {
    if (!versionValid || !aenderungsart || beschreibung.length < 20) return;
    setIsSubmitting(true);
    setError('');
    try {
      await props.onSubmit(version, aenderungsart, beschreibung);
      setSuccess(true);
    } catch (e) {
      setError((e as Error).message ?? 'Unbekannter Fehler');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Panel
      isOpen={props.isOpen}
      onDismiss={props.onDismiss}
      type={PanelType.medium}
      headerText="Hauptversion zur Freigabe einreichen"
      closeButtonAriaLabel="Schliessen"
    >
      <Stack tokens={{ childrenGap: 16 }} styles={{ root: { padding: '16px 0' } }}>

        <Text variant="mediumPlus" styles={{ root: { fontWeight: 600 } }}>
          {props.dokumentname}
        </Text>

        <MessageBar messageBarType={MessageBarType.warning} isMultiline>
          Hauptversionen (x.0) erfordern eine Genehmigung durch den Prozessverantwortlichen.
          Das Dokument wird auf «In Prüfung» gesetzt und ist erst nach Freigabe für alle Leser sichtbar.
        </MessageBar>

        {success ? (
          <MessageBar messageBarType={MessageBarType.success}>
            Dokument zur Freigabe eingereicht. Der Freigeber wird per Teams benachrichtigt.
          </MessageBar>
        ) : (
          <>
            <TextField
              label="Neue Versionsnummer *"
              placeholder="z.B. 1.0 / 2.0 / 3.0"
              value={version}
              onChange={(_, v) => setVersion(v ?? '')}
              errorMessage={
                version && !versionValid
                  ? 'Hauptversionen enden auf .0 (z.B. 1.0, 2.0)'
                  : undefined
              }
            />

            <Dropdown
              label="Art der Änderung *"
              placeholder="Bitte auswählen..."
              options={aenderungsartOptions}
              selectedKey={aenderungsart}
              onChange={(_, o) => setAenderungsart(o?.key as string ?? '')}
            />

            <TextField
              label="Änderungsbeschreibung *"
              placeholder="Detaillierte Beschreibung der inhaltlichen Änderungen (mind. 20 Zeichen)"
              multiline
              rows={5}
              value={beschreibung}
              onChange={(_, v) => setBeschreibung(v ?? '')}
              errorMessage={
                beschreibung && beschreibung.length < 20
                  ? 'Bitte mind. 20 Zeichen eingeben'
                  : undefined
              }
            />

            {props.freigeberEmail && (
              <Label>Freigeber: {props.freigeberEmail}</Label>
            )}

            {error && (
              <MessageBar messageBarType={MessageBarType.error}>{error}</MessageBar>
            )}

            <Stack horizontal tokens={{ childrenGap: 8 }}>
              <PrimaryButton
                text={isSubmitting ? 'Wird eingereicht...' : 'Zur Freigabe einreichen'}
                onClick={handleSubmit}
                disabled={isSubmitting || !versionValid || !aenderungsart || beschreibung.length < 20}
              >
                {isSubmitting && <Spinner size={SpinnerSize.small} styles={{ root: { marginLeft: 8 } }} />}
              </PrimaryButton>
              <DefaultButton text="Abbrechen" onClick={props.onDismiss} disabled={isSubmitting} />
            </Stack>
          </>
        )}
      </Stack>
    </Panel>
  );
};
