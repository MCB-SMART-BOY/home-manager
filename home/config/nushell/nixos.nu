# NixOS-specific helpers. Loaded by the explicit home.platform.nixos entry point.

def please [...args: string] {
    ^/run/wrappers/bin/sudo ...$args
}

def ngc [] {
    ^/run/wrappers/bin/sudo nix-collect-garbage -d
}

def nrs [...args: string] {
    ^mcb-nixos switch ...$args
}

def nrt [...args: string] {
    ^mcb-nixos test ...$args
}

def nrb [...args: string] {
    ^mcb-nixos boot ...$args
}

def nfu [...args: string] {
    ^mcb-nixos update ...$args
}

def nru [...args: string] {
    ^mcb-nixos update-switch ...$args
}

def nrc [...args: string] {
    ^mcb-nixos check ...$args
}
