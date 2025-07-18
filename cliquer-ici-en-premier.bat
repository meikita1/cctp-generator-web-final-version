@echo off
TITLE Generateur CCTP - Lanceur (Version Debug)

ECHO Lancement du Generateur CCTP...
ECHO.

REM --- Verification de l'existence des repertoires ---
ECHO --- Verification des repertoires...
IF NOT EXIST "backend" (
    ECHO ERREUR: Le repertoire 'backend' n'existe pas !
    PAUSE
    EXIT /B 1
)

IF NOT EXIST "frontend" (
    ECHO ERREUR: Le repertoire 'frontend' n'existe pas !
    PAUSE
    EXIT /B 1
)

CD backend
IF NOT EXIST "venv" (
    ECHO --- Creation de l'environnement virtuel Python...
    python -m venv venv
    IF %ERRORLEVEL% NEQ 0 (
        ECHO ERREUR: Impossible de creer l'environnement virtuel !
        ECHO Verifiez que Python est installe et accessible.
        PAUSE
        EXIT /B 1
    )
)

IF NOT EXIST "venv\Scripts\activate.bat" (
    ECHO ERREUR: L'environnement virtuel n'est pas correctement installe !
    PAUSE
    EXIT /B 1
)

ECHO --- Installation des dependances Python...
venv\Scripts\pip install -r requirements.txt
IF %ERRORLEVEL% NEQ 0 (
    ECHO ERREUR: Impossible d'installer les dependances Python !
    PAUSE
    EXIT /B 1
)

CD ..

REM --- Etape 1: Lancement du serveur Backend en arriere-plan ---
ECHO --- Lancement du serveur Backend (Python)...
START "Backend Server" cmd /k "cd backend && call venv\Scripts\activate.bat && set FLASK_APP=app.py && python -m flask run"

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
ECHO --- Serveur Backend detecte ! Lancement du Frontend. ---

REM --- Verification de npm ---
CD frontend
ECHO --- Installation des dependances frontend...
npm install
IF %ERRORLEVEL% NEQ 0 (
    ECHO ERREUR: Impossible d'installer les dependances frontend !
    ECHO Verifiez que Node.js et npm sont installes.
    PAUSE
    EXIT /B 1
)

CD ..

REM --- Etape 3: Lancement du serveur Frontend maintenant que le Backend est pret ---
START "Frontend Server" cmd /k "cd frontend && npm run dev"

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

PAUSE
