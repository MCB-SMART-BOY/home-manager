# NixOS-specific Zsh helpers and aliases; portable Zsh defaults remain in default.nix.
{ lib, ... }:

{
  programs.zsh.shellAliases = {
    nsp = "nix search nixpkgs";
    nsh = "nix-shell";
    ngc = "/run/wrappers/bin/sudo nix-collect-garbage -d";
    please = "/run/wrappers/bin/sudo";
  };

  programs.zsh.initContent = lib.mkAfter (builtins.readFile ./nixos.zsh);
}
