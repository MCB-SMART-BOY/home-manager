# Home Manager 工作流

从仓库根目录操作。唯一部署目标是 `homeConfigurations.home`；[flake/default.nix](../../flake/default.nix) 与 [home/default.nix](../../home/default.nix) 是事实源。部署和检查共用同一套应用，目标为 Linux（`i686`、`x86_64`、`aarch64`）和 macOS（`x86_64`、`aarch64`），不为不同平台跳过应用。原生 Windows、BSD 和其他 CPU 组合不在此配置的支持范围；WSL 使用对应的 Linux 环境。

需要事先有能工作的 Nix。Nixpkgs、Home Manager 和 Nixvim 一并锁在 26.05；这是 Nixpkgs 最后支持 Intel Mac 的版本，不保证后续版本仍支持。不要为绕过平台错误关闭 Nixpkgs 的兼容性检查。

## 日常更新与切换

部署读取执行者的 `USER`、`HOME` 和 Nix 的当前系统标识，因此需要 `--impure`。确认变更影响并获得本次操作授权后，用目标普通用户执行：

```bash
home-manager switch --flake .#home --impure --no-write-lock-file --no-out-link
```

首次接管前，先备份并处理现有应用设置与 Home Manager 管理权的冲突；不要为了通过激活就覆盖它们。对接管后的设置修改仓库源文件。本仓库不部署操作系统或桌面会话，不自动提权，也不做垃圾回收。

如确需更新输入，经本次授权后单独执行 `nix flake update`（或更新指定输入），并审阅 [flake.lock](../../flake.lock) 的改动。更新 lock 与实际激活是两项操作，均不是检查；已获明确授权时不重复确认，示例也不是未来操作的永久授权。

切换前运行 `home-manager generations` 记下当前 generation；切换后确认新的 `(current)`，重开 shell，并实际走一次本次改动影响的功能。构建通过不等于应用运行正常。

## 常用开发工具

切换 Home Manager 只安装以下命令本身，不下载或编译清单里的开发工具。它们是普通可执行文件：在 Home Manager 的 `bin` 已加入 `PATH` 的 Bash、Fish、Zsh 或 Nushell 中都可直接调用。

```bash
bootstrap-toolchain              # Rust、Python、Go、JS 四组全部按最新版本安装
bootstrap-toolchain rust python  # 也可以只选几组
update-toolchain                  # 只升级清单里已有的工具，不安装缺项
check-toolchain                   # 只检查管理器安装位置和 PATH 路径
```

[工具清单](../../home/scripts/toolchain.tsv) 不锁版本。`bootstrap-toolchain` 即使在系统目录或 Nix 中找到同名命令，也照常交给该生态的管理器安装；不会卸载系统包或改 `PATH` 顺序。若管理器自己的安装目录已经有同名文件，则按该管理器的规则处理。`check-toolchain` 报告两边的路径，方便你自己决定用哪份；它不查询远程版本。

| 组 | 前置条件和安装位置 |
| --- | --- |
| `rust` | 已有 Cargo 和本机编译工具；用 `cargo install --locked`。按 `CARGO_INSTALL_ROOT`、`CARGO_HOME`、`~/.cargo` 的顺序选择安装根目录，命令在其 `bin`。`rustfmt`、`clippy`、`rust-analyzer` 是 Rust 工具链组件，单独用 rustup 管。 |
| `python` | 已有 uv；`uv tool install --managed-python --upgrade` 用 uv 托管的 Python 安装独立工具，命令目录见 `uv tool dir --bin`。解释器和项目依赖仍用 `uv python`、`uv add`、`uv sync`。 |
| `go` | 已有官方 Go 工具链；用 `go install ...@latest`，安装到 `GOBIN` 或 `GOPATH` 首项下的 `bin`。 |
| `js` | 已有 Bun 和 Node（有些 CLI 通过 Node 启动）；用 `bun add --global ...@latest`，目录见 `bun pm bin --global`。Bun 不支持 32 位 x86；该机器仍可用 `#home`，安装时显式选其他组。 |
| `mise` | 单独执行 `bootstrap-toolchain mise` 才用现有 mise 安装并选择全局最新版 uv、Bun 和 Node。`update-toolchain mise` 只检查并更新已有的全局 mise 版本，不替代 Rust、Go 或 Python 的管理器。 |

Nix 仍提供编辑器、Shell 所依赖的基础命令、`clangd` 和 Nix 自身的开发工具；`prettier`、`vtsls` 由 Bun 提供。项目锁文件继续决定项目自己的版本；Home Manager 回退不会回退这些独立安装的工具。

## 开发反馈与交付检查

项目入口 [.omp/validate.sh](../validate.sh) 先在临时目录验证工具链命令，再用 Git Flake 源构建当前用户的配置；需要 Nix 与 jq。`--help` 不执行检查。构建使用 `--impure --no-update-lock-file --no-link`，不会激活、更新 lock、写入 `result`、调用 `sudo` 或改动 Git index。

`checks.<system>.home` 对上述五个目标使用合成用户和相同的模块。求值只证明能生成构建计划；完整构建和应用运行仍需相应平台。比如在 `aarch64-linux` 构建机上运行：

```bash
nix build --no-write-lock-file --no-link .#checks.aarch64-linux.home
```

新增源文件尚未进入 Git 时，可用 `path:` 检查工作树而不暂存文件：

```bash
nix build --impure --no-write-lock-file --no-link "path:$PWD#homeConfigurations.home.activationPackage"
```

全局质量门可选用 `~/.omp/agent/validate.sh --eval-only` 获取快速反馈；它可能下载依赖或触发 IFD，不发布成功戳，也不证明真实用户配置可构建。

交付前按顺序执行项目门、再执行独立的全局质量门，并检查每项实际结果：

```bash
bash .omp/validate.sh
~/.omp/agent/validate.sh
```

检查通过后，审阅待交付变更；提交和推送分别取得明确授权，检查入口不自动执行它们。这里不预设已有 CI。

## 权限、失败与回退

flake 的 Git-tracked 源文件进入通常可读的 Nix store；不要将凭据或私密材料放入跟踪文件，也不要让构建依赖未跟踪文件。忽略规则不能保护已跟踪的秘密。`.omp/` 只放检查入口和说明，不保存日志、凭据或运行态。

检查失败时先诊断 Nix 或构建错误，不冒充通过，也不自动切换。切换失败或新配置有问题，先保留现场并判断是否需要回到先前 Home Manager generation；获本次回退授权后可运行：

```bash
home-manager switch --rollback
```

回退只处理 Home Manager generation，不自动撤销 [flake.lock](../../flake.lock)、应用数据或系统 trust store。恢复 lock 与修改系统配置须单独审阅与授权。
