{
  stdenv,
  lib,
  fetchFromGitHub,
  kernel,
}:

stdenv.mkDerivation {
  pname = "aic8800d80-driver";
  version = "unstable-2024-12-18";

  src = fetchFromGitHub {
    owner = "shenmintao";
    repo = "aic8800d80";
    rev = "f834c8fd58f534967873b90547edd8745c544ca5";
    hash = "sha256-s7eAqdBk/+ds0oVTwf0Sn+cIb9TecmOZOpWR3MYNrSo=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;
  hardeningDisable = [ "pic" "format" ];
  
  # 禁用固件压缩（驱动不支持压缩固件）
  compressFirmware = false;

  preBuild = ''
    cd drivers/aic8800
  '';

  makeFlags = [ "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build" ];

  installPhase = ''
    runHook preInstall
    
    # 安装内核模块
    install -Dm644 -t $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/wireless/aic8800 \
      $(find . -name '*.ko')
    
    # 安装固件文件
    cp -r ../../fw/aic8800D80 $out/lib/firmware/
    
    runHook postInstall
  '';

  meta = {
    description = "AIC8800D80 WiFi driver for Linux";
    longDescription = ''
      Kernel driver for AIC8800D80 chipset, used in devices such as:
      - Tenda U11 Pro
      - AX913B
    '';
    homepage = "https://github.com/shenmintao/aic8800d80";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
}
