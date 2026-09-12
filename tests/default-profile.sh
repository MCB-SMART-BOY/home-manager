#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo"

result=$(nix eval --impure --no-write-lock-file --json --expr '
  let
    flake = builtins.getFlake (toString ./.);
    lib = flake.inputs.nixpkgs.lib;
    config = flake.homeConfigurations.default.config;
    packageNames = builtins.map (package: package.name or "") config.home.packages;
    hasPackage = needle: builtins.any (name: lib.hasInfix needle name) packageNames;
  in {
    nixvim = config.programs ? nixvim && config.programs.nixvim.enable;
    desktop = config.programs.aria2.enable;
    development = config.programs.vscode.enable;
    media = config.programs.ncmpcpp.enable;
    research = config.programs.libreoffice.enable;
    containers = config.programs.distrobox.enable;
    theming = config.gtk.enable;
    security = config.programs.gpg.enable;
    nixTools = config.programs.nh.enable;
    terminalTools = config.programs.zellij.enable;
    gaming = hasPackage "steam";
    hardware = hasPackage "nvme-cli";
    observability = hasPackage "bpftrace";
    chinaApps = hasPackage "ani-cli";
    niri = hasPackage "niri";
  }
')

for field in nixvim desktop development media research containers theming security nixTools terminalTools gaming hardware observability chinaApps niri; do
  value=$(jq -r ".${field}" <<<"$result")
  [[ "$value" == true ]] || {
    printf 'default profile field %s was %s\n' "$field" "$value" >&2
    exit 1
  }
done
