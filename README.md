# JARVIS Partikel-Avatar

Leuchtender Partikel-Avatar im Browser — eine einzelne, eigenständige HTML-Datei,
kein Build, keine Abhängigkeiten.

**Live:** https://domenikfranke-lab.github.io/jarvis-face/

## Was er kann
- Kopf aus 3D-Partikel-Höhenlinien, glühende Gesichtszone, Aurora-Felder, Adern im Hals
- Ruhige Atmung (Brustkorb hebt sich, Brustbein glüht mit)
- Kamera-Tracking über MediaPipe: Kopfhaltung, **Mimik** (Mund, Brauen, Lider) und **Hände**
- Tiefenschätzung der Hände — nah an der Kamera = groß und hell, hinter dem Kopf = verdeckt
- Ohne Kamera folgt der Mund dem Mikrofonpegel

## Steuerung
`SPACE` Zustand · `M` Mikrofon · `T` Kamera · `K` Trackingrichtung · `H` UI aus

Kamera und Mikrofon laufen vollständig im Browser. Es werden keine Bild- oder
Tondaten an einen Server geschickt — die Seite ist statisch und hat kein Backend.
Die MediaPipe-Modelle kommen von Googles CDN.

Technische Übergabe: [HANDOVER.md](HANDOVER.md)

Nachbau des Avatars aus einem Instagram-Reel von `reznikov_engineering`.
Das Referenzbild ist absichtlich nicht Teil dieses Repos.
