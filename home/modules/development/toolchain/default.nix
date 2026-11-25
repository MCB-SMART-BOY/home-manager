{
  config,
  lib,
  pkgs,
  ...
}:

let
  homeDir = config.home.homeDirectory;
  toolchainCommands =
    map
      (
        action:
        pkgs.writeShellApplication {
          name = "${action}-toolchain";
          runtimeInputs = [ pkgs.jq ];
          text = ''
            exec ${lib.getExe pkgs.bash} ${./toolchain} ${./manifest.tsv} ${action} "$@"
          '';
        }
      )
      [
        "bootstrap"
        "update"
        "check"
      ];
in
{
  home = {
    packages = toolchainCommands;

    sessionVariables = {
      RUSTUP_HOME = "${homeDir}/.rustup";
      CARGO_HOME = "${homeDir}/.cargo";
      OPAMROOT = "${homeDir}/.opam";
      ELAN_HOME = "${homeDir}/.elan";
      BUN_INSTALL = "${homeDir}/.bun";
      UV_TOOL_BIN_DIR = "${homeDir}/.local/bin";
    };

    sessionPath = [
      "${homeDir}/.cargo/bin"
      "${homeDir}/go/bin"
      "${homeDir}/.opam/default/bin"
      "${homeDir}/.elan/bin"
      "${homeDir}/.bun/bin"
      "${homeDir}/.local/bin"
    ];
  };
}
