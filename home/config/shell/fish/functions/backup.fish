# 快速备份：cp <file> <file>.bak
function backup --argument filename
    cp $filename $filename.bak
end
