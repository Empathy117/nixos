# flake.nix
{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-25.11";
    };
    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    nur = {
      url = "github:nix-community/NUR";
    };

    # macOS (nix-darwin)
    nix-darwin = {
      url = "tarball+https://github.com/nix-darwin/nix-darwin/archive/9f48ffaca1f44b3e590976b4da8666a9e86e6eb1.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager-unstable = {
      url = "tarball+https://github.com/nix-community/home-manager/archive/92394f9deafa80b9de95d7e0f10de78d39ff0564.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, nixpkgs, nixpkgs-unstable, nur, nix-darwin, home-manager, home-manager-unstable, nixvim, nixos-wsl, nixos-vscode-server, ... }:
    let
      inherit (nixpkgs) lib;
      defaultSystem = "x86_64-linux";
      overlays = [ nur.overlays.default ];

      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          inherit overlays;
        };
      mkPkgsUnstable =
        system:
        import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
          inherit overlays;
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

      homeBaseModules = [
        nixvim.homeModules.default
        ./home/home.nix
        ./modules/vscode/remote.nix
      ];

      hostDefs = {
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
            nixos = homeBaseModules;
          };
        };

        devbox = {
          enable = false;
          system = "x86_64-linux";
          systemModules = [
            ./hosts/devbox.nix
            nixos-vscode-server.nixosModules.default
            ./modules/system/vscode-remote.nix
          ];
          homeModules = {
            empathy = homeBaseModules;
          };
        };

        lenovo = {
          enable = true;
          system = "x86_64-linux";
          systemModules = [
            ./hosts/devbox.nix
            ./hosts/lenovo/lenovo.nix # 叠加该主机特有配置
            nixos-vscode-server.nixosModules.default
            ./modules/system/vscode-remote.nix
            ./modules/system/git-users.nix
          ];
          homeModules = {
            empathy = homeBaseModules;
          };
        };

      };

      mkNixosHost =
        name: cfg:
        let
          system = cfg.system or defaultSystem;
          pkgs = mkPkgs system;
          pkgsUnstable = mkPkgsUnstable system;
          homeModules = cfg.homeModules or { };
        in
        lib.nixosSystem {
          inherit system pkgs;
          specialArgs = {
            inherit pkgsUnstable;
          }
          // (cfg.specialArgs or { });
          modules =
            [
              ./modules/system/core.nix
              ./modules/system/docker.nix
              ./modules/system/yoohoo-services.nix
              ./modules/system/yoohoo-deploy.nix
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

      darwinConfigurations."MacBook-Pro" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";

        specialArgs = {
          inherit self;
        };

        modules = [
          home-manager-unstable.darwinModules.home-manager
          (_: {
            nixpkgs = {
              config.allowUnfree = true;
              inherit overlays;
            };
          })
          ./hosts/macbook-pro.nix
        ];
      };

      homeConfigurations."empathy@leny" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsDefault;
        extraSpecialArgs = {
          pkgsUnstable = pkgsUnstableDefault;
        };
        modules = [
          (_: {
            nixpkgs.config.allowUnfree = true;
          })
          nixvim.homeModules.default
          ./home/home.nix
          ./modules/vscode/gui.nix
        ];
      };

      checks.${defaultSystem} = {
        statix = mkCheck "statix-check" [ pkgsDefault.statix ] "statix check ${repoSrc}";
        deadnix = mkCheck "deadnix-check" [ pkgsDefault.deadnix ] "deadnix --fail ${repoSrc}";
      };
    };
}
