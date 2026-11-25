{ ... }:

{
  imports = [
    ./base.nix
    ./packages.nix
    ./scripts
    ./config/development/git
    ./config/shell
    ./config/shell/fish
    ./config/shell/zsh
    ./config/shell/nushell
    ./config/shell/eza
    ./config/shell/direnv
    ./config/shell/zoxide
    ./config/shell/starship
    ./config/cli/bat
    ./config/terminal/tmux
    ./config/cli/btop
    ./config/terminal/kitty
    ./config/cli/fastfetch
    ./config/editor/helix
    ./config/editor/nixvim
    ./config/productivity/sioyek
    ./config/desktop/omarchy
  ];

  home.stateVersion = "26.05";
}
