# common/common.nix
{ ... }:
{
  # --- 联网与镜像 (系统级：NixOS / nix-darwin 通用) ---
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
  #   http_proxy = "http://127.0.0.1:7897";
  #   https_proxy = "http://127.0.0.1:7897";
  #   all_proxy = "socks5://127.0.0.1:7897";
  # };

  nixpkgs.config.allowUnfree = true;

  # --- 基础环境 (系统级) ---
  time.timeZone = "Asia/Shanghai";
}
