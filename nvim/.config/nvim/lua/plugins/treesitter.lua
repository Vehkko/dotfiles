-- Customize Treesitter
-- --------------------
-- Treesitter customizations are handled with AstroCore
-- as nvim-treesitter simply provides a download utility for parsers

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    treesitter = {
      highlight = true,
      indent = true,
      auto_install = true,

      ensure_installed = {
        -- Neovim / Lua
        "lua",
        "luap",
        "vim",
        "vimdoc",
        "query",

        -- C / C++ / CUDA / CMake
        "c",
        "cpp",
        "cuda",
        "cmake",

        -- Python / scientific scripting
        "python",

        -- Shell
        "bash",

        -- Markdown / LaTeX
        "markdown",
        "markdown_inline",
        "latex",

        -- Config formats
        "json",
        "jsonc",
        "yaml",
        "toml",
        "xml",

        -- Other languages you use / have packs for
        "rust",
        "zig",
        "julia",
        "haskell",
        "java",
        "matlab",

        -- Useful for Noice cmdline regex highlighting
        "regex",
      },
    },
  },
}
