# 项目开发环境模板
# 用法：复制此文件到你的项目根目录，重命名为 flake.nix
{
  description = "Java 8 + Spring Boot + React TypeScript 开发环境";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Java 开发环境
            temurin-bin-8  # Eclipse Temurin JDK 8 (OpenJDK)
            # 或者使用其他 JDK 8 发行版：
            # openjdk8
            # zulu8  # Azul Zulu JDK 8

            # Maven 或 Gradle（根据需要选择）
            maven
            # gradle

            # Node.js 开发环境
            nodejs_20  # 或 nodejs_18, nodejs_22
            pnpm
            # yarn  # 如果需要

            # 常用工具
          ];

          shellHook = ''
            echo "======================================"
            echo "开发环境已激活！"
            echo "Java: $(java -version 2>&1 | head -1)"
            echo "Node: $(node --version)"
            echo "pnpm: $(pnpm --version)"
            echo "======================================"

            # 设置 JAVA_HOME
            export JAVA_HOME="${pkgs.temurin-bin-8}"

            # pnpm 配置（可选）
            export PNPM_HOME="$PWD/.pnpm-store"
          '';

          # 环境变量
          JAVA_HOME = "${pkgs.temurin-bin-8}";
        };
      }
    );
}
