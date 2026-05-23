# CoinCasa

Progetto per il corso di Ingegneria del Software. Il repository contiene:
- Backend API in Node.js/TypeScript (Fastify + Prisma + MongoDB).
- App Flutter per la UI mobile.

## Struttura del repository

Nota: per mantenere la lista leggibile sono esclusi file generati e cache (build/, .dart_tool/, .gradle/, Pods/, .idea/, .DS_Store, *.iml).

```
.
|-- .env.example
|-- .gitignore
|-- Dockerfile
|-- HttpRequests/
|   `-- turni.http
|-- README.md
|-- eslint.config.ts
|-- index.ts
|-- package-lock.json
|-- package.json
|-- prisma/
|   `-- schema.prisma
|-- src/
|   |-- config/
|   |   |-- db.ts
|   |   `-- routes.ts
|   |-- controller/
|   |   |-- ProblemaController.ts
|   |   |-- SpeseController.ts
|   |   `-- TurnoController.ts
|   |-- dto/
|   |   |-- AssegnatarioDto.ts
|   |   |-- TurnoDto.ts
|   |   `-- converter/
|   |       `-- TurnoConverter.ts
|   |-- errors/
|   |   |-- errorMapper.ts
|   |   `-- httpErrors.ts
|   |-- middleware/
|   |   `-- RoleMiddleware.ts
|   |-- repository/
|   |   |-- CasaRepository.ts
|   |   `-- TurnoRepository.ts
|   |-- service/
|   |   `-- TurnoService.ts
|   `-- types/
|       |-- fastify.d.ts
|       `-- params.ts
|-- test/
|   |-- turno.converter.test.ts
|   `-- turno.service.test.ts
|-- tsconfig.json
|-- vitest.config.ts
`-- coincasa_app_flutter_frontend/
	|-- .gitignore
	|-- analysis_options.yaml
	|-- pubspec.lock
	|-- pubspec.yaml
	|-- lib/
	|   |-- app.dart
	|   |-- main.dart
	|   |-- core/
	|   |   |-- api/
	|   |   |   |-- api_client.dart
	|   |   |   |-- api_provider.dart
	|   |   |   |-- auth_api.dart
	|   |   |   |-- casa_api.dart
	|   |   |   |-- spese_api.dart
	|   |   |   `-- turni_api.dart
	|   |   |-- config/
	|   |   |   `-- env.dart
	|   |   `-- models/
	|   |       |-- casa.dart
	|   |       |-- inquilino.dart
	|   |       |-- quota.dart
	|   |       |-- spesa.dart
	|   |       `-- turno.dart
	|   `-- ui/
	|       |-- Icons/
	|       |   |-- home.png
	|       |   |-- home_auth_icon.png
	|       |   |-- problemi.png
	|       |   |-- reminder.png
	|       |   |-- spese.png
	|       |   `-- turni.png
	|       |-- screens/
	|       |   |-- casa/
	|       |   |   `-- casa_screen.dart
	|       |   |-- dashboard/
	|       |   |   `-- dashboard_screen.dart
	|       |   |-- login/
	|       |   |   `-- login_screen.dart
	|       |   |-- register/
	|       |   |   `-- register_screen.dart
	|       |   |-- spese/
	|       |   |   `-- spese_screen.dart
	|       |   `-- turni/
	|       |       |-- codice_claude.dart
	|       |       |-- turni_home_screen.dart
	|       |       `-- turno_create_screen.dart
	|       |-- theme/
	|       |   `-- app_theme.dart
	|       `-- widgets/
	|           `-- common/
	|               |-- app_top_bar.dart
	|               |-- info_card.dart
	|               `-- primary_button.dart
	|-- test/
	|   `-- widget_test.dart
	|-- web/
	|   |-- favicon.png
	|   |-- index.html
	|   |-- manifest.json
	|   `-- icons/
	|       |-- Icon-192.png
	|       |-- Icon-512.png
	|       |-- Icon-maskable-192.png
	|       `-- Icon-maskable-512.png
	|-- android/
	|   |-- app/
	|   |-- build.gradle.kts
	|   |-- gradle/
	|   |-- gradle.properties
	|   |-- gradlew
	|   |-- gradlew.bat
	|   |-- local.properties
	|   `-- settings.gradle.kts
	|-- ios/
	|   |-- Flutter/
	|   |-- Podfile
	|   |-- Podfile.lock
	|   |-- Runner/
	|   |-- Runner.xcodeproj/
	|   |-- Runner.xcworkspace/
	|   `-- RunnerTests/
	|-- macos/
	|   |-- Flutter/
	|   |-- Podfile
	|   |-- Runner/
	|   |-- Runner.xcodeproj/
	|   |-- Runner.xcworkspace/
	|   `-- RunnerTests/
	|-- linux/
	|   |-- CMakeLists.txt
	|   |-- flutter/
	|   `-- runner/
	`-- windows/
		|-- CMakeLists.txt
		|-- flutter/
		`-- runner/
```

## Backend API (Node/TypeScript)

- Entry point: index.ts
- Database: Prisma con MongoDB (variabile `MONGODB_URI` in .env)
- Porta: `PORT` (default 3000 se non impostata)

### Script disponibili

- `npm run build` compila TypeScript.
- `npm test` esegue i test con Vitest.

## Frontend (Flutter)

- Entry point: lib/main.dart
- UI: lib/ui/

## Guida rapida per vedere le schermate su emulatore (macOS)

### Cosa installare

- Flutter SDK (canale stable)
- Xcode (per iOS Simulator)
- Android Studio + Android SDK (per emulator Android, opzionale)
- CocoaPods (necessario per build iOS se richiesto da `flutter doctor`)

### Passi rapidi

1) Verifica l'ambiente:

```
flutter doctor
```

2) Risolvi eventuali problemi segnalati da `flutter doctor`:
- Apri Xcode almeno una volta per installare i componenti richiesti.
- Accetta la licenza Xcode se richiesto.
- Per Android, installa Android Studio e accetta le licenze Android.

3) Scarica le dipendenze Flutter:

```
cd coincasa_app_flutter_frontend
flutter pub get
```

4) Avvia un emulatore:
- iOS: apri Simulator da Xcode (Open Developer Tool > Simulator) oppure `open -a Simulator`.
- Android: crea e avvia un AVD da Android Studio (Device Manager).

5) Verifica i device disponibili:

```
flutter devices
```

6) Avvia l'app:

```
flutter run
```

Se hai piu device attivi, usa:

```
flutter run -d <device_id>
```
