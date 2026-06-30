{
  lib,
  inputs ? { },
  ...
}:
let
  obsidianSkills =
    inputs.obsidian-skills or (throw "The obsidian-skills flake input is required for agent skills");

  codexSkillNames = [
    "defuddle"
    "json-canvas"
    "obsidian-bases"
    "obsidian-cli"
    "obsidian-markdown"
  ];
in
{
  home.file =
    (lib.genAttrs (map (name: ".codex/skills/${name}") codexSkillNames) (
      target:
      let
        name = builtins.baseNameOf target;
      in
      {
        source = "${obsidianSkills}/skills/${name}";
      }
    ))
    // {
      ".opencode/skills/obsidian-skills".source = obsidianSkills;
    };
}
