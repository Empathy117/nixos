# NixOS 模块：AIC8800D80 无线网卡支持
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hardware.aic8800d80;
  
  aic8800d80-driver = config.boot.kernelPackages.callPackage ./aic8800d80-driver.nix { };
in
{
  options.hardware.aic8800d80 = {
    enable = lib.mkEnableOption "AIC8800D80 WiFi driver support (Tenda U11 Pro, AX913B)";
    
    usbModeSwitch = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Automatically switch USB device from storage mode to WiFi mode";
      };
      
      vendorId = lib.mkOption {
        type = lib.types.str;
        default = "a69c";
        description = "USB Vendor ID in storage mode";
      };
      
      productId = lib.mkOption {
        type = lib.types.str;
        default = "5725";
        description = "USB Product ID in storage mode";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # 内核模块和固件
    boot.extraModulePackages = [ aic8800d80-driver ];
    hardware.firmware = [ aic8800d80-driver ];
    
    # USB 模式切换
    hardware.enableRedistributableFirmware = true;
    services.udev = lib.mkIf cfg.usbModeSwitch.enable {
      packages = [ pkgs.usb-modeswitch-data ];
      extraRules = ''
        SUBSYSTEM=="usb", ATTR{idVendor}=="${cfg.usbModeSwitch.vendorId}", \
          ATTR{idProduct}=="${cfg.usbModeSwitch.productId}", \
          RUN+="${pkgs.usb-modeswitch}/bin/usb_modeswitch -v ${cfg.usbModeSwitch.vendorId} -p ${cfg.usbModeSwitch.productId} -K"
      '';
    };
    
    # 固件路径兼容性（驱动硬编码 /lib/firmware）
    # 警告：这会在根目录创建 /lib，可能与某些系统冲突
    system.activationScripts.aic8800-firmware = lib.mkAfter ''
      mkdir -p /lib
      ln -sfn /run/current-system/firmware /lib/firmware
    '';
    
    # 推荐的网络工具
    environment.systemPackages = with pkgs; [
      iw
      wirelesstools
    ];
  };
}
