# 项目开发环境模板
# 用法：复制此文件到你的项目根目录，重命名为 flake.nix
{
  description = "Java 8 + Spring Boot + React TypeScript 开发环境";

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
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # Java 开发环境
              temurin-bin-8

              # Maven 或 Gradle（根据需要选择）
              maven

              # Node.js 开发环境
              nodejs_22
              pnpm
            ];

            shellHook = ''
              echo "======================================"
              echo "开发环境已激活！"
              echo "Java: $(java -version 2>&1 | head -1)"
              echo "Node: $(node --version)"
              echo "pnpm: $(pnpm --version)"
              echo "======================================"

              export JAVA_HOME="${pkgs.temurin-bin-8}"
              export PNPM_HOME="$PWD/.pnpm-store"
            '';

            JAVA_HOME = "${pkgs.temurin-bin-8}";
          };
        }
      );
    };
}
