{ lib, pkgs, ... }:

let
  settings = import ../../home/vscode/settings.nix;

  vscodeExtensions =
    with pkgs.vscode-extensions; [
      jnoortheen.nix-ide
      mkhl.direnv
      arrterian.nix-env-selector
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

  metadataFor =
    ext: {
      drv = ext;
      publisher = ext.vscodeExtPublisher;
      name = ext.vscodeExtName;
      version = ext.version;
      uniqueId =
        if ext ? vscodeExtUniqueId && ext.vscodeExtUniqueId != null then
          ext.vscodeExtUniqueId
        else
          "${ext.vscodeExtPublisher}.${ext.vscodeExtName}";
    };
in
{
  options.shared.vscode = {
    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      readOnly = true;
      default = allExtensions;
    };

    remoteMetadata = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      readOnly = true;
      default = map metadataFor allExtensions;
    };

    userSettings = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      default = settings;
    };
  };
}
