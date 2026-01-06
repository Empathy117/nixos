# flake.nix
{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    # macOS 跟随 unstable 更贴近最新 Darwin 兼容性；用 tarball 避免 GitHub API rate limit
    nixpkgs-unstable.url = "tarball+https://github.com/NixOS/nixpkgs/archive/refs/heads/nixpkgs-unstable.tar.gz";
    nix-darwin = {
      # macOS 使用 nixpkgs-unstable 对应 nix-darwin master；用 tarball 避免 GitHub API rate limit
      url = "tarball+https://github.com/nix-darwin/nix-darwin/archive/refs/heads/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
    };
  };

  outputs =
    {
      nixpkgs,
      nix-darwin,
      home-manager,
      nixos-wsl,
      nixos-vscode-server,
      nixpkgs-unstable,
      ...
    }:
    let
      lib = nixpkgs.lib;
      repoSrc = lib.cleanSource ./.;
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = f: lib.genAttrs systems (system: f system);
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
      mkCheck =
        pkgs: name: toolInputs: command:
        pkgs.runCommand name { buildInputs = toolInputs; } ''
          ${command}
          touch $out
        '';
    in
    {
      # WSL: NixOS 集成 Home Manager
      nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {
          pkgsUnstable = mkPkgsUnstable "x86_64-linux";
        };

        modules = [
          nixos-wsl.nixosModules.default
          nixos-vscode-server.nixosModules.default
          ./common/common.nix
          ./hosts/wsl.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              pkgsUnstable = mkPkgsUnstable "x86_64-linux";
            };
          }
        ];
      };

      # 纯 Home Manager 配置
      homeConfigurations."empathy@leny" = home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs "x86_64-linux";

        extraSpecialArgs = {
          pkgsUnstable = mkPkgsUnstable "x86_64-linux";
        };

        # 直接复用同一个 Home profile（不包含系统级配置）
        modules = [
          ./home/profiles/gui.nix
          {
            home.username = "empathy";
            home.homeDirectory = "/home/empathy";
          }
        ];
      };

      # macOS: nix-darwin + Home Manager
      darwinConfigurations."MacBook-Pro" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";

        specialArgs = {
          pkgsUnstable = mkPkgsUnstable "aarch64-darwin";
        };

        modules = [
          ./common/common.nix
          ./hosts/macbook-pro.nix

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              pkgsUnstable = mkPkgsUnstable "aarch64-darwin";
            };
          }
        ];
      };

      checks = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        {
          statix = mkCheck pkgs "statix-check" [ pkgs.statix ] "statix check ${repoSrc}";
          deadnix = mkCheck pkgs "deadnix-check" [ pkgs.deadnix ] "deadnix --fail ${repoSrc}";
        }
      );
    };
}
