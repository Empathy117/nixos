{
  pkgs,
  lib,
  config,
  inputs ? { },
  ...
}:
let
  cfg = config.programs.opencode;
  opencodeInputPackage =
    if inputs ? opencode then
      inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
    else
      pkgs.opencode;
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
      programs.opencode.package = lib.mkDefault opencodeInputPackage;
    }

    (lib.mkIf cfg."oh-my-opencode".enable {
      xdg.configFile."opencode/oh-my-opencode.json" = {
        text = builtins.toJSON cfg."oh-my-opencode".settings;
        onChange = ''echo "oh-my-opencode.json updated"'';
      };
    })
  ];
}
