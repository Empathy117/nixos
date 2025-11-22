# Node.js 开发环境模块
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.nodejs;
in
{
  imports = [
    ./packages.nix # 自动导入包配置
  ];
  options.programs.nodejs = {
    enable = lib.mkEnableOption "Node.js development environment";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nodejs;
      description = "Node.js package to use";
    };

    packageManager = lib.mkOption {
      type = lib.types.enum [
        "npm"
        "pnpm"
        "yarn"
        "bun"
      ];
      default = "pnpm";
      description = "Package manager to use";
    };

    globalPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Packages to install using npx/pnpx wrappers (on-demand)";
    };

    installedPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Packages to actually install globally (faster but takes space)";
    };

    enableCorepack = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable corepack for package manager version management";
    };
  };

  # 默认配置（可以在 home.nix 或其他地方覆盖）
  config = lib.mkMerge [
    # 默认启用 Node.js 环境
    {
      programs.nodejs = {
        enable = lib.mkDefault true;
        packageManager = lib.mkDefault "pnpm";
        globalPackages = lib.mkDefault [ ];
        installedPackages = lib.mkDefault [ ];
      };
    }

    # 实际实现
    (lib.mkIf cfg.enable (
      let
        # 根据包管理器选择执行器
        packageManagerBin =
          {
            npm = "${cfg.package}/bin/npx";
            pnpm = "${pkgs.nodePackages.pnpm}/bin/pnpx";
            yarn = "${pkgs.yarn}/bin/yarn dlx";
            bun = "${pkgs.bun}/bin/bunx";
          }
          .${cfg.packageManager};
      in
      {
        home.packages = [
          cfg.package
        ]
        ++ lib.optional (cfg.packageManager == "pnpm") pkgs.nodePackages.pnpm
        ++ lib.optional (cfg.packageManager == "yarn") pkgs.yarn
        ++ lib.optional (cfg.packageManager == "bun") pkgs.bun
        # 按需包：使用 npx/pnpx 包装器
        ++ (map (
          pkg:
          pkgs.writeShellScriptBin pkg ''
            exec ${packageManagerBin} ${pkg} "$@"
          ''
        ) cfg.globalPackages)
        # 真正安装的包：从 nixpkgs 获取或构建
        ++ (map (
          pkg:
          if pkgs.nodePackages ? ${pkg} then
            pkgs.nodePackages.${pkg}
          else
            # 如果 nixpkgs 里没有，创建一个简单的全局安装
            pkgs.runCommand "npm-${pkg}" { buildInputs = [ cfg.package ]; } ''
              mkdir -p $out
              export HOME=$TMPDIR
              ${packageManagerBin} install -g --prefix $out ${pkg}
            ''
        ) cfg.installedPackages);

        home.sessionVariables = {
          # npm 全局安装路径
          NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
          # pnpm 配置
          PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
        };

        home.sessionPath = [
          "${config.home.homeDirectory}/.npm-global/bin"
          "${config.home.homeDirectory}/.local/share/pnpm"
        ];

        # npm 配置
        home.file.".npmrc".text = lib.mkIf (cfg.packageManager == "npm") ''
          prefix=${config.home.homeDirectory}/.npm-global
        '';

        # pnpm 配置
        home.file.".config/pnpm/rc".text = lib.mkIf (cfg.packageManager == "pnpm") ''
          store-dir=${config.home.homeDirectory}/.local/share/pnpm/store
        '';

        # 启用 corepack
        home.activation.enableCorepack = lib.mkIf cfg.enableCorepack (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            $DRY_RUN_CMD ${cfg.package}/bin/corepack enable
          ''
        );
      }
    ))
  ];
}
