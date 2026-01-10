{ pkgs, lib }:
let
  mkZipApp =
    {
      pname,
      version,
      url,
      hash,
      appName,
      binLinks ? [ ],
    }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname version;

      src = pkgs.fetchurl {
        inherit url hash;
      };

      nativeBuildInputs = [
        pkgs.unzip
      ];

      unpackPhase = ''
        runHook preUnpack
        unzip -qq "$src"
        runHook postUnpack
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p "$out/Applications"

        app=$(find . -maxdepth 3 -name "${appName}" -print -quit)
        if [ -z "$app" ]; then
          echo "Expected ${appName}, but it was not found in the zip."
          find . -maxdepth 3 -name '*.app' -print
          exit 1
        fi

        cp -R "$app" "$out/Applications/${appName}"

        mkdir -p "$out/bin"
        ${lib.concatMapStringsSep "\n" (
          link:
          ''
            target="$out/Applications/${appName}/${link.path}"
            if [ ! -e "$target" ]; then
              echo "Expected ${link.name} target at $target, but it was not found."
              exit 1
            fi
            ln -s "$target" "$out/bin/${link.name}"
          ''
        ) binLinks}
        runHook postInstall
      '';

      dontFixup = true;
      meta.platforms = lib.platforms.darwin;
    };

  mkDmgApp =
    {
      pname,
      version,
      src ? null,
      url ? null,
      hash ? null,
      appName,
      binLinks ? [ ],
    }:
    assert (src != null) || ((url != null) && (hash != null));
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname version;

      src =
        if src != null then
          src
        else
          pkgs.fetchurl {
            inherit url hash;
          };

      nativeBuildInputs = [
        pkgs.undmg
      ];

      unpackPhase = ''
        runHook preUnpack
        if ! undmg "$src"; then
          echo "undmg failed; falling back to hdiutil (APFS DMG?)"

          (
            set -euo pipefail
            mnt=$(TMPDIR=/tmp mktemp -d -t nix-XXXXXXXXXX)
            finish() {
              /usr/bin/hdiutil detach "$mnt" -force >/dev/null 2>&1 || true
              rm -rf "$mnt"
            }
            trap finish EXIT

            /usr/bin/hdiutil attach -nobrowse -readonly -mountpoint "$mnt" "$src" >/dev/null

            app=$(find "$mnt" -maxdepth 3 -name "${appName}" -print -quit)
            if [ -z "$app" ]; then
              echo "Expected ${appName}, but it was not found in the dmg."
              find "$mnt" -maxdepth 3 -name '*.app' -print
              exit 1
            fi

            cp -a "$app" .
          )
        fi
        runHook postUnpack
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p "$out/Applications"

        app=$(find . -maxdepth 3 -name "${appName}" -print -quit)
        if [ -z "$app" ]; then
          echo "Expected ${appName}, but it was not found in the dmg."
          find . -maxdepth 3 -name '*.app' -print
          exit 1
        fi

        cp -R "$app" "$out/Applications/${appName}"

        mkdir -p "$out/bin"
        ${lib.concatMapStringsSep "\n" (
          link:
          ''
            target="$out/Applications/${appName}/${link.path}"
            if [ ! -e "$target" ]; then
              echo "Expected ${link.name} target at $target, but it was not found."
              exit 1
            fi
            ln -s "$target" "$out/bin/${link.name}"
          ''
        ) binLinks}
        runHook postInstall
      '';

      dontFixup = true;
      meta.platforms = lib.platforms.darwin;
    };
in
{
  inherit mkZipApp mkDmgApp;
}
