{ inputs }:

let
  inherit (inputs.nixpkgs) lib;
  systems = [
    "aarch64-darwin"
    "aarch64-linux"
    "i686-linux"
    "x86_64-linux"
  ];
  forAllSystems = lib.genAttrs systems;
  pkgsFor = forAllSystems (system: import inputs.nixpkgs { inherit system; });

  mkHome =
    { system, username, homeDirectory }:
    if !builtins.elem system systems then
      throw "Unsupported system ${system}; supported systems: ${lib.concatStringsSep ", " systems}."
    else
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor.${system};
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
    home = (mkHome {
      inherit system;
      username = "home-check";
      homeDirectory = "/tmp/home-check";
    }).activationPackage;
  });

  devShells = forAllSystems (system: {
    default = pkgsFor.${system}.mkShellNoCC {
      packages = with pkgsFor.${system}; [
        bash
        jq
        shellcheck
      ];
    };
  });

  formatter = forAllSystems (system: pkgsFor.${system}.nixfmt);
}
