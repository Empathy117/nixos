let
  # "$" + "{workspaceFolder}" 避免 Nix 插值，生成 VS Code 可识别的 ${workspaceFolder} 变量
  # VS Code 运行时会将其替换为实际工作区路径，macOS / WSL 通用
  flake = "(builtins.getFlake \"$" + "{workspaceFolder}\")";
in
{
  "editor.formatOnSave" = false;
  "git.autofetch" = true;
  "[python]" = {
    "editor.defaultFormatter" = "charliermarsh.ruff";
  };
  "nix.enableLanguageServer" = true;
  "nix.serverPath" = "nixd";
  "nix.serverSettings" = {
    "nixd" = {
      "diagnostics" = {
        "strictEval" = false;
      };
      "formatting" = {
        "command" = [ "nixfmt" ];
      };
      "options" = {
        "autoDiscover" = false;
        "nixos" = {
          "expr" = "${flake}.nixosConfigurations.wsl.options";
        };
        "home-manager" = {
          "expr" = "${flake}.darwinConfigurations.MacBook-Pro.options.home-manager.users.type.getSubOptions []";
        };
        "nix-darwin" = {
          "expr" = "${flake}.darwinConfigurations.MacBook-Pro.options";
        };
      };
    };
  };
}
