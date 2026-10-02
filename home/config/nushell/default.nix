{ pkgs, ... }:

{
  programs.nushell = {
    enable = true;
    package = pkgs.nushell;
    configFile.source = ./config.nu;
    shellAliases = {
      md = "mkdir";
      rd = "rmdir";
    };
    envFile.source = ./env.nu;
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
