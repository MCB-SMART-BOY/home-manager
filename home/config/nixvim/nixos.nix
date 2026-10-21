# NixOS-specific nixd expressions; portable Nixvim settings remain in lsp.nix.
{
  config,
  lib,
  options,
  mcbNixpkgsExpression,
  mcbNixosOptionsExpression,
  ...
}:

{
  config = lib.optionalAttrs (options ? programs.nixvim) {
    programs.nixvim.lsp.servers.clangd.config.cmd = lib.mkForce [
      "clangd"
      "--background-index"
      "--clang-tidy"
      "--completion-style=detailed"
      "--header-insertion=iwyu"
      "--query-driver=/nix/store/*/bin/gcc,/nix/store/*/bin/g++,/nix/store/*/bin/cc,/nix/store/*/bin/c++"
    ];
    programs.nixvim.lsp.servers.nixd.config.settings = lib.mkIf config.mcb.nixos.enableHostOptions {
      nixd = {
        nixpkgs.expr = mcbNixpkgsExpression;
        options.nixos.expr = mcbNixosOptionsExpression;
      };
    };
  };
}
