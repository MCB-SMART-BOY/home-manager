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
      throw "homeConfigurations.default requires ${name}; re-run the flake command with --impure."
    else
      value;

  mkPkgs =
    { system }:
    import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
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
  # The NixOS platform module stays exported separately for explicit host integration.
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

  homeConfigurations = {
    default = mkHomeConfiguration {
      system = requireImpureValue "builtins.currentSystem" (
        if builtins ? currentSystem then builtins.currentSystem else ""
      );
      username = requireImpureValue "the USER environment variable" (builtins.getEnv "USER");
      homeDirectory = requireImpureValue "the HOME environment variable" (builtins.getEnv "HOME");
      modules = defaultModules;
    };
  };

  checks = forAllSystems (system: {
    home-configuration =
      (mkHomeConfiguration {
        inherit system;
        username = "home-manager-check";
        homeDirectory = "/var/empty/home-manager-check";
      }).activationPackage;
  });
in
{
  inherit homeConfigurations homeModules;

  lib.mkHomeConfiguration = mkHomeConfiguration;

  inherit checks;

  formatter = forAllSystems (system: (mkPkgs { inherit system; }).nixfmt);
}
