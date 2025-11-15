# flake.nix
{
  description = "模块化的 NixOS + Home Manager 配置，支持多主机管理";

  inputs = {
    # 稳定版 nixpkgs - 系统默认使用
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    
    # 不稳定版 nixpkgs - 仅用于需要最新特性的包
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Neovim 配置框架
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    
    # Home Manager - 用户环境管理
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # VS Code Server 支持
    nixos-vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # WSL 支持
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      nixvim,
      nixos-wsl,
      nixos-vscode-server,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      defaultSystem = "x86_64-linux";

      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      mkPkgsUnstable =
        system:
        import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };

      pkgsDefault = mkPkgs defaultSystem;
      pkgsUnstableDefault = mkPkgsUnstable defaultSystem;

      repoSrc = lib.cleanSource ./.;
      mkCheck =
        name: toolInputs: command:
        pkgsDefault.runCommand name { buildInputs = toolInputs; } ''
          ${command}
          touch $out
        '';

      # 主机定义 - 数据驱动的配置方式
      # 每个主机定义包含：
      # - enable: 是否启用该配置
      # - system: 系统架构
      # - systemModules: NixOS 系统级模块列表
      # - homeModules: Home Manager 用户级模块（按用户名分组）
      hostDefs = {
        # WSL2 环境配置
        wsl = {
          enable = true;
          system = "x86_64-linux";
          systemModules = [
            nixos-wsl.nixosModules.default
            ./hosts/wsl/wsl.nix
            nixos-vscode-server.nixosModules.default
            ./modules/system/vscode-remote.nix
          ];
          homeModules = {
            nixos = [
              nixvim.homeManagerModules.default
              ./home/home.nix
              ./home/vscode
            ];
          };
        };

        # 开发服务器基线配置（作为模板）
        devbox = {
          enable = false; # 设为 true 以启用
          system = "x86_64-linux";
          systemModules = [
            ./hosts/devbox.nix
            nixos-vscode-server.nixosModules.default
            ./modules/system/vscode-remote.nix
          ];
          homeModules = {
            empathy = [
              nixvim.homeManagerModules.default
              ./home/home.nix
              ./home/vscode
            ];
          };
        };

        # Lenovo 笔记本配置（继承 devbox 基线 + 特定硬件配置）
        lenovo = {
          enable = true;
          system = "x86_64-linux";
          systemModules = [
            ./hosts/devbox.nix # 基线配置
            ./hosts/lenovo/lenovo.nix # 硬件特定配置
            nixos-vscode-server.nixosModules.default
            ./modules/system/vscode-remote.nix
          ];
          homeModules = {
            empathy = [
              nixvim.homeManagerModules.default
              ./home/home.nix
              ./home/vscode
            ];
          };
        };
      };

      mkNixosHost =
        name: cfg:
        let
          system = cfg.system or defaultSystem;
          pkgsUnstable = mkPkgsUnstable system;
          homeModules = cfg.homeModules or { };
        in
        lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit pkgsUnstable;
          }
          // (cfg.specialArgs or { });
          modules = [
            ./modules/system/core.nix
            (_: {
              networking.hostName = lib.mkDefault name;
            })
          ]
          ++ (cfg.systemModules or [ ])
          ++ lib.optionals (homeModules != { }) [
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit pkgsUnstable; };
                users = lib.mapAttrs (_: modules: { imports = modules; }) homeModules;
              };
            }
          ];
        };
      activeHosts = lib.filterAttrs (_: cfg: cfg.enable or true) hostDefs;
    in
    {
      nixosConfigurations = lib.mapAttrs mkNixosHost activeHosts;

      homeConfigurations."empathy@leny" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsDefault;
        extraSpecialArgs = {
          pkgsUnstable = pkgsUnstableDefault;
        };
        modules = [
          (_: {
            nixpkgs.config.allowUnfree = true;
          })
          nixvim.homeManagerModules.default
          ./home/home.nix
          ./modules/vscode/gui.nix
        ];
      };

      # 代码质量检查
      checks.${defaultSystem} = {
        statix = mkCheck "statix-check" [ pkgsDefault.statix ] "statix check ${repoSrc}";
        deadnix = mkCheck "deadnix-check" [ pkgsDefault.deadnix ] "deadnix --fail ${repoSrc}";
      };

      # 开发环境
      devShells.${defaultSystem} = {
        # 默认开发环境 - 用于维护此配置仓库
        default = pkgsDefault.mkShell {
          name = "nixos-config-dev";
          
          buildInputs = with pkgsDefault; [
            # Nix 工具
            nixfmt-rfc-style # Nix 代码格式化
            statix # 静态分析
            deadnix # 死代码检测
            nil # Nix LSP
            
            # 版本控制
            git
            
            # 文档工具
            mdbook # 如果需要构建文档
          ];
          
          shellHook = ''
            echo "🚀 NixOS 配置开发环境"
            echo ""
            echo "可用命令："
            echo "  nixfmt <file>     - 格式化 Nix 文件"
            echo "  statix check .    - 运行静态分析"
            echo "  deadnix .         - 检测未使用的代码"
            echo "  nix flake check   - 运行所有检查"
            echo ""
          '';
        };
      };

      # 格式化器配置
      formatter.${defaultSystem} = pkgsDefault.nixfmt-rfc-style;
    };
}
