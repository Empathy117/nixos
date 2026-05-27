#!/usr/bin/env nix
/* #!nix shell --ignore-environment .#cacert .#nodejs --command node */
// @ts-check

import assert from "node:assert/strict";
import * as fs from "node:fs";
import * as path from "node:path";

/**
 * @typedef {object} Manifest
 * @property {string} version
 * @property {string} url
 * @property {string} sha512
 */

/**
 * @typedef {object} Source
 * @property {string} url
 * @property {string} sha256
 */

/**
 * @typedef {object} Information
 * @property {string} version
 * @property {Record<string, Source>} sources
 */

const baseUrl =
    "https://antigravity-cli-auto-updater-974169037036.us-central1.run.app";

let version = "";

/**
 * @param {"linux_amd64" | "linux_arm64" | "darwin_amd64" | "darwin_arm64"} targetPlatform
 * @returns {Promise<Source>}
 */
async function getLatestInformation(targetPlatform) {
    /** @type {Manifest} */
    const manifest = await (
        await fetch(`${baseUrl}/manifests/${targetPlatform}.json`)
    ).json();

    assert(manifest.version, `Missing version for ${targetPlatform}`);
    assert(manifest.url, `Missing url for ${targetPlatform}`);

    assert(
        version === "" || version === manifest.version,
        `Version mismatch: ${version} != ${manifest.version} (${targetPlatform})`,
    );

    version = manifest.version;

    const response = await fetch(manifest.url);
    assert(
        response.ok,
        `Failed to download ${manifest.url}: ${response.status} ${response.statusText}`,
    );

    const buffer = Buffer.from(await response.arrayBuffer());
    const hashBuffer = await crypto.subtle.digest("SHA-256", buffer);
    const sha256 = Buffer.from(hashBuffer).toString("hex");

    return {
        url: manifest.url,
        sha256,
    };
}

/** @type {Information["sources"]} */
const sources = {
    "x86_64-linux": await getLatestInformation("linux_amd64"),
    "aarch64-linux": await getLatestInformation("linux_arm64"),
    "x86_64-darwin": await getLatestInformation("darwin_amd64"),
    "aarch64-darwin": await getLatestInformation("darwin_arm64"),
};

/** @type {Information} */
const information = {
    version,
    sources,
};

fs.writeFileSync(
    path.join(import.meta.dirname, "./information.json"),
    JSON.stringify(information, null, 2) + "\n",
    "utf-8",
);

console.log(`[update] Updating antigravity-cli complete, version: ${version}`);