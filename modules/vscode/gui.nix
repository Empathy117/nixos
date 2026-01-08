{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  sharedSettings = config.shared.vscode.userSettings;
  sharedExtensions = config.shared.vscode.extensions;
  hasVscodeProfiles = lib.hasAttrByPath [
    "programs"
    "vscode"
    "profiles"
  ] options;
in
{
  imports = [
    ./base.nix
  ];

  config = lib.mkMerge [
    {
      programs.vscode = {
        enable = true;
        package =
          (pkgs.vscode-with-extensions.override {
            vscodeExtensions = sharedExtensions;
          }).overrideAttrs
            (_: {
              pname = "vscode";
              inherit (pkgs.vscode) version;
            });
      };
    }

    (lib.mkIf hasVscodeProfiles {
      programs.vscode.profiles.default.userSettings = sharedSettings;
    })

    (lib.mkIf (!hasVscodeProfiles) {
      programs.vscode.userSettings = sharedSettings;
    })
  ];
}
