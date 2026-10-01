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
set "REPO_URL=https://github.com/tueftelPark/ArduinoKomponentenLibrariesSammlung/archive/refs/heads/main.zip"
set "TEMP_ZIP=%TEMP%\ArduinoLibsRepo.zip"
set "TEMP_EXTRACT=%TEMP%\ArduinoLibsExtract"
set "TEMP_LIB=%TEMP%\ArduinoLibEinzeln"
set "ARDUINO_LIB_PATH=%USERPROFILE%\Documents\Arduino\libraries"
set "IDE_DIR=%LOCALAPPDATA%\Programs\Arduino IDE"
set "WARNUNGEN=0"

:: Alten temporaeren Entpack-Ordner leeren, falls er noch existiert
if exist "%TEMP_EXTRACT%" rmdir /S /Q "%TEMP_EXTRACT%"

:: 1. Herunterladen
echo [1/5] Lade die Library-Sammlung von GitHub herunter...
curl -fsSL -o "%TEMP_ZIP%" "%REPO_URL%"
if %errorlevel% neq 0 (
    echo [FEHLER] Herunterladen fehlgeschlagen. Die bisherigen Libraries bleiben unveraendert.
    exit /b
)

:: 2. Entpacken und den Libraries-Ordner finden
echo [2/5] Entpacke die heruntergeladene ZIP-Datei...
powershell -NoProfile -command "Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%TEMP_EXTRACT%' -Force"
set "SOURCE_LIBS="
for /D %%I in ("%TEMP_EXTRACT%\*") do set "SOURCE_LIBS=%%I\Libraries"
if not exist "%SOURCE_LIBS%" (
    echo [FEHLER] Der Ordner 'Libraries' wurde nicht gefunden.
    echo          Die bisherigen Libraries bleiben unveraendert.
    goto aufraeumen
)

:: 3. Grundstock: Ordner leeren und die Kopien aus dem Repository einspielen.
:: Erst hier wird geleert - der neue Stand liegt sicher entpackt bereit.
echo [3/5] Spiele den Grundstock ein...
if exist "%ARDUINO_LIB_PATH%" rmdir /S /Q "%ARDUINO_LIB_PATH%"
mkdir "%ARDUINO_LIB_PATH%"
xcopy "%SOURCE_LIBS%\*" "%ARDUINO_LIB_PATH%\" /E /H /C /I /Y >nul
echo        -^> Grundstock installiert.

:: 4. Library Manager: auf die neuesten Versionen aktualisieren.
:: arduino-cli liegt in der Arduino IDE 2 bei; der genaue Unterordner wechselt
:: zwischen IDE-Versionen, darum wird gesucht statt ein Pfad fest eingetragen.
echo [4/5] Aktualisiere Libraries aus dem Arduino Library Manager...
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
:: 5. Libraries, die es nur auf GitHub gibt
echo [5/5] Aktualisiere Libraries direkt von GitHub...
for %%G in (%LIBS_GITHUB%) do call :github_lib %%G

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
