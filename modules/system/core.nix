# modules/system/core.nix
_: {
  # --- 联网与镜像 (所有机器都需要) ---
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      auto-optimise-store = true;

      substituters = [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=10"
        "https://mirrors.ustc.edu.cn/nix-channels/store?priority=20"
        "https://mirror.sjtu.edu.cn/nix-channels/store?priority=30"
        "https://cache.nixos.org?priority=100"
      ];
    };
  };
  # systemd.services.nix-daemon.environment = {
  #   http_proxy = "http://127.0.0.1:7890";
  #   https_proxy = "http://127.0.0.1:7890";
  #   all_proxy = "socks5://127.0.0.1:7890";
  # };

  # --- 基础环境 ---
  time.timeZone = "Asia/Shanghai"; # 所有机器都用这个时区

  programs.zsh.enable = true;

  # --- IPv6 ---
  networking.enableIPv6 = false;
  boot.kernel.sysctl = {
    "net.ipv6.conf.all.disable_ipv6" = 1;
    "net.ipv6.conf.default.disable_ipv6" = 1;
  };

  # --- NixOS 版本锚点 ---
  system.stateVersion = "25.11";
}
