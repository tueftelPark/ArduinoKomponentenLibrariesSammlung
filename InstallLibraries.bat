@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo   Arduino Libraries Downloader und Installer (Auto-Mode)
echo ========================================================
echo.

:: Pfade definieren
set "REPO_URL=https://github.com/tueftelPark/ArduinoKomponentenLibrariesSammlung/archive/refs/heads/main.zip"
set "TEMP_ZIP=%TEMP%\ArduinoLibsRepo.zip"
set "TEMP_EXTRACT=%TEMP%\ArduinoLibsExtract"
set "ARDUINO_LIB_PATH=%USERPROFILE%\Documents\Arduino\libraries"

:: Alten temporaeren Entpack-Ordner leeren, falls er noch existiert
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"

:: 1. Herunterladen
echo.
echo [1/4] Lade das Repository von GitHub herunter...
curl -fsSL -o "%TEMP_ZIP%" "%REPO_URL%"
if %errorlevel% neq 0 (
    echo [FEHLER] Herunterladen fehlgeschlagen. Beende Skript.
    :: Schliesst das Skript bei einem Fehler automatisch
    exit /b
)

:: 2. Entpacken
echo [2/4] Entpacke die heruntergeladene ZIP-Datei...
powershell -command "Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%TEMP_EXTRACT%' -Force"

:: 3. Den richtigen Unterordner finden
echo [3/4] Suche nach dem 'Libraries'-Ordner...
set "SOURCE_LIBS="
for /D %%I in ("%TEMP_EXTRACT%\*") do (
    set "SOURCE_LIBS=%%I\Libraries"
)

:: 4. Kopieren
:: Der bestehende Library-Ordner wird erst hier geleert, wenn der neue Stand
:: sicher entpackt bereitliegt - ohne Internet bleiben die alten Libraries stehen.
if exist "%SOURCE_LIBS%" (
    echo [4/4] Ersetze die Libraries...
    if exist "%ARDUINO_LIB_PATH%" rmdir /S /Q "%ARDUINO_LIB_PATH%"
    mkdir "%ARDUINO_LIB_PATH%"
    xcopy "%SOURCE_LIBS%\*" "%ARDUINO_LIB_PATH%\" /E /H /C /I /Y >nul
    echo.
    echo [ERFOLG] Alle Libraries wurden installiert in:
    echo %ARDUINO_LIB_PATH%
) else (
    echo.
    echo [FEHLER] Der Ordner 'Libraries' wurde nicht gefunden.
    echo          Die bisherigen Libraries wurden nicht veraendert.
)

:: 5. Aufraeumen (Temporaere Dateien loeschen)
echo.
echo Raeume temporaere Dateien auf...
if exist "%TEMP_ZIP%" del "%TEMP_ZIP%"
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"

:: Kein "pause" am Ende -> Das Fenster schliesst sich nun sofort.