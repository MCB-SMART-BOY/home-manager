{
  config,
  lib,
  pkgs,
  ...
}:

let
  niriRun = pkgs.writeShellApplication {
    name = "niri-run";
    text = ''
      exec "$@"
    '';
  };

  lockScreen = pkgs.writeShellApplication {
    name = "lock-screen";
    text = ''
      exec noctalia msg session lock
    '';
  };

  steamLauncher = pkgs.writeShellApplication {
    name = "steam-launcher";
    text = ''
      exec steam "$@"
    '';
  };
in
{
  options.mcb.niri.hostOutputs.enable =
    lib.mkEnableOption "machine-specific Niri output configuration";

  config = {
    home.packages = [
      pkgs.bash
      pkgs.niri
      pkgs.swayidle
      pkgs.polkit_gnome
      niriRun
      lockScreen
      steamLauncher
    ];

    home.file = {
      ".local/bin/niri-run".source = "${niriRun}/bin/niri-run";
      ".local/bin/lock-screen".source = "${lockScreen}/bin/lock-screen";
      ".local/bin/steam-launcher".source = "${steamLauncher}/bin/steam-launcher";
    };

    xdg.configFile = {
      "niri/config.kdl".source = ./config.kdl;
      "niri/rules.kdl".source = ./rules.kdl;
      "niri/binds.kdl".source = ./binds.kdl;
      "niri/outputs.kdl".source = ./outputs.kdl;
    };

  };
}
