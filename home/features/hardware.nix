{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nvme-cli
    fwupd
    cpuid
    pciutils
    usbutils
    dmidecode
    bluez
    bluez-tools
    blueman
    smartmontools
    hdparm
    sdparm
    efibootmgr
    sbctl
    flashrom
  ];
}
