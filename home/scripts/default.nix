{ pkgs, ... }:

let
  mcbToolchain = pkgs.writeShellApplication {
    name = "mcb-toolchain";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnused
      pkgs.jq
    ];
    text = builtins.readFile ./mcb-toolchain;
  };
in
{
  home.packages = [ mcbToolchain ];
}
