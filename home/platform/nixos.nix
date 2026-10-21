# NixOS platform entry point. Import this only on a NixOS host; portable defaults stay in home/default.nix.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  nixosConfig = config.mcb.nixos;

  mcbNixos = pkgs.writeShellApplication {
    name = "mcb-nixos";
    runtimeInputs = with pkgs; [
      coreutils
      git
      jq
      nix
      nixos-rebuild
    ];
    text = ''
      if [[ -z "''${MCB_NIXOS_FLAKE_DIR:-}" ]]; then
        export MCB_NIXOS_FLAKE_DIR=${lib.escapeShellArg nixosConfig.flakeDirectory}
      fi
      ${builtins.readFile ./mcb-nixos}
    '';
  };

  flakeSourceExpression = ''
    let
      configuredSource = builtins.getEnv "MCB_NIXOS_FLAKE_DIR";
      hasScheme = builtins.match ".*:.*" configuredSource != null;
      hasQueryOrFragment = builtins.match ".*[?#].*" configuredSource != null;
      sourcePath =
        if configuredSource == "" then
          ${builtins.toJSON nixosConfig.flakeDirectory}
        else if hasScheme || hasQueryOrFragment then
          throw "MCB_NIXOS_FLAKE_DIR must be an absolute local directory path without a URI scheme, query, or fragment"
        else if builtins.substring 0 1 configuredSource != "/" then
          throw "MCB_NIXOS_FLAKE_DIR must be an absolute local directory path"
        else
          configuredSource;
      sourceDir = /. + sourcePath;
      sourceDirType = builtins.tryEval (builtins.readFileType sourceDir);
      canonicalSourcePath = builtins.toString sourceDir;
      canonicalSourceDir = /. + canonicalSourcePath;
      flakeFile = canonicalSourceDir + "/flake.nix";
      regularFlakeFile =
        builtins.pathExists flakeFile
        && builtins.readFileType flakeFile == "regular";
      source =
        if !builtins.pathExists sourceDir then
          throw "MCB_NIXOS_FLAKE_DIR does not exist or is inaccessible to the editor user: " + sourcePath
        else if !sourceDirType.success || sourceDirType.value != "directory" then
          throw "MCB_NIXOS_FLAKE_DIR must be a non-symlink directory: " + sourcePath
        else if !regularFlakeFile then
          throw "MCB_NIXOS_FLAKE_DIR must contain a regular flake.nix: " + sourcePath
        else if !builtins.pathExists (canonicalSourceDir + "/.git") then
          throw "MCB_NIXOS_FLAKE_DIR must be a Git repository root; non-Git directories are not imported: " + sourcePath
        else
          canonicalSourcePath;
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
in
{
  imports = [
    {
      _module.args = {
        mcbNixosExecutable = "${mcbNixos}/bin/mcb-nixos";
        mcbNixpkgsExpression = nixpkgsExpression;
        mcbNixosOptionsExpression = nixosOptionsExpression;
      };
    }
    ../config/btop/nixos.nix
    ../config/fish/nixos.nix
    ../config/zsh/nixos.nix
    ../config/nushell/nixos.nix
    ../config/helix/nixos.nix
    ../config/nixvim/nixos.nix
  ];

  options.mcb.nixos = {
    flakeDirectory = lib.mkOption {
      type = lib.types.strMatching "/[^:?#]*";
      default = "/etc/nixos";
      description = ''
        Absolute local NixOS Git repository root (no URI scheme, query, or fragment).
        Sets the default source for mcb-nixos and, when host options are enabled,
        nixd's nixpkgs and NixOS options. MCB_NIXOS_FLAKE_DIR overrides it at
        runtime. This option does not grant access to a root-only directory:
        run system commands as root, and disable enableHostOptions for a
        regular user's editor if that user cannot read the source.
        Nix imports Git-tracked source files into its normally readable store;
        tracked files must not contain secrets. Ignored and untracked files
        are not imported. flake.nix must be tracked by Git.
      '';
    };

    enableHostOptions = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Configure nixd to evaluate nixpkgs and NixOS host options from
        flakeDirectory. Enable only when the editor's user can read that
        directory; set false for a root-only system flake while retaining
        generic Nix completion and other NixOS-specific editor settings.
      '';
    };
  };

  config = {
    home.packages = [ mcbNixos ];

    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux;
        message = "homeModules.nixos requires a Linux system.";
      }
      {
        assertion = builtins.pathExists /etc/NIXOS;
        message = "homeModules.nixos requires a NixOS host environment; generic Linux hosts are unsupported.";
      }
    ];

    home.sessionPath = lib.mkAfter [ "/run/wrappers/bin" ];
  };
}
