# 与当前 LazyVim 能力对齐的声明式插件集合。
{ pkgs, ... }:
let
  markdownPreviewBun = pkgs.vimPlugins.markdown-preview-nvim.overrideAttrs (oldAttrs: {
    postPatch =
      (oldAttrs.postPatch or "") + builtins.readFile ../../scripts/markdown-preview-bun-post-patch.sh;
  });
in

{
  programs.nixvim = {
    dependencies = {
      fd.enable = false;
      git.enable = false;
      rust-analyzer.enable = false;
    };

    plugins = {
      blink-cmp = {
        enable = true;
        setupLspCapabilities = true;
        settings = {
          keymap.preset = "super-tab";
          completion = {
            documentation.auto_show = true;
            ghost_text.enabled = true;
          };
          signature.enabled = true;
          sources.default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
          ];
        };
      };
      friendly-snippets.enable = true;
      lspconfig.enable = true;

      snacks = {
        enable = true;
        settings = {
          bigfile.enabled = true;
          dashboard.enabled = true;
          explorer.enabled = true;
          indent.enabled = true;
          input.enabled = true;
          notifier = {
            enabled = true;
            timeout = 3000;
          };
          picker.enabled = true;
          quickfile.enabled = true;
          scope.enabled = true;
          scroll.enabled = true;
          statuscolumn.enabled = true;
          words.enabled = true;
        };
      };

      bufferline = {
        enable = true;
        settings.options = {
          always_show_bufferline = false;
          diagnostics = "nvim_lsp";
          offsets = [
            {
              filetype = "snacks_layout_box";
              text = "Explorer";
              text_align = "center";
            }
          ];
        };
      };
      lualine = {
        enable = true;
        settings.options = {
          globalstatus = true;
          theme = "catppuccin";
        };
      };
      mini-icons = {
        enable = true;
        mockDevIcons = true;
      };
      noice.enable = true;
      which-key.enable = true;

      treesitter = {
        enable = true;
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          bash
          c
          cpp
          css
          diff
          gitcommit
          gitignore
          go
          gomod
          gosum
          gowork
          html
          javascript
          json
          json5
          lua
          markdown
          markdown-inline
          nix
          ocaml
          ocaml-interface
          python
          regex
          rust
          toml
          tsx
          typescript
          vim
          vimdoc
          yaml
        ];
        folding.enable = true;
        highlight.enable = true;
        indent.enable = true;
      };
      ts-autotag.enable = true;
      treesitter-textobjects.enable = true;

      flash.enable = true;
      mini-ai.enable = true;
      mini-pairs.enable = true;
      ts-comments.enable = true;

      gitsigns = {
        enable = true;
        settings = {
          current_line_blame = true;
          current_line_blame_opts.delay = 500;
          signs = {
            add.text = "▎";
            change.text = "▎";
            changedelete.text = "";
            delete.text = "";
            topdelete.text = "";
            untracked.text = "▎";
          };
        };
      };
      grug-far.enable = true;
      todo-comments.enable = true;
      trouble.enable = true;

      persistence = {
        enable = true;
        settings = {
          branch = true;
          need = 1;
        };
      };

      clangd-extensions = {
        enable = true;
        enableOffsetEncodingWorkaround = true;
      };
      crates = {
        enable = true;
        settings = {
          autoload = true;
          autoupdate = true;
        };
      };
      rustaceanvim = {
        enable = true;
        settings.server = {
          cmd = [ "rust-analyzer" ];
          default_settings."rust-analyzer" = {
            check.command = "clippy";
            cargo = {
              allFeatures = true;
              buildScripts.enable = true;
            };
            procMacro.enable = true;
            inlayHints = {
              bindingModeHints.enable = false;
              closingBraceHints.minLines = 10;
              closureReturnTypeHints.enable = "with_block";
              discriminantHints.enable = "fieldless";
              lifetimeElisionHints.enable = "skip_trivial";
              typeHints.hideClosureInitialization = false;
            };
          };
        };
      };
      venv-selector.enable = true;

      markdown-preview = {
        enable = true;
        package = markdownPreviewBun;
        settings = {
          auto_close = 1;
          auto_start = 0;
        };
      };
      render-markdown = {
        enable = true;
        settings = {
          completions.blink.enabled = true;
          file_types = [ "markdown" ];
        };
      };
      schemastore.enable = true;
    };
  };
}
