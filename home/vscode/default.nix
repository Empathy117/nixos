{ config, lib, pkgs, ... }:

let
  inherit (lib) mkMerge;

  vscodeSettings = import ./settings.nix;
  extensionData = import ./extensions.nix { inherit pkgs lib; };
  remoteExtensions = extensionData.extensions;

  json =
    value:
    builtins.toJSON value + "\n";

  homeDir = config.home.homeDirectory;

  extensionLinks =
    builtins.listToAttrs (
      map
        (ext: {
          name = ".vscode-server/extensions/${ext.publisher}.${ext.name}-${ext.version}";
          value = {
            force = true;
            recursive = true;
            source = "${ext.drv}/share/vscode/extensions/${ext.publisher}.${ext.name}";
          };
        })
        remoteExtensions
    );

  extensionsJson =
    json (
      map
        (ext: {
          identifier = {
            id = "${ext.publisher}.${ext.name}";
            uuid = "";
          };
          version = ext.version;
          relativeLocation = "${ext.publisher}.${ext.name}-${ext.version}";
          location = {
            "$mid" = 1;
            path = "${homeDir}/.vscode-server/extensions/${ext.publisher}.${ext.name}-${ext.version}";
            scheme = "file";
          };
          metadata = {
            source = "nix";
            publisherDisplayName = ext.publisher;
            targetPlatform = "undefined";
            pinned = true;
            updated = false;
            private = false;
            isPreReleaseVersion = false;
          };
        })
        remoteExtensions
    );
in
{
  home.file = mkMerge [
    extensionLinks
    {
      ".vscode-server/extensions/extensions.json" = {
        force = true;
        text = extensionsJson;
      };
      ".vscode-server/data/Machine/settings.json" = {
        force = true;
        text = json vscodeSettings;
      };
    }
  ];

  xdg.configFile."nixd/config.json".text = json {
    formatter.command = [ "alejandra" "--quiet" ];
  };
}
