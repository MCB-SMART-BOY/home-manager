{ pkgs, ... }:

{
  assertions = [
    {
      assertion = pkgs.stdenv.hostPlatform.isLinux;
      message = "The desktop feature requires Linux.";
    }
  ];

  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    XIM_SERVERS = "fcitx";
  };
}
