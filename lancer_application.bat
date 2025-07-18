@echo off
TITLE Generateur CCTP - Lanceur

ECHO Lancement du Generateur CCTP...
ECHO.

REM --- Etape 1: Lancement du serveur Backend en arriere-plan ---
ECHO --- Lancement du serveur Backend (Python)...
START "Backend Server" cmd /k "cd backend && call .\\venv\\Scripts\\activate.bat && set FLASK_APP=app.py && python -m flask run"

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