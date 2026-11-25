{
  lib,
  system ? builtins.currentSystem,
  ...
}:

let
  isLinux = lib.hasSuffix "-linux" system;
in
{
  imports = [
    # Layer 0-1: session environment and portable command-line base.
    ./base.nix
    ./packages.nix
    ./invariants.nix

    # Layer 2: portable modules grouped by owner. Nothing here depends on a
    # desktop session.
    ./modules

    # Layer 2: cross-platform capability profiles.
    ./profiles/development.nix
    ./profiles/terminal-tools.nix
  ]
  ++ lib.optionals isLinux [
    # Layer 3: Linux desktop and host capabilities.
    ./profiles/desktop.nix
    ./profiles/media.nix
    ./profiles/research.nix
    ./profiles/china-apps.nix
    ./profiles/observability.nix
    ./profiles/nix-tools.nix
    ./profiles/gaming.nix
    ./profiles/hardware.nix
    ./profiles/containers.nix
    ./profiles/security.nix
  ];

  home.stateVersion = "26.05";
}
