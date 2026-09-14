{ pkgs, ... }:

let
  winboatWithVmx = pkgs.winboat.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      substituteInPlace src/renderer/data/docker.ts src/renderer/data/podman.ts \
        --replace-fail '                VERSION: "11",' \
          '                VERSION: "11",
                VMX: "Y",
                HV: "Y",
                CPU_MODEL: "Broadwell-noTSX-IBRS",
                CPU_FLAGS: "vmx=on,mpx=off,hv-time=on,hv-relaxed=on,hv-vapic=on,hv-spinlocks=0x1fff",
                ADAPTER: "e1000e",'
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
