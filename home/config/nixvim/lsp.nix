# LSP 仅负责客户端配置；所有 server 均从 PATH 启动。
{ lib, ... }:

{
  programs.nixvim = {
    lsp = {
      inlayHints.enable = true;

      keymaps = [
        {
          key = "gd";
          lspBufAction = "definition";
          options.desc = "Goto definition";
        }
        {
          key = "gD";
          lspBufAction = "declaration";
          options.desc = "Goto declaration";
        }
        {
          key = "gr";
          lspBufAction = "references";
          options.desc = "References";
        }
        {
          key = "gI";
          lspBufAction = "implementation";
          options.desc = "Goto implementation";
        }
        {
          key = "gy";
          lspBufAction = "type_definition";
          options.desc = "Goto type definition";
        }
        {
          key = "K";
          lspBufAction = "hover";
          options.desc = "Hover";
        }
        {
          key = "gK";
          lspBufAction = "signature_help";
          options.desc = "Signature help";
        }
        {
          key = "<leader>ca";
          mode = [
            "n"
            "v"
          ];
          lspBufAction = "code_action";
          options.desc = "Code action";
        }
        {
          key = "<leader>cr";
          lspBufAction = "rename";
          options.desc = "Rename symbol";
        }
      ];

      servers = {
        bashls = {
          enable = true;
          package = null;
          config.cmd = [
            "bash-language-server"
            "start"
          ];
        };
        clangd = {
          enable = true;
          package = null;
          config.cmd = [
            "clangd"
            "--background-index"
            "--clang-tidy"
            "--completion-style=detailed"
            "--header-insertion=iwyu"
            "--query-driver=/nix/store/*/bin/gcc,/nix/store/*/bin/g++,/nix/store/*/bin/cc,/nix/store/*/bin/c++"
          ];
        };
        cssls = {
          enable = true;
          package = null;
          config.cmd = [
            "vscode-css-language-server"
            "--stdio"
          ];
        };
        gopls = {
          enable = true;
          package = null;
          config = {
            cmd = [ "gopls" ];
            settings.gopls = {
              analyses.unusedparams = true;
              completeUnimported = true;
              gofumpt = true;
              staticcheck = true;
            };
          };
        };
        html = {
          enable = true;
          package = null;
          config.cmd = [
            "vscode-html-language-server"
            "--stdio"
          ];
        };
        jsonls = {
          enable = true;
          package = null;
          config.cmd = [
            "vscode-json-language-server"
            "--stdio"
          ];
        };
        lua_ls = {
          enable = true;
          package = null;
          config = {
            cmd = [ "lua-language-server" ];
            settings.Lua = {
              completion.callSnippet = "Replace";
              diagnostics.globals = [ "vim" ];
              hint.enable = true;
              runtime.version = "LuaJIT";
              telemetry.enable = false;
              workspace.checkThirdParty = false;
            };
          };
        };
        marksman = {
          enable = true;
          package = null;
          config.cmd = [
            "marksman"
            "server"
          ];
        };
        nixd = {
          enable = true;
          package = null;
          config.cmd = [ "nixd" ];
        };
        ocamllsp = {
          enable = true;
          package = null;
          config.cmd = [
            "opam"
            "exec"
            "--"
            "ocamllsp"
          ];
        };
        ty = {
          enable = true;
          package = null;
          config.cmd = [
            "ty"
            "server"
          ];
        };
        taplo = {
          enable = true;
          package = null;
          config.cmd = [
            "taplo"
            "lsp"
            "stdio"
          ];
        };
        vtsls = {
          enable = true;
          package = null;
          config.cmd = [
            "vtsls"
            "--stdio"
          ];
        };
        yamlls = {
          enable = true;
          package = null;
          config = {
            cmd = [
              "yaml-language-server"
              "--stdio"
            ];
            settings.yaml.keyOrdering = false;
          };
        };
      };
    };

    extraConfigLua = lib.mkAfter ''
      vim.lsp.config("lean", {
        cmd = { "lean", "--server", "--memory=1024" },
        filetypes = { "lean" },
        root_markers = { "lakefile.lean", "lean-toolchain", ".git" },
      })
      vim.lsp.enable("lean")
    '';
  };
}
