# Neovim 核心行为与全局外观。
{ ... }:

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
    };

    clipboard.register = "unnamedplus";

    opts = {
      autoindent = true;
      breakindent = true;
      completeopt = [
        "menu"
        "menuone"
        "noselect"
      ];
      confirm = true;
      cursorline = true;
      expandtab = true;
      ignorecase = true;
      laststatus = 3;
      linebreak = true;
      mouse = "a";
      number = true;
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
      softtabstop = 2;
      splitbelow = true;
      splitright = true;
      tabstop = 2;
      termguicolors = true;
      timeoutlen = 300;
      undofile = true;
      updatetime = 200;
      virtualedit = "block";
      wrap = false;
    };

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
