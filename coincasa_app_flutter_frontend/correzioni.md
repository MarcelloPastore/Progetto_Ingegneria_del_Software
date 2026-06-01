### 🎨 Area: Figma & Flutter
- [ ] **DASHBOARD:** Inserire le icone identificative nelle schermate FAB per l'aggiunta rapida di spesa, turno, scadenza o problema.
- [ ] **GESTIONE TURNI:** Nella schermata di inserimento/modifica turno, rimuovere i campi giorno e mese; integrare un'icona calendario affiancata dal testo "Prima data del turno".
- [ ] **GESTIONE TURNI:** Modificare la palette cromatica dei messaggi di successo, poiché l'attuale layout li fa confondere con dei pulsanti.
- [ ] **AUTENTICAZIONE:** Variare il colore della dicitura "Verifica Codice" commutandolo in grigio chiaro.

### 📱 Area: Flutter
- [ ] **Color-Coding:** Associare un colore univoco a ogni inquilino al fine di mappare cromaticamente i turni all'interno del calendario.
- [ ] **Gestione Permessi:** Per ciascuna schermata, implementare le divergenze funzionali tra HomeAdmin e Inquilino (ove previste).
- [ ] **Inibizione Azioni:** Renderizzare come grigi e non cliccabili i pulsanti legati ad azioni esclusive dell'HomeAdmin (es. la rotazione del turno).
- [/] **FIX SISTEMA:** Correggere la Home del turno; l'interfaccia non si aggiorna dinamicamente con l'inserimento di una nuova casa o di nuovi turni in fase di ricaricamento.
- [ ] **FIX NAVIGAZIONE:** Rimappare i flussi del pulsante "torna indietro", definendo la destinazione ad-hoc per ogni singola schermata.
- [ ] **Flusso Crea Casa:** Il percorso Crea Casa -> Copia link di invito -> Click su X deve essere isolato; l'azione di chiusura post-creazione non deve reindirizzare l'utente ad altre schermate estranee.
- [ ] **GESTIONE CASA:** Configurare un valore di preselezione automatica nel campo "Tipo di abitazione" (es. "Appartamento Condiviso").
- [ ] **DASHBOARD:** Il widget del turno odierno deve mostrare l'icona profilo dell'assegnatario corrente, rimuovendo la spunta verde.
- [ ] **DASHBOARD:** Ordinare rigorosamente da sinistra verso destra gli anelli grafici presenti nella sezione Salute Casa.
- [ ] **DASHBOARD:** Rimuovere la scritta "Urgente" sempre visibile dai problemi aperti; mantenerla attiva solo nel caso specifico in cui non vi siano problemi aperti.
- [ ] **DASHBOARD:** Eliminare la dicitura "Oggi" dalla sezione del turno odierno, in quanto superflua e ripetitiva.
- [ ] **GESTIONE TURNI:** Ottimizzare il design del bottone "Inserisci turno" per renderlo pienamente fedele al mockup di Figma.
- [ ] **GESTIONE TURNI:** Risolvere il glitch nel Dettaglio turno che provoca il caricamento di due schermate consecutive (la prima mostrata vuota, la seconda popolata dai dati del backend).
- [ ] **GESTIONE TURNI:** Valutare la fattibilità tecnica di aprire i dettagli di un turno direttamente selezionandolo dal calendario (Proposta).
- [ ] **GESTIONE TURNI:** Correggere il pulsante di rimozione del turno, rendendo il feedback visivo di conferma più evidente e graficamente gradevole.
- [ ] **GESTIONE TURNI:** Integrare la schermata completa del turno.
- [ ] **GESTIONE TURNI:** Introdurre la schermata di feedback: "Turno assegnato a ... con successo".
- [ ] **GESTIONE TURNI:** Ribilanciare e correggere gli spazi di padding e margine tra i vari widget nella schermata di inserimento turno.