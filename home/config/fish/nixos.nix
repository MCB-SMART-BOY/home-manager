# NixOS-specific Fish functions; portable Fish defaults remain in default.nix.
{ ... }:

let
  nixosFishFunctions = [
    "_mcb_flake_dir"
    "_mcb_flake_ref"
    "_mcb_flake_source"
    "_mcb_flake_target"
    "nfu"
    "nrb"
    "nrc"
    "nrs"
    "nrt"
    "nru"
  ];
  fishFunctionFiles = builtins.listToAttrs (
    map (name: {
      name = "fish/functions/${name}.fish";
      value.source = ./functions + "/${name}.fish";
    }) nixosFishFunctions
  );
in
{
  xdg.configFile = fishFunctionFiles;
}
