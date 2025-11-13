{
  "[nix]" = {
    "editor.defaultFormatter" = "jnoortheen.nix-ide";
  };
  "editor.formatOnSave" = true;
  "git.autofetch" = true;
  "nix.enableLanguageServer" = true;
  "nix.formatterPath" = "alejandra";
  "nix.serverPath" = "nixd";
  "nix.serverSettings" = {
    nixd = {
      formatting = {
        command = [ "alejandra" "--quiet" ];
      };
    };
  };
}
