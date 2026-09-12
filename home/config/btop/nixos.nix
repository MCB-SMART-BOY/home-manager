# NixOS btop integration; the wrapper is the sole NixOS btop package provider.
{ pkgs, ... }:

let
  btopWithNixOSDriver = pkgs.writeShellApplication {
    name = "btop";
    text = ''
      export LD_LIBRARY_PATH="/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      exec ${pkgs.btop}/bin/btop "$@"
    '';
  };
in
{
  programs.btop.package = btopWithNixOSDriver;
}
