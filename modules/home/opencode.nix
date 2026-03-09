{
  pkgs,
  lib,
  config,
  inputs ? { },
  ...
}:
let
  cfg = config.programs.opencode;
  opencodePackage =
    if pkgs ? opencode then
      pkgs.opencode
    else if inputs ? opencode then
      inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
    else
      throw "opencode package is not available in pkgs or inputs";
in
{
  options.programs.opencode."oh-my-opencode" = {
    enable = lib.mkEnableOption "oh-my-opencode plugin";

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Configuration for oh-my-opencode (will be written to oh-my-opencode.json)";
    };
  };

  config = lib.mkMerge [
    {
      programs.opencode.package = lib.mkDefault opencodePackage;
    }

    (lib.mkIf cfg."oh-my-opencode".enable {
      xdg.configFile."opencode/oh-my-opencode.json" = {
        text = builtins.toJSON cfg."oh-my-opencode".settings;
        onChange = ''echo "oh-my-opencode.json updated"'';
      };
    })
  ];
}
