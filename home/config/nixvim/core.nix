# Neovim 核心行为与全局外观。
_:

{
  programs.nixvim = {
    enable = true;
    defaultEditor = false;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    nixpkgs.useGlobalPackages = true;

    withNodeJs = false;
    withPerl = false;
    withPython3 = false;
    withRuby = false;

    globals = {
      mapleader = " ";
      maplocalleader = " ";
      have_nerd_font = true;
      # 键位依赖的两个显式开关（<leader>uf / <leader>uh），默认开启
      autoformat = 1;
      picker_hidden = 1;
    };

    # 剪贴板策略 A（与 Helix 默认一致）：默认寄存器只服务编辑器内部搬运，
    # 与外部程序交换统一走 <leader>y / <leader>p / <leader>P / <leader>R。
    # 因此不设 clipboard=unnamedplus；显式 `"+` 系列命令仍可用。

    opts = {
      autoindent = true;
      breakindent = true;
      # Helix [editor] rulers = [100]（<leader>ur 开关同一键位）
      colorcolumn = "100";
      completeopt = [
        "menu"
        "menuone"
        "noselect"
      ];
      confirm = true;
      # Helix [editor] cursorline/cursorcolumn = true
      cursorcolumn = true;
      cursorline = true;
      expandtab = true;
      # Helix [editor.cursor-shape] normal=block、insert=bar、select=underline
      # nvim 没有 underline 光标，v/ve（可视即 Helix 的 Select）用 20% 高的水平条近似。
      guicursor = "n-c-sm:block,v:hor20,ve:hor20,i-ci:ver25,o:hor20,r-cr:hor20,t:block-blinkon500-blinkoff500-TermCursor";
      ignorecase = true;
      laststatus = 3;
      linebreak = true;
      # Helix [editor.whitespace.characters]：<leader>uW 开关时显示同样的字形
      # （nvim 的 tab 字段需要两个字符：首格与其余格）
      listchars = "space:·,tab:→ ,nbsp:⍽,trail:·";
      mouse = "a";
      number = true;
      # Helix [editor.gutters.line-numbers] min-width = 3
      numberwidth = 3;
      pumheight = 10;
      relativenumber = true;
      scrolloff = 8;
      shiftround = true;
      shiftwidth = 2;
      shortmess = "filnxtToOFWIcC";
      showmode = false;
      sidescrolloff = 8;
      signcolumn = "yes";
      smartcase = true;
      smartindent = true;
      # Helix [editor] shell = ["zsh" "-c"]
      shell = "zsh";
      softtabstop = 2;
      splitbelow = true;
      splitright = true;
      tabstop = 2;
      termguicolors = true;
      timeoutlen = 300;
      undofile = true;
      updatetime = 200;
      virtualedit = "block";
      # Helix [editor] popup-border = "all"
      winborder = "rounded";
      wrap = false;
    };

    # Helix auto-save = true 的等价实现：失焦时保存所有已修改的普通文件缓冲区。
    # 对齐 Helix write_all(force=false, write_scratch=false, auto_format=false)：
    # 跳过 scratch/特殊缓冲区，且保存期间临时关闭 autoformat，
    # 因为 conform 的 format_on_save 会读取 vim.g.autoformat。
    extraConfigLua = ''
      vim.api.nvim_create_autocmd("FocusLost", {
        desc = "Auto-save all modified file buffers (parity with Helix auto-save)",
        callback = function()
          local prev_autoformat = vim.g.autoformat
          vim.g.autoformat = 0
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if
              vim.api.nvim_buf_is_loaded(buf)
              and vim.bo[buf].modified
              and vim.bo[buf].buflisted
              and vim.bo[buf].buftype == ""
              and vim.api.nvim_buf_get_name(buf) ~= ""
            then
              vim.api.nvim_buf_call(buf, function()
                vim.cmd("silent! write")
              end)
            end
          end
          vim.g.autoformat = prev_autoformat
        end,
      })

      -- Helix 的 K 用于 keep_selections；悬浮文档在 <Space>k / <Space>ch / gK。
      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "Drop built-in K = hover (Helix keeps K for keep_selections)",
        callback = function(ev)
          pcall(vim.keymap.del, "n", "K", { buffer = ev.buf })
        end,
      })

      -- Helix [editor] line-number = "relative"：插入或失焦时显示绝对行号。
      local saved_relativenumber
      local is_insert = false
      local is_unfocused = false
      vim.api.nvim_create_autocmd({ "InsertEnter", "FocusLost" }, {
        callback = function(ev)
          if saved_relativenumber == nil then
            saved_relativenumber = vim.wo.relativenumber
          end
          if ev.event == "InsertEnter" then
            is_insert = true
          else
            is_unfocused = true
          end
          vim.wo.relativenumber = false
        end,
      })
      vim.api.nvim_create_autocmd({ "InsertLeave", "FocusGained" }, {
        callback = function(ev)
          if ev.event == "InsertLeave" then
            is_insert = false
          else
            is_unfocused = false
          end
          if not is_insert and not is_unfocused and saved_relativenumber ~= nil then
            vim.wo.relativenumber = saved_relativenumber
            saved_relativenumber = nil
          end
        end,
      })
    '';

    diagnostic.settings = {
      severity_sort = true;
      signs = true;
      underline = true;
      update_in_insert = false;
      virtual_text = {
        spacing = 4;
        source = "if_many";
      };
      float = {
        border = "rounded";
        source = true;
      };
    };

    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        integrations = {
          blink_cmp = true;
          gitsigns = true;
          markdown = true;
          native_lsp.enabled = true;
          noice = true;
          treesitter = true;
          which_key = true;
        };
      };
    };
  };
}
