-- Terminal-Only Options
-- These options are set differently in terminal Neovim vs VSCode/Cursor

local opt = vim.opt

-- Display (VSCode has its own, so we enable Neovim's)
opt.number = true                -- show line numbers
opt.showcmd = true               -- show incomplete commands
opt.laststatus = 2               -- always show statusline

