{
  config,
  lib,
  pkgs,
  ...
}:
let
  baseSettings = import ./settings.nix;

  vscodeExtensions = with pkgs.vscode-extensions; [
    jnoortheen.nix-ide
    mkhl.direnv
    arrterian.nix-env-selector
    bbenoist.nix
  ];

  marketplaceExtensions = [
    (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
      mktplcRef = {
        publisher = "pinage404";
        name = "nix-extension-pack";
        version = "3.0.0";
        sha256 = "sha256-cWXd6AlyxBroZF+cXZzzWZbYPDuOqwCZIK67cEP5sNk=";
      };
    })
  ];

  allExtensions = vscodeExtensions ++ marketplaceExtensions;

  metadataFor = ext: {
    drv = ext;
    publisher = ext.vscodeExtPublisher;
    name = ext.vscodeExtName;
    inherit (ext) version;
    uniqueId =
      if ext ? vscodeExtUniqueId && ext.vscodeExtUniqueId != null then
        ext.vscodeExtUniqueId
      else
        "${ext.vscodeExtPublisher}.${ext.vscodeExtName}";
  };

  cfg = config.shared.vscode;
  finalExtensions = cfg.baseExtensions ++ cfg.extraExtensions;
  finalSettings = lib.foldl' lib.recursiveUpdate cfg.baseUserSettings cfg.extraUserSettings;
in
{
  options.shared.vscode = {
    baseExtensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      readOnly = true;
      default = allExtensions;
    };

    extraExtensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      readOnly = true;
    };

    baseUserSettings = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      default = baseSettings;
    };

    extraUserSettings = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
    };

    userSettings = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
    };

    remoteMetadata = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      readOnly = true;
    };
  };

  config.shared.vscode = {
    extensions = finalExtensions;
    userSettings = finalSettings;
    remoteMetadata = map metadataFor finalExtensions;
  };
}
