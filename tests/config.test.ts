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
