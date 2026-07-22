#!/usr/bin/env bash
# setup.sh — maakt het complete Astro-project 'mijn-site' aan
set -euo pipefail

PROJECT="mijn-site"
mkdir -p "$PROJECT"/{.run,.github/workflows,config,src/{config,lib,layouts,components,pages},tests}
cd "$PROJECT"

# ── README.md ────────────────────────────────────────────────────────────
cat > README.md << 'EOF'
# Mijn Site — Astro + GitHub Pages

Statische website, ontwikkeld in PyCharm met Claude Code, gratis gehost
op GitHub Pages. Configuratie en logging zijn gescheiden van de code.

## Toolstack

| Laag | Tool |
|---|---|
| AI-assistent | Claude Code (plugin in PyCharm Community) |
| IDE | PyCharm Community |
| Framework | Astro (statische HTML) |
| Runtime | Node.js ≥ 20 + npm |
| Versiebeheer | Git + GitHub |
| CI/CD | GitHub Actions (test → build → deploy) |
| Hosting | GitHub Pages (CDN + HTTPS) |
| DNS | GoDaddy (CNAME → GitHub Pages) |

## Vereisten op OS-niveau (Ubuntu 24.04)

```bash
sudo apt update
sudo apt install -y git curl ca-certificates
```

Node.js: de apt-versie van Ubuntu 24.04 (Node 18) is end-of-life.
Installeer Node 22 LTS via NodeSource:

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
node -v   # verwacht v22.x
npm -v
```

Alternatief (geen sudo, makkelijk wisselen van versies): nvm —
`https://github.com/nvm-sh/nvm`, daarna `nvm install 22`.

Meer is er niet nodig: geen database, geen webserver, geen Python-deps.

## PyCharm-configuratie

**Plugins** (Settings → Plugins → Marketplace):

- **Claude Code** — de AI-assistent (heb je al).
- Verder niets verplicht. `Shell Script`, `YAML` en `Markdown` zitten
  standaard in Community en dekken de run-knoppen, `site.yaml` en dit
  bestand af.

**Goed om te weten:** Community heeft géén JavaScript/TypeScript-
taalondersteuning (dat is Professional) en de officiële Astro-plugin
werkt daarom niet. Basis-syntaxkleuring voor `.ts`/`.astro` krijg je via
de meegeleverde TextMate-bundels; echte code-intelligentie komt in de
praktijk van Claude Code, en `npm run build` (met `astro check`) vangt
typefouten af.

**Run-knoppen:** de map `.run/` wordt automatisch ingelezen. Rechtsboven
in de dropdown verschijnen:

| Knop | Doet |
|---|---|
| ▶ Dev server | `npm run dev` — dev-server + browser opent op localhost:4321, hot reload |
| ✓ Tests | `npm run test` — Vitest |
| ⚙ Build | `npm run build` — typecheck + productie-build naar `dist/` |
| 👁 Preview build | build + productie-resultaat lokaal bekijken |

Werkt de knop niet direct: check in de run-configuratie of
`Interpreter path` naar `/bin/bash` wijst.

## Eerste keer

```bash
npm install
cp .env.example .env
```

Kies daarna "▶ Dev server" en klik ▶ — de site opent in je browser en
elke opgeslagen wijziging is direct zichtbaar.

## Structuur

- `config/site.yaml` — alle inhoudelijke configuratie (titel, nav, URL)
- `.env` — omgevingsinstellingen zoals `LOG_LEVEL` (niet in git)
- `src/config/` — laadt en valideert de YAML (fail fast)
- `src/lib/logger.ts` — logging, niveau via `LOG_LEVEL`
- `src/layouts/`, `src/components/` — sjablonen en herbruikbare blokken
- `src/pages/` — elk bestand = een URL (file-based routing)
- `tests/` — Vitest; draait ook in CI en blokkeert deploy bij falen

## Deployen

1. Maak een GitHub-repo en push deze code naar `main`.
2. Repo → Settings → Pages → Source: **GitHub Actions**;
   vul je custom domain in.
3. DNS bij GoDaddy: CNAME `www` → `<gebruikersnaam>.github.io`
   (apex: A-records 185.199.108.153 t/m 185.199.111.153 — verifieer
   de actuele adressen in de GitHub Pages-docs).
4. Vink "Enforce HTTPS" aan zodra DNS is doorgevoerd.

Daarna: elke `git push` naar `main` draait tests, bouwt en publiceert
automatisch (~1 min).

## Debuggen

- Terminal-output: logger (`LOG_LEVEL=debug` in `.env`) en Astro's
  foutoverlay in de browser.
- Extra detail: `npm run dev:debug` (verbose).
- Browsergedrag: F12-devtools.
EOF

# ── package.json ─────────────────────────────────────────────────────────
cat > package.json << 'EOF'
{
  "name": "mijn-site",
  "type": "module",
  "version": "1.0.0",
  "scripts": {
    "dev": "astro dev --open",
    "dev:debug": "astro dev --open --verbose",
    "build": "astro check && astro build",
    "preview": "astro preview --open",
    "test": "vitest run",
    "test:watch": "vitest"
  },
  "dependencies": {
    "astro": "^5.0.0",
    "js-yaml": "^4.1.0"
  },
  "devDependencies": {
    "@astrojs/check": "^0.9.0",
    "typescript": "^5.5.0",
    "vitest": "^3.0.0",
    "@types/js-yaml": "^4.0.9"
  }
}
EOF

# ── configuratie ─────────────────────────────────────────────────────────
cat > config/site.yaml << 'EOF'
site:
  title: "NoviForge"
  description: "Korte omschrijving voor zoekmachines"
  url: "https://www.example.nl"
  language: "nl"

nav:
  - label: "Home"
    href: "/"
  - label: "Over"
    href: "/over"

footer:
  copyright: "NoviForge B.V."
EOF

cat > .env.example << 'EOF'
# Kopieer naar .env — .env staat in .gitignore
LOG_LEVEL=debug        # debug | info | warn | error
EOF

cat > astro.config.mjs << 'EOF'
import { defineConfig } from "astro/config";

export default defineConfig({
  site: "https://www.example.nl",
  // base: "/repo-naam",   // alléén nodig zonder custom domain
});
EOF

cat > tsconfig.json << 'EOF'
{
  "extends": "astro/tsconfigs/strict",
  "include": ["src", "tests"]
}
EOF

cat > .gitignore << 'EOF'
node_modules/
dist/
.env
.astro/
EOF

# ── src ──────────────────────────────────────────────────────────────────
cat > src/lib/logger.ts << 'EOF'
type Level = "debug" | "info" | "warn" | "error";
const ORDER: Record<Level, number> = { debug: 0, info: 1, warn: 2, error: 3 };

const active: Level = (process.env.LOG_LEVEL as Level) ?? "info";

function log(level: Level, msg: string): void {
  if (ORDER[level] < ORDER[active]) return;
  const ts = new Date().toISOString();
  console[level === "debug" ? "log" : level](`[${ts}] [${level.toUpperCase()}] ${msg}`);
}

export const logger = {
  debug: (m: string) => log("debug", m),
  info:  (m: string) => log("info", m),
  warn:  (m: string) => log("warn", m),
  error: (m: string) => log("error", m),
};
EOF

cat > src/config/index.ts << 'EOF'
import { readFileSync } from "node:fs";
import yaml from "js-yaml";
import { logger } from "../lib/logger";

export interface NavItem { label: string; href: string; }

export interface SiteConfig {
  site: { title: string; description: string; url: string; language: string };
  nav: NavItem[];
  footer: { copyright: string };
}

function load(): SiteConfig {
  const raw = readFileSync(new URL("../../config/site.yaml", import.meta.url), "utf-8");
  const cfg = yaml.load(raw) as SiteConfig;

  for (const key of ["title", "description", "url", "language"] as const) {
    if (!cfg?.site?.[key]) throw new Error(`config/site.yaml: 'site.${key}' ontbreekt`);
  }
  if (!Array.isArray(cfg.nav) || cfg.nav.length === 0) {
    throw new Error("config/site.yaml: 'nav' ontbreekt of is leeg");
  }

  logger.debug(`Configuratie geladen: ${cfg.nav.length} nav-items, url=${cfg.site.url}`);
  return cfg;
}

export const config: SiteConfig = load();
EOF

cat > src/layouts/Base.astro << 'EOF'
---
import { config } from "../config";
import Nav from "../components/Nav.astro";

interface Props { title?: string; }
const { title } = Astro.props;
const pageTitle = title ? `${title} — ${config.site.title}` : config.site.title;
---
<!doctype html>
<html lang={config.site.language}>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="description" content={config.site.description} />
    <title>{pageTitle}</title>
  </head>
  <body>
    <Nav />
    <main>
      <slot />
    </main>
    <footer>
      <p>© {new Date().getFullYear()} {config.footer.copyright}</p>
    </footer>
  </body>
</html>
EOF

cat > src/components/Nav.astro << 'EOF'
---
import { config } from "../config";
const current = Astro.url.pathname;
---
<nav>
  {config.nav.map((item) => (
    <a href={item.href} aria-current={current === item.href ? "page" : undefined}>
      {item.label}
    </a>
  ))}
</nav>
EOF

cat > src/pages/index.astro << 'EOF'
---
import Base from "../layouts/Base.astro";
import { config } from "../config";
---
<Base>
  <h1>Welkom bij {config.site.title}</h1>
  <p>Deze pagina is statisch gegenereerd met Astro.</p>
</Base>
EOF

cat > src/pages/over.astro << 'EOF'
---
import Base from "../layouts/Base.astro";
---
<Base title="Over">
  <h1>Over ons</h1>
  <p>Inhoud volgt.</p>
</Base>
EOF

# ── tests ────────────────────────────────────────────────────────────────
cat > tests/config.test.ts << 'EOF'
import { describe, it, expect } from "vitest";
import { config } from "../src/config";

describe("site-configuratie", () => {
  it("bevat verplichte velden", () => {
    expect(config.site.title).toBeTruthy();
    expect(config.site.url).toMatch(/^https:\/\//);
  });

  it("nav-items hebben label en geldige href", () => {
    for (const item of config.nav) {
      expect(item.label).toBeTruthy();
      expect(item.href).toMatch(/^\//);
    }
  });
});
EOF

# ── PyCharm run-knoppen ──────────────────────────────────────────────────
make_run () {
  local file="$1" name="$2" script="$3"
  cat > ".run/${file}" << XML
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="${name}" type="ShConfigurationType">
    <option name="SCRIPT_TEXT" value="${script}" />
    <option name="INDEPENDENT_SCRIPT_PATH" value="true" />
    <option name="INDEPENDENT_SCRIPT_WORKING_DIRECTORY" value="true" />
    <option name="SCRIPT_WORKING_DIRECTORY" value="\$PROJECT_DIR\$" />
    <option name="INDEPENDENT_INTERPRETER_PATH" value="true" />
    <option name="INTERPRETER_PATH" value="/bin/bash" />
    <option name="EXECUTE_IN_TERMINAL" value="true" />
    <option name="EXECUTE_SCRIPT_FILE" value="false" />
    <method v="2" />
  </configuration>
</component>
XML
}

make_run "Dev server.run.xml"    "▶ Dev server"    "npm run dev"
make_run "Tests.run.xml"         "✓ Tests"         "npm run test"
make_run "Build.run.xml"         "⚙ Build"         "npm run build"
make_run "Preview build.run.xml" "👁 Preview build" "npm run build &amp;&amp; npm run preview"

# ── GitHub Actions ───────────────────────────────────────────────────────
cat > .github/workflows/deploy.yml << 'EOF'
name: Deploy naar GitHub Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: npm }
      - run: npm ci
      - run: npm run test

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: withastro/action@v3

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
EOF

echo ""
echo "✔ Project '$PROJECT' aangemaakt."
echo "Volgende stappen:"
echo "  cd $PROJECT"
echo "  npm install"
echo "  cp .env.example .env"
echo "  → open de map in PyCharm en klik op '▶ Dev server'"
EOF
