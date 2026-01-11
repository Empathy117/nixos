{
  config,
  pkgs,
  inputs ? { },
  ...
}:
let
  ghosttyConfig = ''
    theme = "light:Catppuccin Latte,dark:Catppuccin Mocha"

    term = xterm-256color

    font-family = ""
    font-family = "Maple Mono NF CN"
    font-family = "JetBrainsMono Nerd Font Mono"
    font-size = 14

    command = /run/current-system/sw/bin/fish

    window-padding-x = 12
    window-padding-y = 12
    window-padding-balance = true

    window-colorspace = display-p3

    background-opacity = 0.8
    background-opacity-cells = true
    background-blur = 8

    cursor-style = bar
    adjust-cursor-thickness = 3
    cursor-style-blink = false
    cursor-opacity = 0.85

    window-save-state = always

    macos-titlebar-style = transparent
    macos-titlebar-proxy-icon = hidden
    macos-option-as-alt = left

    macos-icon = glass
  '';

  lazygitConfig = ''
    customCommands:
      - key: 'c'
        context: 'files'
        description: 'Commit with Commitizen'
        command: |
          printf '%s\n' \
            'feat: 新功能' \
            'fix: 修复 Bug' \
            'chore: 构建/依赖/杂项' \
            'docs: 文档' \
            'refactor: 重构' \
            'perf: 性能优化' \
            'test: 测试'
          cz commit
        output: terminal
  '';

  opencodePkg =
    if inputs ? opencode then
      inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
    else
      pkgs.opencode;

in
{
  home.username = "empathy";
  home.homeDirectory = "/Users/empathy";
  home.stateVersion = "25.05";
  home.enableNixpkgsReleaseCheck = false;

  targets.darwin.linkApps.enable = false;

  home.sessionPath = [
    "/etc/profiles/per-user/${config.home.username}/bin"
  ];

  home.packages =
    (with pkgs; [
      codex
      claude-code
      commitizen
      lazygit
      nixd
      nixfmt
      statix
      rsync
      tailscale
      tmux
    ])
    ++ [
      opencodePkg
    ];


  programs.tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      yank
      resurrect
      cpu
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor "mocha"
          set -g @catppuccin_window_status_style "rounded"
        '';
      }
      continuum
    ];
    extraConfig = ''
      # ==========================
      # 基础设置
      # ==========================

      # 1. 将前缀键从 Ctrl-b 修改为 Ctrl-e (避免手指跨度太大)
      set -g prefix C-e
      unbind C-b
      bind C-e send-prefix

      # 2. 开启鼠标支持 (拖动窗格、点击选中窗口、鼠标滚轮翻页)
      set -g mouse on

      # 3. 设置历史记录行数 (默认只有 2000，容易不够看)
      set -g history-limit 10000

      # 4. 让 tmux 与系统剪贴板同步
      set -g set-clipboard on

      # 5. 重新加载配置文件的快捷键：前缀 + r
      bind r source-file ~/.tmux.conf \; display "配置文件已重新加载！"

      # 6. Lazygit 弹窗：前缀 + g
      bind g display-popup -E -d "#{pane_current_path}" -w 90% -h 90% lazygit

      # ==========================
      # 窗口与分屏 (直觉化按键)
      # ==========================

      # 1. 左右分屏使用 | (在当前路径打开)
      unbind %
      bind | split-window -h -c "#{pane_current_path}"

      # 2. 上下分屏使用 - (在当前路径打开)
      unbind '"'
      bind - split-window -v -c "#{pane_current_path}"

      # 3. 使用 Vim 风格键位切换光标 (h,j,k,l)
      bind h select-pane -L  # 左
      bind j select-pane -D  # 下
      bind k select-pane -U  # 上
      bind l select-pane -R  # 右

      # ==========================
      # 视觉美化 (Catppuccin)
      # ==========================

      # 开启 256 色支持 (避免 vim 颜色怪异)
      set -g default-terminal "tmux-256color"

      # 状态栏左侧显示 Session 名字
      set -g status-left-length 40
      set -g status-left "Session: #S | #I:#P"

      # 状态栏右侧显示 CPU/RAM + 时间（颜色随负载变化）
      set -g status-right-length 80
      set -g status-right "#{cpu_bg_color}#{cpu_fg_color} CPU #{cpu_percentage} #[default] #{ram_bg_color}#{ram_fg_color} RAM #{ram_percentage} #[default] %Y-%m-%d %R"

      # 自动重新编号窗口 (例如关闭了 2 号窗口，3 号会自动变成 2 号)
      set-option -g renumber-windows on

      # ==========================
      # 会话持久化 (Resurrect + Continuum)
      # ==========================

      set -g @resurrect-capture-pane-contents "on"
      set -g @continuum-restore "on"
      set -g @continuum-save-interval "15"
    '';
  };

  xdg.configFile."ghostty/config".text = ghosttyConfig;
  home.file."Library/Application Support/com.mitchellh.ghostty/config" = {
    text = ghosttyConfig;
    force = true;
  };

  xdg.configFile."lazygit/config.yml".text = lazygitConfig;
  home.file."Library/Application Support/lazygit/config.yml" = {
    text = lazygitConfig;
    force = true;
  };
  home.file.".skhdrc".text = ''
    cmd - space : open -b com.apple.apps.launcher

    cmd - h : yabai -m window --focus west
    cmd - j : yabai -m window --focus south
    cmd - k : yabai -m window --focus north
    cmd - l : yabai -m window --focus east

    cmd + shift - h : yabai -m window --swap west
    cmd + shift - j : yabai -m window --swap south
    cmd + shift - k : yabai -m window --swap north
    cmd + shift - l : yabai -m window --swap east

    ctrl + shift - f : yabai -m window --toggle zoom-fullscreen
    ctrl + shift - t : yabai -m window --toggle float
  '';

  imports = [
    ../../modules/cli/modern.nix
    ../../modules/vscode/gui.nix
    ../../modules/home/nixvim.nix
  ];
}
