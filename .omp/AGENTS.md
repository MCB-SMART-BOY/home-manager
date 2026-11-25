# 项目路由

本仓库是当前用户的 Home Manager flake；项目检查与操作说明集中于 `.omp/`，不替代全局规则，也不保存日志、凭据或运行态。

- [flake.nix](../flake.nix) 与 [flake/default.nix](../flake/default.nix)：输入、唯一部署输出 `homeConfigurations.home` 及跨系统检查的事实源；[flake.lock](../flake.lock) 固定输入版本。当前目标为 `x86_64-linux`、`aarch64-linux` 与 `aarch64-darwin`。
- [home/default.nix](../home/default.nix) 是组合根，按层导入配置：`base.nix`/`packages.nix`/`invariants.nix` → `modules` 按所有者聚合 → `profiles` 能力集；Linux 桌面与主机能力按平台门控。部署读取当前 `USER`、`HOME` 与 Nix 系统标识；用目标普通用户执行 `home-manager switch --flake .#home --impure --no-write-lock-file --no-out-link`，不用 `sudo`。
- [home/base.nix](../home/base.nix) 只管理 XDG、`MANPAGER` 和 Home Manager 自身开关；语言工具链的环境变量与 `PATH` 由 [home/modules/development/toolchain/default.nix](../home/modules/development/toolchain/default.nix) 拥有。[home/packages.nix](../home/packages.nix) 列出没有独立配置的跨平台工具。
- [.omp/validate.sh](validate.sh) 用 `path:$PWD` 工作树构建真实用户的 activation package，因此未暂存的新文件也会被检查；全局 `~/.omp/agent/validate.sh` 是独立的交付质量门。

操作、授权、失败与回退边界见 [Home Manager 工作流](workflow/home-manager.md)。正式配置在 `flake/` 和 `home/`，不要把检查脚本或操作说明当成运行态配置。

## 配置分层

| 层 | 位置 | 职责 |
| --- | --- | --- |
| 0 | `home/base.nix` | 会话环境：XDG、`MANPAGER`、`home-manager` |
| 1 | `home/packages.nix`、`home/modules/tools`、`home/modules/development/toolchain` | 跨平台基础包、Home Manager 命令和工具链环境；Nix 拥有 `rg`、`fd`、`bat`、`eza` 等基础 CLI，工具链清单不重复安装 |
| 2 | `home/modules/<owner>/` | 按所有者聚合的叶子模块：`shell`、`terminal`、`editors`、`tools`、`development`、`apps`、`desktop`、`appearance` |
| 3 | `home/profiles/*.nix` | 能力集：桌面、开发扩展、媒体、研究、Wine 游戏兼容、容器、硬件、可观测性、安全等 |

依赖方向只向下：叶子模块不导入 profile，`home/modules` 不导入平台专属内容。Linux 专属的 `modules/desktop`、`modules/appearance` 与各 Linux app 只由 profile 导入，`home/default.nix` 用 `lib.optionals` 决定操作系统层级；所有 Linux profile 在 `x86_64-linux` 和 `aarch64-linux` 上同样启用，不再按 x86 架构裁剪能力集。`home/invariants.nix` 承载跨模块的语义断言；平台断言在模块被错误导入或误用时明确失败。只安装而没有独立配置的软件留在对应 profile，不为它新增空目录。

宿主 `/root/nixos-config` 拥有 portal、dconf 服务、fcitx5/Qt 包；本仓库只写用户级 GTK 设置、主题资产和 IME 会话变量，不重复声明宿主服务或系统包。
