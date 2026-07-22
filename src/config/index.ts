import yaml from "js-yaml";
import { logger } from "../lib/logger";
import rawYaml from "../../config/site.yaml?raw";

export interface NavItem { label: string; href: string; }

export interface SiteConfig {
  site: { title: string; description: string; url: string; language: string };
  nav: NavItem[];
  footer: { copyright: string };
}

function load(): SiteConfig {
  const cfg = yaml.load(rawYaml) as SiteConfig;

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
