-- Customize Mason

---@type LazySpec
return {
  -- use mason-tool-installer for automatically installing Mason packages
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      -- Make sure to use the names found in `:Mason`
      ensure_installed = {
        -- Lua
        "lua-language-server",
        "stylua",
        "selene",

        -- Python
        "basedpyright",
        "black",
        "isort",
        "debugpy",

        -- C / C++
        "clangd",
        "codelldb",
        -- "cmake-language-server",

        -- Rust
        "rust-analyzer",

        -- Zig
        "zls",

        -- Haskell
        "haskell-language-server",
        "haskell-debug-adapter",

        -- Fortran
        "fortls",
        "findent",

        -- LaTeX / XML / JSON / YAML / TOML
        "texlab",
        "lemminx",
        "json-lsp",
        "yaml-language-server",
        "taplo",

        -- Shell / misc
        "bash-language-server",
        "shfmt",

        -- Treesitter CLI
        "tree-sitter-cli",
      },
    },
  },
}
