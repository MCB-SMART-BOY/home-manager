# NixOS-specific Nushell helpers; portable Nushell defaults remain in default.nix.
{ lib, ... }:

{
  programs.nushell.extraConfig = lib.mkAfter (builtins.readFile ./nixos.nu);
}
