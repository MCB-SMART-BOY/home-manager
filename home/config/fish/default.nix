{ lib, ... }:

let
  portableFishFunctions = [
    "_mcb_toolchain"
    "backup"
    "bootstrap-toolchain"
    "check-toolchain"
    "copy"
    "extract"
    "fcd"
    "fe"
    "history"
    "mkcd"
    "upgrade-toolchain"
  ];

  functionArguments = {
    backup = [ "filename" ];
    extract = [ "archive" ];
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
    }) portableFishFunctions
  );

  fishConfDFiles = builtins.listToAttrs (
    map (name: {
      name = "fish/conf.d/${name}";
      value.source = ./conf.d + "/${name}";
    }) (builtins.attrNames (builtins.readDir ./conf.d))
  );
in
{
  programs.fish = {
    enable = true;
    preferAbbrs = true;
    functions = fishFunctions;
    interactiveShellInit = builtins.readFile ./config.fish;
    shellAbbrs = {
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      "-" = "cd -";
      md = "mkdir -p";
      rd = "rmdir";
      cp = "cp -iv";
      mv = "mv -iv";
      rm = "rm -iv";
      e = "$EDITOR";
      v = "$EDITOR";
      oldls = "command ls";
      oldcat = "command cat";
      oldgrep = "command grep";
      olddf = "command df";
      olddu = "command du";
      oldps = "command ps";
      oldtop = "command top";
      lsz = "eza -al --color=always --total-size --group-directories-first --icons";
      "l." = "eza -ald --color=always --group-directories-first --icons .*";
      catb = "bat --style header,snip,changes";
    };
  };

  xdg.configFile = fishConfDFiles;
}
