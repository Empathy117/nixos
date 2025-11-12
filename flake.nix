# ~/my-nixos-config/flake.nix

{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixos-wsl, ... }: {
    # ① WSL: NixOS 集成 Home Manager
    nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixos-wsl.nixosModules.default
        ./hosts/wsl.nix            # ← 在这里“局部启用” HM 集成
        ./common/common.nix
        home-manager.nixosModules.home-manager
      ];
    };

    # ② 物理机（或其他非 NixOS 场景）: 独立 Home Manager
    homeConfigurations."empathy@leny" =
      home-manager.lib.homeManagerConfiguration {
        # 目标平台：按实际改（x86_64-linux / aarch64-linux / aarch64-darwin）
        pkgs = import nixpkgs { system = "x86_64-linux"; };

        # 直接复用同一个 home.nix
        modules = [ ./home/home.nix ];

        # 可选：指定 username/home 路径（默认从环境推断）
        # extraSpecialArgs = { };
      };
  };
}
