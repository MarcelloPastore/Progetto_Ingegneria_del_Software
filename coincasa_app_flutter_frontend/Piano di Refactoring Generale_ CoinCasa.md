# Piano di Refactoring Generale: CoinCasa

Il presente piano delinea la strategia di refactoring per il progetto **CoinCasa**, finalizzato all'allineamento con le **RULES_definitive.md** (Clean Architecture + MVVM + Riverpod). Il lavoro è ottimizzato per un team di **4 sviluppatori** per massimizzare il parallelismo e minimizzare i conflitti di merge.

---

## 1. Obiettivi Chiave del Refactoring

- **Centralizzazione Design System**: Migrazione di tutti i colori in `AppColors` all'interno di `app_theme.dart`, utilizziamo solo AppColors nelle schermate, eliminando "Theme.of(context).colorScheme".

- **Migrazione a Riverpod**: Sostituzione della gestione dello stato locale (`StatefulWidget`) con `Notifier` o `AsyncNotifier`.

- **Clean Architecture**: Separazione netta tra `Data`, `Domain` e `Presentation` per ogni feature.

- **Eliminazione Hardcoding**: Sostituzione di ogni valore numerico con costanti da `AppSizes`.

---

## 2. Architettura dei Provider (Riverpod)

Per garantire la **Dependency Inversion**, i provider saranno organizzati come segue:

| Tipo Provider | Destinazione | Responsabilità |
| --- | --- | --- |
| **Repository Providers** | `lib/core/api/` | Forniscono le istanze dei repository (es. `authRepositoryProvider`). |
| **ViewModel Providers** | `lib/features/*/ui/viewmodels/` | Gestiscono lo stato della UI (es. `loginViewModelProvider`). |
| **Global Providers** | `lib/core/providers/` | Stato globale come sessione utente o tema (es. `sessionProvider`). |

---

## 3. Suddivisione dei Compiti (Team di 4 Persone)

La divisione è strutturata per feature e livelli architettonici per evitare sovrapposizioni sugli stessi file.

### **Sviluppatore 1: Core & Design System Architect (Luigi?)**

*Responsabile delle fondamenta e della coerenza visiva.*

- [x] **Task 1.1**: Consolidare `lib/core/theme/app_theme.dart`. Mappare tutti i colori esistenti in `ColorScheme` di Material 3.

- [x] **Task 1.2**: Aggiornare `AppSizes` in `lib/core/constants/app_sizes.dart` per coprire ogni necessità di padding/radius.

- [] **Task 1.3**: Creare i widget atomici globali in `lib/core/widgets/common/` (Bottoni, Input, Card standard), utilizzando i colori e sizes definiti in AppColors e AppSizes, in modo tale che ogni widget abbia le dimensioni minime e massime corrette in base al sistema di design.

- []**Task 1.4**: Configurare il `ProviderScope` nel `main.dart` e il `MaterialApp` per usare il nuovo tema.

### **Sviluppatore 2: Auth & Session Specialist (Lorenzo?)**

*Responsabile del flusso di autenticazione e sicurezza.*

- **Task 2.1**: Refactoring del modulo `auth`. Creare `AuthRepository` (Domain) e `AuthRepositoryImpl` (Data).

- **Task 2.2**: Implementare `AuthViewModel` usando `AsyncNotifier` per gestire login, registrazione e recupero password.

- **Task 2.3**: Convertire le View di `lib/features/auth/screens/` in `ConsumerWidget`, eliminando `setState`.

### **Sviluppatore 3: Feature Lead (Dashboard & Casa) (Mauro?)**

*Responsabile della logica principale dell'abitazione.*

- **Task 3.1**: Strutturare la feature `casa` secondo i 3 livelli (Data, Domain, UI).

- **Task 3.2**: Implementare i modelli immutabili per `Casa` e `Inquilino` usando `freezed` o costruttori `const`.

- **Task 3.3**: Sviluppare il `DashboardViewModel` per aggregare i dati da visualizzare nella home.

- **Task 3.4**: Refactoring della `DashboardScreen` per riflettere lo stato reattivo di Riverpod.

### **Sviluppatore 4: Feature Lead (Spese & Turni) (Marcello?)**

*Responsabile dei moduli transazionali e di pianificazione.*

- **Task 4.1**: Refactoring completo delle feature `spese` e `turni`.

- **Task 4.2**: Creazione dei repository per la gestione delle chiamate API verso il backend.

- **Task 4.3**: Implementazione di `SpeseViewModel` e `TurniViewModel` con gestione degli stati di caricamento ed errore.

- **Task 4.4**: Ottimizzazione dei widget locali per la visualizzazione di liste e grafici.

---

## 4. Strategia Anti-Conflitto

1. **Branching Policy**: Ogni sviluppatore lavora su un branch `feature/nome-feature`.

1. **File Header**: Prima di modificare un file in `core`, lo sviluppatore deve notificare il Team Lead (Mauro oppure sul gruppo).

1. **Barrel Files**: Utilizzare file `index.dart` o `feature_name.dart` per esportare i componenti, riducendo il numero di import nei file altrui.

1. **Codice Generato**: Non committare i file `.g.dart` o `.freezed.dart` se creano rumore, o assicurarsi di usare la stessa versione di `build_runner`.

---

## 5. Checklist di Validazione Finale

Ogni PR deve superare i seguenti controlli:

- [ ] Nessun `Color(0xFF...)` fuori da `app_theme.dart`.

- [ ] Nessun `SizedBox(height: 10)` (usare `AppSizes.h8` o simili).

- [ ] Ogni View estende `ConsumerWidget`.

- [ ] La logica di business è assente dai file della View.

- [ ] Tutti i modelli sono immutabili.

