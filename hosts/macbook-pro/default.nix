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
  mkTccApp =
    {
      pname,
      version,
      appName,
      displayName,
      bundleId,
      binName,
      binPath,
    }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname version;

      dontUnpack = true;

      installPhase = ''
                app="$out/Applications/${appName}"
                mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources" "$out/bin"

                cp ${binPath} "$app/Contents/MacOS/${binName}"
                chmod +x "$app/Contents/MacOS/${binName}"

                cat > "$app/Contents/Info.plist" <<EOF
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
          <dict>
            <key>CFBundleDisplayName</key>
            <string>${displayName}</string>
            <key>CFBundleName</key>
            <string>${displayName}</string>
            <key>CFBundleIdentifier</key>
            <string>${bundleId}</string>
            <key>CFBundleExecutable</key>
            <string>${binName}</string>
            <key>CFBundlePackageType</key>
            <string>APPL</string>
            <key>CFBundleShortVersionString</key>
            <string>${version}</string>
            <key>CFBundleVersion</key>
            <string>${version}</string>
            <key>LSUIElement</key>
            <true/>
          </dict>
        </plist>
        EOF
                echo "APPL????" > "$app/Contents/PkgInfo"

                cat > "$out/bin/${binName}" <<EOF
        #!/bin/sh
        exec "$app/Contents/MacOS/${binName}" "\$@"
        EOF
                chmod +x "$out/bin/${binName}"
      '';

      dontFixup = true;
      meta.platforms = lib.platforms.darwin;
    };
  skhdApp = mkTccApp {
    pname = "skhd-app";
    version = pkgs.skhd.version;
    appName = "Skhd.app";
    displayName = "Skhd";
    bundleId = "com.empathy.skhd";
    binName = "skhd";
    binPath = "${pkgs.skhd}/bin/skhd";
  };
  yabaiApp = mkTccApp {
    pname = "yabai-app";
    version = pkgs.yabai.version;
    appName = "Yabai.app";
    displayName = "Yabai";
    bundleId = "com.empathy.yabai";
    binName = "yabai";
    binPath = "${pkgs.yabai}/bin/yabai";
  };
  sketchybarBundle = pkgs.stdenvNoCC.mkDerivation {
    pname = "sketchybar-config";
    version = "official";
    src = ./sketchybar;
    dontUnpack = true;
    installPhase = ''
      mkdir -p "$out/plugins"
      install -m 0644 "$src/sketchybarrc" "$out/sketchybarrc"
      install -m 0755 "$src/plugins/"*.sh "$out/plugins/"
    '';
    dontFixup = true;
  };
  sketchybarConfig = ''
    #!/usr/bin/env bash
    CONFIG_DIR="${sketchybarBundle}"
    . "${sketchybarBundle}/sketchybarrc"
  '';
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
    skhdApp
    yabaiApp
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

  services.skhd.enable = false;

  services.yabai = {
    enable = true;
    enableScriptingAddition = true;
    extraConfig = ''
      yabai -m config layout bsp
      yabai -m config window_placement second_child
      yabai -m config top_padding 10
      yabai -m config bottom_padding 10
      yabai -m config left_padding 10
      yabai -m config right_padding 10
      yabai -m config window_gap 10

      yabai -m rule --add app="^System Preferences$" manage=off
      yabai -m rule --add app="^Activity Monitor$" manage=off
      yabai -m rule --add app="^Calculator$" manage=off
      yabai -m rule --add app="^Dictionary$" manage=off
      yabai -m rule --add app="^App Store$" manage=off
      yabai -m rule --add title="Preferences" manage=off
    '';
  };

  launchd.user.agents.skhd = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.skhd}/bin/skhd"
        "-c"
        "/Users/empathy/.skhdrc"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardErrorPath = "/tmp/skhd.err.log";
      StandardOutPath = "/tmp/skhd.out.log";
      EnvironmentVariables = {
        PATH = "${pkgs.yabai}/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };
  services.sketchybar = {
    enable = false;
    config = sketchybarConfig;
    extraPackages = [
      yabaiApp
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
    dock.mru-spaces = false;

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
          "64" = {
            enabled = 0;
            value = {
              parameters = [
                65535
                49
                1048576
              ];
              type = "standard";
            };
          };
          "65" = {
            enabled = 1;
            value = {
              parameters = [
                65535
                49
                1572864
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
