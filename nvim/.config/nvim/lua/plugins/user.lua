-- You can also add or configure plugins by creating files in this `plugins/` folder.

---@type LazySpec
return {
  -- Presence
  { "andweeb/presence.nvim" },

  -- LSP signature hint
  {
    "ray-x/lsp_signature.nvim",
    event = "BufRead",
    config = function() require("lsp_signature").setup() end,
  },

  -- jk / kj 退出 insert / terminal
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    opts = {
      timeout = 150,
      default_mappings = false,
      mappings = {
        i = {
          j = { k = "<Esc>" },
          k = { j = "<Esc>" },
        },
        t = {
          j = { k = "<C-\\><C-n>" },
          k = { j = "<C-\\><C-n>" },
        },
      },
    },
  },

  -- LuaSnip 自定义 snippets
  {
    "L3MON4D3/LuaSnip",
    config = function(plugin, opts)
      -- 先加载 AstroNvim 默认配置
      require "astronvim.plugins.configs.luasnip"(plugin, opts)

      local luasnip = require "luasnip"
      luasnip.filetype_extend("javascript", { "javascriptreact" })

      require("luasnip.loaders.from_vscode").lazy_load {
        paths = {
          vim.fn.stdpath "config" .. "/lua/user/snippets",
        },
      }
    end,
  },

  -- autopairs：给 LaTeX 增加 $...$ 规则
  {
    "windwp/nvim-autopairs",
    config = function(plugin, opts)
      require "astronvim.plugins.configs.nvim-autopairs"(plugin, opts)

      local npairs = require "nvim-autopairs"
      local Rule = require "nvim-autopairs.rule"
      local cond = require "nvim-autopairs.conds"

      npairs.add_rules {
        Rule("$", "$", { "tex", "latex" })
          :with_pair(cond.not_after_regex "%%")
          :with_pair(cond.not_before_regex("xxx", 3))
          :with_move(cond.none())
          :with_del(cond.not_after_regex "xx")
          :with_cr(cond.none()),
      }
    end,
  },

  -- Fitten Code
  -- {
  --   "luozhiya/fittencode.nvim",
  --   opts = {},
  -- },

  -- Markdown / Typst / LaTeX preview enhancement
  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    opts = {},
  },

  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown", "markdown.mdx" },
    build = "cd app && corepack enable && corepack prepare yarn@1.22.22 --activate && yarn install",
    init = function() vim.g.mkdp_filetypes = { "markdown", "markdown.mdx" } end,
  },

  -- Noice：调整命令行浮窗位置
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      lsp = {
        hover = {
          enabled = false,
        },
        signature = {
          enabled = false,
        },
      },

      views = {
        cmdline_popup = {
          position = {
            row = 5,
            col = "50%",
          },
          border = {
            style = "double",
          },
        },
      },
    },
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
  },

  -- DAP：C/C++ codelldb 配置
  {
    "mfussenegger/nvim-dap",
    optional = true,
    config = function(plugin, opts)
      local ok_cfg, astro_cfg = pcall(require, "astronvim.plugins.configs.nvim-dap")
      if ok_cfg and type(astro_cfg) == "function" then astro_cfg(plugin, opts) end

      vim.schedule(function()
        local dap = require "dap"

        local function pick_program() return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file") end

        local function pick_args()
          local s = vim.fn.input "Args: "
          if not s or s == "" then return {} end
          return vim.split(s, "%s+")
        end

        dap.configurations.cpp = {
          {
            name = "LLDB Launch",
            type = "codelldb",
            request = "launch",
            program = pick_program,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
            console = "internalConsole",
          },
          {
            name = "LLDB Launch (args)",
            type = "codelldb",
            request = "launch",
            program = pick_program,
            args = pick_args,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
            console = "internalConsole",
          },
        }

        dap.configurations.c = dap.configurations.cpp
      end)
    end,
  },

  -- Move lines / blocks
  { "matze/vim-move" },

  -- VimTeX：插件本身由 community.lua 引入，这里只覆盖个人设置
  {
    "lervag/vimtex",
    init = function()
      vim.g.vimtex_view_method = "zathura"
      vim.g.vimtex_syntax_conceal_disable = 1
      vim.opt.conceallevel = 0
    end,
  },

  -- v6 默认 dashboard 是 snacks.nvim，不再用 alpha-nvim
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = table.concat({
            " ███╗   ██╗███████╗ ██████╗ ██╗   ██╗ ██╗███╗   ███╗",
            " ████╗  ██║██╔════╝██╔═████╗██║   ██║███║████╗ ████║",
            " ██╔██╗ ██║█████╗  ██║██╔██║██║   ██║╚██║██╔████╔██║",
            " ██║╚██╗██║██╔══╝  ████╔╝██║╚██╗ ██╔╝ ██║██║╚██╔╝██║",
            " ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝  ██║██║ ╚═╝ ██║",
            " ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝   ╚═╝╚═╝     ╚═╝",
            "",
          }, "\n"),
        },
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function() vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "#FFB000", bold = true }) end,
      })

      vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "#FFB000", bold = true })
    end,
  },

  -- Fortran helper
  {
    "wassup05/fortran.nvim",
    ft = { "fortran" },
    opts = {},
  },

  -- Rainbow delimiters
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = "VeryLazy",
    config = function()
      local rainbow_delimiters = require "rainbow-delimiters"

      vim.g.rainbow_delimiters = {
        strategy = {
          [""] = rainbow_delimiters.strategy["global"],
          vim = rainbow_delimiters.strategy["local"],
        },
        query = {
          [""] = "rainbow-delimiters",
          lua = "rainbow-blocks",
        },
        highlight = {
          "RainbowDelimiterRed",
          "RainbowDelimiterYellow",
          "RainbowDelimiterBlue",
          "RainbowDelimiterOrange",
          "RainbowDelimiterGreen",
          "RainbowDelimiterViolet",
          "RainbowDelimiterCyan",
        },
      }
    end,
  },

  -- 更好的括号匹配
  {
    "andymass/vim-matchup",
    event = "VeryLazy",
    init = function()
      vim.g.matchup_matchparen_enabled = 1
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
    end,
  },

  -- surround
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    opts = {},
  },

  -- Outline
  {
    "stevearc/aerial.nvim",
    opts = {
      default_direction = "right",
      placement = "edge",
      max_width = { 40, 0.2 },
      width = nil,
      min_width = 10,
      backends = { "lsp", "markdown", "man" },
    },
    keys = {
      { "<leader>o", "<cmd>AerialToggle!<CR>", desc = "Aerial Outline" },
      { "]s", "<cmd>AerialNext<CR>", desc = "Next Symbol" },
      { "[s", "<cmd>AerialPrev<CR>", desc = "Prev Symbol" },
    },
  },

  -- -- 多光标
  -- {
  --   "mg979/vim-visual-multi",
  --   branch = "master",
  --   event = "VeryLazy",
  --   -- init = function()
  --   --   -- 可选：显式设置常用快捷键
  --   --   vim.g.VM_maps = {
  --   --     ["Find Under"] = "<C-n>",
  --   --     ["Find Subword Under"] = "<C-n>",
  --   --   }
  --   -- end,
  -- },
}
