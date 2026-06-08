# FLUTTER PROJECT DIRECTIVES - STRICT COMPLIANCE REQUIRED

Sei un Senior Software Engineer. Per ogni nuovo file `.dart` o modifica al progetto, DEVI rispettare tassativamente la seguente architettura Clean Architecture + MVVM. Non ci sono eccezioni.

## 1. STRUTTURA DELLE DIRECTORY E LIVELLI LOGICI
Il codice in `lib/` è separato per funzionalità e livelli. Usa la nomenclatura `lowercase_with_underscores`.
*   **`domain/`**: Il cuore. Contiene Entities (modelli puri), Interfacce dei Repository e Use Cases (es. `LoginUseCase`). Nessuna dipendenza esterna.
*   **`data/`**: Implementazione concreta. Contiene Repository implementati, Services (API REST, SQLite) e logica di serializzazione JSON.
*   **`ui/` (o `presentation/`)**: Organizzata per schermate/feature.
    *   `/view_models/`: Il cervello della UI. 1 Screen = 1 ViewModel.
    *   `/widgets/`: Componenti grafici.
*   **`test/`**: Unit test e widget test associati.

## 2. GESTIONE DELLA UI E DEI WIDGET
In Flutter tutto è un widget. Applica i seguenti principi:
*   **Atomic Design**: Costruisci UI complesse assemblando widget atomici e monouso.
*   **Stateless di default**: Usa `StatelessWidget`. Usa `StatefulWidget` SOLO per stati locali effimeri (es. animazioni, toggle).
*   **Single Scaffold**: Usa un solo `Scaffold` come contenitore di primo livello per rotta.

## 3. DESIGN SYSTEM E STILI GLOBALI (STRICT)
*   **Niente Hardcoding**: È tassativamente vietato definire colori, font o dimensioni custom direttamente nei file UI o nei moduli specifici.
*   **Centralizzazione**: Tutte le palette, i testi e i temi (inclusi quelli per il modulo Auth) risiedono ESCLUSIVAMENTE in `lib/core/theme/app_theme.dart`.

## 4. GESTIONE DELLO STATO E FLUSSO DATI (RIVERPOD)
L'applicazione è guidata dallo stato (UI = f(state)) e utilizza **Riverpod** come unica fonte di verità (Single Source of Truth), azzerando completamente il Prop Drilling.

* **Definizione dei Provider (Data/Domain):** I servizi e le interfacce dei Repository vengono esposti tramite `Provider` standard (read-only) per garantire la Dependency Inversion (DIP). I ViewModel comunicano con i moduli Data SOLO tramite queste astrazioni.
* **Layer UI (ViewModel):** Ogni ViewModel gestisce lo stato di una specifica View estendendo `Notifier` o `AsyncNotifier` (per operazioni asincrone), esposto tramite un `NotifierProvider`.
* **Iniezione delle Dipendenze:** Il ViewModel ottiene i casi d'uso o i repository leggendoli tramite il `ref` interno nel costruttore o nell'inizializzazione, mai tramite istanziazione diretta.
* **Consumo nella UI:** Le schermate (View) devono estendere `ConsumerWidget` o `ConsumerStatefulWidget`.
* **Disciplina del Ref:** * Usa `ref.watch()` **esclusivamente** all'interno del metodo `build()` per ricostruire la UI quando lo stato cambia.
    * Usa `ref.read()` **esclusivamente** all'interno delle funzioni di callback (es. `onPressed`) per invocare metodi del ViewModel senza registrare ascolti inutili.