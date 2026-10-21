# NixOS-specific Nushell helpers; portable Nushell defaults remain in default.nix.
{
  lib,
  pkgs,
  mcbNixosExecutable,
  ...
}:

{
  programs.nushell.extraConfig = lib.mkAfter (
    lib.replaceStrings
      [ "@MCB_NIXOS_EXECUTABLE@" "@MCB_NIXOS_ENV@" ]
      [ mcbNixosExecutable "${pkgs.coreutils}/bin/env" ]
      (builtins.readFile ./nixos.nu)
  );
}
