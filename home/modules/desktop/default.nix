{ lib, system, ... }:
{
  imports = [
    ./niri
    ./noctalia
    ./omarchy
    ./waybar
    ./ime.nix
  ];
  assertions = [
    {
      assertion = lib.hasSuffix "-linux" system;
      message = "home/modules/desktop is Linux-only; remove the desktop profile on this system.";
    }
  ];
}
