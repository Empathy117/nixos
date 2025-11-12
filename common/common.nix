# ~/nixos/common/common.nix

{ config, lib, pkgs, ... }:

{
  # --- 联网与镜像 (所有机器都需要) ---
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];

      auto-optimise-store = true;

      substituters = [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=10"
        "https://mirrors.ustc.edu.cn/nix-channels/store?priority=20"
        "https://mirror.sjtu.edu.cn/nix-channels/store?priority=30"
        "https://cache.nixos.org?priority=100"
      ];
    };
  };

  # --- 基础环境 ---
  time.timeZone = "Asia/Shanghai"; # 所有机器都用这个时区

  # --- NixOS 版本锚点 ---
  system.stateVersion = "25.05";
}
