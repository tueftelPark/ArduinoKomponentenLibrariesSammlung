@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo   Arduino Libraries Downloader und Installer
echo ========================================================
echo.

:: Pfade definieren
set "REPO_URL=https://github.com/tueftelPark/ArduinoKomponentenLibrariesSammlung/archive/refs/heads/main.zip"
set "TEMP_ZIP=%TEMP%\ArduinoLibsRepo.zip"
set "TEMP_EXTRACT=%TEMP%\ArduinoLibsExtract"
set "ARDUINO_LIB_PATH=%USERPROFILE%\Documents\Arduino\libraries"

:: Sicherheitswarnung vor dem Loeschen
echo [ACHTUNG] Der folgende Ordner wird jetzt komplett geleert:
echo           -^> %ARDUINO_LIB_PATH%
echo.
echo           Alle darin enthaltenen, bisherigen Libraries gehen verloren!
echo           Schliesse dieses Fenster oder druecke STRG+C zum Abbrechen.
echo           Um fortzufahren und alles zu ueberschreiben...
pause

:: Zielordner leeren und neu erstellen
if exist "%ARDUINO_LIB_PATH%" (
    echo.
    echo [INFO] Leere den bestehenden Arduino Library Ordner...
    rmdir /S /Q "%ARDUINO_LIB_PATH%"
)
echo [INFO] (Neu-)Erstellung des Arduino Library Ordners...
mkdir "%ARDUINO_LIB_PATH%"

:: Alten temporaeren Entpack-Ordner leeren, falls er noch existiert
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"

:: 1. Herunterladen (nutzt das in Windows integrierte 'curl')
echo.
echo [1/4] Lade das Repository von GitHub herunter...
curl -L -s -o "%TEMP_ZIP%" "%REPO_URL%"
if %errorlevel% neq 0 (
    echo [FEHLER] Herunterladen fehlgeschlagen. Bitte Internetverbindung pruefen.
    pause
    exit /b
)

:: 2. Entpacken (nutzt Windows-internes PowerShell fuer die ZIP-Verarbeitung)
echo [2/4] Entpacke die heruntergeladene ZIP-Datei...
powershell -command "Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%TEMP_EXTRACT%' -Force"

:: 3. Den richtigen Unterordner finden
echo [3/4] Suche nach dem 'Libraries'-Ordner...
set "SOURCE_LIBS="
for /D %%I in ("%TEMP_EXTRACT%\*") do (
    set "SOURCE_LIBS=%%I\Libraries"
)

:: 4. Kopieren mit Pfad-Ausgabe
if exist "%SOURCE_LIBS%" (
    echo [4/4] Kopiere die Libraries...
    echo        -^> ZIELPFAD: %ARDUINO_LIB_PATH%
    xcopy "%SOURCE_LIBS%\*" "%ARDUINO_LIB_PATH%\" /E /H /C /I /Y >nul
    echo.
    echo ========================================================
    echo   Installation ERFOLGREICH abgeschlossen!
    echo   Alle alten Libraries wurden entfernt und die neuen
    echo   wurden in folgenden Ordner kopiert:
    echo   %ARDUINO_LIB_PATH%
    echo ========================================================
) else (
    echo.
    echo [FEHLER] Der Ordner 'Libraries' wurde im heruntergeladenen Repository nicht gefunden.
)

:: 5. Aufraeumen (Temporaere Dateien loeschen)
echo.
echo Raeume temporaere Dateien auf...
del "%TEMP_ZIP%"
rmdir /S /Q "%TEMP_EXTRACT%"

echo Fertig!
pause