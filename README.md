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

**🚀 Pour un démarrage rapide, utilisez le processus en 2 étapes :**

#### **Étape 1 : Installation initiale (une seule fois)**

1. **Installer les dépendances automatiquement** :
   ```bash
   # Double-cliquez sur le fichier ou exécutez :
   installer_dependances.bat
   ```
   
   Ce script va :
   - ✅ Créer l'environnement virtuel Python automatiquement
   - ✅ Installer toutes les dépendances Python (Flask, etc.)
   - ✅ Installer toutes les dépendances Node.js (Vue, Vite, etc.)
   - ✅ Fermer automatiquement une fois terminé

   **⚠️ IMPORTANT :** Cette installation peut prendre quelques minutes. La fenêtre se fermera automatiquement une fois terminée.

#### **Étape 2 : Configuration de la clé API OpenAI**

2. **Configurer la clé API OpenAI** :
   - **Option A (Recommandée)** : Créez une variable d'environnement système `OPENAI_API_KEY` avec votre clé
   - **Option B** : Modifiez temporairement le script `lancer_application.bat` pour inclure votre clé :
     ```bat
     set OPENAI_API_KEY=votre_cle_ici
     ```

#### **Étape 3 : Lancement de l'application**

3. **Lancer l'application** (à chaque utilisation) :
   ```bash
   # Double-cliquez sur le fichier ou exécutez :
   lancer_application.bat
   ```

**Le script de lancement automatique :**
- ✅ Lance le serveur backend Python (Flask)
- ✅ Attend que le backend soit prêt
- ✅ Lance le serveur frontend (Vite)
- ✅ Ouvre automatiquement l'application dans votre navigateur
- ✅ Gère la séquence de démarrage complète

**📝 Note :** Après la première installation avec `installer_dependances.bat`, vous n'aurez plus qu'à utiliser `lancer_application.bat` pour démarrer l'application.

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
- **Dépendances manquantes** : Relancez `installer_dependances.bat`

### Les scripts ne fonctionnent pas :
- **Première installation** : Utilisez d'abord `installer_dependances.bat`, puis `lancer_application.bat`
- **Python/Node.js introuvables** : Vérifiez que Python et Node.js sont installés et dans le PATH
- **Permissions** : Exécutez en tant qu'administrateur si nécessaire
- **Environnement virtuel corrompu** : Supprimez le dossier `backend/venv/` et relancez `installer_dependances.bat`

### Processus de démarrage :
1. **Installation** → `installer_dependances.bat` (une seule fois)
2. **Configuration** → Définir la clé API OpenAI
3. **Utilisation** → `lancer_application.bat` (à chaque fois)