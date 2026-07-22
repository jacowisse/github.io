# Website-toolstack: Astro + GitHub Pages

Statische website, code gegenereerd met Claude Code, gratis gehost.
Vervangt de oude WordPress-setup.

---

## 1. De toolstack (high level)

| Laag | Tool | Rol |
|---|---|---|
| AI-assistent | Claude Code (plugin in PyCharm Community) | Genereert en wijzigt code, draait builds, doet git-werk |
| IDE | PyCharm Community | Werkomgeving |
| Framework | Astro | Bouwt statische HTML uit componenten |
| Runtime (lokaal) | Node.js ≥ 18 + npm | Nodig om Astro te draaien/builden |
| Versiebeheer | Git + GitHub | Broncode; push = trigger voor deploy |
| CI/CD | GitHub Actions | Bouwt de site automatisch bij elke push |
| Hosting | GitHub Pages | Serveert de gebouwde site via CDN + HTTPS |
| DNS | GoDaddy | CNAME wijst het domein naar GitHub Pages |

**Principe:** jij (via Claude Code) werkt alleen in de broncode.
Builden en publiceren gebeurt volledig automatisch na `git push`.

---

## 2. Deployen (de workflow)

```
bewerken in PyCharm ──► git push naar main ──► GitHub Action bouwt ──► GitHub Pages publiceert
     (Claude Code)          (± 5 sec)             (± 1 min)                (live)
```

1. Vraag Claude Code om een wijziging, of bewerk zelf.
2. Controleer lokaal met `npm run dev` (live preview op `http://localhost:4321`).
3. Commit en push naar `main` (kan Claude Code ook doen).
4. GitHub Actions draait `astro build` en zet het resultaat op GitHub Pages.
5. Na ~1 minuut staat de wijziging live. Geen handmatige stappen.

---

## 3. De tools in detail

### 3.1 Astro

**Wat het is:** een framework dat tijdens de build kant-en-klare HTML
genereert. Standaard wordt er *geen* JavaScript naar de browser gestuurd
— vandaar de snelheid en eenvoud.

**Projectstructuur:**

```
mijn-site/
├── astro.config.mjs      # configuratie (o.a. site-URL)
├── package.json
├── public/               # bestanden die 1-op-1 gekopieerd worden (favicon, robots.txt)
└── src/
    ├── layouts/          # paginasjablonen (header, footer, <head>)
    │   └── Base.astro
    ├── components/       # herbruikbare blokken (Nav.astro, Card.astro)
    └── pages/            # elk bestand hier = een URL
        ├── index.astro   # → /
        ├── over.astro    # → /over
        └── blog/
            └── post-1.md # → /blog/post-1 (markdown werkt direct!)
```

**Kernconcepten:**

- **File-based routing** — een bestand in `src/pages/` is automatisch
  een pagina. Geen router configureren.
- **`.astro`-bestanden** — bovenin tussen `---` staat JavaScript
  (build-time), daaronder HTML met `{expressies}`. Vergelijkbaar met
  een template-taal als Jinja2.
- **Markdown-support** — `.md`-bestanden in `pages/` worden pagina's.
  Ideaal voor blog/nieuws zonder CMS.
- **Layouts** — pagina's importeren een layout zodat header/footer maar
  op één plek staan.

**Belangrijkste commando's:**

```bash
npm create astro@latest   # nieuw project (eenmalig)
npm run dev               # dev-server met hot reload
npm run build             # productie-build → map dist/
npm run preview           # dist/ lokaal bekijken
```

### 3.2 GitHub Actions

**Wat het is:** CI/CD van GitHub. Een YAML-bestand in
`.github/workflows/` beschrijft wat er moet gebeuren bij een event
(zoals een push). GitHub draait dat in een tijdelijke VM.

**Voor deze site:** Astro levert een officiële action die alles doet.
Bestand `.github/workflows/deploy.yml`:

```yaml
name: Deploy naar GitHub Pages

on:
  push:
    branches: [main]      # elke push naar main triggert een deploy
  workflow_dispatch:       # + handmatig startbaar via de GitHub-UI

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: withastro/action@v3   # installeert Node, bouwt, uploadt dist/

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

**Goed om te weten:**

- Status en logs zie je onder het tabblad **Actions** in je repo —
  faalt een build, dan blijft de oude versie gewoon live staan.
- Gratis en onbeperkt voor publieke repo's; private repo's krijgen
  2.000 minuten/maand gratis (ruim voldoende: een build kost ~1 min).
- Dit bestand schrijf je één keer en raak je daarna zelden meer aan.

### 3.3 GitHub Pages

**Wat het is:** gratis statische hosting direct vanuit een repo,
geserveerd via het CDN van GitHub (Fastly), inclusief automatische
HTTPS via Let's Encrypt.

**Eenmalige setup:**

1. Repo → **Settings → Pages** → *Source*: **GitHub Actions**.
2. *Custom domain*: vul je domein in (bijv. `www.example.nl`).
3. Bij GoDaddy (DNS-beheer):

   | Type | Naam | Waarde |
   |---|---|---|
   | CNAME | `www` | `<github-gebruikersnaam>.github.io` |

   Voor de apex (`example.nl` zonder `www`): vier A-records naar
   `185.199.108.153` t/m `185.199.111.153`.
4. Terug in GitHub: vink **Enforce HTTPS** aan (kan pas als DNS
   doorgevoerd is, reken op minuten tot enkele uren).

**Beperkingen (voor een eenvoudige site irrelevant):**

- Alleen statische bestanden — geen server-side code (precies waarom
  we Astro gebruiken).
- Softlimieten: site ≤ 1 GB, ~100 GB bandbreedte/maand.

---

## 4. Eenmalig stappenplan (van nul naar live)

1. Installeer Node.js (≥ 18) en controleer: `node -v`
2. `npm create astro@latest mijn-site` (kies een template, bijv. *minimal* of *blog*)
3. Open de map in PyCharm; laat Claude Code de site naar wens ombouwen
4. Maak een (publieke) GitHub-repo aan en push de code
5. Voeg `.github/workflows/deploy.yml` toe (zie §3.2) en push
6. Zet in repo-settings de Pages-source op *GitHub Actions* + custom domain
7. Pas de DNS-records bij GoDaddy aan (zie §3.3)
8. Wacht op DNS + certificaat → site is live
9. Zeg het WordPress-hostingpakket op 🎉

---

## 5. Dagelijks gebruik daarna

```bash
# in PyCharm, via Claude Code of terminal:
npm run dev        # lokaal bekijken tijdens het werken
git add -A && git commit -m "Nieuwe pagina X" && git push
# ... 1 minuut later live
```

Onderhoud beperkt zich tot af en toe `npm update` voor Astro-updates.
Geen plugins, geen security-patches, geen database.
