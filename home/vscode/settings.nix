let
  workspaceFolderLiteral = "$" + "{workspaceFolder}";
in
{
  "editor.formatOnSave" = false;
  "git.autofetch" = true;
  "nix.enableLanguageServer" = true;
  "nix.serverPath" = "~/.nix-profile/bin/nixd";
  # LSP config can be passed via ``nix.serverSettings.{lsp}`` as shown below.
  "nix.serverSettings" = {
    # check https://github.com/nix-community/nixd/blob/main/nixd/docs/configuration.md for all nixd config
    "nixd" = {
      "diagnostics" = {
        "strictEval" = false;
      };
      "formatting" = {
        "command" = [ "nixfmt" ];
      };
      "options" = {
        "autoDiscover" = false;
        # By default, this entry will be read from `import <nixpkgs> { }`.
        # You can write arbitrary Nix expressions here, to produce valid "options" declaration result.
        # Tip: for flake-based configuration, utilize `builtins.getFlake`
        "nixos" = {
          "expr" = "(builtins.getFlake \"/absolute/path/to/flake\").nixosConfigurations.<name>.options";
        };
        "home-manager" = {
          "expr" = "(builtins.getFlake \"/absolute/path/to/flake\").homeConfigurations.<name>.options";
        };
        # Tip: use ${workspaceFolder} variable to define path
        "nix-darwin" = {
          "expr" =
            "(builtins.getFlake \"${workspaceFolderLiteral}/path/to/flake\").darwinConfigurations.<name>.options";
        };
      };
    };
  };
}
