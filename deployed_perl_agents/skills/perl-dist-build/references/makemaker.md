# ExtUtils::MakeMaker

Consult `perldoc ExtUtils::MakeMaker` and
`perldoc ExtUtils::MakeMaker::Tutorial` for the version actually used.
`Makefile.PL` supplies inputs to `WriteMakefile`; the generated `Makefile` is
local build state. Inspect `MY::` overrides and postamble targets before
changing a build rule.

## Configure, build, and test

For a conventional project, with `perl` resolving to the selected interpreter:

```sh
perl Makefile.PL
make
make test TEST_FILES=t/regression.t TEST_VERBOSE=1
make test
```

Here `make` means the make program compatible with this Perl's configuration,
which may be `gmake`, `dmake`, or `nmake`. Read it with
`perl -MConfig -e 'print "$Config{make}\n"'`; do not assume GNU-specific syntax
in custom targets. Use the project's documented invocation when it differs.

For direct debugging after building:

```sh
perl -Mblib t/regression.t
```

Changing the selected Perl requires a fresh configuration and rebuild, ideally
in a separate build directory or checkout. Old object files and shared libraries
can appear to build successfully while belonging to a different interpreter.

## Attributes that need careful handling

| Input | Decision |
| --- | --- |
| `NAME`, `VERSION_FROM`, `XS_VERSION` | Keep package, bootstrap symbol, Perl version value, and native version check consistent. Do not bypass a mismatch. |
| `CONFIGURE_REQUIRES` | Dependencies loaded by `Makefile.PL`, including its minimum MakeMaker. They also need to appear in release metadata. |
| `BUILD_REQUIRES` | Modules used to build, not needed by installed runtime code. |
| `TEST_REQUIRES` | Modules actually used by ordinary tests, with feature-appropriate minimum versions. |
| `PREREQ_PM` | Runtime module requirements. |
| `MIN_PERL_VERSION` | The supported interpreter floor; source syntax and dependency versions must agree. |
| `XS`, `TYPEMAPS` | Map XS inputs to generated C and supply local conversion rules. Inspect the actual `xsubpp` command. |
| `OBJECT`, `depend` | Link all intended object files and rebuild when local headers or generated includes change. Use make's portable object extension variables. |
| `INC`, `DEFINE` | Header search paths and defines; keep project and user configuration intact. |
| `LIBS` | Each array element is an alternative complete link specification. To link both foo and bar, use `['-lfoo -lbar']`, not `['-lfoo', '-lbar']`. |
| `META_MERGE` | Merge authoring metadata through the supported schema instead of editing generated JSON/YAML. |

Attributes have minimum MakeMaker versions. For example, `TEST_REQUIRES` needs
6.64 or later; check before adding it to a distribution supporting older
toolchains. Prefer a declared tool requirement or the project's established
compatibility handling rather than silently dropping dependency declarations.

Overriding `CCFLAGS` replaces its configured value: preserve relevant defaults
when adding flags. Do not assume selecting a C++ compiler also selects a
compatible linker and runtime. Keep native library detection in the existing
build mechanism and report missing headers/libraries usefully.

Nested test directories are not necessarily included by the default `t/*.t`
pattern. Check `test => { TESTS => ... }` and confirm the new regression test
actually runs through `make test`.

## Distribution targets

Use `make distcheck` to compare files with `MANIFEST`; inspect `MANIFEST.SKIP`.
`make manifest` can add unintended working files, so review its output rather
than accepting every discovered file. Core-specific manifest sorting is not a
MakeMaker distribution requirement.

`make disttest` builds and tests a fresh distribution directory from the
manifest; `make dist` creates an archive. These targets can invoke custom hooks
and replace an existing distribution directory, so inspect overrides first.
For an archive regression, unpack the produced archive into a separate temporary
directory and run the ordinary build/test there as well.

`INSTALL_BASE` chooses an installation prefix; `DESTDIR` stages an installation
under a packaging root. They solve different problems. Neither is needed for
normal `blib` testing. Do not use `make install` to work around test path errors.
