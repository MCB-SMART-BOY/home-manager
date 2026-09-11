# LazyVim 与 Helix 风格的统一 leader 分组。
{ ... }:

let
  raw = text: { __raw = text; };
  normal = key: action: desc: {
    mode = "n";
    inherit key action;
    options = {
      inherit desc;
      silent = true;
    };
  };
in
{
  programs.nixvim.keymaps = [
    (normal "<C-s>" "<cmd>write<cr>" "Save file")
    (normal "<C-h>" "<C-w>h" "Focus left window")
    (normal "<C-j>" "<C-w>j" "Focus lower window")
    (normal "<C-k>" "<C-w>k" "Focus upper window")
    (normal "<C-l>" "<C-w>l" "Focus right window")
    (normal "H" "<cmd>BufferLineCyclePrev<cr>" "Previous buffer")
    (normal "L" "<cmd>BufferLineCycleNext<cr>" "Next buffer")
    (normal "[b" "<cmd>BufferLineCyclePrev<cr>" "Previous buffer")
    (normal "]b" "<cmd>BufferLineCycleNext<cr>" "Next buffer")
    (normal "[d" (raw ''
      function()
        vim.diagnostic.jump({ count = -1, float = true })
      end
    '') "Previous diagnostic")
    (normal "]d" (raw ''
      function()
        vim.diagnostic.jump({ count = 1, float = true })
      end
    '') "Next diagnostic")

    (normal "<leader>bb" (raw ''
      function()
        require("snacks").picker.buffers()
      end
    '') "Buffers")
    (normal "<leader>bd" "<cmd>bdelete<cr>" "Delete buffer")
    (normal "<leader>bo" (raw ''
      function()
        local current = vim.api.nvim_get_current_buf()
        for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
          if buffer ~= current and vim.bo[buffer].buflisted then
            vim.api.nvim_buf_delete(buffer, {})
          end
        end
      end
    '') "Delete other buffers")

    (normal "<leader>cf" (raw ''
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end
    '') "Format")
    (normal "<leader>cm" (raw ''
      function()
        local file = vim.api.nvim_buf_get_name(0)
        if file == "" then
          vim.notify("Save the Markdown file before updating its TOC", vim.log.levels.WARN)
          return
        end
        if vim.fn.executable("markdown-toc") == 0 then
          vim.notify("markdown-toc is unavailable; run bootstrap-toolchain", vim.log.levels.ERROR)
          return
        end
        vim.system({ "markdown-toc", "-i", file }, {}, function(result)
          vim.schedule(function()
            if result.code == 0 then
              vim.cmd("checktime")
              vim.notify("Markdown TOC updated")
            else
              vim.notify(result.stderr, vim.log.levels.ERROR)
            end
          end)
        end)
      end
    '') "Update Markdown TOC")
    (normal "<leader>cp" "<cmd>MarkdownPreviewToggle<cr>" "Markdown preview")

    (normal "<leader>ff" (raw ''
      function()
        require("snacks").picker.files()
      end
    '') "Find files")
    (normal "<leader>fF" (raw ''
      function()
        require("snacks").picker.files({ hidden = true, ignored = true })
      end
    '') "Find all files")
    (normal "<leader>fe" (raw ''
      function()
        require("snacks").explorer()
      end
    '') "Explorer")
    (normal "<leader>fr" (raw ''
      function()
        require("snacks").picker.recent()
      end
    '') "Recent files")

    (normal "<leader>gb" (raw ''
      function()
        require("snacks").picker.git_branches()
      end
    '') "Git branches")
    (normal "<leader>gc" (raw ''
      function()
        require("snacks").picker.git_log()
      end
    '') "Git log")
    (normal "<leader>gg" (raw ''
      function()
        require("snacks").lazygit()
      end
    '') "Lazygit")
    (normal "<leader>gs" (raw ''
      function()
        require("snacks").picker.git_status()
      end
    '') "Git status")

    (normal "<leader>s/" (raw ''
      function()
        require("snacks").picker.search_history()
      end
    '') "Search history")
    (normal "<leader>sb" (raw ''
      function()
        require("snacks").picker.lines()
      end
    '') "Buffer lines")
    (normal "<leader>sg" (raw ''
      function()
        require("snacks").picker.grep()
      end
    '') "Grep")
    (normal "<leader>sr" "<cmd>GrugFar<cr>" "Search and replace")
    (normal "<leader>ss" (raw ''
      function()
        require("snacks").picker.lsp_symbols()
      end
    '') "Document symbols")
    (normal "<leader>sS" (raw ''
      function()
        require("snacks").picker.lsp_workspace_symbols()
      end
    '') "Workspace symbols")

    (normal "<leader>w-" "<C-w>s" "Split below")
    (normal "<leader>w|" "<C-w>v" "Split right")
    (normal "<leader>wd" "<C-w>c" "Delete window")
    (normal "<leader>wo" "<C-w>o" "Delete other windows")

    (normal "<leader>xx" "<cmd>Trouble diagnostics toggle<cr>" "Diagnostics")
    (normal "<leader>xX" "<cmd>Trouble diagnostics toggle filter.buf=0<cr>" "Buffer diagnostics")
    (normal "<leader>xt" "<cmd>TodoTrouble<cr>" "Todo diagnostics")

    (normal "<leader>ud" (raw ''
      function()
        vim.diagnostic.enable(not vim.diagnostic.is_enabled())
      end
    '') "Toggle diagnostics")
    (normal "<leader>ul" (raw ''
      function()
        vim.opt.relativenumber = not vim.opt.relativenumber:get()
      end
    '') "Toggle relative line numbers")
    (normal "<leader>un" (raw ''
      function()
        require("snacks").notifier.hide()
      end
    '') "Dismiss notifications")
    (normal "<leader>us" (raw ''
      function()
        vim.opt.spell = not vim.opt.spell:get()
      end
    '') "Toggle spelling")
    (normal "<leader>uw" (raw ''
      function()
        vim.opt.wrap = not vim.opt.wrap:get()
      end
    '') "Toggle wrap")

    (normal "<leader>qs" (raw ''
      function()
        require("persistence").load()
      end
    '') "Restore session")
    (normal "<leader>ql" (raw ''
      function()
        require("persistence").load({ last = true })
      end
    '') "Restore last session")
    (normal "<leader>qd" (raw ''
      function()
        require("persistence").stop()
      end
    '') "Do not save session")
    (normal "<leader>qq" "<cmd>qa<cr>" "Quit all")
    (normal "<leader>qQ" "<cmd>qa!<cr>" "Force quit all")

    (normal "<leader>db" (raw ''
      function()
        require("dap").toggle_breakpoint()
      end
    '') "Toggle breakpoint")
    (normal "<leader>dc" (raw ''
      function()
        require("dap").continue()
      end
    '') "Continue")
    (normal "<leader>de" (raw ''
      function()
        require("dapui").eval()
      end
    '') "Evaluate")
    (normal "<leader>di" (raw ''
      function()
        require("dap").step_into()
      end
    '') "Step into")
    (normal "<leader>do" (raw ''
      function()
        require("dap").step_out()
      end
    '') "Step out")
    (normal "<leader>dn" (raw ''
      function()
        require("dap").step_over()
      end
    '') "Step over")
    (normal "<leader>dr" (raw ''
      function()
        require("dap").repl.open()
      end
    '') "Open REPL")
    (normal "<leader>dt" (raw ''
      function()
        require("dap").terminate()
      end
    '') "Terminate")
    (normal "<leader>du" (raw ''
      function()
        require("dapui").toggle()
      end
    '') "Toggle debug UI")
  ];
}
