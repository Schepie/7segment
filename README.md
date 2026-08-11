# Padel Score Display (ESP32 & Wear OS)

Dit project is een compleet end-to-end systeem voor een elektronisch padel-scorebord. Het bestaat uit een groot, zelf te bouwen 7-segment display (aangestuurd via NeoPixels) dat draadloos via Bluetooth Low Energy (BLE) wordt bediend vanaf een Samsung Galaxy Watch (of ander Wear OS 4+ horloge).

## Systeem Overzicht

1. **Hardware (ESP32-S2 / ESP32-S3):** 
   - Aangestuurd door C++ (PlatformIO / Arduino).
   - Beheert een gigantisch 7-segment display gemaakt met NeoPixel LED-strips (WS2812B).
   - Stelt een BLE GATT-server beschikbaar (via de `NimBLE-Arduino` bibliotheek) die luistert naar inkomende score-updates.
2. **Wear OS Horloge App:**
   - Ontwikkeld in Kotlin & Jetpack Compose for Wear OS.
   - Verbindt actief met de ESP32 over BLE.
   - Bevat een intuïtieve interface om de score bij te houden. Zodra de score verandert, stuurt het horloge direct een Bluetooth-pakket naar het display.
3. **Web Back-end:**
   - Bevat functionaliteit om scores te synchroniseren naar een externe Netlify API, zodat toeschouwers live mee kunnen kijken via een web-app.

---

## Hardware Installatie & Bedrading

### Benodigdheden
* Een **ESP32** microcontroller (bijv. Wemos Lolin S3 Mini).
* Een lange rol **WS2812B / NeoPixel LED-strip**. In onze configuratie gebruiken we 4 cijfers, met 7 segmenten per cijfer, en 4 LED's per segment = **112 LED's in totaal**.
* Een krachtige **5V Voeding** (let op: LED-strips verbruiken veel stroom, reken op minimaal 2A tot 5A, afhankelijk van de helderheid).

### Aansluiten
* **ESP32 PIN 15** -> Gaat naar de Data-In (DI) van de eerste LED-strip.
* **5V Voeding** -> Sluit de 5V en GND van de voeding aan op zowel de ESP32 als de LED-strip.
* *Let op: Voorzie stroominjectie aan het einde van de LED-strip als de kleuren naar het einde toe geel/rood uitslaan door spanningsverlies.*

### LED Mapping
De cijfers worden van links naar rechts opgebouwd. Elk cijfer bestaat uit 28 LED's. 
De code mapt inkomende getallen automatisch naar de specifieke NeoPixel segmenten. Ruimtes (`' '`) worden als leeg segment getoond en een `A` als Advantage.

---

## Software Installatie (ESP32)

1. Open dit project in **VSCode** met de **PlatformIO** extensie geïnstalleerd.
2. Sluit je ESP32 via een USB-kabel aan op je computer.
3. Klik op het **PlatformIO Upload (pijltje naar rechts)** icoon onderaan in de blauwe balk.
4. PlatformIO zal automatisch de `NimBLE-Arduino` en `Adafruit NeoPixel` bibliotheken downloaden en de code naar de ESP32 flashen.
5. Zodra de ESP32 opstart, toont het bord standaard `0000` en zendt hij het Bluetooth-signaal `"Padel Display"` uit.

---

## Software Installatie (Wear OS Horloge)

De broncode voor de horloge app bevindt zich in de `Padel score logger` map.
1. Open het project in **Android Studio**.
2. Zet je Galaxy Watch in **Developer Mode** (via instellingen -> Software info -> klik 7x op Build number).
3. Verbind het horloge via "Wireless Debugging" (Wi-Fi) of ADB met Android Studio.
4. Druk op de groene **Play/Run** knop om de app naar het horloge te sturen (Deploy `assembleDebug`).

---

## Gebruikershandleiding (Manual)

### 1. Opstarten
- Zet de stroom op het ESP32 display. Het display zal rood oplichten en `0000` weergeven. 
- Zolang er geen horloge verbonden is, roept het display via Bluetooth dat hij beschikbaar is.

### 2. Verbinden met het horloge
- Open de **Padel App** op je Galaxy Watch.
- Tijdens het openen van de app zoekt het horloge actief in de buurt naar een apparaat dat "Padel" in de naam heeft.
- Zodra het horloge de ESP32 vindt, verbindt hij direct. Je ziet de tekst veranderen naar **"Connected"**.
- (Technische info: Het horloge wist bij elke connectie de interne Android Bluetooth-cache via `gatt.refresh()` om te voorkomen dat oude sessies voor communicatie-fouten zorgen).

### 3. De score bijhouden
- Tik op je horloge op de `+1` / score knoppen.
- Zodra de score in de app verandert (bijv. naar `15 - 0`), stuurt de app op de achtergrond razendsnel de nieuwe datastring (bijv. `"15 0"`) naar de ESP32.
- Het scorebord update direct en visueel.

### 4. Kantwissel & Team Kleuren (Padel Regels)
- Het horloge houdt automatisch bij wanneer teams van kant moeten wisselen volgens de officiële padel-regels (na de 1e game, en daarna na elke 2 games: 1, 3, 5, 7, etc.).
- Het display ondersteunt 2 kleuren: **Blauw** voor Team 1 en **Rood** voor Team 2.
- Wanneer er van kant wordt gewisseld (oneven wisselstanden), voert het display een coole "wipe" animatie uit. De scores draaien fysiek om op het bord en de kleuren (Blauw en Rood) schuiven mee naar de andere kant, zodat ze altijd perfect matchen met waar de teams op het veld staan!

### 5. Connectie verbroken? & Handmatig Herverbinden
- Als je met je horloge buiten bereik loopt (of de app sluit), verbreekt de verbinding.
- Geen paniek: De ESP32 is geprogrammeerd om dit direct op te merken en **automatisch** opnieuw te adverteren. Je hoeft de stroom er dus niet meer af te halen. 
- In de horloge-app zie je onderaan naast de UNDO-knop de status staan (bijv. "Disconnected").
- **Tip:** Druk in de horloge-app op de status-tekst om de verbinding direct handmatig te forceren (dit werkt alleen als je niet al verbonden bent).
- Zodra de verbinding (opnieuw) succesvol is opgezet, knipperen **alle LED's op het display 3 keer blauw** als visuele bevestiging dat je weer verbonden bent!

---

## Technische Details (Bluetooth)

Voor toekomstige ontwikkeling, dit zijn de UUID's die door het systeem worden gebruikt:
- **Service UUID:** `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- **Characteristic UUID:** `beb5483e-36e1-4688-b7f5-ea07361b26a8`

Het systeem maakt gebruik van de `WRITE_TYPE_DEFAULT` instelling voor gegarandeerde overdracht zonder packet-loss door strenge Wear OS restricties. De C++ ontvanger gebruikt de NimBLE `connInfo` callback architectuur voor maximale compatibiliteit met NimBLE versie 2.0+. De score-string die wordt verzonden is 4 karakters lang, gevolgd door een `,0` (normaal) of `,1` (gewisseld) vlag voor de kantwissel-logica.
