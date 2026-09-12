{ ... }:

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

  fishFunctionFiles = builtins.listToAttrs (
    map (name: {
      name = "fish/functions/${name}.fish";
      value.source = ./functions + "/${name}.fish";
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

  xdg.configFile = fishFunctionFiles // fishConfDFiles;
}
