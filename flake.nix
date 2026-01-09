# flake.nix
{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs = {
      # Use a branch tarball to avoid GitHub API rate limits.
      url = "tarball+https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-25.11.tar.gz";
    };
    nixpkgs-unstable = {
      # Use a branch tarball to avoid GitHub API rate limits.
      url = "tarball+https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-unstable.tar.gz";
    };
    nur = {
      url = "github:nix-community/NUR";
    };

    # macOS (nix-darwin)
    nix-darwin = {
      # Use a branch tarball to avoid GitHub API rate limits.
      url = "tarball+https://github.com/nix-darwin/nix-darwin/archive/refs/heads/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager-unstable = {
      # Use a branch tarball to avoid GitHub API rate limits.
      url = "tarball+https://github.com/nix-community/home-manager/archive/refs/heads/master.tar.gz";
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
    inputs@{ self, nixpkgs, nixpkgs-unstable, nur, nix-darwin, home-manager, home-manager-unstable, nixvim, ... }:
    let
      inherit (nixpkgs) lib;
      defaultSystem = "x86_64-linux";
      overlays = [ nur.overlays.default ];
      supportedSystems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = f: lib.genAttrs supportedSystems (system: f system);

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
            ./hosts/wsl
          ];
          homeModules = {
            nixos = homeBaseModules;
          };
        };

        devbox = {
          enable = false;
          system = "x86_64-linux";
          systemModules = [
            ./hosts/devbox
          ];
          homeModules = {
            empathy = homeBaseModules;
          };
        };

        lenovo = {
          enable = true;
          system = "x86_64-linux";
          systemModules = [
            ./hosts/lenovo # 叠加该主机特有配置
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
            inherit inputs;
            inherit pkgsUnstable;
          }
          // (cfg.specialArgs or { });
          modules =
            [
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
          ./hosts/macbook-pro
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

      checks = forAllSystems (
        system:
        let
          pkgsCheck =
            if lib.hasSuffix "darwin" system then
              mkPkgsUnstable system
            else
              mkPkgs system;

          mkCheck =
            name: toolInputs: command:
            pkgsCheck.runCommand name { buildInputs = toolInputs; } ''
              ${command}
              touch $out
            '';
        in
        {
          statix = mkCheck "statix-check" [ pkgsCheck.statix ] "statix check ${repoSrc}";
          deadnix = mkCheck "deadnix-check" [ pkgsCheck.deadnix ] "deadnix --fail ${repoSrc}";
        }
      );
    };
}
