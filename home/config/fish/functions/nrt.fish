# 测试新配置但不设为默认
# 用法：nrt [额外参数]
function nrt
    _mcb_nixos_root test $argv
end
