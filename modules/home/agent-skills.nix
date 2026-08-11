{
  lib,
  inputs ? { },
  ...
}:
let
  obsidianSkills =
    inputs.obsidian-skills or (throw "The obsidian-skills flake input is required for agent skills");

  upstreamSkillNames = [
    "defuddle"
    "json-canvas"
    "obsidian-bases"
    "obsidian-markdown"
  ];

  localSkillNames = [ "obsidian-runtime" ];

  targetsFor =
    names:
    lib.concatMap (name: [
      ".codex/skills/${name}"
      ".opencode/skills/${name}"
    ]) names;
in
{
  home.file =
    (lib.genAttrs (targetsFor upstreamSkillNames) (
      target:
      let
        name = builtins.baseNameOf target;
      in
      {
        source = "${obsidianSkills}/skills/${name}";
      }
    ))
    // (lib.genAttrs (targetsFor localSkillNames) (
      target:
      let
        name = builtins.baseNameOf target;
      in
      {
        source = ../../skills + "/${name}";
      }
    ));
}
