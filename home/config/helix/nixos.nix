# NixOS-specific Helix language additions; portable languages.toml stays generic.
{
  lib,
  mcbNixpkgsExpression,
  mcbNixosOptionsExpression,
  ...
}:

let
  portableLanguages = fromTOML (builtins.readFile ./languages.toml);
  portableLanguageServers = portableLanguages."language-server";
in
{
  programs.helix.languages = lib.mkForce (
    portableLanguages
    // {
      "language-server" = portableLanguageServers // {
        clangd = portableLanguageServers.clangd // {
          args = portableLanguageServers.clangd.args ++ [
            "--query-driver=/nix/store/*/bin/gcc,/nix/store/*/bin/g++,/nix/store/*/bin/cc,/nix/store/*/bin/c++"
          ];
        };
        nixd = portableLanguageServers.nixd // {
          config = {
            nixpkgs.expr = mcbNixpkgsExpression;
            options.nixos.expr = mcbNixosOptionsExpression;
          };
        };
      };
    }
  );
}
