{
  pkgs,
  lib,
  mkZipApp,
  mkDmgApp,
}:
let
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

  nixpkgsApps = lib.concatMap optionalOn [
    pkgs."ghostty-bin"
    pkgs.telegram-desktop
    pkgs.obsidian
    pkgs.vscode
    pkgs.raycast
    pkgs.iina
    pkgs.chatgpt
  ];

  customApps = [
    keepingYouAwake
    sublimeText
    clashVergeRev
    baiduNetdisk
    infuse
  ];
in
{
  nixpkgs = nixpkgsApps;
  custom = customApps;
  all = nixpkgsApps ++ customApps;
}
