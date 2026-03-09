{ pkgs, ... }:
{
  manual.manpages.enable = false;

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set -g fish_greeting

      set -gx EDITOR vim
      set -gx VISUAL vim

      function setproxy
        set -l host 127.0.0.1
        set -l port 7897
        if test (count $argv) -ge 1
          set host $argv[1]
        end
        if test (count $argv) -ge 2
          set port $argv[2]
        end
        set -gx http_proxy "http://$host:$port"
        set -gx https_proxy "http://$host:$port"
        set -gx all_proxy "socks5://$host:$port"
        set -gx HTTP_PROXY $http_proxy
        set -gx HTTPS_PROXY $https_proxy
        set -gx ALL_PROXY $all_proxy
        echo "Proxy set to $host:$port"
      end

      function unsetproxy
        set -e http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
        echo "Proxy variables cleared"
      end

      if not set -q fish_color_command
        if type -q defaults
          if test (defaults read -g AppleInterfaceStyle 2>/dev/null) = "Dark"
            fish_config theme choose "ayu Mirage"
          else
            fish_config theme choose "Snow Day"
          end
        else
          fish_config theme choose "ayu Mirage"
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
    enableZshIntegration = true;

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
    enableZshIntegration = true;
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
    enableZshIntegration = true;

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
    enableZshIntegration = true;
  };

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";
    settings = {
      manager = {
        ratio = [
          1
          4
          3
        ];
        sort_by = "modified";
        sort_reverse = true;
        sort_dir_first = true;
        show_hidden = false;
        show_symlink = true;
        linemode = "git";
        scrolloff = 2;
      };
      preview = {
        max_width = 1200;
        max_height = 900;
      };
      plugin = {
        prepend_fetchers = [
          {
            id = "git";
            url = "*";
            run = "git";
          }
          {
            id = "git";
            url = "*/";
            run = "git";
          }
        ];
      };
    };
    keymap = {
      mgr.prepend_keymap = [
        {
          on = [
            "g"
            "l"
          ];
          run = "shell --block -- lazygit";
          desc = "Lazygit";
        }
        {
          on = [
            "R"
            "p"
            "p"
          ];
          run = "plugin sudo -- paste";
          desc = "Sudo paste";
        }
        {
          on = [
            "R"
            "P"
          ];
          run = "plugin sudo -- paste --force";
          desc = "Sudo paste (force)";
        }
        {
          on = [
            "R"
            "r"
          ];
          run = "plugin sudo -- rename";
          desc = "Sudo rename";
        }
        {
          on = [
            "R"
            "p"
            "l"
          ];
          run = "plugin sudo -- link";
          desc = "Sudo link";
        }
        {
          on = [
            "R"
            "p"
            "r"
          ];
          run = "plugin sudo -- link --relative";
          desc = "Sudo link (relative)";
        }
        {
          on = [
            "R"
            "p"
            "L"
          ];
          run = "plugin sudo -- hardlink";
          desc = "Sudo hardlink";
        }
        {
          on = [
            "R"
            "a"
          ];
          run = "plugin sudo -- create";
          desc = "Sudo create";
        }
        {
          on = [
            "R"
            "d"
          ];
          run = "plugin sudo -- remove";
          desc = "Sudo trash";
        }
        {
          on = [
            "R"
            "D"
          ];
          run = "plugin sudo -- remove --permanently";
          desc = "Sudo delete";
        }
        {
          on = [
            "R"
            "m"
          ];
          run = "plugin sudo -- chmod";
          desc = "Sudo chmod";
        }
      ];
    };
    plugins = {
      git = pkgs.yaziPlugins.git;
      "full-border" = pkgs.yaziPlugins."full-border";
      githead = pkgs.yaziPlugins.githead;
      sudo = pkgs.yaziPlugins.sudo;
    };
    initLua = ''
      require("full-border"):setup()
      require("git"):setup()
      require("githead"):setup()
    '';
  };

  programs.direnv = {
    enable = true;
    silent = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  home.packages = [
    pkgs.ripgrep
    pkgs.nushell
    pkgs.yt-dlp-light
    pkgs.ffmpeg
    pkgs.deno
  ];
}
