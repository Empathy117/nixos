# NixOS 配置仓库

> 一个模块化、可扩展的 NixOS + Home Manager 配置，支持多主机管理

## 🚀 快速开始

### 首次部署

```bash
# 克隆仓库
git clone <your-repo-url>
cd nixos

# NixOS 系统部署
sudo nixos-rebuild switch --flake .#<hostname>

# 纯 Home Manager 部署（非 NixOS 系统）
home-manager switch --flake .#<user>@<host>
```

### 可用主机配置

- `wsl` - WSL2 环境配置（已启用）
- `lenovo` - Lenovo 笔记本配置（已启用）
- `devbox` - 开发服务器基线配置（模板）

### 可用 Home Manager 配置

- `empathy@leny` - 独立的 Home Manager 配置（用于非 NixOS 系统）

## 📁 目录结构

```
.
├── flake.nix              # Flake 入口，定义所有配置
├── flake.lock             # 锁定依赖版本
├── hosts/                 # 主机特定配置
│   ├── devbox.nix        # 开发服务器基线
│   ├── lenovo/           # Lenovo 笔记本
│   └── wsl/              # WSL2 配置
├── modules/              # 可复用模块
│   ├── home/            # Home Manager 模块
│   ├── system/          # NixOS 系统模块
│   └── vscode/          # VS Code 配置模块
├── home/                # Home Manager 配置入口
│   ├── home.nix         # 通用用户配置
│   └── vscode/          # VS Code Remote 配置
├── scripts/             # 辅助脚本
└── docs/                # 文档
    └── guide.md         # 详细使用指南
```

## 🔧 日常维护

### 更新系统

```bash
# 更新 flake 输入
nix flake update

# 检查配置
nix flake check

# 应用更新（NixOS）
sudo nixos-rebuild switch --flake .#<hostname>

# 应用更新（Home Manager）
home-manager switch --flake .#<user>@<host>
```

### 测试配置

```bash
# 测试配置（不切换）
sudo nixos-rebuild test --flake .#<hostname>

# 构建但不激活
sudo nixos-rebuild build --flake .#<hostname>
```

### 代码质量检查

```bash
# 运行所有检查
nix flake check

# 单独运行 statix（静态分析）
nix run nixpkgs#statix check .

# 单独运行 deadnix（死代码检测）
nix run nixpkgs#deadnix .
```

## 🎯 设计理念

### 模块化分层

- **系统层** (`modules/system/`): 需要 root 权限的系统级配置
- **用户层** (`modules/home/`): 用户空间的配置和软件包
- **主机层** (`hosts/`): 特定主机的硬件和服务配置

### 数据驱动

通过 `flake.nix` 中的 `hostDefs` 数据结构定义主机，避免重复代码：

```nix
hostDefs = {
  myhost = {
    enable = true;
    system = "x86_64-linux";
    systemModules = [ ./hosts/myhost.nix ];
    homeModules = {
      myuser = [ ./home/home.nix ];
    };
  };
};
```

### 渠道管理

- **稳定版** (`nixpkgs`): 默认使用，保证系统稳定性
- **不稳定版** (`nixpkgs-unstable`): 仅用于需要最新特性的包

## 📚 进阶主题

### 添加新主机

1. 在 `hosts/` 创建主机配置文件
2. 在 `flake.nix` 的 `hostDefs` 中添加条目
3. 设置 `enable = true`
4. 运行 `sudo nixos-rebuild switch --flake .#<hostname>`

### 添加新模块

1. 在 `modules/home/` 或 `modules/system/` 创建模块文件
2. 在相应的配置中 import 该模块
3. 使用 `options` 和 `config` 定义可配置选项

### 管理密钥

- SSH 密钥自动生成（见 `modules/home/ssh-key.nix`）
- 敏感文件已在 `.gitignore` 中排除
- 考虑使用 `sops-nix` 或 `agenix` 管理加密密钥

## 🔗 相关资源

- [NixOS 官方文档](https://nixos.org/manual/nixos/stable/)
- [Home Manager 手册](https://nix-community.github.io/home-manager/)
- [Nix Pills](https://nixos.org/guides/nix-pills/) - Nix 深入教程
- [详细使用指南](./docs/guide.md) - 本仓库的完整指南

## 📝 许可证

根据你的需求添加许可证信息。
