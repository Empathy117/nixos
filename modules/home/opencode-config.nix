{ pkgs, inputs ? { }, ... }:
let
  opencodeBase =
    if inputs ? opencode then
      inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
    else
      pkgs.opencode;
  opencodeWithLang = pkgs.symlinkJoin {
    name = "opencode-with-lang";
    paths = [
      opencodeBase
    ];
    buildInputs = [
      pkgs.makeWrapper
    ];
    postBuild = ''
      wrapProgram $out/bin/opencode \
        --set LANG "zh_CN.UTF-8"
    '';
  };
in
{
  programs.opencode = {
    enable = true;
    package = opencodeWithLang;
    settings = {
      autoupdate = false;
      share = "manual";
      plugin = [
        "oh-my-opencode"
      ];
      lsp = {
        nixd = {
          command = [
            "nixd"
          ];
        };
        pyright = {
          command = [
            "pyright-langserver"
            "--stdio"
          ];
        };
      };
    };
    oh-my-opencode = {
      enable = true;
      settings = {
        google_auth = true;
      };
    };
  };
}
