# AIC8800D80 WiFi Driver for NixOS

Linux kernel driver for AIC8800D80 chipset, supporting devices such as:
- Tenda U11 Pro
- AX913B

## Usage

### Option 1: As a NixOS Module (Recommended)

```nix
{
  imports = [
    # If from NUR:
    # inputs.nur.repos.YOUR_USERNAME.nixosModules.aic8800d80
    # Or local:
    ./aic8800d80-module.nix
  ];

  hardware.aic8800d80.enable = true;
}
```

### Option 2: Manual Configuration

```nix
{ config, pkgs, lib, ... }:
let
  aic8800d80-driver = config.boot.kernelPackages.callPackage ./aic8800d80-driver.nix { };
in
{
  boot.extraModulePackages = [ aic8800d80-driver ];
  hardware.firmware = [ aic8800d80-driver ];
  
  # USB mode switch (storage -> WiFi)
  hardware.enableRedistributableFirmware = true;
  services.udev = {
    packages = [ pkgs.usb-modeswitch-data ];
    extraRules = ''
      SUBSYSTEM=="usb", ATTR{idVendor}=="a69c", ATTR{idProduct}=="5725", \
        RUN+="${pkgs.usb-modeswitch}/bin/usb_modeswitch -v a69c -p 5725 -K"
    '';
  };
  
  # Firmware path compatibility (driver hardcodes /lib/firmware)
  system.activationScripts.aic8800-firmware = lib.mkAfter ''
    mkdir -p /lib
    ln -sfn /run/current-system/firmware /lib/firmware
  '';
}
```

## Configuration Options

When using the module:

```nix
hardware.aic8800d80 = {
  enable = true;
  
  usbModeSwitch = {
    enable = true;  # Auto-switch USB mode
    vendorId = "a69c";
    productId = "5725";
  };
};
```

## Notes

- The driver hardcodes `/lib/firmware` path, requiring a symlink to `/run/current-system/firmware`
- Tested on kernel 6.1 and 6.12
- Bluetooth functionality is not supported

## Files for NUR

- `aic8800d80-driver.nix` - Driver package
- `aic8800d80-module.nix` - NixOS module (optional but recommended)

## Credits

- Original driver: [shenmintao/aic8800d80](https://github.com/shenmintao/aic8800d80)
- NixOS packaging: Empathy
