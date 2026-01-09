{
  config,
  lib,
  pkgs,
  ...
}:
{
  manual.manpages.enable = false;

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set -g fish_greeting

      set -gx EDITOR vim
      set -gx VISUAL vim

      if not set -q fish_color_command
        if type -q defaults
          if test (defaults read -g AppleInterfaceStyle 2>/dev/null) = "Dark"
            fish_config theme choose "ayu-mirage"
          else
            fish_config theme choose "snow-day"
          end
        else
          fish_config theme choose "ayu-mirage"
        end
      end
    '';

    shellAliases = {
      cat = "bat --paging=never";
    };
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;

    settings = {
      add_newline = false;

      format = "$directory$git_branch$git_status$nix_shell$cmd_duration$line_break$character";

      character = {
        success_symbol = "[❯](green)";
        error_symbol = "[❯](red)";
      };

      directory = {
        truncation_length = 3;
        truncation_symbol = "…/";
        style = "bold blue";
      };

      git_branch = {
        symbol = " ";
        style = "bold purple";
      };

      nix_shell = {
        symbol = " ";
        format = "[$symbol$state]($style) ";
        style = "bold cyan";
      };

      cmd_duration = {
        min_time = 500;
        format = "[$duration]($style) ";
        style = "yellow";
      };
    };
  };

  programs.bat = {
    enable = true;
    config = {
      pager = "less -FR";
      theme = "TwoDark";
    };
  };

  programs.eza = {
    enable = true;
    git = true;
    icons = "auto";
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fd = {
    enable = true;
    hidden = true;
    ignores = [
      ".git/"
      "node_modules/"
      "target/"
    ];
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;

    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";

    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];

    fileWidgetOptions = [
      "--preview 'bat --style=numbers --color=always --line-range :200 {}'"
    ];

    changeDirWidgetOptions = [
      "--preview 'eza --tree --level=2 --color=always --icons {} | head -200'"
    ];
  };

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";
  };

  programs.direnv = {
    enable = true;
    silent = true;
    nix-direnv.enable = true;
  };

  home.packages = [
    pkgs.ripgrep
  ];
}
