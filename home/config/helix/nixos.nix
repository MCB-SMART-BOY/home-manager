# NixOS-specific Helix language additions; portable languages.toml stays generic.
{ lib, pkgs, ... }:

let
  portableLanguages = builtins.readFile ./languages.toml;
  nixosLanguages =
    builtins.replaceStrings
      [ "  \"--header-insertion=iwyu\",\n" ]
      [
        "  \"--header-insertion=iwyu\",\n  \"--query-driver=/nix/store/*/bin/gcc,/nix/store/*/bin/g++,/nix/store/*/bin/cc,/nix/store/*/bin/c++\",\n"
      ]
      portableLanguages;
in
{
  xdg.configFile."helix/languages.toml".source = lib.mkForce (
    pkgs.writeText "mcbctl-nixos-languages.toml" (
      nixosLanguages + "\n" + builtins.readFile ./nixos.toml
    )
  );
}
