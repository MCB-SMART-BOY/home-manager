# 快速查看将要构建/下载的 derivations（判断是否会源码编译）
# 用法：nrc [flake 引用]
function nrc --argument-names flake
    if test -z "$flake"
        set -l flake_source (_mcb_flake_source)
        or return 1
        set -l flake_target (_mcb_flake_target)
        or return 1
        set flake "$flake_source#nixosConfigurations.$flake_target.config.system.build.toplevel"
    end
    nix build "$flake" --dry-run
end
