import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

// https://vitejs.dev/config/
export default defineConfig({
  base: "/rescript-test/",
  plugins: [
    tailwindcss(),
    react({
      include: ["**/*.res.mjs"],
    }),
  ],
  server: {
    watch: {
      ignored: ["**/lib/bs/**", "**/lib/ocaml/**", "**/lib/rescript.lock"],
    },
  },
});
