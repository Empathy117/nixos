{
  pkgs,
  ...
}:
{
  imports = [
    ./aic8800d80-module.nix
  ];

  # ========================================
  # AIC8800D80 无线网卡支持 (Tenda U11 Pro)
  # ========================================
  
  hardware.aic8800d80.enable = true;
  
  # ========================================
  # 网络配置
  # ========================================
  
  networking.networkmanager.enable = true;
  
  # ========================================
  # 系统工具
  # ========================================
  
  environment.systemPackages = with pkgs; [
    # 开发工具（可选）
    usbutils
    pciutils
  ];
}
