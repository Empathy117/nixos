{ ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 10000;
      share = true;
      ignoreDups = true;
      extended = true;
    };
  };
}
