# 🌐 Guide de connexion réseau - Tablette/Mobile

## Problème résolu

La webapp affichait "Aucun Alt connecté" quand on y accédait depuis une tablette/mobile sur le réseau local, alors que ça fonctionnait en local sur le PC.

### Cause
Les URLs du backend étaient hardcodées sur `localhost:5000`, ce qui ne fonctionne que sur le PC local.

### Solution appliquée
Configuration dynamique qui détecte automatiquement l'URL correcte selon l'appareil.

---

## Configuration actuelle

### Code modifié (`backendService.ts`)

```typescript
const getBackendUrl = (): string => {
  // Si on est en développement (localhost), utiliser localhost
  if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    return 'http://localhost:5000';
  }
  
  // Sinon, utiliser l'IP/hostname actuel avec le port 5000
  return `http://${window.location.hostname}:5000`;
};
```

### Comportement

| Appareil | URL d'accès | Backend utilisé |
|----------|-------------|-----------------|
| PC local | `http://localhost:5000` | `http://localhost:5000` |
| PC local | `http://127.0.0.1:5000` | `http://localhost:5000` |
| Tablette | `http://192.168.1.80:5000` | `http://192.168.1.80:5000` |
| Mobile | `http://192.168.1.80:5000` | `http://192.168.1.80:5000` |

---

## Vérifications à faire

### 1. Vérifier l'IP du PC serveur

Sur Windows (PowerShell):
```powershell
ipconfig
```

Cherchez l'adresse IPv4 de votre carte réseau (ex: `192.168.1.80`)

### 2. Vérifier que le serveur écoute sur toutes les interfaces

Dans `FFXI_ALT_Control.py`, ligne ~580:
```python
socketio.run(app, debug=False, port=5000, host='0.0.0.0', ...)
```

✅ `host='0.0.0.0'` est correct (écoute sur toutes les interfaces)

### 3. Vérifier le pare-feu Windows

Le port 5000 doit être ouvert:

**Méthode 1: Via l'interface graphique**
1. Ouvrir "Pare-feu Windows Defender"
2. "Paramètres avancés"
3. "Règles de trafic entrant"
4. Vérifier qu'il y a une règle pour le port 5000

**Méthode 2: Via PowerShell (en admin)**
```powershell
# Créer une règle pour le port 5000
New-NetFirewallRule -DisplayName "FFXI ALT Control" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

### 4. Tester la connexion depuis la tablette

**Test 1: Ping**
```bash
ping 192.168.1.80
```

**Test 2: Accès HTTP**
Ouvrir dans le navigateur de la tablette:
```
http://192.168.1.80:5000
```

Vous devriez voir l'interface de l'application.

**Test 3: Console du navigateur**
1. Ouvrir les outils de développement (F12 sur PC, ou menu sur mobile)
2. Onglet "Console"
3. Chercher le log:
```
[BackendService] Configuration: {
  hostname: "192.168.1.80",
  apiUrl: "http://192.168.1.80:5000",
  socketUrl: "http://192.168.1.80:5000"
}
```

---

## Dépannage

### Problème: "Aucun Alt connecté"

**Causes possibles:**

1. **Le serveur Python n'est pas démarré**
   - Solution: Lancer `FFXI_ALT_Control.py` et cliquer sur "ON / OFF Servers"

2. **Les ALTs ne sont pas connectés au serveur**
   - Solution: Dans FFXI, taper `/lua r AltControl` pour recharger l'addon

3. **Le pare-feu bloque la connexion**
   - Solution: Voir section "Vérifier le pare-feu Windows" ci-dessus

4. **Mauvaise IP**
   - Solution: Vérifier l'IP avec `ipconfig` et utiliser la bonne IP

5. **WebSocket ne se connecte pas**
   - Vérifier dans la console du navigateur s'il y a des erreurs
   - Chercher: `[BackendService] SocketIO connected`

### Problème: "ERR_CONNECTION_REFUSED"

Le serveur n'est pas accessible:
- ✅ Vérifier que le serveur Python est démarré
- ✅ Vérifier que le pare-feu autorise le port 5000
- ✅ Vérifier que PC et tablette sont sur le même réseau WiFi

### Problème: "CORS Error"

Normalement résolu, mais si ça arrive:
- Vérifier dans `FFXI_ALT_Control.py` ligne ~395:
  ```python
  socketio = SocketIO(app, cors_allowed_origins="*")
  ```

---

## Test complet

### Sur le PC serveur:

1. Lancer `FFXI_ALT_Control.py`
2. Cliquer sur "ON / OFF Servers" (les deux doivent être ON)
3. Lancer FFXI et se connecter avec un personnage
4. Vérifier dans la console Python:
   ```
   [ALT UPDATE] 'NomDuPerso' at 127.0.0.1:5008
   ```

### Sur la tablette:

1. Ouvrir le navigateur
2. Aller sur `http://192.168.1.80:5000` (remplacer par votre IP)
3. Vérifier que l'interface s'affiche
4. Vérifier que les ALTs apparaissent dans la liste
5. Tester une commande (ex: "Assist")

---

## Logs de debug

### Dans la console du navigateur (F12)

Logs à chercher:
```
[BackendService] Configuration: {...}
[BackendService] Connecting to SocketIO: http://192.168.1.80:5000
[BackendService] SocketIO connected
[BackendService] ALT update received: {...}
```

### Dans la console Python

Logs à chercher:
```
[FLASK+SOCKETIO] Starting on http://0.0.0.0:5000
[LUA SERVER] Listening on 127.0.0.1:5007
[ALT UPDATE] 'NomDuPerso' at 127.0.0.1:5008
[WEBSOCKET] Client connected
[WEBSOCKET] Broadcast update for NomDuPerso
```

---

## Accès depuis l'extérieur (Internet)

⚠️ **Non recommandé pour des raisons de sécurité!**

Si vous voulez vraiment accéder depuis l'extérieur:

1. **Port forwarding sur votre routeur**
   - Rediriger le port 5000 externe vers 192.168.1.80:5000

2. **Utiliser votre IP publique**
   - Trouver votre IP publique: https://www.whatismyip.com/
   - Accéder via: `http://VOTRE_IP_PUBLIQUE:5000`

3. **⚠️ Sécurité**
   - Ajouter une authentification
   - Utiliser HTTPS
   - Limiter les IPs autorisées

---

## Résumé des modifications

### Fichiers modifiés:
- ✅ `Web_App/src/services/backendService.ts` - URL dynamique

### Rebuild nécessaire:
```bash
cd Web_App
npm run build
```

### Redémarrage nécessaire:
- ✅ Redémarrer le serveur Python (`FFXI_ALT_Control.py`)
- ✅ Rafraîchir la page sur la tablette (Ctrl+F5 ou vider le cache)

---

**Date de correction:** $(date)
**IP serveur exemple:** 192.168.1.80
**Port:** 5000
