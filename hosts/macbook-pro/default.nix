# hosts/macbook-pro/default.nix
{
  config,
  pkgs,
  lib,
  self,
  inputs,
  ...
}:
let
  appBuilders = import ../../modules/darwin/app-builders.nix { inherit pkgs lib; };
  apps = import ./apps {
    inherit pkgs lib;
    inherit (appBuilders) mkZipApp mkDmgApp;
  };
in
{
  nixpkgs.config.allowUnfree = true;

  # CLI / Shell
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];

  # Fonts (for terminal & Nerd Font icons)
  fonts.packages = [
    pkgs."nerd-fonts"."jetbrains-mono"
    pkgs."maple-mono"."NF-CN"
    pkgs."nerd-fonts"."hack"
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
    };
    users.empathy = {
      imports = [
        inputs.nixvim.homeModules.default
        ../../home/profiles/darwin-cli.nix
      ];
    };
  };

  environment.systemPackages = [
    pkgs.vim
    pkgs.sketchybar
  ]
  ++ apps.all;

  # Determinate Systems 已经管理 Nix 安装与 daemon；这里避免 nix-darwin 介入。
  nix.enable = false;

  users.users.empathy = {
    name = "empathy";
    home = "/Users/empathy";
    shell = pkgs.fish;
  };
  system.primaryUser = "empathy";

  system.keyboard = {
    enableKeyMapping = true;
    userKeyMapping = [
      {
        HIDKeyboardModifierMappingSrc = 30064771129;
        HIDKeyboardModifierMappingDst = 30064771296;
      }
      {
        HIDKeyboardModifierMappingSrc = 30064771296;
        HIDKeyboardModifierMappingDst = 30064771129;
      }
    ];
  };

  services.jankyborders = {
    enable = false;
    active_color = "0x88b7e8ff";
    inactive_color = "0x339dbfe6";
    width = 3.0;
    style = "round";
    blur_radius = 4.0;
    hidpi = true;
  };

  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = true;

    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "clmv";

    screensaver.askForPasswordDelay = 10;

    CustomUserPreferences = {
      "com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = {
          "15".enabled = 0;
          "16".enabled = 0;
          "17".enabled = 0;
          "18".enabled = 0;
          "19".enabled = 0;
          "20".enabled = 0;
          "21".enabled = 0;
          "22".enabled = 0;
          "23".enabled = 0;
          "24".enabled = 0;
          "25".enabled = 0;
          "26".enabled = 0;

          "28" = {
            enabled = 1;
            value = {
              parameters = [
                51
                20
                1441792
              ];
              type = "standard";
            };
          };
          "29" = {
            enabled = 1;
            value = {
              parameters = [
                51
                20
                1179648
              ];
              type = "standard";
            };
          };
          "30" = {
            enabled = 1;
            value = {
              parameters = [
                52
                21
                1441792
              ];
              type = "standard";
            };
          };
          "31" = {
            enabled = 1;
            value = {
              parameters = [
                52
                21
                1179648
              ];
              type = "standard";
            };
          };

          "60" = {
            enabled = 1;
            value = {
              parameters = [
                32
                49
                262144
              ];
              type = "standard";
            };
          };
          "61" = {
            enabled = 1;
            value = {
              parameters = [
                32
                49
                786432
              ];
              type = "standard";
            };
          };
          "79" = {
            enabled = 1;
            value = {
              parameters = [
                65535
                123
                8650752
              ];
              type = "standard";
            };
          };
          "80" = {
            enabled = 1;
            value = {
              parameters = [
                65535
                123
                8781824
              ];
              type = "standard";
            };
          };
          "81" = {
            enabled = 1;
            value = {
              parameters = [
                65535
                124
                8650752
              ];
              type = "standard";
            };
          };
          "82" = {
            enabled = 1;
            value = {
              parameters = [
                65535
                124
                8781824
              ];
              type = "standard";
            };
          };

          "118" = {
            enabled = 1;
            value = {
              parameters = [
                49
                18
                262144
              ];
              type = "standard";
            };
          };
          "119" = {
            enabled = 1;
            value = {
              parameters = [
                50
                19
                262144
              ];
              type = "standard";
            };
          };
          "120" = {
            enabled = 1;
            value = {
              parameters = [
                51
                20
                262144
              ];
              type = "standard";
            };
          };
          "121" = {
            enabled = 1;
            value = {
              parameters = [
                52
                21
                262144
              ];
              type = "standard";
            };
          };
          "122" = {
            enabled = 1;
            value = {
              parameters = [
                53
                23
                262144
              ];
              type = "standard";
            };
          };
          "123" = {
            enabled = 1;
            value = {
              parameters = [
                54
                22
                262144
              ];
              type = "standard";
            };
          };
          "124" = {
            enabled = 1;
            value = {
              parameters = [
                55
                26
                262144
              ];
              type = "standard";
            };
          };
          "125" = {
            enabled = 1;
            value = {
              parameters = [
                56
                28
                262144
              ];
              type = "standard";
            };
          };
          "126" = {
            enabled = 1;
            value = {
              parameters = [
                57
                25
                262144
              ];
              type = "standard";
            };
          };

          "160".enabled = 0;
          "164" = {
            enabled = 0;
            value = {
              parameters = [
                65535
                65535
                0
              ];
              type = "standard";
            };
          };
        };
      };
    };
  };

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 6;
  nixpkgs.hostPlatform = "aarch64-darwin";

  security.pam.services.sudo_local.touchIdAuth = true;
}
