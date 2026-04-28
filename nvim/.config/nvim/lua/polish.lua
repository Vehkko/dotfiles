-- if true then return end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- This will run last in the setup process and is a good place to configure
-- things like custom filetypes. This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- Set up custom filetypes
vim.filetype.add {
  extension = {
    foo = "fooscript",
  },
  filename = {
    ["Foofile"] = "fooscript",
  },
  pattern = {
    ["~/%.config/foo/.*"] = "fooscript",
  },
}

-- 这是自己添加的:

-- opacity
-- vim.g.neovide_transparency = 0.85
vim.g.neovide_opacity = 0.8
vim.g.transparency = 0.8
vim.g.neovide_background_color = ("#0f1117" .. string.format("%x", math.floor(((255 * vim.g.transparency) or 0.82))))

vim.o.exrc = true
vim.o.secure = true

vim.opt.number = true -- 显示绝对行号
vim.opt.relativenumber = true -- 显示相对行号

vim.opt.guifont = { "CaskaydiaCove Nerd Font Mono", ":h13" }

-- ecs 退出终端
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { noremap = true })

-- -- 让 Codeium 的虚拟文本更“灰”，尽量与主题兼容
-- vim.api.nvim_create_autocmd("ColorScheme", {
--   callback = function()
--     -- 这几个名字在不同版本/主题下可能略有差异；至少 Comment 一定存在
--     vim.api.nvim_set_hl(0, "CodeiumSuggestion", { link = "Comment" })
--     vim.api.nvim_set_hl(0, "CodeiumSuggestionText", { link = "Comment" })
--     vim.api.nvim_set_hl(0, "CodeiumSuggestionGhostText", { link = "Comment" })
--   end,
-- })
-- -- 立刻应用一次（不等你切换主题）
-- vim.cmd "doautocmd ColorScheme"

-- 到这里为止
