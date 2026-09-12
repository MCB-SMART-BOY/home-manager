{ ... }:

{
  home.shellAliases = {
    g = "git";
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gl = "git pull";
    gs = "git status";
    gd = "git diff";
    gco = "git checkout";
    gb = "git branch";
    gcp = "git cherry-pick";
    grb = "git rebase";
    glg = "git log --oneline --graph --decorate";
    bcat = "bat --paging=never --style=plain";
    catt = "bat --paging=always";
    compress = "ouch compress";
    decompress = "ouch decompress";
    fdf = "fd";
    top = "btop";
    myip = "curl -s https://ipinfo.io/ip";
  };
}
