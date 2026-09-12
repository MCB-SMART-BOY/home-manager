# NixOS-specific Helix language additions; portable languages.toml stays generic.
{ lib, ... }:

let
  portableLanguages = builtins.fromTOML (builtins.readFile ./languages.toml);
  nixosLanguages = builtins.fromTOML (builtins.readFile ./nixos.toml);
  portableLanguageServers = portableLanguages."language-server";
  nixosLanguageServers = nixosLanguages."language-server";
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
        nixd = nixosLanguageServers.nixd;
      };
    }
  );
}
