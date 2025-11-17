{ stdenv, lib, fetchFromGitHub, kernel, kmod }:

stdenv.mkDerivation rec {
  pname = "aic8800d80-driver";
  version = "unstable-2024-12-18";

  src = fetchFromGitHub {
    owner = "shenmintao";
    repo = "aic8800d80";
    rev = "f834c8fd58f534967873b90547edd8745c544ca5";
    sha256 = lib.fakeSha256;
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    "KSRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  hardeningDisable = [ "pic" "format" ];

  buildPhase = ''
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$(pwd) modules
  '';

  installPhase = ''
    mkdir -p $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/wireless
    find . -name '*.ko' -exec cp {} $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/wireless/ \;
  '';

  meta = with lib; {
    description = "AIC8800D80 WiFi driver for Linux";
    homepage = "https://github.com/shenmintao/aic8800d80";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
