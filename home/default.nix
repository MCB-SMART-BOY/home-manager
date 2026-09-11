{ ... }:

{
  imports = [
    ./base.nix
    ./packages.nix
    ./programs.nix
    ./shell.nix
    ./git.nix
    ./files.nix
    ./scripts
    ./config/git
    ./config/fish
    ./config/zsh
    ./config/nushell
    ./config/eza
    ./config/direnv
    ./config/zoxide
    ./config/starship
    ./config/bat
    ./config/tmux
    ./config/btop
    ./config/fastfetch
    ./config/helix
    ./config/toolchain
  ];

  home.stateVersion = "26.05";
}
