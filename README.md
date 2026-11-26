# SIG Oberuzwil – interne Testversion 0.1.0

Flutter für Android und iOS, zunächst ausdrücklich ohne Firebase oder andere Backends. Keine Store-Veröffentlichung. Die fünf öffentlichen Reiter enthalten statische, lokal verfügbare offizielle Angaben. Keine Registrierung, keine Zahlungsabwicklung, keine simulierten Live-Daten. Die Verwaltung ist bewusst deaktiviert.

## Android APK
GitHub Actions > SIG Android Test APK > erfolgreicher Lauf > Artefakt SIG-Oberuzwil-Test-APK herunterladen, entpacken und app-debug.apk installieren. Debug-Signatur nur zum Testen.
Lokal: Flutter stable, Java 17 und Android SDK installieren; bash scripts/bootstrap.sh; flutter pub get; flutter test; flutter build apk --debug.
iOS: bash scripts/bootstrap.sh erzeugt auch die iOS-Projektstruktur. Auf macOS mit Xcode flutter build ios --no-codesign; Bundle-ID und Signierung mit Vorstand abstimmen.

## Quellen und noch benötigte Angaben
- https://sig-oberuzwil.ch/organisation/ : jüngerer verfügbarer Stand der Vorstandsseite, Kontakt, Adresse und Öffnungszeiten. Ältere Indexversion nennt abweichende Vorstandsmitglieder; bitte durch Vorstand bestätigen.
- https://sig-oberuzwil.ch/sig/ : Vereinsvorstellung, zusammengefasst.
- https://sig-oberuzwil.ch/gebetszeiten/ : dynamischer MyMosq-Kalender (Moschee 1150) konnte nicht ausgelesen werden. Tagesgenaue Gebetsbeginn- und Iqama-Zeiten sowie Freitagszeiten fehlen. Alte Hinweise nicht als tagesgenaue Zeiten verwendet.
- Logo-URL von der Website gefunden, Bildabruf durch Website-Schutz nicht bestätigt. Vor Freigabe Originaldatei und offizielle Porträts einholen.
- Mitgliederbeiträge, Voraussetzungen, Zahlungsrhythmus und Formulare fehlen. Allgemeiner Kontakt ist verfügbar.
- Lokaler offizieller TWINT-QR und Bankverbindung fehlen. Bankdaten der nationalen SIG nicht ungeprüft übernehmen.
- Aktuelle Meldungen haben keine verifizierten Veröffentlichungszeitstempel; kein erfundener Feed.
- Datenschutzerklärung und Anbieterfreigabe fehlen.

## Weitere Umsetzung nach Designfreigabe
Backend und sichere Admin-Rollen, serverseitige Regeln, Bild-Uploads, zentraler Kalenderimport mit Vorschau, Freitagszeiten, News- und Push-Verwaltung, Änderungs-Synchronisierung und Cache mit Aktualisierungszeitpunkt, TWINT-Verifikation, Übersetzungsdateien für alle verbleibenden UI-Texte, Gerätetests (insbesondere grosse Schrift, Telefon/Mail/Karten), Store-Signing. CSV-Schema und validierende Kalenderlogik sowie Datenzugriffsschnittstelle bereits vorbereitet. Testdaten nur in automatisierten Tests; keine offiziellen Zeiten simuliert. Die lokalen Inhalte funktionieren ohne Internet, externe Links benötigen eine Verbindung.
