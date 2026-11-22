{ pkgs, ... }:

{
  programs = {
    fd.enable = true;
    fzf.enable = true;
    fzf.enableNushellIntegration = false;
    jq.enable = true;
    ripgrep.enable = true;
  };

  home.packages = with pkgs; [
    bash
    clang-tools
    coreutils
    curl
    ouch
    less
    nixd
    nixfmt
  ];
}
