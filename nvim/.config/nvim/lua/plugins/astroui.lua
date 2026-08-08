-- AstroUI provides the basis for configuring the AstroNvim User Interface
-- Configuration documentation can be found with `:h astroui`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  "AstroNvim/astroui",
  ---@type AstroUIOpts
  opts = {
    -- change colorscheme
    colorscheme = "cyberdream",

    -- AstroUI allows you to easily modify highlight groups for any and all colorschemes
    highlights = {
      init = {
        -- 这里可以写所有主题通用的高亮覆盖
        -- Normal = { bg = "#000000" },
      },

      astrodark = {
        -- 这里只对 astrotheme/astrodark 生效
        -- Normal = { bg = "#000000" },
      },

      cyberdream = {
        -- 如果以后想专门覆盖 cyberdream，可以写这里
        -- Normal = { bg = "#000000" },
      },
    },

    -- Icons can be configured throughout the interface
    icons = {
      -- configure the loading of the lsp in the status line
      LSPLoading1 = "⠋",
      LSPLoading2 = "⠙",
      LSPLoading3 = "⠹",
      LSPLoading4 = "⠸",
      LSPLoading5 = "⠼",
      LSPLoading6 = "⠴",
      LSPLoading7 = "⠦",
      LSPLoading8 = "⠧",
      LSPLoading9 = "⠇",
      LSPLoading10 = "⠏",
    },
  },
}
