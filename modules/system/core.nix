# modules/system/core.nix
# 
# 核心系统配置 - 所有 NixOS 主机共享的基础设置
# 
# 包含：
# - Nix 守护进程配置（实验性特性、缓存镜像）
# - 时区和本地化
# - 基础 shell 环境
# - 系统版本锚点
#
# 注意：此模块会被所有主机自动加载，只放置通用配置
_: {
  # ============================================================================
  # Nix 配置
  # ============================================================================
  nix = {
    settings = {
      # 启用 Flakes 和新的 nix 命令
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # 自动优化 store，通过硬链接减少磁盘占用
      auto-optimise-store = true;

      # 二进制缓存配置 - 使用国内镜像加速
      # priority 数字越小优先级越高
      substituters = [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=10"
        "https://mirrors.ustc.edu.cn/nix-channels/store?priority=20"
        "https://mirror.sjtu.edu.cn/nix-channels/store?priority=30"
        "https://cache.nixos.org?priority=100" # 官方缓存作为后备
      ];
    };

    # 垃圾回收配置 - 自动清理旧版本
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # 如果需要代理，取消注释以下配置
  # systemd.services.nix-daemon.environment = {
  #   http_proxy = "http://127.0.0.1:7897";
  #   https_proxy = "http://127.0.0.1:7897";
  #   all_proxy = "socks5://127.0.0.1:7897";
  # };

  # ============================================================================
  # 系统环境
  # ============================================================================
  
  # 时区设置 - 所有机器统一使用上海时区
  time.timeZone = "Asia/Shanghai";

  # 启用 zsh - 作为系统级 shell
  programs.zsh.enable = true;

  # ============================================================================
  # 版本管理
  # ============================================================================
  
  # NixOS 版本锚点 - 用于向后兼容性
  # 警告：不要随意更改此值，除非你知道自己在做什么
  system.stateVersion = "25.05";
}
