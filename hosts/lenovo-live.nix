{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    ./devbox.nix
    ./lenovo.nix
  ];

  isoImage = {
    makeEfiBootable = true;
    makeUsbBootable = true;
  };
}
