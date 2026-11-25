{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    nvme-cli
    fwupd
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
