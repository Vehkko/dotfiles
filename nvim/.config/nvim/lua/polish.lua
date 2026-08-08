-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- 自定义 filetype：如果你不用 foo/fooscript，可以整段删掉
-- vim.filetype.add {
--   extension = {
--     foo = "fooscript",
--   },
--   filename = {
--     ["Foofile"] = "fooscript",
--   },
--   pattern = {
--     ["~/%.config/foo/.*"] = "fooscript",
--   },
-- }

-- Neovide / GUI 透明度设置
vim.g.neovide_opacity = 0.88
vim.g.transparency = 0.8
vim.g.neovide_background_color = "#0f1117" .. string.format("%02x", math.floor(255 * vim.g.transparency))

-- 允许项目级 .nvim.lua / .exrc，但开启 secure 限制危险操作
vim.o.exrc = true
vim.o.secure = true

-- 行号
vim.opt.number = true
vim.opt.relativenumber = true

-- GUI 字体；终端里不会生效
-- vim.opt.guifont = { "CaskaydiaCove Nerd Font Mono", ":h13" }
vim.opt.guifont = { "MesloLGS NF", ":h12" }

-- Esc 退出终端模式
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true })

-- Ensure custom Treesitter parser install dir is in runtimepath
local site_dir = vim.fn.stdpath "data" .. "/site"
if not vim.tbl_contains(vim.opt.runtimepath:get(), site_dir) then vim.opt.runtimepath:append(site_dir) end

-- Codeium 相关配置：如果以后重新启用 Codeium，可以打开
-- vim.api.nvim_create_autocmd("ColorScheme", {
--   callback = function()
--     vim.api.nvim_set_hl(0, "CodeiumSuggestion", { link = "Comment" })
--     vim.api.nvim_set_hl(0, "CodeiumSuggestionText", { link = "Comment" })
--     vim.api.nvim_set_hl(0, "CodeiumSuggestionGhostText", { link = "Comment" })
--   end,
-- })
-- vim.cmd "doautocmd ColorScheme"
