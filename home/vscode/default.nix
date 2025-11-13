{ config, lib, ... }:

let
  inherit (lib) mkMerge;
  settings = config.shared.vscode.userSettings;
  remoteExtensions = config.shared.vscode.remoteMetadata;

  json = value: builtins.toJSON value + "\n";
  homeDir = config.home.homeDirectory;

  extensionLinks =
    builtins.listToAttrs (
      map
        (ext: {
          name = ".vscode-server/extensions/${ext.uniqueId}-${ext.version}";
          value = {
            force = true;
            recursive = true;
            source = "${ext.drv}/share/vscode/extensions/${ext.uniqueId}";
          };
        })
        remoteExtensions
    );

  extensionsJson =
    json (
      map
        (ext: {
          identifier = {
            id = ext.uniqueId;
            uuid = "";
          };
          version = ext.version;
          relativeLocation = "${ext.uniqueId}-${ext.version}";
          location = {
            "$mid" = 1;
            path = "${homeDir}/.vscode-server/extensions/${ext.uniqueId}-${ext.version}";
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
in {
  # WSL: only manage remote server state; GUI VS Code stays on Windows.
  home.file = mkMerge [
    extensionLinks
    {
      ".vscode-server/extensions/extensions.json" = {
        force = true;
        text = extensionsJson;
      };
      ".vscode-server/data/Machine/settings.json" = {
        force = true;
        text = json settings;
      };
    }
  ];

  xdg.configFile."nixd/config.json".text = json {
    formatter.command = [ "alejandra" "--quiet" ];
  };
}
