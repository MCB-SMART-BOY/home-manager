{ pkgs, ... }:

let
  winboatWithVmx = pkgs.winboat.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      substituteInPlace src/renderer/data/docker.ts src/renderer/data/podman.ts \
        --replace-fail '                VERSION: "11",' \
          '                VERSION: "11",
                VMX: "Y",'
    '';
  });
in
{
  programs.distrobox.enable = true;

  home.packages = with pkgs; [
    winboatWithVmx
    podman-compose
    firecracker
  ];
}
