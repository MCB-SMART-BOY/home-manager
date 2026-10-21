# 项目路由

本仓库是当前用户的 Home Manager flake；项目检查与操作说明集中于 `.omp/`，不替代全局规则，也不保存日志、凭据或运行态。

- [flake.nix](../flake.nix) 与 [flake/default.nix](../flake/default.nix)：输入、输出、`default`/`nixos` profiles 和 devShell 的事实源；[flake.lock](../flake.lock) 固定输入版本。
- [home/default.nix](../home/default.nix)、[home/base.nix](../home/base.nix) 与 [home/features](../home/features)：用户配置与可移植功能；[home/platform/nixos.nix](../home/platform/nixos.nix) 只为 NixOS 添加主机操作。普通 Linux 用 `#default`，NixOS 本机用 `#nixos`；均取当前 `USER`、`HOME`，求值须 `--impure`。普通用户的 Home Manager 操作不使用 `sudo`。
- [home/scripts](../home/scripts)、[home/config](../home/config)：安装到用户 profile 的工具与应用配置；`mcb-nixos` 和 `nfu`/`nrs`/`nru` 指向另一份 `/root/nixos-config` 系统配置，不是本仓库的 Home Manager 更新命令。独立语言工具链也不随 flake 更新自动升级。
- [.omp/validate.sh](validate.sh) 与 [.omp/tests](tests)：项目行为检查及真实 profile 构建；全局 `~/.omp/agent/validate.sh` 是另一个交付质量门。

操作、授权、失败与回退边界见 [Home Manager 工作流](workflow/home-manager.md)。正式配置在 `flake/` 和 `home/`，不要把检查脚本或操作说明当成运行态配置。
