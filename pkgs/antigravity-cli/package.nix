{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

let
  inherit (stdenv) hostPlatform;
  information = lib.importJSON ./information.json;
  source =
    information.sources.${hostPlatform.system}
      or (throw "antigravity-cli: unsupported system ${hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "antigravity-cli";
  inherit (information) version;

  src = fetchurl {
    inherit (source) url sha256;
  };

  nativeBuildInputs = lib.optionals hostPlatform.isLinux [
    autoPatchelfHook
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 antigravity $out/bin/agy

    runHook postInstall
  '';

  passthru.updateScript = ./update.js;

  meta = {
    description = "Google Antigravity CLI";
    homepage = "https://antigravity.google";
    downloadPage = "https://antigravity.google/download";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "agy";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
}