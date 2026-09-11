{ pkgs, ... }:

{
  home.packages = with pkgs; [
    hashcat
    john
    burpsuite
    metasploit
    autopsy
    foremost
    gnupg
    paperkey
    gitleaks
    trivy
  ];
}
