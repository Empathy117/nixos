{
  config,
  lib,
  options,
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
      programs.vscode.enable = true;
    }

    (lib.mkIf hasVscodeProfiles {
      programs.vscode.profiles.default = {
        userSettings = sharedSettings;
        extensions = sharedExtensions;
      };
    })

    (lib.mkIf (!hasVscodeProfiles) {
      programs.vscode = {
        userSettings = sharedSettings;
        extensions = sharedExtensions;
      };
    })
  ];
}
