@echo off
TITLE Test de lancement - Generateur CCTP

REM --- Determination du repertoire du script ---
SET SCRIPT_DIR=%~dp0
ECHO Repertoire du script: %SCRIPT_DIR%
ECHO.

ECHO =========================================================================
ECHO Test de diagnostic du lancement
ECHO =========================================================================
ECHO.

REM --- Test 1: Verification des dossiers ---
ECHO --- Test 1: Verification de la structure des dossiers ---
IF EXIST "%SCRIPT_DIR%backend" (
    ECHO ✓ Dossier backend: OK
) ELSE (
    ECHO ✗ Dossier backend: MANQUANT
)

IF EXIST "%SCRIPT_DIR%frontend" (
    ECHO ✓ Dossier frontend: OK
) ELSE (
    ECHO ✗ Dossier frontend: MANQUANT
)

IF EXIST "%SCRIPT_DIR%backend\venv" (
    ECHO ✓ Environnement virtuel: OK
) ELSE (
    ECHO ✗ Environnement virtuel: MANQUANT
)

IF EXIST "%SCRIPT_DIR%backend\app.py" (
    ECHO ✓ Fichier app.py: OK
) ELSE (
    ECHO ✗ Fichier app.py: MANQUANT
)

IF EXIST "%SCRIPT_DIR%frontend\package.json" (
    ECHO ✓ Fichier package.json: OK
) ELSE (
    ECHO ✗ Fichier package.json: MANQUANT
)

ECHO.

REM --- Test 2: Test Python ---
ECHO --- Test 2: Test de l'environnement Python ---
cd /d "%SCRIPT_DIR%backend"
ECHO Dossier actuel: %CD%

ECHO Test d'activation de l'environnement virtuel...
call venv\Scripts\activate.bat
IF %ERRORLEVEL% NEQ 0 (
    ECHO ✗ ERREUR: Impossible d'activer l'environnement virtuel
) ELSE (
    ECHO ✓ Environnement virtuel active
    
    ECHO Test de Flask...
    python -c "import flask; print('Flask version:', flask.__version__)"
    IF %ERRORLEVEL% NEQ 0 (
        ECHO ✗ ERREUR: Flask n'est pas installe ou ne fonctionne pas
    ) ELSE (
        ECHO ✓ Flask fonctionne
    )
    
    ECHO Test du fichier app.py...
    python -c "import app; print('app.py importe avec succes')"
    IF %ERRORLEVEL% NEQ 0 (
        ECHO ✗ ERREUR: Probleme avec app.py
    ) ELSE (
        ECHO ✓ app.py fonctionne
    )
)

ECHO.

REM --- Test 3: Test Node.js ---
ECHO --- Test 3: Test de l'environnement Node.js ---
cd /d "%SCRIPT_DIR%frontend"
ECHO Dossier actuel: %CD%

ECHO Test de Node.js...
node --version
IF %ERRORLEVEL% NEQ 0 (
    ECHO ✗ ERREUR: Node.js non disponible
) ELSE (
    ECHO ✓ Node.js fonctionne
)

ECHO Test de npm...
npm --version
IF %ERRORLEVEL% NEQ 0 (
    ECHO ✗ ERREUR: npm non disponible
) ELSE (
    ECHO ✓ npm fonctionne
)

IF EXIST "node_modules" (
    ECHO ✓ Modules Node.js installes
) ELSE (
    ECHO ✗ Modules Node.js manquants
)

ECHO.
ECHO =========================================================================
ECHO Test termine. Analysez les resultats ci-dessus.
ECHO Si tout est OK, essayez lancer_application.bat
ECHO =========================================================================
PAUSE
