{ config, ... }:

let
  homeDir = config.home.homeDirectory;
in
{
  programs.home-manager.enable = true;

  home.sessionVariables = {
    MANPAGER = "less -R";

    XDG_CONFIG_HOME = "${homeDir}/.config";
    XDG_DATA_HOME = "${homeDir}/.local/share";
    XDG_CACHE_HOME = "${homeDir}/.cache";
    XDG_STATE_HOME = "${homeDir}/.local/state";

    RUSTUP_HOME = "${homeDir}/.rustup";
    CARGO_HOME = "${homeDir}/.cargo";
    GOPATH = "${homeDir}/go";
    OPAMROOT = "${homeDir}/.opam";
    ELAN_HOME = "${homeDir}/.elan";
    BUN_INSTALL = "${homeDir}/.bun";
    UV_TOOL_BIN_DIR = "${homeDir}/.local/bin";
  };

  home.sessionPath = [
    "${homeDir}/.cargo/bin"
    "${homeDir}/go/bin"
    "${homeDir}/.opam/default/bin"
    "${homeDir}/.elan/bin"
    "${homeDir}/.bun/bin"
    "${homeDir}/.local/bin"
  ];
}
