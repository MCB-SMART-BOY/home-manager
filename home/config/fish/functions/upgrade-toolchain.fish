# 升级已安装的生态工具链；Home Manager 管理的工具随系统重建更新。
# 用法：upgrade-toolchain [--dry-run]

function upgrade-toolchain
    argparse n/dry-run -- $argv
    or begin
        echo "用法：upgrade-toolchain [--dry-run]"
        return 2
    end
    if test (count $argv) -gt 0
        echo "用法：upgrade-toolchain [--dry-run]"
        return 2
    end

    set -l command_args upgrade
    if set -q _flag_dry_run
        set -a command_args --dry-run
    end
    _mcb_toolchain $command_args
end
