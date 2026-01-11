{
  pkgs,
  lib,
  config,
  inputs ? { },
  ...
}:
let
  cfg = config.programs.opencode;
in
{
  options.programs.opencode = {
    enable = lib.mkEnableOption "opencode configuration";

    package = lib.mkOption {
      type = lib.types.package;
      default =
        if inputs ? opencode then
          inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
        else
          pkgs.opencode;
      description = "OpenCode package to use";
    };

    oh-my-opencode = {
      enable = lib.mkEnableOption "oh-my-opencode plugin";

      settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        description = "Configuration for oh-my-opencode (will be written to oh-my-opencode.json)";
      };
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Configuration for opencode (will be written to opencode.json)";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."opencode/opencode.json" = lib.mkIf (cfg.settings != { }) {
      text = builtins.toJSON cfg.settings;
      onChange = ''echo "opencode.json updated"'';
    };

    xdg.configFile."opencode/oh-my-opencode.json" = lib.mkIf cfg.oh-my-opencode.enable {
      text = builtins.toJSON cfg.oh-my-opencode.settings;
      onChange = ''echo "oh-my-opencode.json updated"'';
    };
  };
}
