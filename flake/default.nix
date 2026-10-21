{ inputs }:

let
  lib = inputs.nixpkgs.lib;
  systems = builtins.filter (lib.hasSuffix "-linux") lib.systems.flakeExposed;
  forAllSystems = lib.genAttrs systems;

  requireNonEmptyString =
    name: value:
    if !builtins.isString value then
      throw "Home Manager ${name} must be a string."
    else if value == "" then
      throw "Home Manager ${name} must not be empty."
    else
      value;

  requireImpureValue =
    name: value:
    if value == "" then
      throw "Current-user Home Manager profiles require ${name}; re-run the flake command with --impure."
    else
      value;

  mkPkgs =
    { system }:
    import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [ (import ../overlays/tela-circle-icon-theme.nix) ];
    };

  homeModules = {
    default = ../home/default.nix;

    desktop = ../home/features/desktop.nix;
    development = ../home/features/development.nix;
    media = ../home/features/media.nix;
    research = ../home/features/research.nix;
    gaming = ../home/features/gaming.nix;
    "china-apps" = ../home/features/china-apps.nix;
    niri = ../home/features/niri.nix;
    theming = ../home/features/theming.nix;
    containers = ../home/features/containers.nix;
    hardware = ../home/features/hardware.nix;
    observability = ../home/features/observability.nix;
    "security-tools" = ../home/features/security-tools.nix;
    "nix-tools" = ../home/features/nix-tools.nix;
    "terminal-tools" = ../home/features/terminal-tools.nix;
    # Explicit NixOS host entry point; generic Linux hosts must use portable modules.
    nixos = ../home/platform/nixos.nix;

    nixvim = {
      imports = [
        inputs.nixvim.homeModules.nixvim
        ../home/config/nixvim
      ];
    };
  };
  # This repository is the user's complete portable profile, not a menu of opt-in features.
  # The separate NixOS profile opts into host operations; default stays portable.
  defaultModules = [
    homeModules.desktop
    homeModules.development
    homeModules.media
    homeModules.research
    homeModules.gaming
    homeModules."china-apps"
    homeModules.niri
    homeModules.theming
    homeModules.containers
    homeModules.hardware
    homeModules.observability
    homeModules."security-tools"
    homeModules."nix-tools"
    homeModules."terminal-tools"
    homeModules.nixvim
  ];

  nixosModules = defaultModules ++ [
    homeModules.nixos
    {
      mcb.nixos = {
        flakeDirectory = "/root/nixos-config";
        enableHostOptions = false;
      };
    }
  ];

  # homeModules remains exported for composing additional configurations.

  mkHomeConfiguration =
    {
      system,
      username,
      homeDirectory,
      modules ? [ ],
    }:
    let
      validatedSystem = requireNonEmptyString "system" system;
      validatedUsername = requireNonEmptyString "username" username;
      validatedHomeDirectory = requireNonEmptyString "homeDirectory" homeDirectory;
    in
    if !builtins.isList modules then
      throw "Home Manager modules must be a list."
    else
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs { system = validatedSystem; };
        modules = [
          homeModules.default
          {
            home.username = validatedUsername;
            home.homeDirectory = validatedHomeDirectory;
          }
        ]
        ++ modules;
      };

  mkCurrentHomeConfiguration =
    modules:
    mkHomeConfiguration {
      system = requireImpureValue "builtins.currentSystem" (builtins.currentSystem or "");
      username = requireImpureValue "the USER environment variable" (builtins.getEnv "USER");
      homeDirectory = requireImpureValue "the HOME environment variable" (builtins.getEnv "HOME");
      inherit modules;
    };

  homeConfigurations = {
    default = mkCurrentHomeConfiguration defaultModules;
    nixos = mkCurrentHomeConfiguration nixosModules;
  };

  mkCheckHomeConfiguration =
    system: modules:
    (mkHomeConfiguration {
      inherit system modules;
      username = "home-manager-check";
      homeDirectory = "/var/empty/home-manager-check";
    }).activationPackage;

  checks = forAllSystems (
    system:
    {
      home-configuration = mkCheckHomeConfiguration system [ ];
    }
    # Keep the portable base checks on every existing platform. The complete
    # desktop build is checked on the workstation architecture, not advertised
    # as supporting every Linux architecture in lib.systems.flakeExposed.
    // lib.optionalAttrs (system == "x86_64-linux") {
      full-home-configuration = mkCheckHomeConfiguration system defaultModules;
    }
  );

  devShells = forAllSystems (system: {
    default = (mkPkgs { inherit system; }).mkShell {
      packages = with (mkPkgs { inherit system; }); [
        deadnix
        statix
      ];
    };
  });
in
{
  inherit devShells homeConfigurations homeModules;

  lib.mkHomeConfiguration = mkHomeConfiguration;

  inherit checks;

  formatter = forAllSystems (system: (mkPkgs { inherit system; }).nixfmt);
}
