{ pkgs, ... }:

{
  programs.gpg.enable = true;

  home.packages = with pkgs; [
    hashcat
    john
    burpsuite
    metasploit
    autopsy
    foremost
    paperkey
    gitleaks
    trivy
  ];
}
