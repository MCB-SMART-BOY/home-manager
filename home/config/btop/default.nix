{ ... }:

{
  programs.btop.enable = true;

  xdg.configFile = {
    "btop/btop.conf".source = ./btop.conf;
    "btop/themes/noctalia.theme".source = ./themes/noctalia.theme;
  };
}
