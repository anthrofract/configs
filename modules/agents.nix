{ inputs, ... }:
{
  flake.commonModules.agents =
    {
      pkgs,
      lib,
      latestPkgs,
      hostName,
      ...
    }:
    {
      environment.systemPackages = [
        latestPkgs.antigravity-cli
        latestPkgs.claude-code
        latestPkgs.codex
        inputs.autolith.packages.${pkgs.stdenv.hostPlatform.system}.default
        latestPkgs.omp
      ];

      home-manager.sharedModules = [
        {
          home.file.".omp/agent/agents/reviewer-secondary.md".source =
            pkgs.runCommand "reviewer-secondary.md" { }
              ''
                substitute \
                  ${latestPkgs.omp.src}/packages/coding-agent/src/prompts/agents/reviewer.md \
                  "$out" \
                  --replace-fail 'name: reviewer' 'name: reviewer-secondary' \
                  --replace-fail 'model: "@slow"' 'model: openai-codex/gpt-6.2-astra:high'
              '';
          home.file.".omp/agent/SYSTEM_TEMPLATE.md".source = pkgs.runCommand "omp-system-template.md" { } ''
            patch --fuzz=0 -o "$out" \
              ${latestPkgs.omp.src}/packages/coding-agent/src/prompts/system/system-prompt.md \
              < ${./agents/omp-system-prompt.patch}
            printf '\n# Host\nHostname: %s\n' ${lib.escapeShellArg hostName} >> "$out"
          '';
          home.file.".omp/agent/skills/nushell".source = pkgs.runCommand "nushell-skill" { } ''
            cp -r ${inputs.nu-scripts}/skills/nushell "$out"
            chmod -R u+w "$out"
            cp ${pkgs.nushell.src}/crates/nu-mcp/src/instructions.md \
              "$out/references/mcp-server-instructions.md"
            substituteInPlace "$out/SKILL.md" \
              --replace-fail 'mcp__nushell__' 'xd://mcp__nushell_' \
              --replace-fail 'instead of stdio |' 'instead of stdio |
            | [mcp-server-instructions.md](references/mcp-server-instructions.md) | The full instructions the MCP server sends: `$history`, output limits, background jobs. On MCP behavior they take precedence over this skill |' \
              --replace-fail '- Use `| to text` or `| to json` for large outputs.' '- Slice large results from `$history` instead of capping or converting the live pipeline.'
          '';
        }
      ];
    };
}
