# Générateur CCTP - Version Web

Cette application est une migration web de l'application de bureau Tkinter pour générer des CCTP.

## Architecture

-   **Backend**: Python avec le micro-framework Flask. Gère la logique métier, les appels à l'API OpenAI, la manipulation des fichiers et la génération des documents.
-   **Frontend**: JavaScript avec le framework Vue.js (via Vite). Gère l'interface utilisateur interactive dans le navigateur.

## Prérequis

-   Python 3.8+
-   Node.js 18+ et npm
-   Une clé API OpenAI

## Installation et Lancement

### 1. Cloner le projet

Clonez ce dépôt et naviguez à la racine du projet.

### 2. Configuration du Backend

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
   Créez une variable d'environnement nommée `OPENAI_API_KEY` avec votre clé.
   ```bash
   # Pour Windows (dans le terminal actuel)
   set OPENAI_API_KEY="votre_cle_ici"

   # Pour macOS/Linux (dans le terminal actuel)
   export OPENAI_API_KEY="votre_cle_ici"
   ```
   **Note :** Pour une utilisation permanente, ajoutez cette variable à votre système.

e. **Préparez les données initiales (si nécessaire) :**
   - Placez vos fichiers de polices `DejaVuSans.ttf` et `DejaVuSans-Bold.ttf` dans un dossier `backend/fonts/`.
   - Placez vos fichiers de projet `.json` dans `backend/modeles_cctp/`.
   - Placez vos fichiers PDF d'exemples dans un dossier et utilisez la fonction d'analyse (à implémenter via un endpoint API si besoin).

f. **Lancez le serveur backend :**
   ```bash
   flask run
   ```
   Le serveur devrait démarrer sur `http://127.0.0.1:5000`. Laissez ce terminal ouvert.

### 3. Configuration du Frontend

a. **Ouvrez un NOUVEAU terminal** et naviguez vers le dossier frontend :
   ```bash
   cd frontend
   ```

b. **Installez les dépendances JavaScript :**
   ```bash
   npm install
   ```

c. **Lancez le serveur de développement du frontend :**
   ```bash
   npm run dev
   ```
   Le serveur de développement Vite démarrera, généralement sur `http://localhost:5173`.

### 4. Utilisation

Ouvrez l'URL du frontend (ex: `http://localhost:5173`) dans votre navigateur. L'application web communiquera automatiquement avec votre serveur backend local.