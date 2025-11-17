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
  hardware.firmware = [ pkgs.linux-firmware ];
  
  boot.kernelPackages = pkgs.linuxPackages;
  
  boot.extraModulePackages = [
    aic8800d80-driver  # 包含驱动和固件
  ];
  
  # 启用 usb_modeswitch 来切换 USB 网卡模式
  hardware.enableRedistributableFirmware = true;
  services.udev.packages = [ pkgs.usb-modeswitch-data ];
  
  # 添加网络调试工具和编译工具
  environment.systemPackages = with pkgs; [
    usbutils
    pciutils
    iw
    wirelesstools
    usb-modeswitch
    gcc
    gnumake
    git
  ];
  
  # AIC8800 USB 模式切换规则
  services.udev.extraRules = ''
    # AIC8800 存储模式 -> 网卡模式
    SUBSYSTEM=="usb", ATTR{idVendor}=="a69c", ATTR{idProduct}=="5725", RUN+="${pkgs.usb-modeswitch}/bin/usb_modeswitch -v a69c -p 5725 -K"
  '';
  environment.etc."wifi/auth.sh" = {
    source = ../../scripts/auth.sh;
    mode = "0555";
  };

  systemd.services.corp-auth = {
    description = "Campus Wi-Fi bootstrap";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /etc/wifi/auth.sh";
    };
  };
}
