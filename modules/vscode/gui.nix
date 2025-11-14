{
  config,
  pkgs,
  ...
}:

let
  sharedSettings = config.shared.vscode.userSettings;
  sharedExtensions = config.shared.vscode.extensions;
in
{
  imports = [
    ./base.nix
  ];

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
    userSettings = sharedSettings;
  };
}
