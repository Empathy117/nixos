{ stdenv, lib, fetchFromGitHub, kernel }:

stdenv.mkDerivation rec {
  pname = "aic8800d80-driver";
  version = "unstable-2024-12-18";

  src = fetchFromGitHub {
    owner = "shenmintao";
    repo = "aic8800d80";
    rev = "f834c8fd58f534967873b90547edd8745c544ca5";
    sha256 = "sha256-s7eAqdBk/+ds0oVTwf0Sn+cIb9TecmOZOpWR3MYNrSo=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  hardeningDisable = [ "pic" "format" ];

  preBuild = ''
    cd drivers/aic8800
  '';

  makeFlags = [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  installPhase = ''
    # 安装内核模块
    mkdir -p $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/wireless/aic8800
    find . -name '*.ko' -exec cp {} $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/wireless/aic8800/ \;
    
    # 安装固件
    mkdir -p $out/lib/firmware
    cp -r ../../fw/aic8800D80 $out/lib/firmware/
  '';

  meta = with lib; {
    description = "AIC8800D80 WiFi driver for Linux (Tenda U11, AX913B)";
    homepage = "https://github.com/shenmintao/aic8800d80";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
