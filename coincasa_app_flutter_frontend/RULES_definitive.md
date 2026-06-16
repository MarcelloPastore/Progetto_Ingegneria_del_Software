# GUIDA DEFINITIVA AL REFACTORING: FLUTTER, RIVERPOD & CLEAN ARCHITECTURE

Il presente documento stabilisce gli standard architettonici e di sviluppo per il progetto mobile. Ogni operazione di refactoring o generazione di codice deve conformarsi rigorosamente a questi principi per garantire manutenibilità, scalabilità e prestazioni ottimali.

## 1. ARCHITETTURA E STRUTTURA DEL PROGETTO

L'applicazione adotta una **Clean Architecture** combinata con il pattern **MVVM**, garantendo un disaccoppiamento totale tra la logica di business e l'interfaccia utente.

| Livello | Responsabilità | Contenuto |
| :--- | :--- | :--- |
| **Domain** | Logica di business pura | Entities (modelli immutabili), Repository Interfaces, Use Cases. |
| **Data** | Implementazione e dati | Repository Implementations, Data Sources (API, DB), DTOs e Mapper. |
| **Presentation (UI)** | Interfaccia e stato UI | Screens (View), ViewModels (Notifier), Widgets atomici. |
| **Core** | Risorse condivise | Design System, Costanti, Utilities, Global Providers. |

### Regole di Organizzazione File
*   Utilizzare esclusivamente la nomenclatura `lowercase_with_underscores`.
*   **1 Screen = 1 ViewModel**: Ogni schermata principale deve avere il proprio ViewModel dedicato.
*   **Separazione delle Feature**: Organizzare `lib/features/nome_feature/` includendo internamente i livelli `ui`, `domain` e `data`.

---

## 2. DESIGN SYSTEM E UI (ATOMIC DESIGN)

La UI deve essere intesa come una funzione dello stato: **UI = f(state)**. È tassativamente vietato l'uso di valori hardcoded.

### Principi Costruttivi
*   **Atomic Design**: Scomporre le interfacce in widget atomici e riutilizzabili. Prima di creare un widget, verificare la presenza in `lib/core/widgets/common/`.
*   **Stateless di Default**: Preferire `StatelessWidget`. Usare `StatefulWidget` solo per stati effimeri locali (es. animazioni o controller di testo).
*   **Single Scaffold**: Ogni rotta deve contenere un unico `Scaffold` radice. Evitare Scaffold annidati.
*   **SafeArea**: Avvolgere sempre il corpo dello Scaffold in una `SafeArea` per gestire notch e aree di sistema.

### Vincoli del Design System
> **Divieto Assoluto**: Non inserire codici esadecimali (es. `0xFF...`) o valori numerici diretti per padding/spaziature nei file della View.

*   **Colori e Temi**: Accedere esclusivamente tramite `Theme.of(context).colorScheme`. preferire l'uso di `AppColors` per costanti semantiche. vedere `lib/core/theme/app_theme.dart`.
*   **Dimensioni**: Usare le costanti semantiche definite in `AppSizes` (es. `AppSizes.p16`, `AppSizes.h8`).
*   **Tipografia**: Usare `Theme.of(context).textTheme`.

---

## 3. GESTIONE DELLO STATO (RIVERPOD)

**Riverpod** è l'unica fonte di verità (Single Source of Truth) ed è utilizzato per la Dependency Injection e la gestione dello stato globale.

### Utilizzo dei Provider
1.  **ViewModel**: Estendere `Notifier` o `AsyncNotifier` per gestire lo stato della UI.
2.  **Accesso ai Dati**: I ViewModel devono accedere ai Repository esclusivamente tramite Provider per rispettare la **Dependency Inversion**.
3.  **Consumo nella UI**:
    *   Le View devono estendere `ConsumerWidget`.
    *   **`ref.watch()`**: Usato solo nel metodo `build` per reagire ai cambiamenti di stato.
    *   **`ref.read()`**: Usato solo nei callback (es. `onPressed`) per invocare azioni nel ViewModel.

---

## 4. LOGICA DI BUSINESS E DATI

*   **Modelli Immutabili**: Tutte le entità del dominio devono essere immutabili.
*   **Repository Pattern**: Funge da mediatore tra le sorgenti dati (API/Service) e la logica di presentazione.
*   **Use Cases (Interactors)**: Incapsulare azioni specifiche (es. `LoginUser`) per promuovere il principio di **Single Responsibility**.
*   **SOLID**: Il codice deve rispettare i cinque principi SOLID, con particolare attenzione alla **Interface Segregation** e alla **Dependency Inversion**.

---

## 5. CHECKLIST PER IL REFACTORING AI

Durante il refactoring di un modulo esistente, l'AI deve verificare:

1.  **Disaccoppiamento**: La View contiene logica di business o chiamate API dirette? Se sì, spostarle nel ViewModel o Repository.
2.  **Hardcoding**: Esistono colori o dimensioni numeriche? Sostituirli con `Theme.of(context)` e `AppSizes`.
3.  **Composizione**: Il widget è troppo grande? Scomporlo in widget atomici più piccoli.
4.  **Riverpod**: Lo stato è gestito correttamente tramite `NotifierProvider`? Viene usato `ref.watch` in modo efficiente?
5.  **Naming**: I file e le classi seguono le convenzioni stabilite?

---

*Nota: Questo documento funge da "Sorgente di Verità" per lo sviluppo. Qualsiasi deviazione deve essere giustificata e documentata.*
