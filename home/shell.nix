{
  config,
  pkgs,
  ...
}:

{
  programs.nushell = {
    enable = true;
    package = pkgs.nushell;
    configFile.source = ./config/nushell/config.nu;
    shellAliases = {
      md = "mkdir";
      rd = "rmdir";
    };
    envFile.source = ./config/nushell/env.nu;
    settings = {
      show_banner = false;
      edit_mode = "emacs";
      table.mode = "rounded";
      completions.case_sensitive = false;
      completions.external.enable = true;
      completions.external.max_results = 200;
      history.file_format = "sqlite";
      history.max_size = 50000;
      history.sync_on_enter = true;
      history.isolation = false;
      history.ignore_space_prefixed = true;
    };
  };

  home.shellAliases = {
    g = "git";
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gl = "git pull";
    gs = "git status";
    gd = "git diff";
    gco = "git checkout";
    gb = "git branch";
    tree = "eza --tree --icons --group-directories-first --git";
    gcp = "git cherry-pick";
    grb = "git rebase";
    glg = "git log --oneline --graph --decorate";
    bcat = "bat --paging=never --style=plain";
    catt = "bat --paging=always";
    compress = "ouch compress";
    decompress = "ouch decompress";
    fdf = "fd";
    top = "btop";
    myip = "curl -s https://ipinfo.io/ip";
    j = "z";
    ji = "zi";
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
    extraOptions = [
      "--group-directories-first"
      "--time-style=long-iso"
    ];
    git = true;
  };

  programs.direnv = {
    enable = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = builtins.readFile ./config/zsh/.zshrc;
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

  programs.tmux.enable = true;

  programs.fish = {
    enable = true;
    preferAbbrs = true;
    interactiveShellInit = builtins.readFile ./config/fish/config.fish;
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

  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.bat = {
    enable = true;
    config.theme = "Catppuccin Mocha";
  };
}
