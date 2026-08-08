return {
  {
    "sheng-tse/jupynvim",

    build = function(plugin)
      local install = loadfile(plugin.dir .. "/lua/jupynvim/install.lua")()
      install.run(plugin)
    end,

    config = function()
      local J = require "jupynvim"
      local Notebook = require "jupynvim.notebook"
      local CellMode = require "jupynvim.cellmode"

      J.setup {
        log_level = "info",

        image_renderer = "placeholder",
        image_rows = 16,
        image_cols = 48,

        -- Use registered kernelspecs. A nearby .venv will not silently
        -- override the kernel stored in the notebook.
        auto_venv = false,

        smooth_scroll = false,

        -- Disable jupynvim's normal action mappings.
        disable_default_keymaps = true,
        keymaps = {},

        -- Do not intercept AstroNvim's global mappings.
        explorer_keys = {},
        terminal_keys = {},
        terminal_right_keys = {},
        pick_keys = {
          files = {},
          grep = {},
        },

        remote = {},
      }

      local clipboard = nil
      local repairing = {}
      local repair_pending = {}

      local function is_notebook(buf) return vim.api.nvim_buf_is_valid(buf) and Notebook.get(buf) ~= nil end

      local function get_win(buf)
        local win = vim.fn.bufwinid(buf)
        if win == -1 or not vim.api.nvim_win_is_valid(win) then return nil end
        return win
      end

      local function native_normal(keys)
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
      end

      local function source_lines(source)
        source = source or ""
        if source:sub(-1) == "\n" then source = source:sub(1, -2) end
        if source == "" then return { "" } end
        return vim.split(source, "\n", { plain = true })
      end

      local function set_cell_cursor(buf, index)
        local win = get_win(buf)
        local range = CellMode.ranges(buf)[index]
        if not win or not range then return false end
        pcall(vim.api.nvim_win_set_cursor, win, { range.start + 1, 0 })
        return true
      end

      ------------------------------------------------------------------------
      -- Notebook structure guard
      ------------------------------------------------------------------------

      local function count_line(lines, target)
        local count = 0
        for _, line in ipairs(lines) do
          if line == target then count = count + 1 end
        end
        return count
      end

      local function expected_output_markers(nb)
        local count = 0
        for _, cell in ipairs(nb.cells) do
          if cell.cell_type == "code" and #Notebook.output_lines(cell) > 0 then count = count + 1 end
        end
        return count
      end

      local function output_regions_valid(buf, nb, ranges)
        for index, range in ipairs(ranges) do
          local expected = Notebook.output_lines(nb.cells[index] or {})

          if #expected == 0 then
            if range.out_sep ~= nil then return false end
          else
            if range.out_sep == nil or range.out_stop == nil then return false end

            local actual = vim.api.nvim_buf_get_lines(buf, range.out_sep + 1, range.out_stop, false)

            if not vim.deep_equal(actual, expected) then return false end
          end
        end

        return true
      end

      local function restore_valid_buffer(buf, edit_index, message)
        local nb = Notebook.get(buf)
        if not nb then return end

        local was_modifiable = vim.bo[buf].modifiable
        vim.bo[buf].modifiable = true
        J._populate_buffer(nb)
        vim.bo[buf].modifiable = was_modifiable
        vim.bo[buf].modified = true

        set_cell_cursor(buf, math.max(1, math.min(edit_index or 1, #nb.cells)))
        J.refresh(buf)

        if message then vim.notify(message, vim.log.levels.WARN) end
      end

      local function validate_edit_buffer(buf)
        if repairing[buf] or not is_notebook(buf) or CellMode.is_command(buf) then return end

        repairing[buf] = true

        local ok, err = pcall(function()
          local nb = Notebook.get(buf)
          local edit_index = vim.b[buf].user_jupynvim_edit_index or CellMode.selected_idx(buf)
          local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

          if
            count_line(lines, Notebook.CELL_SEP) ~= math.max(#nb.cells - 1, 0)
            or count_line(lines, Notebook.OUT_SEP) ~= expected_output_markers(nb)
          then
            restore_valid_buffer(buf, edit_index, "Notebook metadata is protected; the invalid edit was reverted")
            return
          end

          local ranges = CellMode.ranges(buf)
          if #ranges ~= #nb.cells or not output_regions_valid(buf, nb, ranges) then
            restore_valid_buffer(
              buf,
              edit_index,
              "Notebook output regions are protected; the invalid edit was reverted"
            )
            return
          end

          local range = ranges[edit_index]
          if not range then
            restore_valid_buffer(buf, edit_index, "Notebook structure was repaired")
            return
          end

          -- An empty cell must still occupy one real blank buffer line.
          if range.stop <= range.start then
            local was_modifiable = vim.bo[buf].modifiable
            vim.bo[buf].modifiable = true
            vim.api.nvim_buf_set_lines(buf, range.start, range.start, false, { "" })
            vim.bo[buf].modifiable = was_modifiable

            range = CellMode.ranges(buf)[edit_index]
            local win = get_win(buf)
            if win and range then
              pcall(vim.api.nvim_win_set_cursor, win, { range.start + 1, 0 })
              CellMode.set_position(buf, edit_index, range.start + 1, 0)
            end
          end

          -- Keep the notebook model synchronized with the latest valid edit.
          -- If a later operation damages a separator, this is the state that
          -- gets restored.
          nb:sync_from_buffer()
          CellMode.clamp_to_cell(buf)
        end)

        repairing[buf] = nil

        if not ok then vim.notify("Notebook structure guard failed: " .. tostring(err), vim.log.levels.ERROR) end
      end

      local function schedule_validation(buf)
        if repair_pending[buf] then return end

        repair_pending[buf] = true
        vim.schedule(function()
          repair_pending[buf] = nil
          validate_edit_buffer(buf)
        end)
      end

      local function enter_edit(buf, keys)
        validate_edit_buffer(buf)
        vim.b[buf].user_jupynvim_edit_index = CellMode.selected_idx(buf)
        CellMode.enter_edit(buf, keys)
      end

      local function enter_command(buf)
        validate_edit_buffer(buf)
        CellMode.enter_command(buf)
        vim.b[buf].user_jupynvim_edit_index = nil
      end

      ------------------------------------------------------------------------
      -- Cell operations
      ------------------------------------------------------------------------

      local function wait_for_insert(buf, old_count, target, callback, attempt)
        attempt = attempt or 1

        local nb = Notebook.get(buf)
        if not nb then return end

        if #nb.cells > old_count and nb.cells[target] then
          set_cell_cursor(buf, target)
          callback(nb, target)
          return
        end

        if attempt >= 100 then
          vim.notify("Timed out while inserting a notebook cell", vim.log.levels.ERROR)
          return
        end

        vim.defer_fn(function() wait_for_insert(buf, old_count, target, callback, attempt + 1) end, 20)
      end

      local function insert_cell(buf, where, cell_type, source)
        validate_edit_buffer(buf)

        local nb = Notebook.get(buf)
        if not nb then return end

        local selected = CellMode.selected_idx(buf)
        local old_count = #nb.cells
        local target = where == "above" and selected or selected + 1

        CellMode.with_modifiable(buf, function() J.add_cell(buf, where) end)

        wait_for_insert(buf, old_count, target, function(current_nb, index)
          local range = CellMode.ranges(buf)[index]
          if not range then return end

          local was_modifiable = vim.bo[buf].modifiable
          vim.bo[buf].modifiable = true
          vim.api.nvim_buf_set_lines(buf, range.start, range.stop, false, source_lines(source))
          vim.bo[buf].modifiable = was_modifiable

          current_nb:sync_from_buffer()
          set_cell_cursor(buf, index)

          if cell_type == "markdown" then J.set_cell_type(buf, "markdown") end

          CellMode.enter_command(buf)
          vim.b[buf].user_jupynvim_edit_index = nil
          vim.bo[buf].modified = true
          J.refresh(buf)
        end)
      end

      local function delete_cell(buf)
        validate_edit_buffer(buf)

        local nb = Notebook.get(buf)
        if not nb then return end

        local index = CellMode.selected_idx(buf)
        local cell = nb.cells[index]
        if not cell then return end

        local deleted_id = cell.id

        CellMode.with_modifiable(buf, function() J.delete_cell(buf) end)

        local attempt = 0
        local function finish()
          attempt = attempt + 1

          local current_nb = Notebook.get(buf)
          if not current_nb then return end

          local exists = false
          for _, current_cell in ipairs(current_nb.cells) do
            if current_cell.id == deleted_id then
              exists = true
              break
            end
          end

          if not exists then
            set_cell_cursor(buf, math.max(1, math.min(index, #current_nb.cells)))
            CellMode.enter_command(buf)
            vim.bo[buf].modified = true
            J.refresh(buf)
            return
          end

          if attempt < 100 then vim.defer_fn(finish, 20) end
        end

        vim.defer_fn(finish, 20)
      end

      local function move_cell(buf, delta)
        validate_edit_buffer(buf)

        local nb = Notebook.get(buf)
        if not nb then return end

        local index = CellMode.selected_idx(buf)
        local cell = nb.cells[index]
        if not cell then return end

        local target = math.max(1, math.min(#nb.cells, index + delta))
        if target == index then return end

        local cell_id = cell.id
        J.move_cell(buf, delta)

        local attempt = 0
        local function finish()
          attempt = attempt + 1

          local current_nb = Notebook.get(buf)
          if not current_nb then return end

          if current_nb.cells[target] and current_nb.cells[target].id == cell_id then
            set_cell_cursor(buf, target)
            CellMode.enter_command(buf)
            vim.bo[buf].modified = true
            return
          end

          if attempt < 100 then vim.defer_fn(finish, 20) end
        end

        vim.defer_fn(finish, 20)
      end

      local function yank_cell(buf)
        validate_edit_buffer(buf)

        local nb = Notebook.get(buf)
        if not nb then return end

        nb:sync_from_buffer()

        local cell = nb.cells[CellMode.selected_idx(buf)]
        if not cell then return end

        clipboard = {
          source = cell.source or "",
          cell_type = cell.cell_type or "code",
        }

        vim.fn.setreg('"', clipboard.source)
        vim.notify("Notebook cell yanked", vim.log.levels.INFO)
      end

      local function paste_cell(buf, where)
        if not clipboard then
          vim.notify("No notebook cell has been yanked", vim.log.levels.INFO)
          return
        end

        insert_cell(buf, where, clipboard.cell_type, clipboard.source)
      end

      ------------------------------------------------------------------------
      -- Keymaps
      ------------------------------------------------------------------------

      local function remove_upstream_keymaps(buf)
        for _, mode in ipairs { "n", "i", "v", "x", "s", "o", "t" } do
          for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
            if type(mapping.desc) == "string" and mapping.desc:match "^jupynvim:" then
              pcall(vim.api.nvim_buf_del_keymap, buf, mode, mapping.lhs)
            end
          end
        end
      end

      local function command_or_native(buf, lhs, action, description)
        vim.keymap.set("n", lhs, function()
          if CellMode.is_command(buf) then
            action()
          else
            native_normal(lhs)
          end
        end, {
          buffer = buf,
          silent = true,
          nowait = true,
          desc = description,
        })
      end

      local function attach_cellmode_keymaps(buf)
        command_or_native(buf, "j", function() CellMode.move_selection(buf, 1) end, "Notebook cell: select next cell")

        command_or_native(
          buf,
          "k",
          function() CellMode.move_selection(buf, -1) end,
          "Notebook cell: select previous cell"
        )

        command_or_native(buf, "gg", function() CellMode.select_first(buf) end, "Notebook cell: select first cell")

        command_or_native(buf, "G", function() CellMode.select_last(buf) end, "Notebook cell: select last cell")

        command_or_native(buf, "i", function() enter_edit(buf, "i") end, "Notebook cell: edit with insert")

        command_or_native(buf, "a", function() enter_edit(buf, "a") end, "Notebook cell: edit with append")

        command_or_native(buf, "I", function() enter_edit(buf, "I") end, "Notebook cell: edit at first non-blank")

        command_or_native(buf, "A", function() enter_edit(buf, "A") end, "Notebook cell: edit at end of line")

        command_or_native(
          buf,
          "o",
          function() insert_cell(buf, "below", "code", "") end,
          "Notebook cell: insert code cell below"
        )

        command_or_native(
          buf,
          "O",
          function() insert_cell(buf, "above", "code", "") end,
          "Notebook cell: insert code cell above"
        )

        command_or_native(buf, "dd", function() delete_cell(buf) end, "Notebook cell: delete cell")

        command_or_native(buf, "yy", function() yank_cell(buf) end, "Notebook cell: yank cell")

        command_or_native(buf, "p", function() paste_cell(buf, "below") end, "Notebook cell: paste cell below")

        command_or_native(buf, "P", function() paste_cell(buf, "above") end, "Notebook cell: paste cell above")

        vim.keymap.set("n", "<Esc>", function()
          if CellMode.is_command(buf) then
            vim.cmd "nohlsearch"
          else
            enter_command(buf)
          end
        end, {
          buffer = buf,
          silent = true,
          nowait = true,
          desc = "Notebook cell: return to cell command mode",
        })
      end

      local function attach_notebook_menu(buf)
        local function map(lhs, action, description)
          vim.keymap.set("n", lhs, action, {
            buffer = buf,
            silent = true,
            desc = "Notebook: " .. description,
          })
        end

        -- Execution
        map("<leader>Nr", function()
          validate_edit_buffer(buf)
          J.run_cell(buf, { advance = false })
        end, "Run current cell")

        map("<leader>Nx", function()
          validate_edit_buffer(buf)
          J.run_cell(buf, { advance = true })
        end, "Run current cell and advance")

        map("<leader>NR", function()
          validate_edit_buffer(buf)
          J.run_all(buf)
        end, "Run all cells")

        map("<leader>Nu", function()
          validate_edit_buffer(buf)
          J.run_above(buf)
        end, "Run cells above")

        map("<leader>Nd", function()
          validate_edit_buffer(buf)
          J.run_below(buf)
        end, "Run current cell and cells below")

        -- Insert
        map("<leader>Nac", function() insert_cell(buf, "above", "code", "") end, "Insert code cell above")

        map("<leader>Nam", function() insert_cell(buf, "above", "markdown", "") end, "Insert Markdown cell above")

        map("<leader>Nbc", function() insert_cell(buf, "below", "code", "") end, "Insert code cell below")

        map("<leader>Nbm", function() insert_cell(buf, "below", "markdown", "") end, "Insert Markdown cell below")

        -- Cell operations
        map("<leader>Ncd", function() delete_cell(buf) end, "Delete current cell")

        map("<leader>Ncy", function() yank_cell(buf) end, "Yank current cell")

        map("<leader>Ncp", function() paste_cell(buf, "below") end, "Paste cell below")

        map("<leader>NcP", function() paste_cell(buf, "above") end, "Paste cell above")

        map("<leader>Nck", function() move_cell(buf, -1) end, "Move current cell up")

        map("<leader>Ncj", function() move_cell(buf, 1) end, "Move current cell down")

        map("<leader>Ncc", function()
          validate_edit_buffer(buf)
          J.set_cell_type(buf, "code")
        end, "Convert current cell to code")

        map("<leader>Ncm", function()
          validate_edit_buffer(buf)
          J.set_cell_type(buf, "markdown")
        end, "Convert current cell to Markdown")

        -- Modes and save
        map("<leader>Ne", function() enter_edit(buf) end, "Enter cell edit mode")

        map("<leader>Nv", function() enter_command(buf) end, "Enter cell command mode")

        map("<leader>Nw", function()
          validate_edit_buffer(buf)
          vim.api.nvim_buf_call(buf, function() vim.cmd "write" end)
        end, "Save notebook")

        -- Navigation
        map("<leader>Njn", function() J.jump_cell(buf, 1) end, "Jump to next cell")

        map("<leader>Njp", function() J.jump_cell(buf, -1) end, "Jump to previous cell")

        map("<leader>Njg", function() CellMode.select_first(buf) end, "Jump to first cell")

        map("<leader>NjG", function() CellMode.select_last(buf) end, "Jump to last cell")

        map("<leader>Nji", function() J.jump_image(buf, 1) end, "Jump to next image cell")

        map("<leader>NjI", function() J.jump_image(buf, -1) end, "Jump to previous image cell")

        -- Kernel
        map("<leader>Nkp", function() J.kernel_picker(buf) end, "Select kernel")

        map("<leader>Nks", function() J.start_kernel(buf) end, "Start kernel")

        map("<leader>NkS", function() J.stop_kernel(buf) end, "Stop kernel")

        map("<leader>Nki", function() J.interrupt_kernel(buf) end, "Interrupt kernel")

        map("<leader>Nkr", function() J.restart_kernel(buf) end, "Restart kernel")

        -- Output
        map("<leader>Noc", function() J.clear_cell_output(buf) end, "Clear current output")

        map("<leader>NoC", function() J.clear_outputs(buf) end, "Clear all outputs")

        -- Images and display
        map("<leader>Nis", function() J.save_image(buf) end, "Save current image")

        map("<leader>Nid", function() J.delete_image(buf) end, "Delete embedded Markdown image")

        map("<leader>Nir", function() J.refresh(buf) end, "Refresh notebook display")

        map("<leader>Nip", function() vim.cmd "JupynvimImageMode placeholder" end, "Use placeholder renderer")

        map("<leader>Nik", function() vim.cmd "JupynvimImageMode kitty" end, "Use Kitty renderer")

        map("<leader>Nic", function() vim.cmd "JupynvimImageMode chafa" end, "Use Chafa renderer")
      end

      local function register_which_key(buf)
        if vim.b[buf].user_jupynvim_which_key then return end
        vim.b[buf].user_jupynvim_which_key = true

        pcall(
          function()
            require("which-key").add {
              { "<leader>N", group = "Notebook", buffer = buf },
              { "<leader>Na", group = "Insert Above", buffer = buf },
              { "<leader>Nb", group = "Insert Below", buffer = buf },
              { "<leader>Nc", group = "Cell", buffer = buf },
              { "<leader>Nj", group = "Jump", buffer = buf },
              { "<leader>Nk", group = "Kernel", buffer = buf },
              { "<leader>No", group = "Output", buffer = buf },
              { "<leader>Ni", group = "Image", buffer = buf },
            }
          end
        )
      end

      ------------------------------------------------------------------------
      -- Attach only to real jupynvim notebook buffers
      ------------------------------------------------------------------------

      local group = vim.api.nvim_create_augroup("UserJupynvimControls", { clear = true })

      local function attach(buf)
        if not is_notebook(buf) then return end

        -- CellMode installs its own mappings independently of
        -- disable_default_keymaps, so remove those and add only the selected
        -- minimal command-mode keys.
        remove_upstream_keymaps(buf)
        attach_cellmode_keymaps(buf)
        attach_notebook_menu(buf)
        register_which_key(buf)

        if not vim.b[buf].user_jupynvim_guard then
          vim.b[buf].user_jupynvim_guard = true

          vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave" }, {
            group = group,
            buffer = buf,
            callback = function()
              if not CellMode.is_command(buf) then schedule_validation(buf) end
            end,
          })
        end
      end

      vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
        group = group,
        callback = function(event)
          vim.schedule(function() attach(event.buf) end)
        end,
      })

      vim.api.nvim_create_autocmd("BufWipeout", {
        group = group,
        callback = function(event)
          repairing[event.buf] = nil
          repair_pending[event.buf] = nil
        end,
      })

      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        vim.schedule(function() attach(buf) end)
      end
    end,
  },
}
