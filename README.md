# Générateur CCTP - Version Web

Cette application est une migration web de l'application de bureau Tkinter pour générer des CCTP (Cahiers des Clauses Techniques Particulières) avec l'aide de l'IA.

## Structure du Projet

```
cctp-generator-web/
├── backend/                    # Serveur Python Flask
│   ├── app.py                 # Application principale Flask
│   ├── requirements.txt       # Dépendances Python
│   ├── venv/                  # Environnement virtuel Python
│   ├── fonts/                 # Polices pour l'export PDF
│   ├── modeles_cctp/         # Modèles de projets CCTP (.json)
│   ├── previews_cctp/        # Prévisualisations générées
│   └── knowledge_base/       # Base de connaissances (PDFs analysés)
├── frontend/                  # Interface utilisateur Vue.js
│   ├── src/                  # Code source Vue.js
│   ├── package.json          # Dépendances Node.js
│   └── vite.config.js        # Configuration Vite
└── lancer_application.bat    # Script de lancement automatique (Windows)
```

## Architecture

-   **Backend**: Python avec Flask. Gère la logique métier, les appels à l'API OpenAI, la manipulation des fichiers et la génération des documents PDF/Word.
-   **Frontend**: JavaScript avec Vue.js (via Vite). Interface utilisateur interactive dans le navigateur.
-   **Communication**: API REST entre le frontend et le backend.

## Prérequis

-   **Python 3.8+** avec pip
-   **Node.js 18+** avec npm
-   **Une clé API OpenAI** (GPT-4 recommandé)
-   **Windows** (pour le script de lancement automatique)

## Installation et Lancement

### Option 1: Lancement automatique (Windows - Recommandé)

**🚀 Pour un démarrage rapide, utilisez le script de lancement automatique :**

1. **Préparer l'environnement** (première fois uniquement) :
   ```bash
   # Créer l'environnement virtuel Python
   cd backend
   python -m venv venv
   .\venv\Scripts\activate
   pip install -r requirements.txt
   cd ..
   
   # Installer les dépendances Node.js
   cd frontend
   npm install
   cd ..
   ```

2. **Configurer la clé API OpenAI** :
   - Créez une variable d'environnement système `OPENAI_API_KEY` avec votre clé
   - Ou modifiez temporairement le script `lancer_application.bat` pour inclure votre clé

3. **Lancer l'application** :
   ```bash
   # Double-cliquez sur le fichier ou exécutez :
   lancer_application.bat
   ```

**Le script automatique :**
- ✅ Lance le serveur backend Python (Flask)
- ✅ Attend que le backend soit prêt
- ✅ Lance le serveur frontend (Vite)
- ✅ Ouvre automatiquement l'application dans votre navigateur
- ✅ Gère la séquence de démarrage complète

### Option 2: Lancement manuel

#### 1. Configuration du Backend

a. **Naviguez vers le dossier backend :**
   ```bash
   cd backend
   ```

b. **Créez un environnement virtuel et activez-le :**
   ```bash
   # Pour Windows
   python -m venv venv
   .\venv\Scripts\activate

   # Pour macOS/Linux
   python3 -m venv venv
   source venv/bin/activate
   ```

c. **Installez les dépendances Python :**
   ```bash
   pip install -r requirements.txt
   ```

d. **Configurez votre clé API OpenAI :**
   ```bash
   # Pour Windows
   set OPENAI_API_KEY="votre_cle_ici"

   # Pour macOS/Linux
   export OPENAI_API_KEY="votre_cle_ici"
   ```

e. **Lancez le serveur backend :**
   ```bash
   python -m flask run
   ```
   Le serveur démarre sur `http://127.0.0.1:5000`. **Laissez ce terminal ouvert.**

#### 2. Configuration du Frontend

a. **Ouvrez un NOUVEAU terminal** et naviguez vers le dossier frontend :
   ```bash
   cd frontend
   ```

b. **Installez les dépendances JavaScript :**
   ```bash
   npm install
   ```

c. **Lancez le serveur de développement :**
   ```bash
   npm run dev
   ```
   Le serveur Vite démarre sur `http://localhost:5173`.

### 3. Utilisation

- Ouvrez `http://localhost:5173` dans votre navigateur
- L'application communique automatiquement avec le backend sur le port 5000
- **Important :** Gardez les deux terminaux (backend et frontend) ouverts pendant l'utilisation

## Fonctionnalités

- 📝 Création et gestion de projets CCTP
- 🏗️ Organisation par typologies et sections
- 🤖 Génération automatique de contenu avec IA (GPT-4)
- 📚 Base de connaissances à partir de PDFs existants
- 📄 Export PDF et Word
- 🔄 Prévisualisation en temps réel
- ✏️ Édition manuelle et suggestions IA

## Dépannage

### Problèmes courants :
- **Port 5000 occupé** : Arrêtez les autres applications Flask ou changez le port
- **Clé API manquante** : Vérifiez que `OPENAI_API_KEY` est bien configurée
- **Polices manquantes** : Placez les fichiers `.ttf` dans `backend/fonts/`
- **Dépendances manquantes** : Réexécutez `pip install -r requirements.txt` et `npm install`

### Le script lancer_application.bat ne fonctionne pas :
- Vérifiez que Python et Node.js sont installés et dans le PATH
- Assurez-vous que l'environnement virtuel existe (`backend/venv/`)
- Vérifiez que les dépendances sont installées dans les deux dossiers