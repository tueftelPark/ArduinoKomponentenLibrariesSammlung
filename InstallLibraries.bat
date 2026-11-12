@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo   Arduino Libraries Downloader und Installer (Auto-Mode)
echo ========================================================
echo.

:: ---------------- Welche Libraries? ----------------
:: Aus dem Arduino Library Manager - installiert wird immer die neueste Version.
:: Bricht ein Update einmal Kurs-Sketches, laesst sich eine Version festhalten:
:: "IRremote@4.7.1" statt "IRremote".
set LIBS_MANAGER="Adafruit NeoPixel" "Arduino_Sensorkit" "DHT20" "Gesture PAJ7620" "Grove-3-Axis-Digital-Accelerometer-2g-to-16g-LIS3DHTR" "Grove I2C Motor Driver v1.3" "Grove Ultrasonic Ranger" "IRremote" "NewPing"
:: Nicht im Library Manager - direkt der neueste Stand von GitHub.
:: Format: "Ordnername#Besitzer/Repo#Branch"
set LIBS_GITHUB="Grove_Gesture-master#Seeed-Studio/Grove_Gesture#master" "Grove_touch_sensor_MPR121-master#Seeed-Studio/Seeed_MRP121#master" "Seeed_RGB_Led_Matrix#Seeed-Studio/Seeed_RGB_LED_Matrix#master"
:: Neue Library: in eine der beiden Listen eintragen UND in den Ordner Libraries\
:: legen - der Ordner ist der Grundstock, falls kein Internet oder keine IDE da ist.

:: Pfade definieren
set "SAMMLUNG_REPO=tueftelPark/ArduinoKomponentenLibrariesSammlung"
set "REPO_URL=https://github.com/%SAMMLUNG_REPO%/archive/refs/heads/main.zip"
set "TEMP_ZIP=%TEMP%\ArduinoLibsRepo.zip"
set "TEMP_EXTRACT=%TEMP%\ArduinoLibsExtract"
set "TEMP_LIB=%TEMP%\ArduinoLibEinzeln"
set "ARDUINO_LIB_PATH=%USERPROFILE%\Documents\Arduino\libraries"
set "IDE_DIR=%LOCALAPPDATA%\Programs\Arduino IDE"
:: Lokale Kopie des letzten vollstaendigen Stands - damit nur heruntergeladen wird,
:: wenn sich auf GitHub wirklich etwas geaendert hat.
set "STAND_DIR=%LOCALAPPDATA%\TueftelPark\LibrariesStand"
set "KOPIE_LIBS=%STAND_DIR%\libraries"
set "STAND_DATEI=%STAND_DIR%\stand.txt"
set "WARNUNGEN=0"
set "AUS_KOPIE="

:: Alten temporaeren Entpack-Ordner leeren, falls er noch existiert
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"

:: 1. Stand pruefen: Hat sich die Sammlung oder eine GitHub-Library seit dem letzten
:: Lauf geaendert? git ls-remote fragt nur den neuesten Commit ab (wenige Bytes).
:: Unveraendert -> Libraries aus der lokalen Kopie einspielen, ohne Download.
:: Der Ordner wird trotzdem frisch eingespielt, Aenderungen aus dem Kurs verschwinden.
echo [1/6] Pruefe, ob sich an den Libraries etwas geaendert hat...
call :stand_ermitteln
set "STAND_ALT="
if exist "%STAND_DATEI%" set /p STAND_ALT=<"%STAND_DATEI%"
if defined STAND_NEU if exist "%KOPIE_LIBS%\*" if "!STAND_NEU!"=="!STAND_ALT!" goto aus_kopie
if defined STAND_NEU (
    echo        -^> Neuer Stand auf GitHub - wird heruntergeladen.
) else (
    echo        -^> Stand nicht pruefbar - wird zur Sicherheit heruntergeladen.
)

:: 2. Herunterladen
echo [2/6] Lade die Library-Sammlung von GitHub herunter...
curl -fsSL -o "%TEMP_ZIP%" "%REPO_URL%"
if %errorlevel% neq 0 (
    echo [FEHLER] Herunterladen fehlgeschlagen. Die bisherigen Libraries bleiben unveraendert.
    exit /b
)

:: 3. Entpacken und den Libraries-Ordner finden
echo [3/6] Entpacke die heruntergeladene ZIP-Datei...
powershell -NoProfile -command "Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%TEMP_EXTRACT%' -Force"
set "SOURCE_LIBS="
for /D %%I in ("%TEMP_EXTRACT%\*") do set "SOURCE_LIBS=%%I\Libraries"
if not exist "%SOURCE_LIBS%" (
    echo [FEHLER] Der Ordner 'Libraries' wurde nicht gefunden.
    echo          Die bisherigen Libraries bleiben unveraendert.
    goto aufraeumen
)

:: 4. Grundstock: Ordner leeren und die Kopien aus dem Repository einspielen.
:: Erst hier wird geleert - der neue Stand liegt sicher entpackt bereit.
echo [4/6] Spiele den Grundstock ein...
if exist "%ARDUINO_LIB_PATH%" rmdir /S /Q "%ARDUINO_LIB_PATH%"
mkdir "%ARDUINO_LIB_PATH%"
xcopy "%SOURCE_LIBS%\*" "%ARDUINO_LIB_PATH%\" /E /H /C /I /Y >nul
echo        -^> Grundstock installiert.
goto manager

:aus_kopie
echo        -^> Unveraendert seit dem letzten Mal - kein Download noetig.
echo [2-4/6] Spiele die Libraries aus der lokalen Kopie ein...
if exist "%ARDUINO_LIB_PATH%" rmdir /S /Q "%ARDUINO_LIB_PATH%"
mkdir "%ARDUINO_LIB_PATH%"
xcopy "%KOPIE_LIBS%\*" "%ARDUINO_LIB_PATH%\" /E /H /C /I /Y >nul
echo        -^> Libraries eingespielt.
set "AUS_KOPIE=1"

:manager
:: 5. Library Manager: auf die neuesten Versionen aktualisieren. arduino-cli laedt
:: nur, wenn es eine neuere Version gibt - aus der lokalen Kopie meist gar nichts.
:: arduino-cli liegt in der Arduino IDE 2 bei; der genaue Unterordner wechselt
:: zwischen IDE-Versionen, darum wird gesucht statt ein Pfad fest eingetragen.
echo [5/6] Aktualisiere Libraries aus dem Arduino Library Manager...
set "ARDUINO_CLI="
if exist "%IDE_DIR%\resources" (
    for /R "%IDE_DIR%\resources" %%F in (arduino-cli.exe) do if exist "%%F" set "ARDUINO_CLI=%%F"
)
if not defined ARDUINO_CLI (
    echo        [WARNUNG] Arduino IDE nicht gefunden - es bleibt beim Grundstock.
    set /a WARNUNGEN+=1
    goto github
)
"%ARDUINO_CLI%" lib update-index >nul 2>&1
if errorlevel 1 (
    echo        [WARNUNG] Library Manager nicht erreichbar - es bleibt beim Grundstock.
    set /a WARNUNGEN+=1
    goto github
)
for %%L in (%LIBS_MANAGER%) do call :manager_lib %%L

:github
:: 6. Libraries, die es nur auf GitHub gibt. Aus der lokalen Kopie sind sie schon
:: aktuell - ihr Stand gehoert zur Pruefung in Schritt 1.
if defined AUS_KOPIE (
    echo [6/6] Libraries von GitHub sind unveraendert - kein Download noetig.
) else (
    echo [6/6] Aktualisiere Libraries direkt von GitHub...
    for %%G in (%LIBS_GITHUB%) do call :github_lib %%G
)

:: Lokale Kopie fuer das naechste Mal aktualisieren - nur wenn alles geklappt hat,
:: sonst wird beim naechsten Lauf wieder vollstaendig heruntergeladen.
if !WARNUNGEN! equ 0 if defined STAND_NEU call :kopie_speichern

echo.
if !WARNUNGEN! equ 0 (
    echo [ERFOLG] Alle Libraries sind auf dem neuesten Stand:
) else (
    echo [FERTIG] Libraries installiert, !WARNUNGEN! davon aus dem Grundstock statt neuester Version:
)
echo %ARDUINO_LIB_PATH%

:aufraeumen
echo.
echo Raeume temporaere Dateien auf...
if exist "%TEMP_ZIP%" del "%TEMP_ZIP%"
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"
if exist "%TEMP_LIB%" rmdir /S /Q "%TEMP_LIB%"
:: Kein "pause" am Ende -> Das Fenster schliesst sich nun sofort.
exit /b


:: ---------------- Unterprogramme ----------------

:: Ermittelt den aktuellen Stand auf GitHub: neuester Commit der Sammlung (enthaelt
:: auch dieses Skript und die Listen oben) und jeder GitHub-Library. Ergebnis in
:: STAND_NEU; leer, wenn etwas nicht abgefragt werden konnte (kein Git/Internet).
:stand_ermitteln
set "STAND_NEU="
set "GIT=%LOCALAPPDATA%\TueftelPark\MinGit\cmd\git.exe"
if not exist "%GIT%" set "GIT=git"
:: Nie nach Zugangsdaten fragen (z. B. wenn ein Repo umbenannt wurde) - sonst haengt SETUP.
set "GIT_TERMINAL_PROMPT=0"
call :sha_holen "%SAMMLUNG_REPO%" "main"
if not defined SHA exit /b
set "STAND=sammlung:!SHA!"
for %%G in (%LIBS_GITHUB%) do (
    for /f "tokens=2,3 delims=#" %%b in ("%%~G") do call :sha_holen "%%b" "%%c"
    if not defined SHA exit /b
    set "STAND=!STAND!+%%~G:!SHA!"
)
set "STAND_NEU=!STAND!"
exit /b

:: Neuester Commit eines Branches, ohne etwas herunterzuladen. Ergebnis in SHA.
:sha_holen
set "SHA="
for /f "tokens=1" %%S in ('call "%GIT%" -c credential.helper^= ls-remote "https://github.com/%~1.git" "refs/heads/%~2" 2^>nul') do set "SHA=%%S"
exit /b

:: Den fertigen Libraries-Ordner als lokale Kopie ablegen und den Stand merken.
:kopie_speichern
if not exist "%STAND_DIR%" mkdir "%STAND_DIR%"
if exist "%STAND_DATEI%" del "%STAND_DATEI%"
if exist "%KOPIE_LIBS%" rmdir /S /Q "%KOPIE_LIBS%"
xcopy "%ARDUINO_LIB_PATH%\*" "%KOPIE_LIBS%\" /E /H /C /I /Y >nul
if errorlevel 1 (
    echo        [INFO] Lokale Kopie konnte nicht gespeichert werden - naechstes Mal wird neu geladen.
    exit /b
)
> "%STAND_DATEI%" echo !STAND_NEU!
exit /b

:: Eine Library aus dem Library Manager in der neuesten Version installieren.
:: Liegt sie schon als Grundstock vor, ersetzt arduino-cli sie (oder meldet
:: "bereits installiert", wenn der Grundstock schon aktuell ist).
:manager_lib
"%ARDUINO_CLI%" lib install %1 >nul 2>&1
if errorlevel 1 (
    echo        [WARNUNG] %~1 - Update fehlgeschlagen, Grundstock bleibt
    set /a WARNUNGEN+=1
) else (
    echo        -^> %~1
)
exit /b

:: Eine Library als ZIP des Branches von GitHub laden und den Grundstock-Ordner
:: ersetzen. Klappt der Download nicht, bleibt der Grundstock stehen.
:github_lib
for /f "tokens=1-3 delims=#" %%a in ("%~1") do (
    set "LIB_ORDNER=%%a"
    set "LIB_REPO=%%b"
    set "LIB_BRANCH=%%c"
)
if exist "%TEMP_LIB%" rmdir /S /Q "%TEMP_LIB%"
mkdir "%TEMP_LIB%"
curl -fsSL -o "%TEMP_LIB%\lib.zip" "https://github.com/!LIB_REPO!/archive/refs/heads/!LIB_BRANCH!.zip"
if errorlevel 1 (
    echo        [WARNUNG] !LIB_ORDNER! - Download fehlgeschlagen, Grundstock bleibt
    set /a WARNUNGEN+=1
    exit /b
)
powershell -NoProfile -command "Expand-Archive -Path '%TEMP_LIB%\lib.zip' -DestinationPath '%TEMP_LIB%\x' -Force"
set "LIB_QUELLE="
for /D %%D in ("%TEMP_LIB%\x\*") do set "LIB_QUELLE=%%D"
if not exist "!LIB_QUELLE!\library.properties" (
    echo        [WARNUNG] !LIB_ORDNER! - ZIP unvollstaendig, Grundstock bleibt
    set /a WARNUNGEN+=1
    exit /b
)
if exist "%ARDUINO_LIB_PATH%\!LIB_ORDNER!" rmdir /S /Q "%ARDUINO_LIB_PATH%\!LIB_ORDNER!"
xcopy "!LIB_QUELLE!\*" "%ARDUINO_LIB_PATH%\!LIB_ORDNER!\" /E /H /C /I /Y >nul
echo        -^> !LIB_ORDNER! (GitHub: !LIB_REPO!)
exit /b
