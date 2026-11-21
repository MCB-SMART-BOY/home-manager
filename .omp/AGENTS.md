# 项目路由

本仓库是当前用户的 Home Manager flake；项目检查与操作说明集中于 `.omp/`，不替代全局规则，也不保存日志、凭据或运行态。

- [flake.nix](../flake.nix) 与 [flake/default.nix](../flake/default.nix)：输入、唯一部署输出 `homeConfigurations.home` 及跨系统检查的事实源；[flake.lock](../flake.lock) 固定输入版本。
- [home/default.nix](../home/default.nix) 直接组合所有系统共用的用户配置，[home/packages.nix](../home/packages.nix) 列出没有独立配置的工具。部署读取当前 `USER`、`HOME` 与 Nix 系统标识；用目标普通用户执行 `home-manager switch --flake .#home --impure --no-write-lock-file --no-out-link`，不用 `sudo`。
- [.omp/validate.sh](validate.sh) 构建真实用户的 activation package；全局 `~/.omp/agent/validate.sh` 是独立的交付质量门。

操作、授权、失败与回退边界见 [Home Manager 工作流](workflow/home-manager.md)。正式配置在 `flake/` 和 `home/`，不要把检查脚本或操作说明当成运行态配置。

## 软件配置分类

`home/config/<分类>/<软件>` 按主要用途组织，如终端、编辑器、Shell、开发工具和独立命令行工具。目录位置不决定是否启用；实际应用集合以 `home/default.nix` 及其模块为准。只安装而没有独立配置的软件留在相应模块，不为它新增空目录。
