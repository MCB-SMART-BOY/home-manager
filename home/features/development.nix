{ pkgs, ... }:

{
  imports = [
    ../config/helix
    ../config/clangd
    ../config/toolchain
  ];

  home.packages = with pkgs; [
    rustup
    opam
    elan
    go
    bun
    uv
    gnumake
    cmake
    pkg-config
    openssl
    gcc
    binutils
    bear
    mold
    sccache
    ccache
    vscode-fhs
    zed-editor-fhs
    lua-language-server
    marksman
    nixd
    nixfmt
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
