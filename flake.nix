# flake.nix
{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opencode = {
      url = "github:anomalyco/opencode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    obsidian-skills = {
      url = "github:kepano/obsidian-skills";
      flake = false;
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nur,
      nix-darwin,
      home-manager,
      nixvim,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      overlays = [
        nur.overlays.default
        (final: prev: {
          direnv =
            if prev.stdenv.hostPlatform.isDarwin then
              prev.direnv.overrideAttrs (_: {
                doCheck = false;
              })
            else
              prev.direnv;
          commitizen = prev.commitizen.overridePythonAttrs (old: {
            disabledTests = (old.disabledTests or [ ]) ++ [
              "test_invalid_command"
            ];
          });
          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (python-final: python-prev: {
              python-lsp-server = python-prev.python-lsp-server.overridePythonAttrs (_: {
                doCheck = false;
              });
            })
          ];
          opencode = prev.opencode.overrideAttrs (old: {
            node_modules = old.node_modules.overrideAttrs (nmOld: {
              buildPhase = ''
                echo "registry=https://registry.npmmirror.com" > .npmrc
                ${nmOld.buildPhase}
              '';
              env = (nmOld.env or { }) // {
                NPM_CONFIG_REGISTRY = "https://registry.npmmirror.com";
                npm_config_registry = "https://registry.npmmirror.com";
                BUN_CONFIG_REGISTRY = "https://registry.npmmirror.com";
                BUN_INSTALL_REGISTRY = "https://registry.npmmirror.com";
              };
            });
          });
        })
        (final: prev: {
          yaziPlugins = prev.yaziPlugins // {
            githead = prev.yaziPlugins.mkYaziPlugin {
              pname = "githead.yazi";
              version = "2.0.2";
              src = prev.fetchFromGitHub {
                owner = "llanosrocas";
                repo = "githead.yazi";
                rev = "v2.0.2";
                hash = "sha256-c8jwfVrgQBLii4Yv3B020TdlYyt4VI70pNzqbuXyOgE=";
              };
              meta = {
                description = "Git status header for yazi";
                homepage = "https://github.com/llanosrocas/githead.yazi";
                license = prev.lib.licenses.mit;
              };
            };
          };
        })

      ];
      supportedSystems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = f: lib.genAttrs supportedSystems f;

      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          inherit overlays;
        };
      repoSrc = lib.cleanSource ./.;

      wslHomeModules = [
        nixvim.homeModules.default
        ./home/profiles/linux-cli.nix
        ./modules/vscode/remote.nix
      ];
    in
    {
      nixosConfigurations.wsl = lib.nixosSystem {
        system = "x86_64-linux";
        pkgs = mkPkgs "x86_64-linux";
        specialArgs = {
          inherit inputs;
        };
        modules = [
          home-manager.nixosModules.home-manager
          ./hosts/wsl
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = {
                inherit inputs;
              };
              users.nixos.imports = wslHomeModules;
            };
          }
        ];
      };

      darwinConfigurations."MacBook-Pro" = nix-darwin.lib.darwinSystem {
        pkgs = mkPkgs "aarch64-darwin";

        specialArgs = {
          inherit self inputs;
        };

        modules = [
          home-manager.darwinModules.home-manager
          ./hosts/macbook-pro
        ];
      };

      checks = forAllSystems (
        system:
        let
          pkgsCheck = mkPkgs system;

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
