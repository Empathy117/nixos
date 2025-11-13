{ pkgs }:

let
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
    (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
      mktplcRef = {
        publisher = "openai";
        name = "chatgpt";
        version = "0.5.39";
        sha256 = "sha256-cT96SOErVa8BbVGfpgRc4p4FoLSVT74hx08D2JwW/Ks=";
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
in {
  packages = allExtensions;
  remote = map metadataFor allExtensions;
}
