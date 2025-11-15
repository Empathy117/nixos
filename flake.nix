# flake.nix
{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixvim = {
      url = "github:nix-community/nixvim";
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
            nixos = [
              nixvim.homeManagerModules.default
              ./home/home.nix
              ./home/vscode
            ];
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
            empathy = [
              nixvim.homeManagerModules.default
              ./home/home.nix
              ./home/vscode
            ];
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

      checks.${defaultSystem} = {
        statix = mkCheck "statix-check" [ pkgsDefault.statix ] "statix check ${repoSrc}";
        deadnix = mkCheck "deadnix-check" [ pkgsDefault.deadnix ] "deadnix --fail ${repoSrc}";
      };
    };
}
