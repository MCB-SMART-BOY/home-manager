{ pkgs, ... }:

{
  imports = [
    ../config/helix
    ../config/clangd
    ../config/toolchain
  ];

  programs = {
    gcc.enable = true;
    go.enable = true;
    bun.enable = true;
    uv.enable = true;
    opam.enable = true;
    vscode = {
      enable = true;
      package = pkgs.vscode-fhs;
    };
    zed-editor = {
      enable = true;
      package = pkgs.zed-editor-fhs;
    };
  };

  home.packages = with pkgs; [
    rustup
    elan
    gnumake
    cmake
    pkg-config
    openssl
    binutils
    bear
    mold
    sccache
    ccache
    lua-language-server
    marksman
    shellcheck
    statix
  ];

  home.shellAliases = {
    c = "cargo";
    cb = "cargo build";
    cr = "cargo run";
    ct = "cargo test";
    cc = "cargo check";
    cf = "cargo fmt";
    ccl = "cargo clippy";
  };
}
