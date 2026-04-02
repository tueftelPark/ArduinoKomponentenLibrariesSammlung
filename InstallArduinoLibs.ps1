# Definition der Pfade und URLs
# Wir laden den 'main'-Branch als ZIP-Datei herunter
$repoUrl = "https://github.com/tueftelPark/ArduinoKomponentenLibrariesSammlung/archive/refs/heads/main.zip"
$tempZip = Join-Path $env:TEMP "ArduinoLibsRepo.zip"
$tempExtract = Join-Path $env:TEMP "ArduinoLibsExtract"

# Der Standard-Pfad für Arduino Libraries unter Windows (Dokumente\Arduino\libraries)
$docsPath = [Environment]::GetFolderPath("MyDocuments")
$arduinoLibPath = Join-Path $docsPath "Arduino\libraries"

Write-Host "Starte den Download und Installationsprozess..." -ForegroundColor Cyan

# Sicherstellen, dass der Arduino-Library-Ordner existiert
if (!(Test-Path -Path $arduinoLibPath)) {
    Write-Host "Erstelle Arduino Library Ordner unter: $arduinoLibPath"
    New-Item -ItemType Directory -Path $arduinoLibPath | Out-Null
}

# Temporären Entpack-Ordner leeren, falls er vom letzten Mal noch existiert
if (Test-Path -Path $tempExtract) {
    Remove-Item -Path $tempExtract -Recurse -Force
}

# 1. Herunterladen
Write-Host "Lade das Repository von GitHub herunter..."
try {
    Invoke-WebRequest -Uri $repoUrl -OutFile $tempZip
} catch {
    Write-Host "Fehler beim Herunterladen. Bitte Internetverbindung prüfen." -ForegroundColor Red
    exit
}

# 2. Entpacken
Write-Host "Entpacke die heruntergeladene ZIP-Datei..."
Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

# 3. Den richtigen Unterordner finden
# GitHub packt den Inhalt meistens in einen Ordner wie "RepoName-main"
$extractedRepoFolder = Get-ChildItem -Path $tempExtract -Directory | Select-Object -First 1
$sourceLibsPath = Join-Path $extractedRepoFolder.FullName "Libraries"

# 4. Kopieren
if (Test-Path -Path $sourceLibsPath) {
    Write-Host "Kopiere die Libraries in den Arduino-Ordner ($arduinoLibPath)..."
    Copy-Item -Path "$sourceLibsPath\*" -Destination $arduinoLibPath -Recurse -Force
    Write-Host "Installation erfolgreich abgeschlossen!" -ForegroundColor Green
} else {
    Write-Host "Fehler: Der Ordner 'Libraries' wurde im Repository nicht gefunden. Hat sich die Ordnerstruktur auf GitHub geändert?" -ForegroundColor Red
}

# 5. Aufräumen (Temporäre Dateien löschen)
Write-Host "Räume temporäre Dateien auf..."
Remove-Item -Path $tempZip -Force
Remove-Item -Path $tempExtract -Recurse -Force

Write-Host "Fertig. Du kannst dieses Fenster nun schließen."