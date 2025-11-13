#!/usr/bin/env python3

"""
Update home/vscode/extensions/generated.nix from sources.json.

Usage:
  nix run .#update-vscode-extensions
  python scripts/update-vscode-extensions.py /path/to/repo
"""

from __future__ import annotations

import json
import subprocess
import sys
import urllib.request
from pathlib import Path
from typing import Iterable

MARKETPLACE_URL = "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
MARKETPLACE_HEADERS = {
  "Content-Type": "application/json",
  "Accept": "application/json;api-version=7.2-preview.1",
}


def resolve_repo_root() -> Path:
  if len(sys.argv) > 1:
    return Path(sys.argv[1]).resolve()
  return Path.cwd()


def load_sources(path: Path) -> list[dict]:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def encode_payload(publisher: str, name: str) -> bytes:
  payload = {
    "filters": [
      {
        "criteria": [
          {"filterType": 10, "value": "target:\"Microsoft.VisualStudio.Code\""},
          {"filterType": 7, "value": f"{publisher}.{name}"},
        ],
        "pageNumber": 1,
        "pageSize": 1,
        "sortBy": 0,
        "sortOrder": 0,
      }
    ],
    "flags": 914,
  }
  return json.dumps(payload).encode("utf-8")


def fetch_marketplace_version(publisher: str, name: str) -> tuple[str, str]:
  request = urllib.request.Request(
    MARKETPLACE_URL,
    data=encode_payload(publisher, name),
    headers=MARKETPLACE_HEADERS,
    method="POST",
  )
  with urllib.request.urlopen(request) as response:  # noqa: S310 (Marketplace is trusted)
    payload = json.load(response)

  extensions = payload["results"][0]["extensions"]
  if not extensions:
    raise RuntimeError(f"Marketplace entry {publisher}.{name} not found")
  latest = extensions[0]["versions"][0]
  version = latest["version"]
  try:
    vsix_url = next(
      f["source"]
      for f in latest["files"]
      if f["assetType"] == "Microsoft.VisualStudio.Services.VSIXPackage"
    )
  except StopIteration as exc:
    raise RuntimeError(f"VSIX package not found for {publisher}.{name}") from exc
  return version, vsix_url


def nix_prefetch(url: str) -> str:
  result = subprocess.run(
    ["nix-prefetch-url", "--type", "sha256", url],
    check=True,
    capture_output=True,
    text=True,
  )
  base32 = result.stdout.strip().splitlines()[0]
  sri = subprocess.run(
    ["nix", "hash", "to-sri", "--type", "sha256", base32],
    check=True,
    capture_output=True,
    text=True,
  )
  return sri.stdout.strip()


def nix_escape(value: str) -> str:
  escaped = value.replace("\\", "\\\\").replace('"', '\\"')
  return f"\"{escaped}\""


def render_entries(entries: Iterable[dict]) -> str:
  lines = ["["]
  for entry in entries:
    lines.extend(
      [
        "  {",
        f"    publisher = {nix_escape(entry['publisher'])};",
        f"    name = {nix_escape(entry['name'])};",
        f"    version = {nix_escape(entry['version'])};",
        f"    sha256 = {nix_escape(entry['sha256'])};",
        "  }",
      ]
    )
  lines.append("]")
  return "\n".join(lines) + "\n"


def main() -> None:
  root = resolve_repo_root()
  sources_path = root / "home/vscode/extensions/sources.json"
  generated_path = root / "home/vscode/extensions/generated.nix"

  specs = load_sources(sources_path)
  entries = []
  for spec in specs:
    publisher = spec["publisher"]
    name = spec["name"]
    spec_type = spec.get("type", "marketplace")

    if spec_type != "marketplace":
      raise RuntimeError(
        f"Unsupported extension type '{spec_type}' for {publisher}.{name}. "
        "Only marketplace entries are handled automatically."
      )

    version, url = fetch_marketplace_version(publisher, name)
    sha256 = nix_prefetch(url)
    entries.append(
      {
        "publisher": publisher,
        "name": name,
        "version": version,
        "sha256": sha256,
      }
    )
    print(f"✔ {publisher}.{name} @ {version}", file=sys.stderr)

  generated_path.write_text(render_entries(entries), encoding="utf-8")
  print(f"Updated {generated_path}", file=sys.stderr)


if __name__ == "__main__":
  main()
