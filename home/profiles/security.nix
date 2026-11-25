{
  pkgs,
  ...
}:

{
  programs.gpg.enable = true;

  home.packages = with pkgs; [
    hashcat
    john
    burpsuite
    metasploit
    foremost
    paperkey
    gitleaks
    trivy
  ];
}
