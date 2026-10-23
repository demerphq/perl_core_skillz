# Module::Build

Use `perldoc Module::Build`, `Module::Build::Authoring`, `Module::Build::API`,
and `Module::Build::Cookbook` from the selected environment. Inspect which class
`Build.PL` actually uses. Do not apply these internals to `Module::Build::Tiny`
or assume an existing `Makefile.PL` is an independent maintained build driver.

## Build and test

For a conventional Module::Build project:

```sh
perl Build.PL
perl Build
perl Build test --test_files t/regression.t --verbose 1
perl Build test
```

Use the same selected Perl throughout. `Build` and `_build/` hold generated,
interpreter-specific state. Reconfigure and rebuild separately when switching
Perls. `perl Build` avoids relying on executable suffix/shebang behavior.

`test_files` selects focused files. Check `recursive_test_files`, `test_files`,
and custom actions before assuming a nested test is discovered by the full
suite. Run the normal action after direct debugging with `perl -Mblib`.

## Authoring inputs

| Property | Use |
| --- | --- |
| `module_name`, `dist_version_from` | Identify the distribution and the maintained version source. |
| `configure_requires` | Modules needed before `Build.PL` executes, including its builder class. |
| `build_requires` | Build tools; XS projects should declare `ExtUtils::CBuilder` here. |
| `test_requires` | Modules needed by ordinary tests; available since Module::Build 0.4004. |
| `requires` | Runtime modules and the `perl` version requirement. |
| `xs_files` | Map maintained XS files to their build locations when defaults are insufficient. |
| `c_source` | Additional directories containing native sources compiled for the extension. |
| `include_dirs` | Additional header search directories. |
| `extra_compiler_flags`, `extra_linker_flags` | Additional native flags using the selected Perl's toolchain. |

Check property availability against the declared builder version. A module
required by a custom builder at configuration time belongs in configure
requirements even if it also participates in later actions. Generated
`ConfigData` is configuration output; change its inputs.

## Custom builders and release actions

Existing custom `ACTION_*` methods can add generation, native detection, or
test setup. Preserve their dependencies and superclass behavior. Use the
builder's dispatch/dependency mechanisms rather than bypassing stages through
handwritten shell commands. Restore the original distribution directory when
an action temporarily changes directories.

`perl Build distcheck` checks distribution contents; `perl Build disttest`
tests a distribution directory; `perl Build dist` builds the archive. Confirm
custom actions before invoking them and check the final unpacked archive for
packaging changes. Generated scripts, `_build`, `blib`, objects, and local
`MYMETA` normally do not belong in release contents.

`install_base` controls installation layout; `destdir` stages installation.
Use build-tree tests without installing for routine development. A system
installation is not a prerequisite to debug an extension.
