# NixOS 集成模块：仅显式导入时提供系统重建与 NixOS 选项工具。
{
  lib,
  options,
  pkgs,
  ...
}:
let
  flakeSourceExpression = ''
    let
      configuredSource = builtins.getEnv "MCB_NIXOS_FLAKE_DIR";
      hasScheme = builtins.match ".*:.*" configuredSource != null;
      hasQueryOrFragment = builtins.match ".*[?#].*" configuredSource != null;
      sourcePath =
        if configuredSource == "" then
          "/etc/nixos"
        else if hasScheme || hasQueryOrFragment then
          throw "MCB_NIXOS_FLAKE_DIR must be an absolute local directory path without a URI scheme, query, or fragment"
        else if builtins.substring 0 1 configuredSource != "/" then
          throw "MCB_NIXOS_FLAKE_DIR must be an absolute local directory path"
        else
          configuredSource;
      source =
        if builtins.pathExists (/. + sourcePath) then
          "path:" + sourcePath
        else
          throw "MCB_NIXOS_FLAKE_DIR does not exist: " + sourcePath;
    in
  '';

  nixpkgsExpression = ''
    ${flakeSourceExpression}
    let
      flake = builtins.getFlake source;
    in
    import flake.inputs.nixpkgs { system = builtins.currentSystem; }
  '';

  nixosOptionsExpression = ''
    ${flakeSourceExpression}
    let
      flake = builtins.getFlake source;
      targetEnv = builtins.getEnv "MCB_NIXOS_FLAKE_TARGET";
      hostEnv = builtins.getEnv "NIXD_HOST";
      hostFile =
        if builtins.pathExists /etc/hostname then
          builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile /etc/hostname)
        else
          "";
      cfgs = flake.nixosConfigurations;
      explicitHost =
        if targetEnv != "" then
          targetEnv
        else
          hostEnv;
      selectedHost =
        if explicitHost != "" then
          if builtins.hasAttr explicitHost cfgs then
            explicitHost
          else
            throw "NixOS target not found in flake: " + explicitHost
        else if hostFile != "" && builtins.hasAttr hostFile cfgs then
          hostFile
        else if builtins.hasAttr "nixos" cfgs then
          "nixos"
        else
          let
            cfgNames = builtins.attrNames cfgs;
          in
          if builtins.length cfgNames == 1 then
            builtins.head cfgNames
          else
            throw "Cannot select a unique NixOS target; set MCB_NIXOS_FLAKE_TARGET";
    in
    cfgs.''${selectedHost}.options
  '';

  btopWithNixOSDriver = pkgs.writeShellApplication {
    name = "btop";
    text = ''
      export LD_LIBRARY_PATH="/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      exec ${pkgs.btop}/bin/btop "$@"
    '';
  };

  nixosFishFunctions = [
    "_mcb_flake_dir"
    "_mcb_flake_ref"
    "_mcb_flake_source"
    "_mcb_flake_target"
    "nfu"
    "nrb"
    "nrc"
    "nrs"
    "nrt"
    "nru"
  ];
  fishFunctionFiles = builtins.listToAttrs (
    map (name: {
      name = "fish/functions/${name}.fish";
      value.source = ./config/fish/functions + "/${name}.fish";
    }) nixosFishFunctions
  );
in
{
  config = {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux;
        message = "homeModules.nixos requires a Linux system.";
      }
    ];

    home.packages = lib.mkAfter [ btopWithNixOSDriver ];
    home.file.".local/bin/btop".source = "${btopWithNixOSDriver}/bin/btop";
    home.sessionPath = lib.mkAfter [ "/run/wrappers/bin" ];
    programs.zsh.shellAliases = {
      nsp = "nix search nixpkgs";
      nsh = "nix-shell";
      ngc = "/run/wrappers/bin/sudo nix-collect-garbage -d";
      please = "/run/wrappers/bin/sudo";
    };

    xdg.configFile = fishFunctionFiles // {
      "helix/languages.toml".source = lib.mkForce (
        pkgs.writeText "mcbctl-nixos-languages.toml" (
          builtins.readFile ./config/helix/languages.toml + "\n" + builtins.readFile ./config/helix/nixos.toml
        )
      );
    };

    programs.zsh.initContent = lib.mkAfter (builtins.readFile ./config/zsh/nixos.zsh);
    programs.nushell.extraConfig = lib.mkAfter (builtins.readFile ./config/nushell/nixos.nu);
  }
  // lib.optionalAttrs (options ? programs.nixvim) {
    programs.nixvim.lsp.servers.nixd.config.settings.nixd = {
      nixpkgs.expr = nixpkgsExpression;
      options.nixos.expr = nixosOptionsExpression;
    };
  };
}
