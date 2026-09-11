# 初始化各语言生态的开发工具链。
# 用法：bootstrap-toolchain [--dry-run]

function bootstrap-toolchain
    argparse n/dry-run -- $argv
    or begin
        echo "用法：bootstrap-toolchain [--dry-run]"
        return 2
    end
    if test (count $argv) -gt 0
        echo "用法：bootstrap-toolchain [--dry-run]"
        return 2
    end

    set -l command_args bootstrap
    if set -q _flag_dry_run
        set -a command_args --dry-run
    end
    _mcb_toolchain $command_args
end
