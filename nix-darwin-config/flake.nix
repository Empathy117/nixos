{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, determinate }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      nixpkgs.config.allowUnfree = true;
      environment.systemPackages =
        [ pkgs.vim
          pkgs.codex
        ];

      # Necessary for using flakes on this system.(but this configured by DetSys now)
      # nix.settings.experimental-features = "nix-command flakes";
      nix.enable = false;

      users.users.empathy = {
        name = "empathy";
        home = "/Users/empathy";
      };
      system.primaryUser = "empathy";
      system.defaults = {
        # Dock 设置
        dock.autohide = true;             # 自动隐藏 Dock
        dock.mru-spaces = false;          # 禁止“根据最近使用情况自动重新排列空间” 
        
        # Finder 设置
        finder.AppleShowAllExtensions = true; # 显示所有文件扩展名
        finder.FXPreferredViewStyle = "clmv"; # 默认文件夹视图：分栏视图 (Column View)
        
        # 屏幕保护/锁屏设置
        screensaver.askForPasswordDelay = 10; # 进入屏保后多久需要密码 (10秒)
      };

      determinate-nix.customSettings = {
        # 追加 SJTU 镜像；priority=10 比 cache.nixos.org 的默认 40 更高优先级
        "extra-substituters" =
          "https://mirror.sjtu.edu.cn/nix-channels/store?priority=10";
      };

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # personal config
      security.pam.services.sudo_local.touchIdAuth = true;
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [ configuration
        determinate.darwinModules.default ];
    };
  };
}
