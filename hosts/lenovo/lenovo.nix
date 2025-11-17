{
  pkgs,
  pkgsUnstable,
  config,
  ...
}:
let
  aic8800-driver = config.boot.kernelPackages.callPackage ./aic8800-driver.nix { };
in
{
  hardware.firmware = [
    pkgs.linux-firmware
  ];
  
  boot.kernelPackages = pkgs.linuxPackages;
  
  boot.extraModulePackages = [
    aic8800-driver
  ];
  
  # 启用 usb_modeswitch 来切换 USB 网卡模式
  hardware.enableRedistributableFirmware = true;
  services.udev.packages = [ pkgs.usb-modeswitch-data ];
  
  # 添加网络调试工具和编译工具
  environment.systemPackages = with pkgs; [
    usbutils # lsusb
    pciutils # lspci
    iw # 无线网络工具
    wirelesstools # iwconfig 等
    gcc
    gnumake
    git
    config.boot.kernelPackages.kernel.dev
    pkgs.linuxPackages_6_6.kernel.dev # kernel headers
  ];
  
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="1a2b", ENV{UDISKS_IGNORE}="1", ENV{UDISKS_AUTO}="0"
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
