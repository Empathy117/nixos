{ pkgs, config, ... }:
{
  hardware.firmware = [
    pkgs.linux-firmware
    pkgs.rtl8761fw
  ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ rtl8812au-aircrack ];
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="1a2b", ENV{UDISKS_IGNORE}="1", ENV{UDISKS_AUTO}="0"
  '';
  environment.etc."wifi/auth.sh" = {
    source = ../scripts/auth.sh;
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
