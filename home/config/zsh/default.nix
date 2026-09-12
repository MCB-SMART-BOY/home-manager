{ config, ... }:

{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = builtins.readFile ./.zshrc;
    shellAliases = {
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      "~" = "cd ~";
      "-" = "cd -";
      md = "mkdir -p";
      rd = "rmdir";
      cp = "cp -i";
      mv = "mv -i";
      rm = "rm -i";
      oldls = "command ls";
      oldcat = "command cat";
      oldgrep = "command grep";
      olddf = "command df";
      olddu = "command du";
      oldps = "command ps";
      oldtop = "command top";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [
        "sudo"
        "docker"
        "rust"
        "fzf"
      ];
      theme = "robbyrussell";
    };
  };
}
