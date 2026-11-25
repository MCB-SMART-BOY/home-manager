{
  config,
  lib,
  pkgs,
  ...
}:

let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  programs = {
    gcc.enable = true;
    go = {
      enable = true;
      env.GOPATH = "${config.home.homeDirectory}/go";
    };
    bun.enable = true;
    uv.enable = true;
    opam.enable = true;
  }
  // lib.optionalAttrs isLinux {
    vscode = {
      enable = true;
      package = pkgs.vscode-fhs;
    };
    zed-editor = {
      enable = true;
      package = pkgs.zed-editor-fhs;
    };
  };

  home = {
    sessionVariables.PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    packages =
      with pkgs;
      [
        rustup
        elan
        nodejs
        gnumake
        cmake
        pkg-config
        openssl
        openssl.dev
        binutils
        sccache
        ccache
        lua-language-server
        marksman
        shellcheck
        statix
      ]
      ++ lib.optionals isLinux [
        bear
        mold
      ];
    shellAliases = {
      c = "cargo";
      cb = "cargo build";
      cr = "cargo run";
      ct = "cargo test";
      cc = "cargo check";
      cf = "cargo fmt";
      ccl = "cargo clippy";
    };
  };
}
