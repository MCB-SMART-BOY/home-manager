{ pkgs, ... }:

{
  programs = {
    fd.enable = true;
    fzf.enable = true;
    jq.enable = true;
    ripgrep.enable = true;
  };

  home.packages = with pkgs; [
    coreutils
    curl
    ouch
    less
    nixd
    nixfmt
  ];
}
