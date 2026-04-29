# NixOS 开发环境工作流程指南

## Nix Way 哲学

在 NixOS 中，最佳实践是**项目隔离开发环境**，而不是全局安装开发工具：

- ❌ **不推荐**：全局安装 JDK、Node.js 到系统
- ✅ **推荐**：每个项目定义自己的开发环境
- 🌟 **最佳**：使用 direnv 自动切换环境

### 优势

1. **环境隔离**：不同项目使用不同版本的 JDK/Node.js 互不干扰
2. **可复现**：团队成员环境完全一致
3. **清洁系统**：系统不会被各种工具污染
4. **版本控制**：开发环境配置可以提交到 git

## 快速开始

### 1. 启用 direnv（已完成）

你的系统已经配置了 direnv（在 `modules/cli/modern.nix`），重建系统后即可使用：

```bash
sudo nixos-rebuild switch --flake .#wsl
```

### 2. 为你的项目创建开发环境

#### 方法一：使用 Flake（推荐）

在你的项目根目录创建 `flake.nix`：

```bash
cd /path/to/your/project
cp ~/nixos/docs/dev-env-template.nix ./flake.nix
```

然后创建 `.envrc` 文件：

```bash
echo "use flake" > .envrc
direnv allow
```

**就这么简单！**当你 `cd` 进入项目目录时，开发环境会自动激活。

#### 方法二：使用 shell.nix（传统方式）

创建 `shell.nix`：

```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
buildInputs = with pkgs; [
  temurin-bin-8
  nodejs_22
  pnpm
  maven
];

  shellHook = ''
    export JAVA_HOME="${pkgs.temurin-bin-8}"
    echo "开发环境已激活！"
  '';
}
```

使用方式：

```bash
# 手动进入环境
nix-shell

# 或使用 direnv 自动加载
echo "use nix" > .envrc
direnv allow
```

## 自定义你的开发环境

### 选择不同的 JDK 版本

```nix
buildInputs = with pkgs; [
  # OpenJDK 8
  openjdk8

  # Eclipse Temurin 8 (推荐)
  temurin-bin-8

  # Azul Zulu JDK 8
  zulu8

  # Oracle GraalVM JDK 8
  graalvm-ce
];
```

### 选择不同的 Node.js 版本

```nix
buildInputs = with pkgs; [
  nodejs_20  # 例如固定到 Node.js 20
  nodejs_22  # 或切到 Node.js 22
  nodejs     # 或直接跟随 nixpkgs 默认版本
];
```

### 添加其他工具

```nix
buildInputs = with pkgs; [
  temurin-bin-8
  nodejs_22
  pnpm

  # 构建工具
  maven
  gradle

  # 数据库客户端
  postgresql
  mysql80

  # 其他工具
  redis
  docker-compose
];
```

## 实际示例

### Spring Boot + React 全栈项目

```nix
{
  description = "我的全栈项目";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # 后端
              temurin-bin-8
              maven

              # 前端
              nodejs_22
              pnpm

              # 数据库
              postgresql_15

              # 工具
              git
              docker-compose
            ];

            shellHook = ''
              export JAVA_HOME="${pkgs.temurin-bin-8}"
              export PGDATA="$PWD/.postgres"

              if [ ! -d "$PGDATA" ]; then
                initdb -D "$PGDATA"
              fi

              echo "环境已激活！"
              echo "后端: Java $(java -version 2>&1 | head -1)"
              echo "前端: Node $(node --version), pnpm $(pnpm --version)"
              echo ""
              echo "启动 PostgreSQL: pg_ctl -D .postgres -l logfile start"
              echo "停止 PostgreSQL: pg_ctl -D .postgres stop"
            '';
          };
        }
      );
    };
}
```

## 常见问题

### Q: 我需要全局安装某些工具吗？

A: 一般不需要。只有以下情况才考虑全局安装：
- **系统工具**：如 git（虽然也可以项目级）
- **编辑器/IDE**：VSCode、IntelliJ 等
- **direnv**：用于自动切换环境

### Q: 如何在 IDE 中使用项目的 JDK？

A: 两种方式：

1. **通过 direnv**：IDE 会继承环境变量（VSCode、IntelliJ IDEA 支持）
2. **手动配置**：
   ```bash
   # 进入开发环境
   cd your-project
   # 查看 JDK 路径
   echo $JAVA_HOME
   # 在 IDE 中设置这个路径
   ```

### Q: 团队成员不用 NixOS 怎么办？

A: 他们可以：
1. 安装 Nix 包管理器（支持 Linux/macOS）
2. 使用 `nix develop` 进入开发环境
3. 享受同样的可复现环境！

### Q: 我想临时测试某个工具怎么办？

A: 使用 `nix shell`：

```bash
# 临时使用 JDK 17
nix shell nixpkgs#temurin-bin-17

# 临时使用多个工具
nix shell nixpkgs#nodejs_22 nixpkgs#yarn nixpkgs#python311
```

## 进阶：多环境管理

如果你的项目需要多个开发环境：

```nix
{
  outputs = { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = [ pkgs.temurin-bin-8 pkgs.maven ];
          };

          jdk17 = pkgs.mkShell {
            packages = [ pkgs.temurin-bin-17 pkgs.maven ];
          };

          frontend = pkgs.mkShell {
            packages = [ pkgs.nodejs_22 pkgs.pnpm ];
          };
        }
      );
    };
}
```

使用：

```bash
# 使用默认环境
nix develop

# 使用 JDK 17 环境
nix develop .#jdk17

# 使用前端环境
nix develop .#frontend
```

配合 direnv：

```bash
# .envrc
use flake .#jdk17
```

## 总结

**Nix way = 项目级环境隔离 + direnv 自动切换**

这样做的好处：
- ✅ 环境隔离，互不干扰
- ✅ 完全可复现
- ✅ 自动切换，无需手动激活
- ✅ 配置即代码，可版本控制
