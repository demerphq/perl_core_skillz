# Prerequisites and release contents

## Find the source of truth

Projects may maintain `Makefile.PL`/`Build.PL` directly or generate them using
Dist::Zilla, Module::Install, or another authoring tool. Inspect project
configuration and contributor docs. Fix maintained inputs and regenerate with
the established tool; do not introduce a new release system for a narrow fix.

An ordinary user should be able to build from the released files without the
author's checkout, Git history, private paths, or author-only modules. If a
generator is required during consumer builds, declare its dependency in the
correct phase. If its output is shipped instead, validate that output and its
regeneration procedure. Include needed typemaps, `ppport.h`, native headers,
generated constant includes, test data, and native sources.

## Metadata

`META.json`/`META.yml` describe the release before configuration;
`MYMETA.json`/`MYMETA.yml` describe the locally configured instance. Do not ship
one developer's `MYMETA` as release metadata. A configure dependency cannot be
bootstrapped merely by discovering it halfway through `Makefile.PL` or
`Build.PL`.

Use the metadata fields emitted by the selected builder for configure, build,
test, and runtime prerequisites. Include the actual modules imported by tests,
such as `Test::More` or the chosen Test2 bundle, rather than only a distribution
name such as Test2::Suite. Choose versions for features used; do not assume a
module is present because it ships with the development Perl.

Declare native libraries and compiler requirements in user-facing installation
docs and existing detection logic. A Perl prerequisite declaration alone does
not install a system library. Preserve optional-feature behavior and distinguish
missing optional capabilities from a broken required installation.

Inspect emitted metadata for minimum Perl, prerequisites, version, license,
abstract, resources, and indexing exclusions when those are changed. Use
`CPAN::Meta` validation or the project's metadata tests. Distinguish author and
release tests from the default consumer suite; network access, credentials,
spelling tools, and arbitrary installed developer utilities are not ordinary
runtime or test prerequisites.

## Validate what users receive

1. Check the project's manifest or generated file-list mechanism. Review added
   files and skip patterns; avoid shipping build debris or omitting fixtures.
2. Create the release directory/archive through the existing build tool.
3. Build and test in a fresh extracted directory, using the selected Perl.
   Confirm no accidental path back to the author checkout supplies missing data.
4. For prerequisite changes, use an isolated environment containing declared
   dependencies when available. A developer environment with extra modules is
   weaker evidence; state that limitation.

Read `ExtUtils::Manifest`, `CPAN::Meta::Spec`, and the active builder's
distribution documentation for exact behavior. Preserve the distribution's
versioning, changelog, and release policies. Preparing an archive is separate
from uploading it or registering a namespace.
