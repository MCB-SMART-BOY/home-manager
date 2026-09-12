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
      completions.case_sensitive = false;
      completions.external.enable = true;
      completions.external.max_results = 200;
      history.file_format = "sqlite";
      history.max_size = 50000;
      history.sync_on_enter = true;
      history.isolation = false;
      history.ignore_space_prefixed = true;
    };
  };
}
