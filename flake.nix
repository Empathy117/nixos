# flake.nix
{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
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

  outputs = {
    nixpkgs,
    home-manager,
    nixos-wsl,
    nixos-vscode-server,
    nixpkgs-unstable,
    ...
  }: let
    system = "x86_64-linux";
    pkgsStable = import nixpkgs {inherit system;};
    pkgsUnstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    # WSL: NixOS 集成 Home Manager
    nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {inherit pkgsUnstable;};

      modules = [
        nixos-wsl.nixosModules.default
        ./hosts/wsl.nix
        nixos-vscode-server.nixosModules.default
        ./common/common.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {inherit pkgsUnstable;};

          home-manager.users.nixos = {
            imports = [
              ./home/home.nix
            ];
          };
        }
      ];
    };

    # 纯 Home Manager 配置
    homeConfigurations."empathy@leny" = home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsStable;

      extraSecialArgs = {inherit pkgsUnstable;};

      # 直接复用同一个 home.nix
      modules = [
        ./home/home.nix
        ./common/common.nix
      ];
    };
  };
}
