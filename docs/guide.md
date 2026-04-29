# NixOS / nix-darwin 维护指南

> 当前仓库只服务两台机器：`wsl` 和 `MacBook-Pro`。  
> 设计目标是减少分叉、减少历史兼容层、降低后续维护成本。

## 当前架构

- 单一 `nixpkgs` 输入：`nixos-unstable`
- 两个系统输出：
  - `nixosConfigurations.wsl`
  - `darwinConfigurations."MacBook-Pro"`
- 一个共享 CLI Home Manager profile：
  - `home/profiles/shared-cli.nix`
- 两个平台各自再叠加少量差异：
  - Linux/WSL: `home/profiles/linux-cli.nix`
  - macOS: `home/profiles/darwin-cli.nix`

这意味着：

- CLI、Git、SSH、Neovim、Node.js、Opencode 这类“用户态共性”统一放在共享 profile。
- WSL 与 macOS 只保留必须不同的部分。
- 不再保留稳定/不稳定双通道，也不再保留未使用主机模板。

## 目录速览

| 路径 | 作用 |
| --- | --- |
| `flake.nix` | 仓库入口；定义输入、WSL 与 macOS 两个系统输出 |
| `hosts/wsl/default.nix` | WSL 系统层配置 |
| `hosts/macbook-pro/default.nix` | macOS 系统层配置 |
| `home/profiles/shared-cli.nix` | Linux/macOS 共用的 Home Manager imports |
| `home/profiles/linux-cli.nix` | WSL/Linux 用户环境 |
| `home/profiles/darwin-cli.nix` | macOS 用户环境 |
| `modules/home/*.nix` | 按功能拆分的 Home Manager 模块 |
| `modules/cli/modern.nix` | 跨 shell CLI 体验配置（fish/starship/fzf/direnv/tmux/yazi 等） |
| `modules/vscode/remote.nix` | 远程 VS Code Server 的 Home Manager 配置 |
| `modules/vscode/gui.nix` | macOS GUI VS Code 配置 |
| `modules/system/*.nix` | 系统级通用模块 |

## 配置分层

### 系统层

系统层负责：

- 主机名、用户、SSH、WSL、launchd/systemd、系统服务
- macOS GUI 应用与系统 defaults
- WSL 上必须 root 管理的服务与系统包

对应位置：

- `hosts/wsl/default.nix`
- `hosts/macbook-pro/default.nix`
- `modules/system/*`

### 用户层

用户层负责：

- CLI 工具
- Git / SSH / shell
- Neovim
- Direnv / nix-direnv
- VS Code 的用户态配置

对应位置：

- `home/profiles/*.nix`
- `modules/home/*.nix`
- `modules/vscode/*.nix`

## 共享策略

### 应该共享的

- Git 策略
- SSH client 配置
- shell 体验
- 常用 CLI
- Neovim
- Opencode

这些都应该优先放进：

- `home/profiles/shared-cli.nix`
- `modules/home/*.nix`

### 应该分开的

- WSL 特有服务与包
- macOS GUI 应用
- macOS defaults / keyboard / fonts / sketchybar
- VS Code GUI 与 VS Code Remote 的差异

这些分别放在：

- `hosts/wsl/default.nix`
- `hosts/macbook-pro/default.nix`
- `modules/vscode/gui.nix`
- `modules/vscode/remote.nix`

## 日常命令

### WSL

```bash
sudo nixos-rebuild test --flake .#wsl
sudo nixos-rebuild switch --flake .#wsl
```

### macOS

```bash
sudo darwin-rebuild switch --flake .#MacBook-Pro
```

### 快速检查

```bash
nix flake check --no-build --no-warn-dirty
```

### 更新输入

```bash
nix flake update
```

如果只想更新主包源：

```bash
nix flake lock --update-input nixpkgs
```

## 维护原则

### 1. 避免重新引入双通道

这个仓库已经收敛到单一 `unstable`。  
除非有明确回退需求，否则不要重新引入 `stable + unstable` 并存结构。

### 2. 新增配置前先问：是否真有第二个使用者

如果某段配置只服务一台机器、一个场景，不要先抽象。

优先顺序：

1. 放到具体主机
2. 确认另一台也需要
3. 再抽成共享模块

### 3. 删除死代码比保留模板更重要

这个仓库之前的维护成本，主要来自：

- 不再使用的主机定义
- 过期文档
- 双通道兼容层
- 重复模块

所以当某个主机或模块不用了，优先删除，而不是“以后也许有用”。

### 4. 文档必须跟结构同步

只要输出结构变了，就同步更新：

- `AGENTS.md`
- `docs/guide.md`
- `docs/dev-workflow.md`

否则文档会很快重新变成噪音。

## 目前已知的后续优化方向

- 评估 `docs/dev-workflow.md` 是否也需要做一次针对当前仓库的精简
- 在每次大改结构后运行一次最小目标构建，而不是只看 `flake check`

## 核心结论

当前仓库的最佳维护方向不是“继续通用化”，而是：

- 保持两台机器的真实边界
- 共享真正稳定的用户态配置
- 及时删除历史遗留层
- 让文档只描述当前实际结构
