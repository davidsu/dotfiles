import type { ExtensionAPI, RegisteredCommand } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

const COLORS: Record<string, [number, number, number]> = {
  red: [120, 50, 50],
  blue: [40, 80, 120],
  green: [50, 90, 60],
  yellow: [80, 100, 40],
  purple: [100, 50, 120],
  orange: [130, 70, 30],
  pink: [120, 40, 80],
  cyan: [40, 100, 90],
  indigo: [60, 60, 120],
  mauve: [90, 60, 100],
};

const COLOR_NAMES = Object.keys(COLORS);

function hashString(text: string): number {
  let hash = 0;
  for (let i = 0; i < text.length; i++) {
    hash = ((hash << 5) - hash + text.charCodeAt(i)) | 0;
  }
  return Math.abs(hash);
}

function colorFromText(text: string) {
  return COLORS[COLOR_NAMES[hashString(text) % COLOR_NAMES.length]];
}

function randomColorName() {
  return COLOR_NAMES[Math.floor(Math.random() * COLOR_NAMES.length)];
}

function bg(rgb: [number, number, number], text: string): string {
  const [red, green, blue] = rgb;
  return `\x1b[48;2;${red};${green};${blue}m${text}\x1b[49m`;
}

function white(text: string): string {
  return `\x1b[38;2;255;255;255m${text}\x1b[39m`;
}

function bold(text: string): string {
  return `\x1b[1m${text}\x1b[22m`;
}

function colorCompletions(prefix: string) {
  return ["default", ...COLOR_NAMES]
    .filter((name) => name.startsWith(prefix.toLowerCase()))
    .map((name) => ({ value: name, label: name }));
}

export default function (pi: ExtensionAPI) {
  let bannerText = "";
  let colorName = "";

  pi.on("session_start", async (_event, ctx) => {
    for (const entry of ctx.sessionManager.getEntries()) {
      if (entry.type !== "custom") continue;
      if (entry.customType === "session-banner") bannerText = entry.data?.text ?? "";
      if (entry.customType === "session-banner-color") colorName = entry.data?.color ?? "";
    }
    if (bannerText) {
      showBanner(ctx);
    }
  });

  function showBanner(ctx: { ui: { setWidget: Function } }) {
    ctx.ui.setWidget("session-banner", () => {
      return {
        render(width: number): string[] {
          const fill = (text: string) =>
            bg(COLORS[colorName] ?? colorFromText(bannerText), text);
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

  const setBanner: Omit<RegisteredCommand, "name"> = {
    description: "Set the session banner and name (empty to clear)",
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
  };

  pi.registerCommand("banner", setBanner);
  pi.registerCommand("rename", setBanner);

  pi.registerCommand("color", {
    description: `Set the banner color (${COLOR_NAMES.join(", ")}, default, or empty for random)`,
    getArgumentCompletions: colorCompletions,
    handler: async (args, ctx) => {
      const requested = (args ?? "").trim().toLowerCase();

      if (requested && requested !== "default" && !COLORS[requested]) {
        ctx.ui.notify(`Unknown color: ${requested}. Available: ${COLOR_NAMES.join(", ")}, default`, "error");
        return;
      }

      colorName = requested === "default" ? "" : requested || randomColorName();
      pi.appendEntry("session-banner-color", { color: colorName });

      if (bannerText) showBanner(ctx);
      ctx.ui.notify(colorName ? `Banner color: ${colorName}` : "Banner color reset", "info");
    },
  });
}
