@echo off
TITLE Installation des dependances - Generateur CCTP

REM --- Determination du repertoire du script ---
SET SCRIPT_DIR=%~dp0
ECHO Repertoire du projet: %SCRIPT_DIR%

ECHO =========================================================================
ECHO Installation automatique des dependances pour le Generateur CCTP
ECHO =========================================================================
ECHO.

REM --- Verification de Python ---
ECHO --- Verification de Python...
python --version >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    ECHO ERREUR: Python n'est pas installe ou pas dans le PATH !
    ECHO Veuillez installer Python depuis https://python.org
    PAUSE
    EXIT /B 1
)
python --version

REM --- Verification de Node.js ---
ECHO --- Verification de Node.js...
node --version >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    ECHO ERREUR: Node.js n'est pas installe ou pas dans le PATH !
    ECHO Veuillez installer Node.js depuis https://nodejs.org
    PAUSE
    EXIT /B 1
)
node --version
npm --version

ECHO.
ECHO --- Installation des dependances Backend (Python)...
cd /d "%SCRIPT_DIR%backend"

REM Creation de l'environnement virtuel
IF NOT EXIST "venv" (
    ECHO Creation de l'environnement virtuel Python...
    python -m venv venv
    IF %ERRORLEVEL% NEQ 0 (
        ECHO ERREUR: Impossible de creer l'environnement virtuel !
        PAUSE
        EXIT /B 1
    )
)

REM Activation et installation des packages
ECHO Activation de l'environnement virtuel et installation des packages...
call venv\Scripts\activate.bat
pip install --upgrade pip
pip install -r requirements.txt
IF %ERRORLEVEL% NEQ 0 (
    ECHO ERREUR: Impossible d'installer les dependances Python !
    PAUSE
    EXIT /B 1
)

ECHO.
ECHO --- Installation des dependances Frontend (Node.js)...
cd /d "%SCRIPT_DIR%frontend"

REM Installation des packages npm
ECHO Installation des packages npm...
npm install
IF %ERRORLEVEL% NEQ 0 (
    ECHO ERREUR: Impossible d'installer les dependances Node.js !
    PAUSE
    EXIT /B 1
)

ECHO.
ECHO =========================================================================
ECHO Installation terminee avec succes !
ECHO.
ECHO Vous pouvez maintenant lancer l'application avec:
ECHO   lancer_application.bat
ECHO =========================================================================
PAUSE
