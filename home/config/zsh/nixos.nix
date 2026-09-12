# NixOS-specific Zsh helpers and aliases; portable Zsh defaults remain in default.nix.
{ ... }:

{
  programs.zsh.shellAliases = {
    nsp = "nix search nixpkgs";
    nsh = "nix-shell";
    ngc = "/run/wrappers/bin/sudo nix-collect-garbage -d";
    please = "/run/wrappers/bin/sudo";
  };

  programs.zsh.siteFunctions = {
    # --- NixOS 管理 ---
    nrs = ''
      mcb-nixos switch "$@"
    '';

    nrt = ''
      mcb-nixos test "$@"
    '';

    nrb = ''
      mcb-nixos boot "$@"
    '';

    nfu = ''
      mcb-nixos update "$@"
    '';

    nru = ''
      mcb-nixos update-switch "$@"
    '';

    nrc = ''
      mcb-nixos check "$@"
    '';
  };
}
