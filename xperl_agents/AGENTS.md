# XPerl Agent Guidance

Read `../perl_agents/AGENTS.md` for the generic Perl-core guidance. This
package adds instructions for XPerl's exception and diagnostic implementation.

Use the skills under `skills/` only for an XPerl checkout with the structured
exception implementation. Do not apply its exception APIs, diagnostic catalog,
or migration requirements to an ordinary Perl checkout.

The canonical skill source is `../../perl/.agents/skills/`, where these skills
have `xperl-*` names. Make substantive updates there first, then run
`./sync-agent-skills --sync --xperl` from the repository root. Verify with
`./sync-agent-skills --check --xperl`.
