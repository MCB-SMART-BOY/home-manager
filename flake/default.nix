{ inputs }:

let
  inherit (inputs.nixpkgs) lib;
  systems = [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ];
  forAllSystems = lib.genAttrs systems;

  mkPkgs =
    system:
    import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [ (import ../overlays/tela-circle-icon-theme.nix) ];
    };

  pkgsFor = forAllSystems mkPkgs;

  mkHome =
    {
      system,
      username,
      homeDirectory,
    }:
    if !builtins.elem system systems then
      throw "Unsupported system ${system}; supported systems: ${lib.concatStringsSep ", " systems}."
    else
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor.${system};
        extraSpecialArgs = { inherit system; };
        modules = [
          inputs.nixvim.homeModules.nixvim
          ../home
          {
            home = { inherit username homeDirectory; };
          }
        ];
      };

  currentHome =
    let
      system = builtins.currentSystem or "";
      username = builtins.getEnv "USER";
      homeDirectory = builtins.getEnv "HOME";
    in
    if system == "" || username == "" || homeDirectory == "" then
      throw "Use --impure from the target user's session to read USER, HOME and the current system."
    else
      mkHome { inherit system username homeDirectory; };
in
{
  homeConfigurations.home = currentHome;

  checks = forAllSystems (system: {
    home =
      (mkHome {
        inherit system;
        username = "home-check";
        homeDirectory = "/tmp/home-check";
      }).activationPackage;
  });

  devShells = forAllSystems (system: {
    default = pkgsFor.${system}.mkShellNoCC {
      packages = with pkgsFor.${system}; [
        bash
        deadnix
        jq
        shellcheck
        statix
      ];
    };
  });

  formatter = forAllSystems (system: pkgsFor.${system}.nixfmt);
}
