{
  config,
  lib,
  pkgs,
  ...
}:
let
  settings = import ../../home/vscode/settings.nix;

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
   (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
      # Fetch from marketplace so we don't have to vendor the VSIX manually.
     mktplcRef = {
       publisher = "openai";
       name = "chatgpt";
       version = "0.5.39";
       sha256 = "sha256-cT96SOErVa8BbVGfpgRc4p4FoLSVT74hx08D2JwW/Ks=";
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
      default = settings;
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
