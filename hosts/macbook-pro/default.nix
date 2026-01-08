# hosts/macbook-pro/default.nix
{
  pkgs,
  lib,
  self,
  ...
}:
let
  mkZipApp =
    {
      pname,
      version,
      url,
      hash,
      appName,
      binLinks ? [ ],
    }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname version;

      src = pkgs.fetchurl {
        inherit url hash;
      };

      nativeBuildInputs = [
        pkgs.unzip
      ];

      unpackPhase = ''
        runHook preUnpack
        unzip -qq "$src"
        runHook postUnpack
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p "$out/Applications"

        app=$(find . -maxdepth 3 -name "${appName}" -print -quit)
        if [ -z "$app" ]; then
          echo "Expected ${appName}, but it was not found in the zip."
          find . -maxdepth 3 -name '*.app' -print
          exit 1
        fi

        cp -R "$app" "$out/Applications/${appName}"

        mkdir -p "$out/bin"
        ${lib.concatMapStringsSep "\n" (
          link:
          ''
            target="$out/Applications/${appName}/${link.path}"
            if [ ! -e "$target" ]; then
              echo "Expected ${link.name} target at $target, but it was not found."
              exit 1
            fi
            ln -s "$target" "$out/bin/${link.name}"
          ''
        ) binLinks}
        runHook postInstall
      '';

      dontFixup = true;
      meta.platforms = lib.platforms.darwin;
    };

  mkDmgApp =
    {
      pname,
      version,
      src ? null,
      url ? null,
      hash ? null,
      appName,
    }:
    assert (src != null) || ((url != null) && (hash != null));
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname version;

      src =
        if src != null then
          src
        else
          pkgs.fetchurl {
            inherit url hash;
          };

      nativeBuildInputs = [
        pkgs.undmg
      ];

      unpackPhase = ''
        runHook preUnpack
        if ! undmg "$src"; then
          echo "undmg failed; falling back to hdiutil (APFS DMG?)"

          (
            set -euo pipefail
            mnt=$(TMPDIR=/tmp mktemp -d -t nix-XXXXXXXXXX)
            finish() {
              /usr/bin/hdiutil detach "$mnt" -force >/dev/null 2>&1 || true
              rm -rf "$mnt"
            }
            trap finish EXIT

            /usr/bin/hdiutil attach -nobrowse -readonly -mountpoint "$mnt" "$src" >/dev/null

            app=$(find "$mnt" -maxdepth 3 -name "${appName}" -print -quit)
            if [ -z "$app" ]; then
              echo "Expected ${appName}, but it was not found in the dmg."
              find "$mnt" -maxdepth 3 -name '*.app' -print
              exit 1
            fi

            cp -a "$app" .
          )
        fi
        runHook postUnpack
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p "$out/Applications"

        app=$(find . -maxdepth 3 -name "${appName}" -print -quit)
        if [ -z "$app" ]; then
          echo "Expected ${appName}, but it was not found in the dmg."
          find . -maxdepth 3 -name '*.app' -print
          exit 1
        fi

        cp -R "$app" "$out/Applications/${appName}"
        runHook postInstall
      '';

      dontFixup = true;
      meta.platforms = lib.platforms.darwin;
    };

  keepingYouAwake = mkZipApp {
    pname = "keepingyouawake";
    version = "1.6.8";
    url = "https://github.com/newmarcel/KeepingYouAwake/releases/download/1.6.8/KeepingYouAwake-1.6.8.zip";
    hash = "sha256-gAGhSbRJDACP2sGYmLzpkC1RbEqmQSp+sPmjdEOxXGs=";
    appName = "KeepingYouAwake.app";
  };

  sublimeText = mkZipApp {
    pname = "sublime-text";
    version = "4200";
    url = "https://download.sublimetext.com/sublime_text_build_4200_mac.zip";
    hash = "sha256-SDXrKl0/KyI86TonFJ82DvFYr5+N1wi29QHXCMCB0xk=";
    appName = "Sublime Text.app";
    binLinks = [
      {
        name = "subl";
        path = "Contents/SharedSupport/bin/subl";
      }
    ];
  };

  clashVergeRev = mkDmgApp {
    pname = "clash-verge-rev";
    version = "2.4.4";
    url = "https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.4.4/Clash.Verge_2.4.4_aarch64.dmg";
    hash = "sha256-F1h/SuVl+KQAf2mqkfFtkOVNjioG/xgHQhPJ/RdXIh8=";
    appName = "Clash Verge.app";
  };

  baiduNetdisk = mkDmgApp {
    pname = "baidunetdisk";
    version = "8.1.7";
    url = "https://pkg-ant.baidu.com/issue/netdisk/MACguanjia/8.1.7/BaiduNetdisk_mac_8.1.7_arm64.dmg";
    hash = "sha256-E8U2CVV0A5I2shPU/PbwZY+HLe8xf6o4fpGv1EBhCi0=";
    appName = "BaiduNetdisk_mac.app";
  };

  infuse = mkDmgApp {
    pname = "infuse";
    version = "8.3.4";
    url = "file:///Users/empathy/Library/Mobile%20Documents/com~apple~CloudDocs/dmg/Infuse.dmg";
    hash = "sha256-FNQJ27O2c62w9yMx931qPwtmpSBESDRAEZ6b6mrn9EU=";
    appName = "Infuse.app";
  };

  optionalOn = pkg: lib.optional (lib.meta.availableOn pkgs.stdenv.hostPlatform pkg) pkg;
  nixpkgsGuiApps = [
    pkgs."ghostty-bin"
    pkgs.telegram-desktop
    pkgs.obsidian
    pkgs.raycast
    pkgs.iina
    pkgs.chatgpt
  ];
  customGuiApps = [
    keepingYouAwake
    sublimeText
    clashVergeRev
    baiduNetdisk
    infuse
  ];
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
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.empathy = import ../../home/profiles/darwin-cli.nix;
  };

  environment.systemPackages =
    [
      pkgs.vim
    ]
    ++ lib.optional (pkgs ? codex) pkgs.codex
    ++ lib.concatMap optionalOn nixpkgsGuiApps
    ++ customGuiApps;

  # Determinate Systems 已经管理 Nix 安装与 daemon；这里避免 nix-darwin 介入。
  nix.enable = false;

  users.users.empathy = {
    name = "empathy";
    home = "/Users/empathy";
    shell = pkgs.fish;
  };
  system.primaryUser = "empathy";

  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;

    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "clmv";

    screensaver.askForPasswordDelay = 10;
  };

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 6;
  nixpkgs.hostPlatform = "aarch64-darwin";

  security.pam.services.sudo_local.touchIdAuth = true;
}
