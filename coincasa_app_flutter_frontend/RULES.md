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

### Widget e componenti globali riutilizzabili
Prima di creare un nuovo widget, **controlla sempre** la cartella:

```
coincasa_app_flutter_frontend/lib/core/widgets/
```

Questa cartella contiene i widget condivisi e riutilizzabili dell'intera applicazione, organizzati nelle seguenti sottocartelle:
*   **`common/`**: Componenti UI generici (bottoni, input, card, loader, ecc.) usabili in qualsiasi feature.
*   **`auth/`**: Widget specifici per il flusso di autenticazione.
*   **`dashboard/`**: Widget specifici per la schermata dashboard.

**Regola**: Se un componente che stai per costruire esiste già in `lib/core/widgets/`, DEVI usarlo senza ridefinirlo. Se realizzi un nuovo widget che è condivisibile tra più feature, aggiungilo in `lib/core/widgets/common/` anziché nella cartella locale della feature.

## 3. DESIGN SYSTEM E STILI GLOBALI (STRICT)
*   **Niente Hardcoding**: È tassativamente vietato definire colori (es. `Color(0xFF...)`, `Colors.blue`), dimensioni o stili custom direttamente nei file UI o nei moduli specifici.
*   **Centralizzazione dei Temi e Colori**: Tutte le palette, i testi, i temi e le `ColorScheme` (inclusi quelli per il modulo Auth) risiedono ESCLUSIVAMENTE in:

    ```
    coincasa_app_flutter_frontend/lib/core/theme/app_theme.dart
    ```

    Per usare un colore, accedi sempre tramite il tema globale:
    ```dart
    // ✅ CORRETTO
    Theme.of(context).colorScheme.primary
    Theme.of(context).textTheme.titleLarge

    // ❌ VIETATO
    Color(0xFF6200EE)
    Colors.purple
    ```

*   **Centralizzazione delle Dimensioni**: Tutte le costanti di spaziatura, dimensioni, padding e border radius sono definite in:

    ```
    coincasa_app_flutter_frontend/lib/core/constants/app_sizes.dart
    ```

    Per usare una dimensione, usa sempre le costanti semantiche:
    ```dart
    // ✅ CORRETTO
    padding: EdgeInsets.all(AppSizes.p16)
    SizedBox(height: AppSizes.h8)

    // ❌ VIETATO
    padding: EdgeInsets.all(16.0)
    SizedBox(height: 8)
    ```

### Riferimento rapido alle risorse del Design System
| Risorsa | Percorso |
|---|---|
| Colori, temi, font, `ThemeData` | `lib/core/theme/app_theme.dart` |
| Padding, spacing, border radius, dimensioni | `lib/core/constants/app_sizes.dart` |
| Widget globali riutilizzabili | `lib/core/widgets/` |
| Configurazioni app (es. env, costanti API) | `lib/core/config/` |
| Modelli condivisi tra feature | `lib/core/models/` |
| Utilities e helpers | `lib/core/utils/` |
| Gestione stato globale condiviso | `lib/core/state/` |


## 4. GESTIONE DELLO STATO E FLUSSO DATI (RIVERPOD)
L'applicazione è guidata dallo stato (UI = f(state)) e utilizza **Riverpod** come unica fonte di verità (Single Source of Truth), azzerando completamente il Prop Drilling.

* **Definizione dei Provider (Data/Domain):** I servizi e le interfacce dei Repository vengono esposti tramite `Provider` standard (read-only) per garantire la Dependency Inversion (DIP). I ViewModel comunicano con i moduli Data SOLO tramite queste astrazioni.
* **Layer UI (ViewModel):** Ogni ViewModel gestisce lo stato di una specifica View estendendo `Notifier` o `AsyncNotifier` (per operazioni asincrone), esposto tramite un `NotifierProvider`.
* **Iniezione delle Dipendenze:** Il ViewModel ottiene i casi d'uso o i repository leggendoli tramite il `ref` interno nel costruttore o nell'inizializzazione, mai tramite istanziazione diretta.
* **Consumo nella UI:** Le schermate (View) devono estendere `ConsumerWidget` o `ConsumerStatefulWidget`.
* **Disciplina del Ref:** * Usa `ref.watch()` **esclusivamente** all'interno del metodo `build()` per ricostruire la UI quando lo stato cambia.
    * Usa `ref.read()` **esclusivamente** all'interno delle funzioni di callback (es. `onPressed`) per invocare metodi del ViewModel senza registrare ascolti inutili.