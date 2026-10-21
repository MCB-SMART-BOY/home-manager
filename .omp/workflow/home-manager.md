# Home Manager 工作流

从仓库根目录操作。配置与 profile 的事实源是 [flake/default.nix](../../flake/default.nix)、[home/default.nix](../../home/default.nix) 和 [home/platform/nixos.nix](../../home/platform/nixos.nix)；本页不是另一套配置。`#default` 是普通 Linux 上的完整可移植用户配置；本机 NixOS 使用 `#nixos`，它在 `default` 基础上加入 NixOS 主机工具，仅适用于 NixOS。两者读取执行者的 `USER`、`HOME` 和当前系统，均须 `--impure`；以将要使用该 profile 的普通用户运行 Home Manager，不用 `sudo`，勿在 root 环境替用户执行。

## 日常更新与切换

确认目标、变更影响及获得本次操作授权后，在仓库根目录直接运行：

```bash
nix flake update
home-manager switch --flake .#nixos --impure --no-write-lock-file --no-out-link
```

只在 NixOS 主机用 `#nixos`；普通 Linux 将第二行换为：

```bash
home-manager switch --flake .#default --impure --no-write-lock-file --no-out-link
```

第一步改动 [flake.lock](../../flake.lock)；第二步实际激活用户 profile，两步都不是检查命令。只更新选定输入或不更新时，另行决定并记录预期变更，不把 `switch` 当成 lock 更新。执行切换须有覆盖该操作的明确授权；已明确授权时不重复确认。文中的示例不构成未来操作的永久授权。不自动提权、不自动运行 NixOS 系统更新命令，也不做垃圾回收。

切换前运行 `home-manager generations` 记下当前 generation；切换后确认新的 `(current)`，重开 shell，并实际走一次本次改动影响的功能。NixOS profile 可先执行 `mcb-nixos --help` 检查主机工具入口，不借此执行系统更新。构建通过不等于应用运行正常。

`mcb-nixos`、`nfu`、`nrs`、`nru` 是另一份 `/root/nixos-config` 的系统操作，不是本仓库的 HM 更新/回退入口；这里的切换不会替代系统配置部署。[mcb-toolchain](../../home/scripts/mcb-toolchain) 按 [tools.json](../../home/config/toolchain/tools.json) 管理独立语言工具；`nix flake update` 不会一并升级这些工具，确需更新时另行批准并操作。

## 开发反馈与交付检查

在考虑激活前可先查看帮助；帮助不执行 Nix：

```bash
bash .omp/validate.sh --help
```

可选的快速求值反馈是 `~/.omp/agent/validate.sh --eval-only`；它可能下载依赖或触发 IFD，不发布成功戳，不等于完整检查，也不证明真实 profile 可构建。

项目入口 [.omp/validate.sh](../validate.sh) 首先诊断所需工具，限定范围运行 ShellCheck，运行四项现有行为测试（`mcb-toolchain.sh`、`mcb-nixos.sh`、`default-profile.sh`、`nixos-profile.sh`），然后构建当前用户的 `default` activationPackage；仅在 `/etc/NIXOS` 存在时还构建 `nixos` activationPackage，否则明确标记不适用。独立检查串行执行并汇总失败；构建使用 `--impure --no-write-lock-file --no-link`，不激活、不更新本项目 lock、不生成 `result`、不调用全局门，不运行 `sudo` 或改动本仓库 Git index。测试仅在临时 fixture 中创建 Git 元数据。缺少前置工具会报错并停止，不算通过。系统 Nix 须预装；项目 devShell 保留 `deadnix`/`statix` 并提供 `bash`、`coreutils`、`git`、`jq`、`shellcheck`、`util-linux`，需要工具时手动进入：

```bash
nix develop --no-write-lock-file --command bash .omp/validate.sh
```

交付前按顺序执行项目门、再执行独立的全局质量门，并检查每项实际结果：

```bash
bash .omp/validate.sh
~/.omp/agent/validate.sh
```

[flake checks](../../flake/default.nix) 使用合成用户构建 portable/base（工作站架构还含完整可移植模块），不使用当前 `USER`/`HOME` 构建 `#default`/`#nixos`，不能取代项目门的真实用户 activationPackage 构建，也不能取代实际激活后的观察。检查均通过且准备交付后，人工审阅本仓库全部待提交变更，按全局提交门要求处理整个非忽略工作树，不做部分暂存；提交与推送分别取得明确授权，validator 不自动执行它们。这里不预设已有 CI。

## 权限、失败与回退

flake 的 Git-tracked 源文件进入通常可读的 Nix store；不要将凭据或私密材料放入跟踪文件，也不要让构建依赖未跟踪文件。忽略规则不能保护已跟踪的秘密。`.omp/` 只放检查入口、行为测试和说明，不保存日志、凭据或运行态；对仓库读权限、Git 状态和系统/用户操作权限分别审视。普通用户无法读取 root-only 系统仓库时，不要为了 HM 校验提权；`nixos` profile 默认禁用读取该系统仓库的编辑器 host options。

工具缺失按提示进入 devShell 后重试；检查失败先诊断对应测试、求值或构建错误，不冒充通过，也不自动切换。切换失败或新配置有问题，先保留现场并判断是否需要回到先前 Home Manager generation；获本次回退授权后可运行：

```bash
home-manager switch --rollback
```

此回退只处理 Home Manager generation，不自动撤销 [flake.lock](../../flake.lock)、应用数据或系统 trust store；需要恢复 lock 须单独审阅与授权。NixOS 系统配置和 VM 运行态不在该回退范围内，不自动处理；任何系统级变更、提交或推送也分别取得明确授权。
