-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- You can also add or configure plugins by creating files in this `plugins/` folder
-- PLEASE REMOVE THE EXAMPLES YOU HAVE NO INTEREST IN BEFORE ENABLING THIS FILE
-- Here are some examples:

---@type LazySpec
return {

  -- == Examples of Adding Plugins ==

  { "andweeb/presence.nvim" },

  {
    "ray-x/lsp_signature.nvim",
    event = "BufRead",
    config = function() require("lsp_signature").setup() end,
  },

  -- You can disable default plugins as follows:
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    opts = {
      timeout = 150, -- 100~200 都行：越小越不误触
      default_mappings = false, -- 不用它默认的，完全按你的来
      mappings = {
        i = {
          j = { k = "<Esc>" }, -- insert: jk
          k = { j = "<Esc>" }, -- insert: kj
        },
        t = {
          j = { k = "<C-\\><C-n>" }, -- terminal: jk
          k = { j = "<C-\\><C-n>" }, -- terminal: kj
        },
      },
    },
  },

  -- You can also easily customize additional setup of plugins that is outside of the plugin's setup call
  {
    "L3MON4D3/LuaSnip",
    config = function(plugin, opts)
      require "astronvim.plugins.configs.luasnip"(plugin, opts) -- include the default astronvim config that calls the setup call
      -- add more custom luasnip configuration such as filetype extend or custom snippets
      local luasnip = require "luasnip"
      luasnip.filetype_extend("javascript", { "javascriptreact" })

      -- load snippets paths
      require("luasnip.loaders.from_vscode").lazy_load {
        -- this can be used if your configuration lives in ~/.config/nvim
        -- if your configuration lives in ~/.config/astronvim, the full path
        -- must be specified in the next line
        paths = { "./lua/user/snippets" },
      }
    end,
  },

  {
    "windwp/nvim-autopairs",
    config = function(plugin, opts)
      require "astronvim.plugins.configs.nvim-autopairs"(plugin, opts) -- include the default astronvim config that calls the setup call
      -- add more custom autopairs configuration such as custom rules
      local npairs = require "nvim-autopairs"
      local Rule = require "nvim-autopairs.rule"
      local cond = require "nvim-autopairs.conds"
      npairs.add_rules(
        {
          Rule("$", "$", { "tex", "latex" })
            -- don't add a pair if the next character is %
            :with_pair(cond.not_after_regex "%%")
            -- don't add a pair if  the previous character is xxx
            :with_pair(
              cond.not_before_regex("xxx", 3)
            )
            -- don't move right when repeat character
            :with_move(cond.none())
            -- don't delete if the next character is xx
            :with_del(cond.not_after_regex "xx")
            -- disable adding a newline when you press <cr>
            :with_cr(cond.none()),
        },
        -- disable for .vim files, but it work for another filetypes
        Rule("a", "a", "-vim")
      )
    end,
  },

  {
    "luozhiya/fittencode.nvim",
    opts = {},
  },

  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    dependencies = {
      -- "nvim-treesitter/nvim-treesitter",
      -- "nvim-tree/nvim-web-devicons",
    },
    opts = {},
  },

  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      -- add any options here
      views = {
        cmdline_popup = {
          position = {
            row = 5, -- 调整命令行位置到上方
            col = "50%", -- 让它水平居中
          },
          border = {
            style = "double", -- 使用双线边框
          },
        },
      },
    },
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      "rcarriga/nvim-notify",
    },
  },

  {
    "mfussenegger/nvim-dap",
    optional = true,
    config = function(plugin, opts)
      -- 1) 先跑 AstroNvim 默认的 dap 配置（重要）
      pcall(require, "astronvim.plugins.configs.nvim-dap")
      local ok_cfg, astro_cfg = pcall(require, "astronvim.plugins.configs.nvim-dap")
      if ok_cfg and type(astro_cfg) == "function" then astro_cfg(plugin, opts) end

      -- 2) 再“延迟”覆盖（确保在所有默认/社区 pack 修改之后执行）
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

  { "matze/vim-move" },

  {
    "lervag/vimtex",
    lazy = false, -- we don't want to lazy load VimTeX
    -- tag = "v2.15", -- uncomment to pin to a specific release
    init = function()
      -- VimTeX configuration goes here, e.g.
      vim.g.vimtex_view_method = "zathura"
      vim.g.vimtex_syntax_conceal_disable = 1
      vim.opt.conceallevel = 0
    end,
  },

  {
    "goolord/alpha-nvim",
    opts = function(_, opts)
      -- 你的 Neovim 自定义 logo
      opts.section.header.val = {
        " ███╗   ██╗███████╗ ██████╗ ██╗   ██╗ ██╗███╗   ███╗",
        " ████╗  ██║██╔════╝██╔═████╗██║   ██║███║████╗ ████║",
        " ██╔██╗ ██║█████╗  ██║██╔██║██║   ██║╚██║██╔████╔██║",
        " ██║╚██╗██║██╔══╝  ████╔╝██║╚██╗ ██╔╝ ██║██║╚██╔╝██║",
        " ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝  ██║██║ ╚═╝ ██║",
        " ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝   ╚═╝╚═╝     ╚═╝",
        "",
        "",
      }

      -- Alpha header 橙色（自定义高亮组）
      vim.api.nvim_set_hl(0, "AlphaHeaderOrange", { fg = "#FFB000", bold = true })
      opts.section.header.opts.hl = "AlphaHeaderOrange"
      -- opts.section.header.opts.hl = "Function"
      return opts
    end,
  },

  {
    "wassup05/fortran.nvim",
    lazy = true,
    -- load the plugin when `ft` is fortran
    ft = { "fortran" },
    opts = {
      -- all your configuration options go here
    },
  },

  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = ":call mkdp#util#install()",
  },

  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      opts.autocmds = opts.autocmds or {}
      opts.autocmds.enable_inlay_hints = {
        {
          event = "LspAttach",
          desc = "Enable inlay hints on LSP attach",
          callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client and client:supports_method "textDocument/inlayHint" then
              vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
            end
          end,
        },
      }
      return opts
    end,
  },
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
  {
    "andymass/vim-matchup",
    event = "VeryLazy",
    init = function()
      vim.g.matchup_matchparen_enabled = 1
      vim.g.matchup_matchparen_offscreen = { method = "popup" } -- 匹配在屏幕外时提示
    end,
  },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    opts = {},
  },

  {
    "stevearc/aerial.nvim",
    opts = {
      default_direction = "right",
      max_width = { 40, 0.2 },
      width = nil,
      min_width = 10,
    },
    keys = {
      { "<leader>o", "<cmd>AerialToggle!<CR>", desc = "Aerial Outline" },
      { "]s", "<cmd>AerialNext<CR>", desc = "Next Symbol" },
      { "[s", "<cmd>AerialPrev<CR>", desc = "Prev Symbol" },
    },
  },

  -- {
  --   -- 注册 <leader>-j
  --   "folke/which-key.nvim",
  --   opts = function(_, opts)
  --     opts.spec = opts.spec or {}
  --     vim.list_extend(opts.spec, {
  --       { "<leader>j", group = "Jupyter", mode = { "n", "v" } },
  --     })
  --   end,
  -- },
  -- {
  --   "GCBallesteros/jupytext.nvim",
  --   lazy = false,
  --   config = function()
  --     require("jupytext").setup {
  --       style = "hydrogen",
  --       output_extension = "auto",
  --     }
  --   end,
  -- },
  --
  -- {
  --   "3rd/image.nvim",
  --   build = false,
  --   opts = {
  --     backend = "kitty",
  --     processor = "magick_cli",
  --     max_width = 100,
  --     max_height = 120,
  --     max_width_window_percentage = math.huge,
  --     max_height_window_percentage = math.huge,
  --     window_overlap_clear_enabled = true,
  --     window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
  --     integrations = {
  --       markdown = {
  --         enabled = false,
  --       },
  --     },
  --   },
  -- },
  --
  -- {
  --   "benlubas/molten-nvim",
  --   version = "^1.0.0",
  --   build = ":UpdateRemotePlugins",
  --   dependencies = {
  --     "3rd/image.nvim",
  --   },
  --   init = function()
  --     vim.g.molten_image_provider = "image.nvim"
  --     vim.g.molten_image_location = "both"
  --     vim.g.molten_auto_open_output = false
  --     vim.g.molten_output_win_border = { "", "━", "", "" }
  --     vim.g.molten_output_win_max_height = 20
  --     vim.g.molten_output_virt_lines = true
  --     vim.g.molten_virt_text_output = true
  --     vim.g.molten_virt_text_max_lines = 12
  --     vim.g.molten_wrap_output = true
  --     vim.g.molten_tick_rate = 200
  --   end,
  --
  --   config = function()
  --     local function get_line(bufnr, lnum) return (vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or "") end
  --
  --     local function is_percent_marker(bufnr, lnum)
  --       local line = get_line(bufnr, lnum)
  --       return line:match "^# %%%%" or line:match "^#%%%%"
  --     end
  --
  --     local function trim_cell(bufnr, start_lnum, stop_lnum)
  --       local start = start_lnum
  --       local stop = stop_lnum
  --
  --       while start <= stop and get_line(bufnr, start):match "^%s*$" do
  --         start = start + 1
  --       end
  --       while stop >= start and get_line(bufnr, stop):match "^%s*$" do
  --         stop = stop - 1
  --       end
  --
  --       return start, stop
  --     end
  --
  --     local function current_percent_cell()
  --       local bufnr = 0
  --       local cur = vim.api.nvim_win_get_cursor(0)[1]
  --       local last = vim.api.nvim_buf_line_count(bufnr)
  --
  --       local marker = nil
  --       for l = cur, 1, -1 do
  --         if is_percent_marker(bufnr, l) then
  --           marker = l
  --           break
  --         end
  --       end
  --
  --       local next_marker = last + 1
  --       for l = cur + 1, last do
  --         if is_percent_marker(bufnr, l) then
  --           next_marker = l
  --           break
  --         end
  --       end
  --
  --       local start = marker and (marker + 1) or 1
  --       local stop = next_marker - 1
  --       start, stop = trim_cell(bufnr, start, stop)
  --
  --       local header = marker and get_line(bufnr, marker) or ""
  --       local is_markdown = header:match "%[markdown%]" ~= nil or header:match "%[md%]" ~= nil
  --
  --       return {
  --         start = start,
  --         stop = stop,
  --         is_markdown = is_markdown,
  --       }
  --     end
  --
  --     local function collect_percent_cells()
  --       local bufnr = 0
  --       local last = vim.api.nvim_buf_line_count(bufnr)
  --       local markers = {}
  --
  --       for l = 1, last do
  --         if is_percent_marker(bufnr, l) then table.insert(markers, l) end
  --       end
  --
  --       local cells = {}
  --
  --       if #markers == 0 then
  --         local start, stop = trim_cell(bufnr, 1, last)
  --         if start <= stop then
  --           table.insert(cells, {
  --             start = start,
  --             stop = stop,
  --             is_markdown = false,
  --           })
  --         end
  --         return cells
  --       end
  --
  --       for i, marker in ipairs(markers) do
  --         local next_marker = markers[i + 1] or (last + 1)
  --         local start, stop = trim_cell(bufnr, marker + 1, next_marker - 1)
  --         local header = get_line(bufnr, marker)
  --         local is_markdown = header:match "%[markdown%]" ~= nil or header:match "%[md%]" ~= nil
  --
  --         if start <= stop then
  --           table.insert(cells, {
  --             start = start,
  --             stop = stop,
  --             is_markdown = is_markdown,
  --           })
  --         end
  --       end
  --
  --       return cells
  --     end
  --
  --     local function ensure_kernel_attached()
  --       local kernels = vim.fn.MoltenRunningKernels(true)
  --       if type(kernels) == "table" and #kernels > 0 then return true end
  --
  --       vim.notify(
  --         "当前 buffer 还没有绑定 Jupyter kernel。请先按 <leader>ji 初始化一次。",
  --         vim.log.levels.WARN
  --       )
  --       return false
  --     end
  --
  --     local function eval_current_percent_cell()
  --       if not ensure_kernel_attached() then return end
  --
  --       local cell = current_percent_cell()
  --
  --       if cell.start > cell.stop then
  --         vim.notify("当前 # %% cell 为空", vim.log.levels.WARN)
  --         return
  --       end
  --
  --       if cell.is_markdown then
  --         vim.notify("这是 markdown cell，不发送到 kernel", vim.log.levels.INFO)
  --         return
  --       end
  --
  --       vim.fn.MoltenEvaluateRange(cell.start, cell.stop)
  --     end
  --
  --     local function eval_all_percent_cells()
  --       if not ensure_kernel_attached() then return end
  --
  --       local cells = collect_percent_cells()
  --       local count = 0
  --
  --       for _, cell in ipairs(cells) do
  --         if not cell.is_markdown then
  --           vim.fn.MoltenEvaluateRange(cell.start, cell.stop)
  --           count = count + 1
  --         end
  --       end
  --
  --       vim.notify(("已发送 %d 个 code cells 到 kernel"):format(count), vim.log.levels.INFO)
  --     end
  --
  --     local function has_floating_window_in_current_tab()
  --       for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
  --         local cfg = vim.api.nvim_win_get_config(win)
  --         if cfg.relative ~= "" then return true end
  --       end
  --       return false
  --     end
  --
  --     local function toggle_molten_output()
  --       if has_floating_window_in_current_tab() then
  --         vim.cmd "MoltenHideOutput"
  --       else
  --         vim.cmd "MoltenShowOutput"
  --       end
  --     end
  --
  --     vim.keymap.set("n", "<leader>ji", "<cmd>MoltenInit<cr>", {
  --       desc = "Jupyter: init kernel",
  --       silent = true,
  --     })
  --
  --     vim.keymap.set("n", "<leader>jj", eval_current_percent_cell, {
  --       desc = "Jupyter: run current #%% cell",
  --       silent = true,
  --     })
  --
  --     vim.keymap.set("n", "<leader>ja", eval_all_percent_cells, {
  --       desc = "Jupyter: run all #%% cells",
  --       silent = true,
  --     })
  --
  --     vim.keymap.set("v", "<leader>jr", ":<C-u>MoltenEvaluateVisual<CR>gv", {
  --       desc = "Jupyter: run visual selection",
  --       silent = true,
  --     })
  --
  --     vim.keymap.set("n", "<leader>jl", "<cmd>MoltenEvaluateLine<cr>", {
  --       desc = "Jupyter: run current line",
  --       silent = true,
  --     })
  --
  --     vim.keymap.set("n", "<leader>jo", toggle_molten_output, {
  --       desc = "Jupyter: toggle output",
  --       silent = true,
  --     })
  --
  --     vim.keymap.set("n", "<leader>jp", "<cmd>noautocmd MoltenEnterOutput<cr>", {
  --       desc = "Jupyter: enter output",
  --       silent = true,
  --     })
  --
  --     vim.keymap.set("n", "<leader>jR", "<cmd>MoltenReevaluateCell<cr>", {
  --       desc = "Jupyter: rerun active molten cell",
  --       silent = true,
  --     })
  --
  --     vim.keymap.set("n", "<leader>jk", "<cmd>MoltenInterrupt<cr>", {
  --       desc = "Jupyter: interrupt kernel",
  --       silent = true,
  --     })
  --   end,
  -- },
}
