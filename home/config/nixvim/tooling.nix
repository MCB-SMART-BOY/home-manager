# Formatter 与 linter 仅调用 PATH 中由各生态管理的工具。
{ ... }:

{
  programs.nixvim.plugins = {
    conform-nvim = {
      enable = true;
      autoInstall.enable = false;
      settings = {
        default_format_opts = {
          lsp_format = "fallback";
          timeout_ms = 3000;
        };
        format_on_save = {
          lsp_format = "fallback";
          timeout_ms = 3000;
        };
        formatters = {
          ocamlformat_impl = {
            command = "opam";
            args = [
              "exec"
              "--"
              "ocamlformat"
              "--impl"
              "-"
            ];
          };
          ocamlformat_intf = {
            command = "opam";
            args = [
              "exec"
              "--"
              "ocamlformat"
              "--intf"
              "-"
            ];
          };
          shfmt.prepend_args = [
            "-i"
            "2"
          ];
        };
        formatters_by_ft = {
          bash = [ "shfmt" ];
          c = [ "clang_format" ];
          cpp = [ "clang_format" ];
          css = [ "prettier" ];
          go = [ "gofumpt" ];
          html = [ "prettier" ];
          javascript = [ "prettier" ];
          javascriptreact = [ "prettier" ];
          json = [ "prettier" ];
          json5 = [ "prettier" ];
          jsonc = [ "prettier" ];
          lua = [ "stylua" ];
          markdown = [ "prettier" ];
          nix = [ "nixfmt" ];
          ocaml = [ "ocamlformat_impl" ];
          ocamlinterface = [ "ocamlformat_intf" ];
          python = [ "ruff_format" ];
          rust = [ "rustfmt" ];
          sh = [ "shfmt" ];
          toml = [ "taplo" ];
          typescript = [ "prettier" ];
          typescriptreact = [ "prettier" ];
          yaml = [ "prettier" ];
        };
      };
    };

    lint = {
      enable = true;
      autoInstall.enable = false;
      lintersByFt = {
        go = [ "golangcilint" ];
        markdown = [ "markdownlint-cli2" ];
        nix = [ "statix" ];
        python = [ "ruff" ];
        sh = [ "shellcheck" ];
      };
    };
  };
}
