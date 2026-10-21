# NixOS-specific Zsh helpers and aliases; portable Zsh defaults remain in default.nix.
{ pkgs, mcbNixosExecutable, ... }:

{
  programs.zsh.shellAliases = {
    nsp = "nix search nixpkgs";
    nsh = "nix-shell";
    ngc = "/run/wrappers/bin/sudo nix-collect-garbage -d";
    please = "/run/wrappers/bin/sudo";
  };

  programs.zsh.siteFunctions = {
    _mcb_nixos_root = ''
      ${pkgs.coreutils}/bin/env -i \
        MCB_NIXOS_FLAKE_DIR="''${MCB_NIXOS_FLAKE_DIR-}" \
        MCB_NIXOS_FLAKE_TARGET="''${MCB_NIXOS_FLAKE_TARGET-}" \
        NIXD_HOST="''${NIXD_HOST-}" \
        /run/wrappers/bin/sudo --preserve-env=MCB_NIXOS_FLAKE_DIR,MCB_NIXOS_FLAKE_TARGET,NIXD_HOST \
        -- ${mcbNixosExecutable} "$@"
    '';

    # --- NixOS 管理 ---
    nrs = ''
      _mcb_nixos_root switch "$@"
    '';

    nrt = ''
      _mcb_nixos_root test "$@"
    '';

    nrb = ''
      _mcb_nixos_root boot "$@"
    '';

    nfu = ''
      _mcb_nixos_root update "$@"
    '';

    nru = ''
      _mcb_nixos_root update-switch "$@"
    '';

    nrc = ''
      if [[ $# -eq 0 ]]; then
        _mcb_nixos_root check
      else
        ${mcbNixosExecutable} check "$@"
      fi
    '';
  };
}
