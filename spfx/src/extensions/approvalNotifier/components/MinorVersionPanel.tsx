import * as React from 'react';
import {
  Panel, PanelType, PrimaryButton, DefaultButton,
  TextField, Dropdown, IDropdownOption, Spinner, SpinnerSize,
  MessageBar, MessageBarType, Stack, Text, Label
} from '@fluentui/react';

export interface IMinorVersionPanelProps {
  isOpen: boolean;
  dokumentname: string;
  aktuelleVersion: string;
  erstellerEmail: string;
  onDismiss: () => void;
  onSubmit: (version: string, aenderungsart: string, beschreibung: string) => Promise<void>;
}

const aenderungsartOptions: IDropdownOption[] = [
  { key: 'Inhaltliche Änderung', text: 'Inhaltliche Änderung' },
  { key: 'Formale Korrektur',    text: 'Formale Korrektur' },
];

export const MinorVersionPanel: React.FC<IMinorVersionPanelProps> = (props) => {
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

  const versionValid = /^\d+\.[1-9]\d*$/.test(version);

  const handleSubmit = async (): Promise<void> => {
    if (!versionValid || !aenderungsart || beschreibung.length < 10) return;
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
      headerText="Nebenversion dokumentieren"
      closeButtonAriaLabel="Schliessen"
    >
      <Stack tokens={{ childrenGap: 16 }} styles={{ root: { padding: '16px 0' } }}>

        <Text variant="mediumPlus" styles={{ root: { fontWeight: 600 } }}>
          {props.dokumentname}
        </Text>

        <MessageBar messageBarType={MessageBarType.info} isMultiline>
          Nebenversionen benötigen keine Genehmigung. Die Änderung wird direkt im
          Changelog dokumentiert. Leser sehen weiterhin die letzte genehmigte Hauptversion.
        </MessageBar>

        {success ? (
          <MessageBar messageBarType={MessageBarType.success}>
            Nebenversion erfolgreich dokumentiert.
          </MessageBar>
        ) : (
          <>
            <TextField
              label="Neue Nebenversionsnummer *"
              placeholder="z.B. 1.1 / 1.2 / 2.1"
              value={version}
              onChange={(_, v) => setVersion(v ?? '')}
              errorMessage={
                version && !versionValid
                  ? 'Nebenversionen enden auf .1, .2 usw. (z.B. 1.1, 2.3)'
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
              label="Was wurde geändert? *"
              placeholder="Kurze Beschreibung der vorgenommenen Änderungen (mind. 10 Zeichen)"
              multiline
              rows={4}
              value={beschreibung}
              onChange={(_, v) => setBeschreibung(v ?? '')}
              errorMessage={
                beschreibung && beschreibung.length < 10
                  ? 'Bitte mind. 10 Zeichen eingeben'
                  : undefined
              }
            />

            {error && (
              <MessageBar messageBarType={MessageBarType.error}>{error}</MessageBar>
            )}

            <Stack horizontal tokens={{ childrenGap: 8 }}>
              <PrimaryButton
                text={isSubmitting ? 'Wird gespeichert...' : 'Änderung dokumentieren'}
                onClick={handleSubmit}
                disabled={isSubmitting || !versionValid || !aenderungsart || beschreibung.length < 10}
              >
                {isSubmitting && <Spinner size={SpinnerSize.small} styles={{ root: { marginLeft: 8 } }} />}
              </PrimaryButton>
              <DefaultButton text="Abbrechen" onClick={props.onDismiss} disabled={isSubmitting} />
            </Stack>

            <Label styles={{ root: { color: '#605e5c', fontSize: 12 } }}>
              Die Nebenversion ist sofort für Freigeber und Autoren sichtbar.
            </Label>
          </>
        )}
      </Stack>
    </Panel>
  );
};
