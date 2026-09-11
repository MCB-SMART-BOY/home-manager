# Neovim：nixvim 管理编辑器与插件，语言工具统一从 PATH 解析。
{ ... }:

{
  imports = [
    ./core.nix
    ./plugins.nix
    ./tooling.nix
    ./dap.nix
    ./keymaps.nix
    ./lsp.nix
  ];
}
