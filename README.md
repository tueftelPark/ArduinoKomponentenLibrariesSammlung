# ArdunioKomponentenLibrariesSammlung
Dieses Repository beinhaltet eine Sammlung von Libraries von Komponenten die wir für unsere Kurse und Camps benötigen.

Hier der Link wie man Libraries in Arduino installiert: https://wiki.seeedstudio.com/How_to_install_Arduino_Library/

Libraries können auch im Bulk (alle zusammen) installiert werden, in dem man sie manuell in den entsprechenden Ordner des Installationsverzeichnis von Arduino kopiert. (...\Arduino\libraries)

Nicht vergessen die verwendeten Libraries richtig zu includen:

#include "paj7620.h"  
#include "Grove_I2C_Motor_Driver.h"  
#include "Seeed_MPR121_driver.h"  
#include <Adafruit_NeoPixel.h>  
#include "Arduino_SensorKit.h"  

## Automatische Installation (`InstallLibraries.bat`)

Wird von `SETUP.bat` / `FULL_RESET.bat` aus dem Repo [Skripte](https://github.com/tueftelPark/Skripte) aufgerufen:

1. Der Ordner `Libraries/` wird als Grundstock nach `Dokumente\Arduino\libraries` kopiert. Ohne Internet oder ohne installierte Arduino IDE bleibt es bei diesem Stand.
2. Libraries aus dem Arduino Library Manager werden in der **festgelegten Version** installiert (in `LIBS_MANAGER`, z. B. `"IRremote@4.7.1"`). Weil der Grundstock dieselben Versionen enthält, lädt das normalerweise nichts nach.
3. Libraries, die es nur auf GitHub gibt (Grove Gesture, MPR121, RGB LED Matrix), werden direkt vom neuesten Stand ihres Repos geladen.

**Nur bei Änderungen herunterladen:** Vor dem Download fragt das Skript mit `git ls-remote` den neuesten Commit dieser Sammlung und der GitHub-Libraries ab (wenige Bytes). Hat sich seit dem letzten erfolgreichen Lauf nichts geändert, gleicht es `Dokumente\Arduino\libraries` nur mit einer lokalen Kopie ab (`%LOCALAPPDATA%\TueftelPark\LibrariesStand`, mit `robocopy /MIR`): geänderte Dateien werden ersetzt, im Kurs dazugekommene Libraries entfernt. Kein Download, auch nicht der Library-Index. Ist Git nicht da oder kein Internet, läuft alles wie oben beschrieben.

**Library aktualisieren:** Version in `LIBS_MANAGER` erhöhen **und** den Ordner in `Libraries/` durch dieselbe Version ersetzen (z. B. in der Arduino IDE installieren und aus `Dokumente\Arduino\libraries` hineinkopieren). Nach dem Push lädt jeder Laptop beim nächsten SETUP einmal neu.

**Neue Library hinzufügen:** oben in `InstallLibraries.bat` in `LIBS_MANAGER` (Name wie im Library Manager, mit `@Version`) oder `LIBS_GITHUB` eintragen **und** den Ordner in `Libraries/` ablegen.
