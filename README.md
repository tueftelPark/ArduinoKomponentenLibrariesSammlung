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

Wird von `SETUP.bat` / `FULL_RESET.bat` aus dem Repo [Skripte](https://github.com/tueftelPark/Skripte) aufgerufen und installiert immer die **neueste Version** jeder Library:

1. Der Ordner `Libraries/` wird als Grundstock nach `Dokumente\Arduino\libraries` kopiert. Ohne Internet oder ohne installierte Arduino IDE bleibt es bei diesem Stand.
2. Libraries aus dem Arduino Library Manager werden mit dem `arduino-cli` der Arduino IDE auf die neueste Version gebracht.
3. Libraries, die es nur auf GitHub gibt (Grove Gesture, MPR121, RGB LED Matrix), werden direkt vom neuesten Stand ihres Repos geladen.

**Neue Library hinzufügen:** oben in `InstallLibraries.bat` in `LIBS_MANAGER` (Name wie im Library Manager) oder `LIBS_GITHUB` eintragen **und** den Ordner in `Libraries/` ablegen.
Bricht ein Update einmal die Kurs-Sketches, lässt sich eine Version festhalten: `"IRremote@4.7.1"` statt `"IRremote"`.
