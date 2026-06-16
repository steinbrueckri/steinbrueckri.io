# TODO

Liste der geplanten Verbesserungen für die Website. Sortiert nach Priorität.

## 🔴 Sicherheit (kritisch)

- [x] **`pull_request_target` + `permissions: write-all` + Secrets** (`.github/workflows/ci.yml`):
      → Trigger auf `push` reduziert (kein PR-Trigger mehr), `permissions` auf das Minimum
      (`contents: write` für Commit-Kommentare, `deployments: write` für Netlify) eingeschränkt.
- [x] **Mergify Auto-Merge für Dependabot** (`.mergify.yml`): Auf patch/minor beschränkt –
      Major-Updates ("from 1.x to 2.x") erfordern jetzt manuelles Review.
- [x] **`actions/checkout@master`** (`ci.yml`): Auf `@v4` gepinnt (konsistent mit den übrigen Actions).

## 🟠 SEO / Social / Korrektheit

- [x] **`baseURL = ""` ist leer** (`config.toml`): Auf `https://steinbrueck.io/` gesetzt.
- [x] **Kaputte/widersprüchliche Social-Meta-Tags** (`partials/head.html`):
      Template auf die real existierenden Params umgestellt (`author`, `description`,
      `shareImage`, `twitterHandle`). OG- und Twitter-Card-Tags rendern jetzt korrekt mit
      absoluten URLs. `shareImage`/`author_image` auf den tatsächlichen Pfad (`me.jpg`) korrigiert.
- [x] **Platzhalter-Metadaten** (`config.toml`): `tagline = "Photography & Tech"`,
      `description = "Street photography portfolio and tech blog by Richard Steinbrück."`
- [x] **Fehlende Canonical-URL und strukturierte Daten** (head): `<link rel="canonical">`
      ergänzt; JSON-LD (`WebSite` + `Person`) auf der Startseite hinzugefügt.

## 🟠 Datenschutz (DSGVO)

- [x] **Google Fonts direkt von Google geladen** (`head.html`): Roboto Mono (400) lokal
      self-hostet (latin + latin-ext) via `@font-face` in `main.css`; CDN-Links entfernt,
      Font-Preload ergänzt. Download reproduzierbar über `task download-fonts`.
- [x] **Google-Analytics-Template eingebunden** (`head.html`): Entfernt (keine GA-ID konfiguriert).

## 🟡 Performance / Web-Vitals

- [x] **Thumbnails zu groß** (`partials/responsive-image-gallery.html`): Echtes LQIP mit
      `400x q50` statt `1500x q10`.
- [x] **Kein `width`/`height` an `<img>`**: `$image.Width/.Height` gesetzt, `loading="lazy"`
      ergänzt, CSS `height: auto` gegen Verzerren/CLS.
- [x] **Doppelte Minification** (`Taskfile.yml`): Auf Hugos natives `hugo --minify` umgestellt,
      die `minify`-Tasks und die npm-Dependency entfernt.

## 🟡 Accessibility / UX

- [x] **`hide_mouse_cursor.js` blendet den Cursor global aus**: Auf den geöffneten
      baguetteBox-Lightbox-Overlay beschränkt.
- [x] **Alt-Texte nur aus EXIF-Daten**: Sinnvoller `alt` (Galerie-Titel), EXIF wandert in
      `figcaption` und `title`.
- [x] **"Look time: X minutes" = 4 Min. pro Bild** (`gallery/single.html`): Realistischer
      Faktor (~0,5 Min./Bild), Label zu "Viewing time" geändert.
- [x] **Mobile View: Frontpage klebte oben am Rand**: `.frontpage` bekommt auf Mobile
      (≤768px/≤500px) denselben oberen Abstand (80px/70px) wie `.content`, sodass das Bild
      nicht mehr unter dem fixierten Navigations-Button hängt.

## 🟡 CI / Build-Robustheit

- [x] **Cache-Key falsch** (`ci.yml`): Auf `hashFiles('package-lock.json')` + `restore-keys` umgestellt.
- [x] **`setup-node@v5` ohne `node-version`/`cache`** (`ci.yml`): `node-version: "20"` + `cache: "npm"`.
- [x] **B2-CLI-Befehle inkonsistent**: `get_gallery_images.sh` nutzt jetzt ebenfalls
      `b2 account authorize` (B2 CLI v3+).
- [x] **Lighthouse-Audit deaktiviert** (`ci.yml`, FIXME "NO_FCP issues"):
      → Ursache (globaler Cursor-Hide, leere `baseURL`) behoben – NO_FCP tritt nicht mehr auf
      (lokal verifiziert: Performance 97, A11y 85, Best Practices 96, SEO 100, FCP 1,4 s).
      Statt im CI läuft das Audit jetzt offline über `task lighthouse` (lokaler Hugo-Server +
      Lighthouse-CLI, Reports unter `.lighthouse/`). Der CI-Block bleibt auskommentiert.

## ⚪ Aufräumen / Doku

- [x] **README inkonsistent**: `ci.yml`-Pfad korrigiert, `gulp`-Verweise auf Taskfile aktualisiert.
- [x] **`.DS_Store`** in `.gitignore` aufgenommen.
- [~] B2 mit hetzner objectstore austauschen (fsn1.your-objectstorage.com / steinbrueck-io-gallery, op uuid gvxtufmimnh2y576ehxdmcukwm)
  - [x] Daten via rclone von B2 nach Hetzner kopiert
  - [x] Tooling auf rclone + Hetzner-S3 umgestellt (Skript, Taskfile, CI, README, Archetype)
  - [x] `source_bucket` entfernt – Pfad wird aus dem Galerie-Titel abgeleitet (per `source_bucket` überschreibbar)
  - [ ] GitHub-Secrets `HETZNER_S3_ACCESS_KEY` / `HETZNER_S3_SECRET_KEY` anlegen (alte `B2_*`-Secrets entfernen)
  - [ ] `task get-gallery-images` real gegen Hetzner verifizieren
- [ ] Netlify vs <https://github.com/basecamp/kamal-skiff>

## 📸 Workflow (aus altem TODO.txt)

- [ ] HOWTO dokumentieren.
- [ ] HOWTO: neues Frontpage-Bild erstellen
