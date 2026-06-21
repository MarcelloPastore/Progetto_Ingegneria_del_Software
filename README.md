# CoinCasa 🏠

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=MarcelloPastore_Progetto_Ingegneria_del_Software&metric=alert_status&organization=marcellopastore)](https://sonarcloud.io/summary/new_code?id=MarcelloPastore_Progetto_Ingegneria_del_Software)

**CoinCasa** è una piattaforma progettata per semplificare la convivenza in case condivise. Permette agli inquilini di gestire in modo coordinato spese, turni, scadenze e problemi domestici.

---

## 🚀 Funzionalità principali
- **🏠 Gestione Case:** Crea o unisciti a una casa tramite link d'invito.
- **💰 Spese e Quote:** Traccia spese comuni, anticipi e quote individuali.
- **📅 Scadenze:** Gestione di bollette, affitti e promemoria ricorrenti.
- **🧹 Turni:** Organizzazione rotativa delle pulizie e dei compiti.
- **⚠️ Problemi:** Sistema di segnalazione per problemi tecnici o manutenzione della casa.
- **📂 Documenti:** archivio condiviso per contratti e documenti della casa.

## 🛠️ Tech Stack
- **Backend:** Node.js, TypeScript, Fastify, Prisma (MongoDB).
- **Frontend:** Flutter (iOS/Android/Web).
- **DevOps/QA:** Vitest, SonarCloud, Docker.

---

## 📦 Guida all'avvio

### 1. Backend (Node.js)
Il backend gestisce l'API e la persistenza dei dati.

```bash
# Installa le dipendenze
npm install

# Configura l'ambiente (.env)
cp .env.example .env
# Modifica .env con la tua MONGODB_URI e JWT_SECRET

# Genera il client database
npx prisma generate

# Avvia l'applicazione
npx tsx index.ts
```

### 2. Frontend (Flutter)
L'interfaccia utente per i dispositivi mobili.

```bash
cd coincasa_app_flutter_frontend
flutter pub get
flutter run
```

### 3. Docker (Alternativa Backend)
Avvia il backend e un server mail di test (Mailpit) tramite Docker Compose:

```bash
docker-compose up --build
```

---

## 🧪 Testing
Per eseguire i test unitari e di integrazione del backend:
```bash
npm test
```
Per visualizzare la copertura dei test:
```bash
npm run test:coverage
```

---

## 📄 Licenza
Questo progetto è rilasciato sotto la licenza **MIT**. Consulta il file [LICENSE](LICENSE) per maggiori informazioni.

---
*Progetto sviluppato per il corso di Ingegneria del Software.*
