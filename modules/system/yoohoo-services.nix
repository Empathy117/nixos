{ config, lib, pkgs, ... }:

let
  cfg = config.services.yoohoo;

  mkBscInstance =
    name: instCfg:
    let
      serviceName = "yoohoo-bsc-${name}";
      workingDir = instCfg.workingDir or "${cfg.baseDir}/${name}";
      profile = instCfg.profile or "local";
      javaHome = instCfg.javaHome or pkgs.temurin-bin-8;
      extraEnv = instCfg.extraEnv or [ ];
    in
    if instCfg.enable or false then
      {
        ${serviceName} = {
          description = "Yoohoo BSC Service (${name})";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];

          serviceConfig = {
            WorkingDirectory = workingDir;
            ExecStart = "${pkgs.bash}/bin/bash -lc 'set -e; chmod +x ./gradlew || true; ./gradlew bootRun -Pprofile=${profile}'";
            Restart = "on-failure";
            Environment =
              [
                "JAVA_HOME=${javaHome}"
              ]
              ++ extraEnv;
          };
        };
      }
    else
      { };

  mkMdmInstance =
    name: instCfg:
    let
      serviceName = "yoohoo-mdm-${name}";
      workingDir = instCfg.workingDir or "${cfg.baseDir}/${name}";
      profile = instCfg.profile or "local";
      javaHome = instCfg.javaHome or pkgs.temurin-bin-8;
      extraEnv = instCfg.extraEnv or [ ];
    in
    if instCfg.enable or false then
      {
        ${serviceName} = {
          description = "Yoohoo MDM Service (${name})";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];

          serviceConfig = {
            WorkingDirectory = workingDir;
            ExecStart = "${pkgs.bash}/bin/bash -lc 'set -e; chmod +x ./gradlew || true; ./gradlew bootRun -Pprofile=${profile}'";
            Restart = "on-failure";
            Environment =
              [
                "JAVA_HOME=${javaHome}"
              ]
              ++ extraEnv;
          };
        };
      }
    else
      { };

  mkBmsInstance =
    name: instCfg:
    let
      serviceName = "yoohoo-bms-${name}";
      workingDir = instCfg.workingDir or "${cfg.baseDir}/${name}";
      profile = instCfg.profile or "local";
      javaHome = instCfg.javaHome or pkgs.temurin-bin-8;
      extraEnv = instCfg.extraEnv or [ ];
    in
    if instCfg.enable or false then
      {
        ${serviceName} = {
          description = "Yoohoo BMS Service (${name})";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];

          serviceConfig = {
            WorkingDirectory = workingDir;
            ExecStart = "${pkgs.bash}/bin/bash -lc 'set -e; chmod +x ./gradlew || true; ./gradlew bootRun -Pprofile=${profile}'";
            Restart = "on-failure";
            Environment =
              [
                "JAVA_HOME=${javaHome}"
              ]
              ++ extraEnv;
          };
        };
      }
    else
      { };
in
{
  options.services.yoohoo = {
    enable = lib.mkEnableOption "Yoohoo application services";

    baseDir = lib.mkOption {
      type = lib.types.str;
      default = "/srv/yoohoo";
      description = "Base directory for Yoohoo service working trees.";
    };

    bsc.instances = lib.mkOption {
      type =
        lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }:
            {
              options = {
                enable = lib.mkEnableOption "Enable yoohoo-bsc-${name} instance.";

                workingDir = lib.mkOption {
                  type = lib.types.path;
                  default = "${cfg.baseDir}/${name}";
                  description = "Working directory for yoohoo-bsc-${name}.";
                };

                profile = lib.mkOption {
                  type = lib.types.str;
                  default = "local";
                  description = "Gradle profile passed as -Pprofile= for this instance.";
                };

                javaHome = lib.mkOption {
                  type = lib.types.path;
                  default = pkgs.temurin-bin-8;
                  description = "JAVA_HOME for this instance.";
                };

                extraEnv = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "Additional environment variables (KEY=VALUE) for this instance.";
                };
              };
            }
          )
        );
      default = { };
      description = "BSC service instances keyed by name (e.g. dev, test).";
    };

    mdm.instances = lib.mkOption {
      type =
        lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }:
            {
              options = {
                enable = lib.mkEnableOption "Enable yoohoo-mdm-${name} instance.";

                workingDir = lib.mkOption {
                  type = lib.types.path;
                  default = "${cfg.baseDir}/${name}";
                  description = "Working directory for yoohoo-mdm-${name}.";
                };

                profile = lib.mkOption {
                  type = lib.types.str;
                  default = "local";
                  description = "Gradle profile passed as -Pprofile= for this instance.";
                };

                javaHome = lib.mkOption {
                  type = lib.types.path;
                  default = pkgs.temurin-bin-8;
                  description = "JAVA_HOME for this instance.";
                };

                extraEnv = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "Additional environment variables (KEY=VALUE) for this instance.";
                };
              };
            }
          )
        );
      default = { };
      description = "MDM service instances keyed by name (e.g. dev, test).";
    };

    bms.instances = lib.mkOption {
      type =
        lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }:
            {
              options = {
                enable = lib.mkEnableOption "Enable yoohoo-bms-${name} instance.";

                workingDir = lib.mkOption {
                  type = lib.types.path;
                  default = "${cfg.baseDir}/${name}";
                  description = "Working directory for yoohoo-bms-${name}.";
                };

                profile = lib.mkOption {
                  type = lib.types.str;
                  default = "local";
                  description = "Gradle profile passed as -Pprofile= for this instance.";
                };

                javaHome = lib.mkOption {
                  type = lib.types.path;
                  default = pkgs.temurin-bin-8;
                  description = "JAVA_HOME for this instance.";
                };

                extraEnv = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "Additional environment variables (KEY=VALUE) for this instance.";
                };
              };
            }
          )
        );
      default = { };
      description = "BMS service instances keyed by name (e.g. dev, test).";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services =
      lib.mkMerge (
        (lib.mapAttrsToList mkBscInstance cfg.bsc.instances)
        ++ (lib.mapAttrsToList mkMdmInstance cfg.mdm.instances)
        ++ (lib.mapAttrsToList mkBmsInstance cfg.bms.instances)
      );
  };
}
