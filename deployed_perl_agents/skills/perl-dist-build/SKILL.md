---
name: perl-dist-build
description: "Build, package, or repair a Perl module distribution using an installed Perl, including ExtUtils::MakeMaker, Module::Build, XS compilation, prerequisite metadata, and release archives."
---

# Perl distribution builds

Follow the project's existing authoring toolchain. Inspect `Makefile.PL`,
`Build.PL`, release configuration, metadata, and CI to distinguish maintained
inputs from generated release files. Do not migrate build systems as a side
effect of a module fix.

1. Select one Perl explicitly. Record `$^X`, its `Config`, and the build tool
   version. Use that interpreter for configuration, generation, and tests;
   resolve its configured make program for MakeMaker projects.
2. Build before testing XS. Test from `blib/lib` and `blib/arch` or through
   the project's build driver, and verify the loaded `.pm` and native library
   belong to this build when diagnosing surprising results.
3. Declare prerequisites at the phase that uses them. Modules loaded while
   configuring must be available before build/test prerequisites can help.
   Inspect emitted metadata as well as the source declaration.
4. Change XS inputs, typemaps, generator inputs, or build configuration rather
   than patching derived C, Makefiles, or local configuration caches. Rebuild
   affected targets; verify header and typemap dependencies when incremental
   builds leave stale results.
5. For packaging changes, build and test the release contents in a fresh
   directory. A successful working-tree test does not establish that required
   files, generated includes, or prerequisites reach the archive.

Read only the applicable driver reference:

- [makemaker.md](references/makemaker.md): `WriteMakefile`, native linking,
  MakeMaker tests and distribution targets.
- [module-build.md](references/module-build.md): `Module::Build` properties,
  actions, custom builders and XS files. `Module::Build::Tiny` is a different
  implementation; use its own documentation when it owns `Build.PL`.
- [release-contents.md](references/release-contents.md): prerequisites,
  metadata, manifests, generated files, and archive validation.

Build and test locally without installing over an existing module. Uploading
to CPAN, publishing tags, or changing an installation requires the corresponding
user request; building an archive alone does not require publishing it.
