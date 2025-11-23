# 📱 AltControl V2 - Web App

Interface web moderne pour contrôler vos ALTs FFXI.

## 🚀 Quick Start

### Installation

```bash
npm install
```

### Développement

```bash
npm run dev
```

Ouvre http://localhost:3000

### Build Production

```bash
npm run build
```

Les fichiers sont générés dans `dist/`

### Preview Production

```bash
npm run preview
```

## 📦 Stack

- **React 18** - UI Framework
- **TypeScript** - Type Safety
- **Vite** - Build Tool
- **Tailwind CSS** - Styling
- **Socket.IO** - Real-time Updates
- **Lucide React** - Icons

## 🏗️ Structure

```
webapp/
├── src/
│   ├── components/
│   │   ├── Home.tsx              # Page d'accueil
│   │   ├── AltController.tsx     # Contrôleur ALT
│   │   └── CommandButton.tsx     # Bouton réutilisable
│   ├── services/
│   │   └── backendService.ts     # Communication backend
│   ├── App.tsx                   # App principale
│   ├── main.tsx                  # Point d'entrée
│   └── index.css                 # Styles globaux
├── index.html
├── package.json
├── vite.config.ts
├── tsconfig.json
└── tailwind.config.js
```

## 🔌 Backend

La Web App se connecte au serveur Python sur `http://localhost:5000`

Assure-toi que le serveur Python tourne :

```bash
cd ../python
python server.py
```

## 🎨 Fonctionnalités

### Home
- Liste des ALTs connectés
- Sélection de 2 ALTs
- Infos : Job, Level, Pet

### AltController
- Commandes de base (Assist, Attack)
- Liste des sorts
- Liste des abilities
- Updates temps réel via SocketIO

## 🔧 Configuration

### Backend URL

Par défaut, la Web App se connecte à `http://localhost:5000`

Pour changer l'URL, édite `src/services/backendService.ts` :

```typescript
const BACKEND_CONFIG = {
  apiUrl: 'http://YOUR_IP:5000',
  socketUrl: 'http://YOUR_IP:5000',
};
```

### Port

Pour changer le port de dev, édite `vite.config.ts` :

```typescript
export default defineConfig({
  server: {
    port: 3000, // Change ici
  }
})
```

## 📝 Scripts

- `npm run dev` - Démarrer le serveur de dev
- `npm run build` - Build pour production
- `npm run preview` - Preview du build

## 🐛 Troubleshooting

### La Web App ne se connecte pas au backend

1. Vérifie que le serveur Python tourne
2. Vérifie l'URL dans `backendService.ts`
3. Vérifie le firewall

### Les ALTs n'apparaissent pas

1. Vérifie que les ALTs sont connectés au jeu
2. Vérifie que l'addon Lua est chargé
3. Regarde les logs du serveur Python

### Erreurs TypeScript

```bash
npm install
```

## 🎯 Prochaines étapes

- [ ] Weapon Skills
- [ ] Pet Commands
- [ ] Macros
- [ ] Teleports
- [ ] AutoCast
- [ ] Recast timers
- [ ] Configuration panel

## 📄 License

Voir LICENSE à la racine du projet
