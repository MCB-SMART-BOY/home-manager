{ ... }:

{
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = "MCB-SMART-BOY";
        email = "2720838051@qq.com";
      };
      user.useConfigOnly = true;
      core.editor = "hx";
    };
  };
}
