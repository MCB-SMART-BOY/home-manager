{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Nushell resolves source paths at parse time, before startup code runs.
  starshipInit = pkgs.runCommand "mcb-starship-init.nu" { } ''
    ${lib.getExe config.programs.starship.package} init nu > "$out"
  '';
  zoxideInit = pkgs.runCommand "mcb-zoxide-init.nu" { } ''
    ${lib.getExe config.programs.zoxide.package} init nushell > "$out"
  '';
in

{
  programs.nushell = {
    enable = true;
    package = pkgs.nushell;
    loadSessionVariables = false;
    configFile.text = ''
      source ${starshipInit}
      source ${zoxideInit}
      ${builtins.readFile ./config.nu}
    '';

    # Even with its Nushell integration disabled, HM's eza module injects
    # an options alias. Keep only the shared aliases and the cargo shortcuts.
    shellAliases = lib.mkForce ({
      c = "cargo";
      cb = "cargo build";
      cr = "cargo run";
      ct = "cargo test";
      cc = "cargo check";
      cf = "cargo fmt";
      ccl = "cargo clippy";
    } // config.home.shellAliases);
    settings = {
      show_banner = false;
      edit_mode = "emacs";
      table.mode = "rounded";
      completions = {
        case_sensitive = false;
        external = {
          enable = true;
          max_results = 200;
        };
      };
      history = {
        file_format = "sqlite";
        max_size = 50000;
        sync_on_enter = true;
        isolation = false;
        ignore_space_prefixed = true;
      };
    };
  };
}
