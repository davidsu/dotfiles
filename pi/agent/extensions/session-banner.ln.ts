import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

// Visually distinct background colors — all readable with white bold text
const PALETTES = [
  { bg: [40, 80, 120], label: "steel" },
  { bg: [120, 40, 80], label: "berry" },
  { bg: [80, 100, 40], label: "olive" },
  { bg: [100, 50, 120], label: "plum" },
  { bg: [40, 100, 90], label: "teal" },
  { bg: [130, 70, 30], label: "amber" },
  { bg: [60, 60, 120], label: "indigo" },
  { bg: [120, 50, 50], label: "brick" },
  { bg: [50, 90, 60], label: "forest" },
  { bg: [90, 60, 100], label: "mauve" },
];

function hashString(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = ((h << 5) - h + s.charCodeAt(i)) | 0;
  }
  return Math.abs(h);
}

function pickPalette(text: string) {
  return PALETTES[hashString(text) % PALETTES.length];
}

function bg(r: number, g: number, b: number, s: string): string {
  return `\x1b[48;2;${r};${g};${b}m${s}\x1b[49m`;
}

function white(s: string): string {
  return `\x1b[38;2;255;255;255m${s}\x1b[39m`;
}

function bold(s: string): string {
  return `\x1b[1m${s}\x1b[22m`;
}

export default function (pi: ExtensionAPI) {
  let bannerText = "";

  pi.on("session_start", async (_event, ctx) => {
    for (const entry of ctx.sessionManager.getEntries()) {
      if (entry.type === "custom" && entry.customType === "session-banner") {
        bannerText = entry.data?.text ?? "";
      }
    }
    if (bannerText) {
      showBanner(ctx);
    }
  });

  function showBanner(ctx: { ui: { setWidget: Function } }) {
    const palette = pickPalette(bannerText);
    const [r, g, b] = palette.bg;

    ctx.ui.setWidget("session-banner", () => {
      return {
        render(width: number): string[] {
          const fill = (s: string) => bg(r, g, b, s);
          const pad = fill(" ".repeat(width));

          const raw = `  ▌ ${bannerText}  `;
          const textWidth = visibleWidth(raw);
          const leftPad = Math.max(0, Math.floor((width - textWidth) / 2));
          const rightPad = Math.max(0, width - leftPad - textWidth);

          const content = fill(
            truncateToWidth(
              " ".repeat(leftPad) + white(bold(raw)) + " ".repeat(rightPad),
              width,
              "",
            ),
          );
          return [pad, content, pad];
        },
        invalidate() {},
      };
    });
  }

  pi.registerCommand("banner", {
    description: "Set a session banner (empty to clear)",
    handler: async (args, ctx) => {
      bannerText = (args ?? "").trim();

      pi.appendEntry("session-banner", { text: bannerText });

      if (bannerText) {
        showBanner(ctx);
        pi.setSessionName(bannerText);
        ctx.ui.notify(`Banner set: ${bannerText}`, "info");
      } else {
        ctx.ui.setWidget("session-banner", undefined);
        ctx.ui.notify("Banner cleared", "info");
      }
    },
  });
}
