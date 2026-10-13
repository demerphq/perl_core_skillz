# XPerl Agent Skills

This package supplements the generic skills in `../perl_agents/skills/`.
Its canonical source is the `xperl-*` skills under `perl/.agents/skills/`.

Use these skills for XPerl's structured exception and diagnostic APIs.
They do not describe ordinary Perl exception handling.

From the repository root, synchronize or check both packages with:

```sh
./sync-agent-skills --sync --xperl
./sync-agent-skills --check --xperl
```

To restore an XPerl checkout, add `--from-mirror` and its path. Generic
restoration omits this package.
