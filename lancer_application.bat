@echo off
TITLE Generateur CCTP - Lanceur

REM --- Determination du repertoire du script ---
SET SCRIPT_DIR=%~dp0
ECHO Repertoire du script: %SCRIPT_DIR%

ECHO Lancement du Generateur CCTP...
ECHO.

REM --- Etape 1: Verification et lancement du serveur Backend ---
ECHO --- Verification de l'environnement Backend...

REM Verification que le dossier backend existe
IF NOT EXIST "%SCRIPT_DIR%backend" (
    ECHO ERREUR: Le dossier backend n'existe pas !
    ECHO Chemin recherche: %SCRIPT_DIR%backend
    PAUSE
    EXIT /B 1
)

REM Verification que l'environnement virtuel existe
IF NOT EXIST "%SCRIPT_DIR%backend\venv\Scripts\activate.bat" (
    ECHO ERREUR: L'environnement virtuel Python n'existe pas !
    ECHO Chemin recherche: %SCRIPT_DIR%backend\venv\Scripts\activate.bat
    ECHO.
    ECHO Pour resoudre ce probleme:
    ECHO 1. Ouvrez un terminal dans le dossier backend
    ECHO 2. Executez: python -m venv venv
    ECHO 3. Puis: venv\Scripts\activate.bat
    ECHO 4. Et enfin: pip install -r requirements.txt
    PAUSE
    EXIT /B 1
)

REM Verification que app.py existe
IF NOT EXIST "%SCRIPT_DIR%backend\app.py" (
    ECHO ERREUR: Le fichier app.py n'existe pas dans le dossier backend !
    PAUSE
    EXIT /B 1
)

ECHO --- Lancement du serveur Backend (Python)...
START "Backend Server" cmd /k "cd /d "%SCRIPT_DIR%backend" && call venv\Scripts\activate.bat && set FLASK_APP=app.py && python -m flask run"

REM --- Etape 2: Boucle d'attente active du serveur Backend ---
ECHO --- En attente du demarrage complet du serveur Backend (port 5000)...
:checkloop
ECHO    Verification...
REM La commande "netstat" verifie les connexions reseau.
REM On cherche une ligne contenant ":5000" et l'etat "LISTENING".
netstat -an | findstr ":5000" | findstr "LISTENING" > nul
REM Si la commande precedente n'a rien trouve (errorlevel n'est pas 0), on attend et on recommence.
if %errorlevel% neq 0 (
    timeout /t 1 /nobreak > nul
    goto checkloop
)

ECHO.
ECHO --- Serveur Backend detecte ! Verification et lancement du Frontend. ---

REM Verification que le dossier frontend existe
IF NOT EXIST "%SCRIPT_DIR%frontend" (
    ECHO ERREUR: Le dossier frontend n'existe pas !
    ECHO Chemin recherche: %SCRIPT_DIR%frontend
    PAUSE
    EXIT /B 1
)

REM Verification que package.json existe
IF NOT EXIST "%SCRIPT_DIR%frontend\package.json" (
    ECHO ERREUR: Le fichier package.json n'existe pas dans le dossier frontend !
    PAUSE
    EXIT /B 1
)

REM --- Etape 3: Lancement du serveur Frontend maintenant que le Backend est pret ---
START "Frontend Server" cmd /k "cd /d "%SCRIPT_DIR%frontend" && npm run dev"

REM --- Etape 4: Ouverture de l'application dans le navigateur ---
ECHO --- Ouverture de l'application dans le navigateur...
REM Petite pause supplementaire pour que le serveur frontend demarre.
timeout /t 5 > nul
START http://localhost:5173

ECHO.
ECHO =========================================================================
ECHO L'application est lancee.
ECHO IMPORTANT: Veuillez laisser les deux fenetres de terminal ouvertes
ECHO            pour que l'application continue de fonctionner.
ECHO =========================================================================
ECHO.