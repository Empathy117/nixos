{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkMerge;
  sharedSettings = config.shared.vscode.userSettings;
  sharedExtensions = config.shared.vscode.extensions;

  json = value: builtins.toJSON value + "\n";
in
{
  programs.vscode = {
    enable = true;
    package =
      (pkgs.vscode-with-extensions.override {
        vscodeExtensions = sharedExtensions;
      }).overrideAttrs
        (_: {
          pname = "vscode";
          version = pkgs.vscode.version;
        });
    userSettings = sharedSettings;
  };
}
