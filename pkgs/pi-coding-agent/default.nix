{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  stdenv,
}:
let
  version = "0.85.1";

  sources = {
    aarch64-darwin = {
      file = "pi-darwin-arm64.tar.gz";
      hash = "sha256-1fcOPAz3OY6sI5/QJh7gdNmLe6f2tD/jYX8FLtW3nQY=";
    };
    x86_64-darwin = {
      file = "pi-darwin-x64.tar.gz";
      hash = "sha256-rbkYuEViXxhNi+pAjVXqyvIaqHI4eTwPW087lze85is=";
    };
    x86_64-linux = {
      file = "pi-linux-x64.tar.gz";
      hash = "sha256-SU5Jj0fXTSH0CzOG9qXpIaPUlTGhacq1W72soOof4lo=";
    };
    aarch64-linux = {
      file = "pi-linux-arm64.tar.gz";
      hash = "sha256-BC0grohe5POxAoFfMoC5YsN3sun7RN5AN5CMxTDq5NQ=";
    };
  };

  inherit (stdenvNoCC.hostPlatform) system;
  source = sources.${system} or (throw "pi-coding-agent: unsupported system ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "pi-coding-agent";
  inherit version;

  src = fetchurl {
    url = "https://github.com/earendil-works/pi/releases/download/v${version}/${source.file}";
    inherit (source) hash;
  };

  sourceRoot = "pi";

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  # Prebuilt bundle: the `pi` executable resolves its assets (theme/, native/,
  # node_modules/, wasm) relative to the directory it lives in, so keep the
  # release tree intact and only link the entrypoint into $out/bin.
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/pi" "$out/bin"
    cp -r . "$out/share/pi"
    chmod +x "$out/share/pi/pi"
    ln -s "$out/share/pi/pi" "$out/bin/pi"

    runHook postInstall
  '';

  meta = {
    description = "Self-extensible interactive coding agent CLI";
    homepage = "https://pi.dev";
    changelog = "https://github.com/earendil-works/pi/releases/tag/v${version}";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "pi";
    platforms = lib.attrNames sources;
  };
}
