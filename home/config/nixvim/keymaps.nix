# Neovim 键位以 Helix 配置为唯一规范逐键对齐，事实源：
#   home/config/helix/config.toml 的 [keys.normal] / [keys.normal.space*] /
#   [keys.insert] / [keys.select]
# 约定：
#   - Space 分组、缓冲区/窗口导航、诊断与 Git 跳转沿用 Helix 语义；
#   - 文本编辑仍遵循 Neovim 自身规则，不把 nvim 改造成 Helix；
#   - Helix 未占用的键才承载 nvim 独有能力（Markdown、DAP、session、Lazygit 等）。
_:

let
  raw = text: { __raw = text; };

  keymap = mode: key: action: desc: {
    inherit mode key action;
    options = {
      inherit desc;
      silent = true;
    };
  };

  normal = keymap "n";
  visual = keymap "x";
  # Helix 的 keys.select 只继承默认 normal trie，用户自定义 Space 分组须显式镜像；
  # 此处同一组键覆盖 n/x/v（x/v 在 Helix 中没有独立的模式区分）。
  workflow = keymap [
    "n"
    "x"
    "v"
  ];

  # Helix [editor.file-picker] hidden = true：文件选择器默认含隐藏文件，
  # 由 <leader>uh 切换（对应 Helix 的 :toggle file-picker.hidden）。
  pickerFiles = raw ''
    function()
      require("snacks").picker.files({ hidden = vim.g.picker_hidden ~= 0 })
    end
  '';

  hover = raw ''
    function()
      vim.lsp.buf.hover()
    end
  '';

  navHunk =
    direction:
    raw ''
      function()
        require("gitsigns").nav_hunk("${direction}")
      end
    '';

  diagJump =
    count:
    raw ''
      function()
        vim.diagnostic.jump({ count = ${toString count}, float = true })
      end
    '';
in
{
  programs.nixvim.keymaps = [
    # ===== 跨编辑器共识（Helix [keys.normal] / [keys.select]）=====
    (keymap [ "n" "x" "v" ] "<C-s>" "<cmd>write<cr>" "Save file")
    (workflow "<C-q>" "<cmd>quit<cr>" "Quit window")

    (workflow "<C-h>" "<C-w>h" "Focus left window")
    (workflow "<C-j>" "<C-w>j" "Focus lower window")
    (workflow "<C-k>" "<C-w>k" "Focus upper window")
    (workflow "<C-l>" "<C-w>l" "Focus right window")

    (workflow "H" "<cmd>BufferLineCyclePrev<cr>" "Previous buffer")
    (workflow "L" "<cmd>BufferLineCycleNext<cr>" "Next buffer")
    (workflow "[b" "<cmd>BufferLineCyclePrev<cr>" "Previous buffer")
    (workflow "]b" "<cmd>BufferLineCycleNext<cr>" "Next buffer")
    (workflow "[d" (diagJump (-1)) "Previous diagnostic")
    (workflow "]d" (diagJump 1) "Next diagnostic")
    (workflow "[g" (navHunk "prev") "Previous git change")
    (workflow "]g" (navHunk "next") "Next git change")

    # 按行移动（Helix A-j/A-k = move_line_*）；Helix 在 Select 下是 extend_line_*，
    # nvim 可视模式用同名 A-j/A-k 展开为 j/k（wrap = false，一行即一个缓冲区行）。
    # 边界行静默不动（`:move` 越界会 E16）。
    (normal "<A-j>" (raw ''
      function()
        if vim.fn.line(".") < vim.fn.line("$") then
          vim.cmd("move .+1")
        end
      end
    '') "Move line down")
    (normal "<A-k>" (raw ''
      function()
        if vim.fn.line(".") > 1 then
          vim.cmd("move .-2")
        end
      end
    '') "Move line up")
    (visual "<A-j>" "j" "Extend selection down")
    (visual "<A-k>" "k" "Extend selection up")

    # 注释（Helix C-/）：gcc/gc 是内建映射，需 remap 展开
    {
      mode = "n";
      key = "<C-/>";
      action = "gcc";
      options = {
        desc = "Toggle comments";
        silent = true;
        remap = true;
      };
    }
    {
      mode = "x";
      key = "<C-/>";
      action = "gc";
      options = {
        desc = "Toggle comments";
        silent = true;
        remap = true;
      };
    }

    # ===== 系统剪贴板（Helix 默认 Space y / p / P / R，策略 A）=====
    # 默认寄存器只服务编辑器内部搬运（原生 y/p/P/R 与 d/c 同通道），
    # 与外部程序交换统一走这组键；Helix 侧同名键位见 config.toml [keys.normal.space]。
    (workflow "<leader>y" "\"+y" "Yank to system clipboard")
    (workflow "<leader>p" "\"+p" "Paste from system clipboard")
    (workflow "<leader>P" "\"+P" "Paste from system clipboard before")
    (workflow "<leader>R" "\"+p" "Replace selection with system clipboard")

    # ===== Space 顶层（Space h / Space k 是 Helix 原生保留项）=====
    (workflow "<leader><space>" pickerFiles "Find files")
    (workflow "<leader>/" (raw ''
      function()
        require("snacks").picker.grep()
      end
    '') "Grep project")
    (workflow "<leader>?" (raw ''
      function()
        require("snacks").picker.commands()
      end
    '') "Command palette")
    (workflow "<leader>-" "<C-w>s" "Split below")
    (workflow "<leader>|" "<C-w>v" "Split right")
    (workflow "<leader>a" (raw ''
      function()
        vim.lsp.buf.code_action()
      end
    '') "Code action")
    (workflow "<leader>r" (raw ''
      function()
        vim.lsp.buf.rename()
      end
    '') "Rename symbol")
    (workflow "<leader>h" (raw ''
      function()
        require("snacks").picker.lsp_references()
      end
    '') "References")
    (workflow "<leader>k" hover "Hover")

    # ===== b 缓冲区生命周期 =====
    (workflow "<leader>bb" (raw ''
      function()
        require("snacks").picker.buffers()
      end
    '') "Buffers")
    (workflow "<leader>bd" "<cmd>bdelete<cr>" "Delete buffer")
    (workflow "<leader>bn" "<cmd>BufferLineCycleNext<cr>" "Next buffer")
    (workflow "<leader>bp" "<cmd>BufferLineCyclePrev<cr>" "Previous buffer")
    (workflow "<leader>bo" (raw ''
      function()
        local current = vim.api.nvim_get_current_buf()
        for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
          if buffer ~= current and vim.bo[buffer].buflisted then
            vim.api.nvim_buf_delete(buffer, {})
          end
        end
      end
    '') "Delete other buffers")

    # ===== c 代码理解与修改（ca/cr 由 lsp.nix 的 LSP 键位提供）=====
    (workflow "<leader>cf" (raw ''
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end
    '') "Format")
    (workflow "<leader>ch" hover "Hover")
    (visual "<leader>c=" (raw ''
      function()
        local opts = { async = true, lsp_format = "fallback" }
        -- conform 对行选区（V）算出的 end 少一列，get_offsets_from_range 当排他偏移用，
        -- 结果最后一行落在范围外被 formatter 跳过；这里按整行显式给出范围（1 基行、0 基列）。
        if vim.fn.mode() == "V" then
          local anchor = vim.fn.line("v")
          local cursor = vim.fn.line(".")
          local first = math.min(anchor, cursor)
          local last = math.max(anchor, cursor)
          opts.range = { start = { first, 0 }, ["end"] = { last, #vim.fn.getline(last) } }
        end
        require("conform").format(opts)
      end
    '') "Format selection")
    (workflow "<leader>cm" (raw ''
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
    (workflow "<leader>cp" "<cmd>MarkdownPreviewToggle<cr>" "Markdown preview")

    # ===== f 文件与配置源码 =====
    (workflow "<leader>ff" pickerFiles "Find files")
    # Helix 的 fF 是"当前目录"版选择器；nvim 的文件选择器本就以 cwd 为根，
    # 两者无法区分，故大写改表"范围更大：连 .gitignore 忽略的文件一起找"。
    (workflow "<leader>fF" (raw ''
      function()
        require("snacks").picker.files({ hidden = true, ignored = true })
      end
    '') "Find all files (including ignored)")
    (workflow "<leader>fe" (raw ''
      function()
        require("snacks").explorer()
      end
    '') "Explorer")
    (workflow "<leader>fE" (raw ''
      function()
        require("snacks").explorer.open({ cwd = vim.fn.expand("%:p:h") })
      end
    '') "Explorer (buffer directory)")
    # Helix 的 fc 打开仓库里的配置源文件；nvim 侧对应 nixvim 的键位源文件。
    (workflow "<leader>fc" (raw ''
      function()
        vim.cmd.edit(vim.fn.expand("~/.config/home-manager/home/config/nixvim/keymaps.nix"))
      end
    '') "Edit Nixvim config source")
    (workflow "<leader>fr" (raw ''
      function()
        require("snacks").picker.recent()
      end
    '') "Recent files")

    # ===== g Git（Helix 的 :sh 只读输出与交互式 picker 分开）=====
    (workflow "<leader>gc" (raw ''
      function()
        require("snacks").picker.git_status()
      end
    '') "Changed files")
    (workflow "<leader>gb" (raw ''
      function()
        require("gitsigns").blame_line({ full = true })
      end
    '') "Blame line")
    (workflow "<leader>gd" (raw ''
      function()
        require("gitsigns").diffthis()
      end
    '') "Diff current file")
    (workflow "<leader>gl" (raw ''
      function()
        require("snacks").picker.git_log()
      end
    '') "Git log")
    (workflow "<leader>gs" (raw ''
      function()
        require("snacks").terminal({ "git", "status", "--short", "--branch" }, { interactive = true })
      end
    '') "Git status (shell)")
    (workflow "<leader>gB" (raw ''
      function()
        require("snacks").picker.git_branches()
      end
    '') "Git branches")
    (workflow "<leader>gg" (raw ''
      function()
        require("snacks").lazygit()
      end
    '') "Lazygit")

    # ===== s 搜索与符号 =====
    (workflow "<leader>ss" (raw ''
      function()
        require("snacks").picker.lsp_symbols()
      end
    '') "Document symbols")
    (workflow "<leader>sS" (raw ''
      function()
        require("snacks").picker.lsp_workspace_symbols()
      end
    '') "Workspace symbols")
    (workflow "<leader>sg" (raw ''
      function()
        require("snacks").picker.grep()
      end
    '') "Grep")
    (workflow "<leader>s/" (raw ''
      function()
        require("snacks").picker.search_history()
      end
    '') "Search history")
    (workflow "<leader>sb" (raw ''
      function()
        require("snacks").picker.lines()
      end
    '') "Buffer lines")
    (workflow "<leader>sr" "<cmd>GrugFar<cr>" "Search and replace")

    # ===== w 窗口布局与焦点 =====
    (workflow "<leader>w-" "<C-w>s" "Split below")
    (workflow "<leader>w|" "<C-w>v" "Split right")
    (workflow "<leader>wh" "<C-w>h" "Focus left window")
    (workflow "<leader>wj" "<C-w>j" "Focus lower window")
    (workflow "<leader>wk" "<C-w>k" "Focus upper window")
    (workflow "<leader>wl" "<C-w>l" "Focus right window")
    (workflow "<leader>wo" "<C-w>o" "Delete other windows")
    (workflow "<leader>wq" "<C-w>c" "Delete window")
    (workflow "<leader>wd" "<C-w>c" "Delete window")
    (workflow "<leader>ws" "<C-w>s" "Split below")
    (workflow "<leader>wv" "<C-w>v" "Split right")

    # ===== x 诊断（小写=当前缓冲区，大写=工作区，与 Helix xx/xX 一致）=====
    (workflow "<leader>xx" "<cmd>Trouble diagnostics toggle filter.buf=0<cr>" "Buffer diagnostics")
    (workflow "<leader>xX" "<cmd>Trouble diagnostics toggle<cr>" "Workspace diagnostics")
    (workflow "<leader>xt" "<cmd>TodoTrouble<cr>" "Todo diagnostics")

    # ===== u 编辑器开关与显示 =====
    (workflow "<leader>ud" (raw ''
      function()
        vim.diagnostic.enable(not vim.diagnostic.is_enabled())
      end
    '') "Toggle diagnostics")
    (workflow "<leader>uf" (raw ''
      function()
        vim.g.autoformat = vim.g.autoformat == 0 and 1 or 0
        vim.notify("auto-format on save: " .. (vim.g.autoformat ~= 0 and "on" or "off"))
      end
    '') "Toggle auto-format on save")
    (workflow "<leader>uh" (raw ''
      function()
        vim.g.picker_hidden = vim.g.picker_hidden == 0 and 1 or 0
        vim.notify("hidden files in pickers: " .. (vim.g.picker_hidden ~= 0 and "on" or "off"))
      end
    '') "Toggle hidden files in pickers")
    (workflow "<leader>ui" (raw ''
      function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
      end
    '') "Toggle inlay hints")
    (workflow "<leader>ul" (raw ''
      function()
        vim.opt.relativenumber = not vim.opt.relativenumber:get()
      end
    '') "Toggle relative line numbers")
    (workflow "<leader>un" (raw ''
      function()
        require("snacks").notifier.hide()
      end
    '') "Dismiss notifications")
    (workflow "<leader>ur" (raw ''
      function()
        if #vim.opt.colorcolumn:get() > 0 then
          vim.opt.colorcolumn = ""
        else
          vim.opt.colorcolumn = "100"
        end
      end
    '') "Toggle rulers")
    (workflow "<leader>us" (raw ''
      function()
        vim.opt.smartcase = not vim.opt.smartcase:get()
      end
    '') "Toggle smart case")
    (workflow "<leader>uS" (raw ''
      function()
        vim.opt.spell = not vim.opt.spell:get()
      end
    '') "Toggle spelling")
    (workflow "<leader>uw" (raw ''
      function()
        vim.opt.wrap = not vim.opt.wrap:get()
      end
    '') "Toggle wrap")
    (workflow "<leader>uW" (raw ''
      function()
        vim.opt.list = not vim.opt.list:get()
      end
    '') "Toggle whitespace rendering")
    # 只重载已部署的 init.lua；改仓库源码后仍需 home-manager switch
    (workflow "<leader>uR" (raw ''
      function()
        local config = vim.env.MYVIMRC
        if config == nil or config == "" then
          vim.notify("MYVIMRC is unset; nothing to reload", vim.log.levels.WARN)
          return
        end
        vim.cmd.source(vim.fn.fnameescape(config))
      end
    '') "Reload deployed config")

    # ===== q 退出与会话（Helix 已撤下强制退出，不提供 qQ）=====
    (workflow "<leader>qq" "<cmd>qa<cr>" "Quit all")
    (workflow "<leader>qs" (raw ''
      function()
        require("persistence").load()
      end
    '') "Restore session")
    (workflow "<leader>ql" (raw ''
      function()
        require("persistence").load({ last = true })
      end
    '') "Restore last session")
    (workflow "<leader>qd" (raw ''
      function()
        require("persistence").stop()
      end
    '') "Do not save session")

    # ===== nvim 独有：DAP（Helix 无对应能力）=====
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

    # ===== Helix [keys.insert] =====
    # 只移植 jk：Helix 的 C-k（签名帮助）在 nvim 是 digraph 输入、
    # C-space（补全）是 i_CTRL-@，且补全由 blink 自动触发，不覆盖原生行为。
    {
      mode = "i";
      key = "jk";
      action = "<Esc>";
      options = {
        desc = "Exit insert mode";
        silent = true;
      };
    }
  ];
}
