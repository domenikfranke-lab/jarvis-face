# JARVIS Partikel-Avatar — Übergabe

**Datei:** `~/Public/Claudes_Workspace/jarvis-face/index.html` (eigenständig, kein Build)
**Artifact:** https://claude.ai/artifact/2rzpezz4ZmQXYWEshhmXst (Kopie ohne html/head/body-Wrapper, Stand ist älter)
**Live (HTTPS, remote):** https://domenikfranke-lab.github.io/jarvis-face/
**Repo:** https://github.com/domenikfranke-lab/jarvis-face (public — Pages ist sonst kostenpflichtig)
**Lokal starten:** `cd ~/Public/Claudes_Workspace/jarvis-face && python3 serve.py 8901`
→ http://localhost:8901/index.html (Kamera braucht http bzw. https, über `file://` blockt Chrome das Modell)
**Deployen:** `./deploy.sh "Was geaendert wurde"` — kopiert nach `~/Developer/jarvis-face-pages`
und pusht. Der Klon liegt bewusst ausserhalb des Vaults, sonst landet `.git` im Drive-Sync.
`ref.png` ist absichtlich nicht im Repo: Standbild aus einem fremden Instagram-Reel.

`serve.py` statt `python3 -m http.server`: der eingebaute Server cacht, und der
Browser zeigte dadurch minutenlang alte Stände. `serve.py` schickt `no-store`.

## Was es ist
Nachbau des Jarvis-Avatars aus einem Instagram-Reel (`ref.png` = Originalframe,
`_Eingang/ScreenRecording_09-15-2026 11-05-49_1.MP4` = das Reel selbst).
Leuchtender Kopf aus Partikel-Höhenlinien, glühende Gesichtszone, Aurora-Felder,
orange Adern im Hals. Dazu Atmung, Kamera-Tracking von Kopf, **Mimik** und **Händen**.

## Aufbau (wichtig für Änderungen)
- **Kopf** = echte 3D-Punktwolke: 46 waagerechte Schnittringe durch ein Schädelvolumen,
  gleichmäßig über den Winkel abgetastet, schwach-perspektivisch projiziert.
  Flaches Abtasten in x sah sofort künstlich aus.
- **Körper** = Fächer aus Stromlinien aus der Kehle nach unten-außen, Bündelung am
  Brustbein. KEINE waagerechten Ringe (war ein Irrweg).
- **Seitenfelder** = gerichtete Stromlinien-Bänder mit hellem Grat.
- **Maße stammen aus Pixelvermessung der Vorlage:** Kopfhöhe:Breite = 1.19:1,
  Kiefer endet bei 0.40 Kopfbreite, Rim `#05CDFC`, Glut `#DFA801→#E1EC74→#F1EFF6`.
- **Rendering:** Partikel in Farb-Buckets sammeln, pro Bucket ein `fillStyle`,
  benachbarte Ringpunkte werden zu Linienstücken verschmolzen. Danach 3 Bloom-Stufen.
  `QUALITY` regelt sich anhand der Framezeit selbst nach.

## Atmung (`BR`, `breathCurve`)
Eine Phase p läuft 0..1 durch: **einatmen 0…0.36, halten …0.45, ausatmen …0.88, ruhen**.
Jeder Abschnitt ist kosinus-geglättet, die Ableitung ist an den Nahtstellen null —
deshalb gibt es keine harten Knicke. Zusätzlich läuft `BR.v` noch durch einen
Tiefpass. Wirkung: Brustkorb hebt sich (`G.HH*0.0125`), wird 1.9 % breiter,
Brustbein und Adern glühen auf, der Kopf fährt leicht mit.
Rate ~0.19 Hz im Leerlauf, ~0.29 Hz beim Sprechen. `JARVIS.breath.amp` skaliert alles,
`?breath=0` schaltet es ab.

## Mimik
`outputFaceBlendshapes:true` am Face Landmarker. `FT` = Zielwerte aus den Blendshapes,
`FACE` = geglättet (Mund/Lider schnell ~65 ms, Brauen/Lage ruhig).
- **Mund** = Ober- und Unterlippe als eigene Partikelzüge auf der Gesichtsoberfläche
  (`drawMouth` + `faceSurf`). Über das Glut-Gitter allein ging das **nicht**: die
  Höhenlinien des Kopfes liegen ~18 px auseinander, ein Mund fand darin keine Form.
  Das Gitter macht nur noch die dunkle Mundhöhle und einen weichen Halo.
- **Brauen** = `drawBrows`, nur sichtbar solange die Kamera wirklich führt.
- **Lider** = die vorhandenen dunklen Augenhöhlen im Glut-Gitter, ihre Höhe folgt
  dem Blinzeln. Ohne Kamera blinzelt er von selbst alle 2–7 s.
- **Ohne Kamera** folgt der Mund dem Mikrofonpegel, Brauen bleiben aus — der
  Leerlauf sieht also aus wie vorher.
- **Seiten:** MediaPipe benennt Personen-Seiten, gezeichnet werden Bildschirm-Seiten.
  Im Spiegelmodus bleibt links links, im Gegenüber-Modus werden die Seiten getauscht
  (`sw` / `L()` in `trackLoop`).

## Hände (keine Arme mehr)
Arme, Schultergelenk und die Zweiknochen-IK sind **raus** — nur noch Hände.
- Größe kommt aus der gemessenen **Handflächenlänge** (Landmarke 0 → 9) in
  Szenenpixeln, nicht aus `G.HW`. Dadurch stimmt die Strichstärke automatisch,
  egal wie nah die Hand ist.
- **Tiefe z (−1 fern … +1 nah)** aus dem Verhältnis Handfläche zu Gesichtsbreite:
  `z = ln((palm/faceW)/zRef)/0.55`. `TRACK.zRef` (Start 0.68) zieht langsam
  (τ ≈ 1 min) zur Ruhelage nach, damit die Schätzung nicht an den Körperproportionen
  hängt. z steuert Helligkeit, Strichstärke und — bei z < −0.1 — die **Verdeckung**
  durch Kopf/Körper (`insideBust`). Einzelne Finger, die zur Kamera zeigen, werden
  über das relative `z` der Landmarken dicker.
- **Nähe zum Gesicht** (`A.face`): Abstand Handmitte↔Gesichtsmitte in Gesichtsbreiten,
  gewichtet damit die Tiefe passt. Sie färbt die Hand warm und zieht im Glut-Gitter
  eine lokale Aufhellung zur Hand — daran sieht man, dass er die Hand am Gesicht merkt.
- **Abbildung Kamera→Szene ist jetzt maßstabsgetreu** (`MAP.sc`, Faktor 0.985 statt
  vorher 0.62). Nur so landet eine Hand an der Wange auch an der Wange.
  `?hand=0.85` staucht, falls die Hände zu weit nach außen laufen.
- Handerkennung läuft jedes Bild, solange eine Hand sichtbar ist, sonst jedes dritte.

## Leistung — was gebremst hat und was hilft
Mit Kamera lief es zäh. Drei Ursachen, alle behoben:

1. **Bloom lief auf voller Fläche.** Drei `ctx.filter='blur(...)'`-Durchgänge über die
   ganze Leinwand, der weiteste mit 20 px. Jetzt werden die beiden weiten Stufen auf
   dem 1/4-Puffer unscharf gerechnet (1/16 der Pixel) und ohne Filter hochgezogen,
   die enge Stufe braucht gar keinen Filter mehr — das Hochskalieren weicht sie schon
   auf. Es gibt keinen einzigen Vollbild-Filter mehr. Der Look ist dabei gleich
   geblieben, gegengeprüft mit identischen Einstellungen.
2. **Kein Pixelbudget.** Auf einem Retina-Bildschirm waren es schnell 6 Mpx, und
   Partikel, Bloom und Compositing zahlen das alle mit. Budget jetzt 2.6 Mpx
   (`PXBUDGET`, `?px=4` hebt es an), `RS` regelt zusätzlich nach.
3. **Beide Modelle liefen bei jedem Bild** — die Handerkennung sogar durchgehend,
   sobald eine Hand sichtbar war (das war mein Fehler aus der Runde davor).
   Jetzt hat jedes Modell eine eigene Taktrate, Gesicht 26 Hz, Hände 13 Hz, und sie
   teilen sich nie dasselbe Bild. Pose und Landmarken werden ohnehin geglättet.

**Falle beim Takten:** fester Vorrang fürs Gesicht lässt die Hände verhungern, sobald
die Bildrate in die Nähe der Gesichtsrate kommt (gemessen: 0 Handerkennungen pro
Sekunde). Es wird deshalb der relativ am weitesten Überfällige gewählt, nicht der
Wichtigere.

**Selbstregler** misst jetzt die echte Bildrate, nicht mehr nur die Zeichenzeit —
die Modelle laufen auf demselben Thread und tauchten vorher nirgends auf.
Reihenfolge beim Sparen: erst Auflösung (`RS`, kostet überall), dann Partikeldichte
(`QUALITY`), dann die Taktrate der Erkennung. Zurückgeregelt wird unter 18.5 ms —
eine Schwelle unter 16.7 ms würde bei 60 Hz nie auslösen.

**Taste `P`** blendet die Messwerte ein: Bildrate, Zeichenzeit, Gesicht und Hände je
in ms und Hz, Fläche, RS und QUALITY. `?perf=1` schaltet sie beim Start ein.
Wenn es wieder klemmt: dort ablesen, welche Zeile groß ist.

## Steuerung
`SPACE` Zustand · `M` Mikrofon · `T` Kamera (Kopf·Mimik·Hände) · `K` Richtung · `P` Messwerte · `H` UI aus

## JS-API
```js
JARVIS.setState('idle'|'listening'|'speaking'|'thinking')
JARVIS.setLevel(0..1)            // Sprachpegel
JARVIS.say('Text')               // Untertitel
JARVIS.startTracking() / .stopTracking() / .tracking
JARVIS.setPose(yaw,pitch,roll,shift)          // Bogenmaß
JARVIS.setHands([[ [x,y,z?] ×21 ], …], {cx,cy,w,asp})   // Bildkoordinaten 0..1
JARVIS.setFace({jaw,smile,pucker,funnel,blinkL,blinkR,browL,browR,browIn,mX,mY})
JARVIS.face / .breath / .hands                // Lesezugriff auf den Zustand
```

## URL-Parameter
`?track=1` Tracking sofort · `?mirror=0` Richtung umdrehen · `?gain=1.3` Yaw-Verstärkung
`?hand=0.85` Hand-Maßstab · `?breath=0.6` Atem-Amplitude · `?ref=0.5` Originalframe als Overlay
`?px=4` Pixelbudget in Mpx · `?facehz=20` / `?handhz=10` Taktrate der Erkennung · `?perf=1` Messwerte an

## Fallen, die schon Zeit gekostet haben
1. **Cache.** Gelöst durch `serve.py` (no-store). Wer doch `-m http.server` nimmt:
   `?cb=<zahl>` anhängen.
2. **Partikel-Bucket-Puffer liefen still über** und verwarfen ausgerechnet die
   äußeren Schulterlinien. Es gibt einen Überlauf-Flush — nicht wieder entfernen.
3. **Im Artifact geht kein Tracking** — die CSP blockt Modell- und WASM-Downloads.
4. `getImageData` auf dem Canvas liefert im Claude-Browser-Pane nur Nullen.
5. **Framerate im Claude-Browser-Pane ist wertlos** — rAF wird dort gedrosselt,
   sobald nicht gerendert wird. Gemessen wurde stattdessen die interne Framezeit:
   9.5 ms ohne Hand, 10.4 ms mit Hand, `QUALITY` bleibt auf 1.

## Offen / ungetestet
- **Live-Kamera wurde nie mit echtem Gesicht/echten Händen getestet** — der
  Browser-Pane blockt Kamerazugriff. Geprüft wurde alles mit synthetischen Hand-
  und Blendshape-Daten. Falls Richtungen falsch wirken: `K` drücken bzw.
  `JARVIS.tracking.gain*` justieren.
- `TRACK.zRef` driftet, wenn die Hand sehr lange dicht am Gesicht bleibt.
  Zurücksetzen: `JARVIS.tracking.zRef = 0.68`.
- Seitenfelder sind körniger im Original als im Nachbau.
- Das Artifact ist noch auf dem alten Stand (Arme, keine Mimik, keine Atmung).
