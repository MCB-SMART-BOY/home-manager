# NixOS-specific nixd expressions; portable Nixvim settings remain in lsp.nix.
{
  lib,
  options,
  mcbNixpkgsExpression,
  mcbNixosOptionsExpression,
  ...
}:

{
  config = lib.optionalAttrs (options ? programs.nixvim) {
    programs.nixvim.lsp.servers.nixd.config.settings.nixd = {
      nixpkgs.expr = mcbNixpkgsExpression;
      options.nixos.expr = mcbNixosOptionsExpression;
    };
  };
}
