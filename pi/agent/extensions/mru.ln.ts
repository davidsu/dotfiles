/**
 * MRU (Most Recently Used) file picker.
 *
 * `/mru` opens the shell `mru --print-path` (fzf over neovim MRU list)
 * and inserts the selected file path into the editor.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent"
import { spawnSync } from "node:child_process"

export default function (pi: ExtensionAPI) {
	pi.registerCommand("mru", {
		description: "Pick a recently used file and insert its path",
		handler: async (_args, ctx) => {
			if (!ctx.hasUI) {
				ctx.ui.notify("mru requires interactive mode", "error")
				return
			}

			const selected = await ctx.ui.custom<string | null>((tui, _theme, _kb, done) => {
				setTimeout(() => {
					tui.stop()

					const result = spawnSync("zsh", ["-ic", "mru --print-path"], {
						stdio: ["inherit", "pipe", "inherit"],
						encoding: "utf-8",
					})

					tui.start()
					tui.terminal.clearScreen()
					tui.requestRender(true)

					const output = (result.stdout ?? "").trim()
					done(output || null)
				}, 0)

				return {
					render: () => [],
					invalidate: () => {},
					handleInput: () => {},
				}
			})

			if (selected) ctx.ui.setEditorText(selected)
		},
	})
}
