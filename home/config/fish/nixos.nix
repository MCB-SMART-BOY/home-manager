# NixOS-specific Fish functions; portable Fish defaults remain in default.nix.
{ lib, ... }:

let
  nixosFishFunctions = [
    "nfu"
    "nrb"
    "nrc"
    "nrs"
    "nrt"
    "nru"
  ];

  functionArguments = {
    nrc = [ "flake" ];
  };

  findFunctionLine =
    lines:
    let
      go =
        index:
        if index >= builtins.length lines then
          throw "Fish function definition is missing its function header."
        else if lib.hasPrefix "function " (builtins.elemAt lines index) then
          index
        else
          go (index + 1);
    in
    go 0;

  functionBody =
    name:
    let
      lines = lib.splitString "\n" (builtins.readFile (./functions + "/${name}.fish"));
      functionLine = findFunctionLine lines;
      bodyLines = lib.sublist (functionLine + 1) (builtins.length lines - functionLine - 3) lines;
    in
    lib.concatStringsSep "\n" bodyLines;

  fishFunctions = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = {
        body = functionBody name;
        argumentNames = lib.attrByPath [ name ] null functionArguments;
      };
    }) nixosFishFunctions
  );

in
{
  programs.fish.functions = fishFunctions;
}
