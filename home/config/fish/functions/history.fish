# Fish history listing with timestamps while preserving builtin subcommands.
function history
    if test (count $argv) -eq 0
        builtin history --show-time='%F %T '
        return
    end

    switch "$argv[1]"
        case clear clear-session delete merge save append --help -h
            builtin history $argv
        case '*'
            builtin history --show-time='%F %T ' $argv
    end
end
