{
  pkgs,
  pkgsUnstable,
  config,
  ...
}:
let
  aic8800d80-driver = config.boot.kernelPackages.callPackage ./aic8800d80-driver.nix { };
in
{
  hardware.firmware = [
    pkgs.linux-firmware
    aic8800d80-driver
  ];
  
  boot.kernelPackages = pkgs.linuxPackages;
  
  boot.extraModulePackages = [
    aic8800d80-driver
  ];
  
  # 启用 NetworkManager 管理网络
  networking.networkmanager.enable = true;
  
  # 启用 usb_modeswitch 来切换 USB 网卡模式
  hardware.enableRedistributableFirmware = true;
  services.udev.packages = [ pkgs.usb-modeswitch-data ];
  
  # 创建 /lib/firmware 软链接（AIC8800 驱动硬编码路径）
  system.activationScripts.aic8800-firmware = ''
    mkdir -p /lib
    ln -sfn /run/current-system/firmware /lib/firmware
  '';
  
  # 添加网络调试工具和编译工具
  environment.systemPackages = with pkgs; [
    usbutils
    pciutils
    iw
    wirelesstools
    usb-modeswitch
    wpa_supplicant
    gcc
    gnumake
    git
  ];
  
  # AIC8800 USB 模式切换规则
  services.udev.extraRules = ''
    # AIC8800 存储模式 -> 网卡模式
    SUBSYSTEM=="usb", ATTR{idVendor}=="a69c", ATTR{idProduct}=="5725", RUN+="${pkgs.usb-modeswitch}/bin/usb_modeswitch -v a69c -p 5725 -K"
  '';
}
