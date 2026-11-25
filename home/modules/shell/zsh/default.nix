{ config, lib, ... }:

{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    autocd = true;
    history = {
      size = 50000;
      save = 50000;
      path = "${config.home.homeDirectory}/.zsh_history";
      append = true;
      share = true;
      extended = true;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
      findNoDups = true;
    };
    setOptions = [
      "HIST_REDUCE_BLANKS"
      "HIST_VERIFY"
      "NO_INC_APPEND_HISTORY"
      "AUTO_PUSHD"
      "PUSHD_IGNORE_DUPS"
      "PUSHD_SILENT"
      "CORRECT"
      "INTERACTIVE_COMMENTS"
      "NO_BEEP"
      "EXTENDED_GLOB"
      "COMPLETE_IN_WORD"
      "AUTO_MENU"
      "NO_FLOW_CONTROL"
    ];
    sessionVariables = {
      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git";
      FZF_CTRL_T_COMMAND = "fd --type f --hidden --follow --exclude .git";
      FZF_ALT_C_COMMAND = "fd --type d --hidden --follow --exclude .git";
      FZF_DEFAULT_OPTS = ''
        --height 40%
        --layout=reverse
        --border=rounded
        --preview-window=right:60%
        --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
        --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
        --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
      '';
    };
    siteFunctions = {
      mkcd = ''
        mkdir -p "$@" && cd "$@"
      '';

      extract = ''
        if [ "$#" -lt 1 ]; then
            echo "用法: extract <archive>"
            return 1
        fi

        local archive="$1"
        if [ -f "$archive" ]; then
            if command -v ouch &> /dev/null; then
                ouch decompress "$archive"
                return $?
            fi

            case "$archive" in
                *.tar.bz2)   tar xjf "$archive"    ;;
                *.tar.gz)    tar xzf "$archive"    ;;
                *.tar.xz)    tar xJf "$archive"    ;;
                *.bz2)       bunzip2 "$archive"    ;;
                *.gz)        gunzip "$archive"     ;;
                *.tar)       tar xf "$archive"     ;;
                *.tbz2)      tar xjf "$archive"    ;;
                *.tgz)       tar xzf "$archive"    ;;
                *.zip)       unzip "$archive"      ;;
                *.Z)         uncompress "$archive" ;;
                *.7z)        7z x "$archive"       ;;
                *.rar)       unrar x "$archive"    ;;
                *)           echo "'$archive' 无法识别的压缩格式" ;;
            esac
        else
            echo "'$archive' 不是有效文件"
        fi
      '';

      fe = ''
        local file
        local preview_cmd
        if command -v bat &> /dev/null; then
            preview_cmd='bat --color=always {}'
        else
            preview_cmd='sed -n "1,200p" {}'
        fi
        file=$(fd --type f --hidden --exclude .git | fzf --preview "''${preview_cmd}")
        [ -n "$file" ] && "''${EDITOR:-nvim}" "$file"
      '';

      fcd = ''
        local dir
        dir=$(fd --type d --hidden --exclude .git | fzf --preview 'eza -la --icons {}')
        [ -n "$dir" ] && cd "$dir"
      '';
    };
    initContent = lib.mkAfter ''
      bindkey "^[[3~" delete-char
      bindkey "^[3;5~" delete-char
      bindkey "^[[H" beginning-of-line
      bindkey "^[[F" end-of-line

      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      if [[ -n "''${LS_COLORS:-}" ]]; then
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      fi
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*:descriptions' format '%F{magenta}── %d ──%f'
      zstyle ':completion:*:messages' format '%F{yellow}%d%f'
      zstyle ':completion:*:warnings' format '%F{red}没有找到匹配项%f'

      if [[ "''${TERM:-}" != "dumb" ]]; then
        if command -v fastfetch &> /dev/null; then
          fastfetch
        fi
      fi
    '';
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
