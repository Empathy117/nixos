# NixOS 多主机架构与维护指南

> 写给未来的自己和刚入坑 Nix/NixOS 的你：这一套结构既能支撑个人多台机器，也足够扩展成团队级别的配置基线。

## 1. 总体思路
- **分层**：`modules/system` 管系统级共用配置，`home/home.nix` 聚合 CLI/Git/SSH/Direnv，VS Code 通过独立模块实现 GUI 与 Remote Server 双模。
- **数据驱动**：`flake.nix` 中的 `hostDefs` 决定每台主机加载哪些 System Module + 哪些 Home Module；新增主机只需要“描述”，不用复制粘贴配置。
- **通道管理**：稳定版 (`nixpkgs`) 与不稳定版 (`nixpkgs-unstable`) 同时引入。默认从稳定渠道取包，只对确实需要新特性的包使用 `pkgsUnstable`。
- **一次定义，到处复用**：Git、SSH、Direnv 这类“必须保持一致”而且不随硬件变化的内容全部放进 home 模块；VS Code 设置集中在 `home/vscode/settings.nix`，GUI/WSL 共享同一份 JSON。

## 2. 目录速览
| 路径 | 作用 |
| --- | --- |
| `modules/system/core.nix` | 所有主机共享的 Nix/Nixpkgs/镜像/时区等硬性策略 |
| `modules/system/vscode-remote.nix` | 启用 `services.vscode-server`，只在需要远程 VS Code 的主机引用 |
| `modules/home/*.nix` | 按功能拆分的 Home Manager 片段（CLI 包、Git、SSH、Direnv、自动生成密钥等）|
| `modules/vscode/base.nix` | 把 VS Code 扩展/设置抽象成 `config.shared.vscode.*`，供 GUI/Remote 共用 |
| `modules/vscode/gui.nix` | GUI VS Code（本地桌面/非 WSL）的安装与设置 |
| `home/vscode` | VS Code Server（WSL/远程 Linux）的一次性部署脚本 |
| `hosts/*.nix` | 每台主机的特有配置（WSL、`devbox` 示范）|
| `docs/guide.md` | 本指南，记录架构、命令和最佳实践 |

## 3. 主机编排：`flake.nix` 中的 `hostDefs`
```nix
hostDefs = {
  wsl = {
    enable = true;
    systemModules = [ nixos-wsl ... ./modules/system/vscode-remote.nix ];
    homeModules = {
      nixos = [ ./home/home.nix ./home/vscode ];
    };
  };
  devbox = {
    enable = false; # 作为模板存在，需要时再打开
    ...
  };
};
```
- **systemModules**：硬件/虚拟化相关、需要 root 权限的配置。
- **homeModules**：需要 Home Manager 托管的用户配置，值是一个列表（模块顺序等于叠加顺序）。
- **pkgsUnstable** 自动注入 `specialArgs`，只要模块声明 `pkgsUnstable` 就能取用。
- **延展方式**：新增主机时只需：
  1. 在 `hosts/<name>.nix` 写主机特有设置（例如 Docker、硬件驱动、代理）；
  2. 把主机添加进 `hostDefs`，挑选 System/Home 模块组合并将 `enable = true`；
  3. 运行 `sudo nixos-rebuild switch --flake .#<name>` 或 `nixos-rebuild test` 先验证。

## 4. Home Manager 角色划分
- `home/home.nix` 只负责“任何地方都需要”的 CLI 体验：常用包、Git/SSH、Direnv、自动生成 ssh key。
- VS Code：
  - **Remote/WSL**：`./home/vscode`（链接 `.vscode-server`、锁定扩展版本、同步 `settings.json`）。
  - **GUI**：`modules/vscode/gui.nix`（通过 `vscode-with-extensions` 打包 + 设置）。
- 如果以后需要针对某主机加包，只需在该主机的 `homeModules.<user>` 列表里追加模块即可（例如 `./home/profiles/java.nix`）。

## 5. Git / SSH 统一策略
- **应该统一的部分**：用户签名、`sshCommand`, `AddressFamily`, `url.*.insteadOf` 这类“安全/网络策略”。
- **可按主机拆分**：`extraConfig` 支持在 Home Manager 模块里使用 `lib.mkIf` 搭配环境变量或 `config.networking.hostName`，只在特定主机添加 pushurl / proxy。
- 推送到多个 remote（`pushurl`）通常只有在“同一仓库需要同步到不同托管”时才需要；建议在仓库级别通过 `.git/config` 管理，不要在全局 Git 配置里设置，以免误推。

## 6. Direnv、devenv、nix develop 究竟何时用？
- **Direnv + nix-direnv**（已经启用）：适合语言无关、需要频繁切换 repo 的个人开发者。进入目录即自动加载 `flake.nix` 或 `shell.nix` 提供的环境，退出目录自动卸载。
- **`nix develop` / `devshell`**：当某个项目需要大量特定工具链（Go, Rust nightly, CUDA 等）时再引入。建议：
  1. 项目根写 `flake.nix` + `devShells.<system>.default`；
  2. 在 repo `.envrc` 写 `use flake`; Direnv 自动触发。
- **不要滥用**：把所有 CLI 工具塞到 devshell 只会拖慢进入目录的时间。简单命令直接 `home.packages` 即可。

## 7. VS Code 配置复用技巧
- 所有扩展集中在 `modules/vscode/base.nix`，GUI/Remote 都复用同一个 `settings.nix`。
- Remote 侧（WSL/服务器）使用 `home/vscode/default.nix` 创建符号链接 + `extensions.json`，防止 VS Code 自动升级导致 hash 失效。
- GUI 侧通过 `modules/vscode/gui.nix` 直接封装 `vscode-with-extensions`，保证每次重建后本地也一致。

## 8. Nix 语法 & 函数式思维速成
- **Attribute Set**：`{ a = 1; b = 2; }`，通过 `foo.bar or default` 取值并附带默认值。
- **函数**：`{ pkgs, ... }: { ... }` 其实是“接受一个 attrset，返回另一个 attrset”。模块系统会把所有结果按 key 合并。
- **`lib` 的常用函数**：
  - `lib.mapAttrs (name: value: ...) attrs` 在 `flake.nix` 里把 `hostDefs` 映射成 `nixosConfigurations`。
  - `lib.optionals cond list` 根据条件决定是否追加模块。
  - `lib.mkDefault` / `mkForce` 控制优先级，适合在主机模块里覆写 shared 配置。
- **`specialArgs`**：提供额外参数（如 `pkgsUnstable`）给模块环境，无需层层传递。
- **`lib.mkMerge`**：把多段配置合并成一个 attrset，VS Code Remote 模块就是靠它把若干 `home.file` 片段拼成最终结果。

## 9. 日常维护流程
1. **检查**：`nix flake check`（会触发 statix + deadnix）。
2. **NixOS 主机**：`sudo nixos-rebuild switch --flake .#wsl` / `.#devbox`，或 `test` 先验证。
3. **纯 Home Manager**：`home-manager switch --flake .#empathy@leny`。
4. **更新依赖**：`nix flake update`，然后重新 `nix flake check` 并测试一台机器再推广。
5. **诊断**：利用 `nix repl` 或 `nix eval .#nixosConfigurations.wsl.config.system.build.toplevel` 查看实际生成的 derivation。

## 10. 需要特别小心的点
- **不要在 core 模块里放 host-specific 设置**，否则每台机器都会继承，后续拆分麻烦。
- **慎用 `pkgsUnstable`**：最好只在具体模块里显式引用，方便未来审计哪些软件来自不稳定通道。
- **密钥/证书**：`modules/home/ssh-key.nix` 会自动生成 key，不要把私钥写进 repo。若要分发公钥，请创建 `secrets/`（git-ignored）并在模块读取。
- **服务端口**：远程 VS Code 会打开 9816/9000 等端口，部署在公网服务器时请确认防火墙策略。
- **WSL 细节**：`nixos-wsl` 模块会自动处理 systemd/user，升级后若遇到 Windows 挂载问题，优先检查该模块 release notes。

## 11. 什么时候不要“统一配置”
- 那些**和硬件强绑定**的配置（显卡驱动、触摸板、USB 规则）应该放在专用主机模块里。
- **一次性实验**：直接在 shell 里运行 `nix shell nixpkgs#<pkg>` 更快，不需要写入 flake。
- **项目特定 Git 行为**：例如某仓库要推送到双 remote，把配置写进该仓库 `.git/config`，而不是全局 `programs.git.extraConfig`。

## 12. 下一步可以扩展什么？
1. 新建 `modules/home/<lang>.nix`（如 `rust.nix`, `python.nix`），按需添加到各主机 `homeModules`。
2. 引入 `devenv`/`devshell` 管理复杂语言栈，再透过 Direnv 自动加载。
3. 如果要管理 Secrets，可考虑引入 `sops-nix` 或 `agenix`，并从 `hostDefs` 的 `systemModules` 里启用。

拥抱函数式配置的关键是“描述事实，而不是命令步骤”。沿着这份架构，你可以在不牺牲灵活性的前提下，持续地扩展多主机场景。
