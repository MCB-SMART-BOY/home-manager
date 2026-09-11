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
  ];

  home.stateVersion = "26.05";
}
