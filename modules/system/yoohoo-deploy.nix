{ config, lib, pkgs, ... }:

let
  cfg = config.services.yoohooDeploy;
  inherit (lib) mkEnableOption mkOption;

  mkInstance =
    name: instCfg:
    let
      bareRepo = "${cfg.repoDir}/${instCfg.repoName}";
      workTree = instCfg.workTree;
      preReceiveScript = ''
        #!/usr/bin/env bash
        set -euo pipefail

        BRANCH=${lib.escapeShellArg instCfg.branch}
        ALLOWED_PUSHERS=${lib.escapeShellArg (lib.concatStringsSep " " instCfg.allowedPushers)}

        # If no allowed pushers configured, allow all pushes
        if [ -z "$ALLOWED_PUSHERS" ]; then
          exit 0
        fi

        while read oldrev newrev ref; do
          if [ "$ref" = "$BRANCH" ]; then
            case " $ALLOWED_PUSHERS " in
              *" $USER "*) ;;
              *)
                echo "You are not allowed to push to $BRANCH" >&2
                exit 1
                ;;
            esac
          fi
        done

        exit 0
      '';
      deployPkg =
        pkgs.writeShellScriptBin "yoohoo-deploy-${name}" ''
          set -euo pipefail

          # Update work tree from bare repo
          ${pkgs.git}/bin/git --work-tree=${workTree} --git-dir=${bareRepo} checkout -f ${instCfg.branch}

          cd ${workTree}

          # Run custom deploy steps for this repo (build, copy, restart, etc.)
          ${instCfg.postCheckoutCmd}
        '';
    in
    {
      name = "yoohoo-deploy-${name}";
      package = deployPkg;
      scriptPath = "${deployPkg}/bin/yoohoo-deploy-${name}";
      bareRepo = bareRepo;
      workTree = workTree;
      branch = instCfg.branch;
      preReceiveScript = preReceiveScript;
    };

  instanceList = lib.mapAttrsToList mkInstance cfg.instances;
in
{
  options.services.yoohooDeploy = {
    enable = mkEnableOption "Yoohoo Git bare repo + simple deploy workflow (multi-repo)";

    user = lib.mkOption {
      type = lib.types.str;
      default = "git";
      description = "System user that owns the bare repository and receives pushes.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "git";
      description = "Primary group for the Git user.";
    };

    repoDir = lib.mkOption {
      type = lib.types.path;
      default = "/srv/git";
      description = "Directory that contains the bare repository.";
    };

    instances = mkOption {
      type =
        lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }:
            {
              options = {
                repoName = mkOption {
                  type = lib.types.str;
                  default = "${name}.git";
                  description = "Bare repository name for this instance (inside repoDir).";
                };

                workTree = mkOption {
                  type = lib.types.path;
                  default = "/srv/yoohoo/${name}";
                  description = "Deploy work tree that services and/or Nginx read from.";
                };

                branch = mkOption {
                  type = lib.types.str;
                  default = "main";
                  description = "Git branch to deploy on push.";
                };

                allowedPushers = mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "System users allowed to push the deploy branch; empty list means no restriction.";
                };

                postCheckoutCmd = mkOption {
                  type = lib.types.str;
                  default = "";
                  description = "Shell snippet executed after checkout (build, copy, restart, etc.).";
                };
              };
            }
          )
        );
      default = { };
      description = "Per-repo deploy instances (e.g. bsc-service, bsc-frontend, mdm-service, ...).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Git user/group for bare repo
    users.groups.${cfg.group} = { };

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.repoDir;
      createHome = true;
      shell = pkgs.bashInteractive;
      description = "Yoohoo Git user (bare repo + hooks)";
    };

    # Allow the Git user to run each deploy script as root without password
    security.sudo.extraRules =
      [
        {
          users = [ cfg.user ];
          commands = map
            (inst: {
              command = inst.scriptPath;
              options = [ "NOPASSWD" ];
            })
            instanceList;
        }
      ];

    # Make deploy helpers available in PATH (optional, but handy)
    environment.systemPackages = map (inst: inst.package) instanceList;

    # Create bare repos, hooks, and work trees
    system.activationScripts.yoohooDeploy = ''
      mkdir -p ${cfg.repoDir}
      chown -R ${cfg.user}:${cfg.group} ${cfg.repoDir}
      chmod 2775 ${cfg.repoDir}

      ${lib.concatMapStringsSep "\n" (inst: ''
        mkdir -p ${inst.workTree}
        if [ ! -d ${inst.bareRepo} ]; then
          ${pkgs.git}/bin/git init --bare ${inst.bareRepo}
        fi

        chown -R ${cfg.user}:${cfg.group} ${inst.bareRepo}
        chmod -R 2775 ${inst.bareRepo}

        hook="${inst.bareRepo}/hooks/post-receive"
        cat >"$hook" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

while read oldrev newrev ref; do
  if [ "$ref" = "refs/heads/${inst.branch}" ]; then
    sudo ${inst.scriptPath}
  fi
done
EOF
        chmod +x "$hook"
        preHook="${inst.bareRepo}/hooks/pre-receive"
        cat >"$preHook" <<'EOF'
${inst.preReceiveScript}
EOF
        chmod +x "$preHook"
      '') instanceList}
    '';
  };
}
