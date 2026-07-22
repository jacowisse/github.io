import { defineConfig } from "astro/config";
import mdx from "@astrojs/mdx";

export default defineConfig({
  site: "https://www.noviforge.nl",
  integrations: [mdx()],
});
