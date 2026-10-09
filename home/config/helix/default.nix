_:

{
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings =
      let
        base = builtins.fromTOML (builtins.readFile ./config.toml);
        keys = base.keys or { };
      in
      base
      // {
        keys = keys // {
          # Select 只继承默认 Normal trie；用户自定义的 Space 分组必须显式镜像。
          # 此处从 Nix 单点派生，修改 config.toml 的 [keys.normal.space] 即同时生效。
          select = (keys.select or { }) // {
            space = (keys.normal or { }).space or { };
            # LSP 跳转按工作流共享；gl/gh 是移动语义，Select 下由 extend_line_* 承担，故排除。
            g =
              ((keys.select or { }).g or { })
              // builtins.removeAttrs ((keys.normal or { }).g or { }) [
                "h"
                "l"
              ];
          };
        };
      };
    languages = fromTOML (builtins.readFile ./languages.toml);
  };
}
