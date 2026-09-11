{ pkgs, ... }:

{
  home.packages = with pkgs; [
    coreutils
    curl
    fd
    fzf
    jq
    ouch
    less
    ripgrep
  ];
}
