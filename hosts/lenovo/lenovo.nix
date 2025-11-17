{
  pkgs,
  config,
  ...
}:
let
  aic8800d80-driver = config.boot.kernelPackages.callPackage ./aic8800d80-driver.nix { };
in
{
  imports = [
    ./hardware-configuration.nix
  ];
  hardware.firmware = [
    pkgs.linux-firmware
    aic8800d80-driver
  ];
  networking.networkmanager.enable = true;
  boot.kernelPackages = pkgs.linuxPackages;
  boot.extraModulePackages = [
    aic8800d80-driver
  ];

  environment.systemPackages = with pkgs; [
    usbutils
    pciutils
    iw
    wirelesstools
    usb-modeswitch
    gcc
    gnumake
    config.boot.kernelPackages.kernel.dev
    wpa_supplicant
  ];

  services.mihomo = {
    enable = true;
    configFile = "/etc/mihomo/config.yaml";
    tunMode = false;
  };
  # environment.etc."mihomo/config.yaml".text = ''
  #   # placeholder – scp your real config to /etc/mihomo/config.yaml
  # '';
  environment.etc."mihomo/config.yaml".source = "/home/empathy/.mihomo/config.yaml";
  services.mihomo.webui = pkgs.metacubexd;

  hardware.enableRedistributableFirmware = true;
  services.udev.packages = [ pkgs.usb-modeswitch-data ];
  system.activationScripts.auc8800D80-firmware = ''
    mkdir -p /lib
    ln -sfn /run/current-system/firmware /lib/firmware
  '';
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="a69c", ATTR{idProduct}=="5725", RUN+="${pkgs.usb-modeswitch}/bin/usb_modeswitch -v a69c -p 5725 -K"
  '';

  networking.firewall = {
    enable = true; # 如果原来就是 true 可不写
    allowedTCPPorts = [
      7890   # mixed port
      9090   # mihomo 控制端（Web UI）
      8081   # nexus
    ];
    # allowedUDPPorts = [ 7890 ];  # 需要 UDP 时再开启
  };
}
