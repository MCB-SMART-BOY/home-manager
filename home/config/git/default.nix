{ ... }:

{
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user.useConfigOnly = true;
      core.editor = "hx";
    };
  };
}
