{ lib, system, ... }:
{
  imports = [
    ./gtk.nix
    ./themes.nix
  ];
  assertions = [
    {
      assertion = lib.hasSuffix "-linux" system;
      message = "home/modules/appearance is Linux-only; remove the desktop profile on this system.";
    }
  ];
}
