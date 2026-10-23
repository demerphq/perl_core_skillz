# API and platform compatibility

## API availability and ppport

Check the target `perlapi` and the project's minimum Perl before using a new
function, macro, flag, or struct accessor. `perlguts` is explanatory and contains
internal material; `perlintern` is not the public extension contract. Even a
listed API can be experimental or deprecated. Prefer a supported operation
over direct SV bodies, parser layouts, or copied internal helpers.

If the distribution uses `ppport.h`, inspect its version and instructions:

```sh
perl ppport.h --api-info=sv_magicext
perl ppport.h --compat-version=5.16.0
```

Replace the example floor with the distribution's actual minimum. Review the
diagnostics against actual usage; a scanner is not a full C/XS semantic checker.
Use required `NEED_*` declarations before including `ppport.h` where its docs
require them. Prefer normal API short names so compatibility wrappers can work.

Generate a new header with `Devel::PPPort::WriteFile` when needed, recording the
generator version and checking the resulting diff and supported-version tests.
Ship the required header in the release rather than making ordinary consumers
regenerate it. Do not replace an existing header without reviewing local
configuration and effects. Hand-written `#ifndef` replacements can shadow real
functions and often miss semantic differences; use established backports first.

## C types and configuration

Use `IV`, `UV`, `NV`, `STRLEN`, and appropriate signed index/offset types for
their intended Perl values. `long`, `int`, pointers, and `size_t` do not have
universal relative sizes. Check ranges before narrowing or converting negative
values to unsigned counts. Validate `count * element_size` and terminator
addition before allocation. Use matching formatting macros such as `IVdf`,
`UVuf`, and `NVgf` for the actual types passed to variadic functions.

For pointer storage use documented conversion macros, but keep validity and
ownership checks separate. Avoid serializing pointers or native C struct
layouts. For binary formats use defined widths/endianness; native alignment and
padding vary (`perlpacktut`).

Use `Config` and the active builder for target features and compiler/linker
flags. Do not assume a function is available because the OS name resembles a
tested system. Feature tests should respect cross-compilation: running a target
executable during configuration is not always possible. Retain the project's
existing probe and override mechanisms.

Respect the distribution's C dialect/toolchain floor. Do not blindly import
core C-style restrictions or assume that a modern local compiler proves older
consumer toolchains support a new construct. Test external-library version
gates independently from Perl API gates.

## Characters, locale, platforms, and I/O

Use Perl's documented native-character and classification APIs for Perl
character semantics. A byte value, a native character ordinal, and a Unicode
code point are different domains. Do not introduce ASCII arithmetic, platform
endianness, signed-char assumptions, or byte-based classification of Unicode
text accidentally. Keep actual wire-format ASCII bytes explicit where that is
the protocol contract. Check `perlebcdic` for affected character operations.

Avoid process-global locale changes in library code. Choose locale-sensitive
versus invariant parsing/formatting deliberately and consult `perlclib` and
`perllocale` for safe interactions. Native-library locale/thread guarantees
remain relevant even when Perl data is interpreter-local.

Do not assume POSIX shells, fork, Unix signals, symlinks, slash-only paths, or
ELF shared libraries. Use established Perl/build-tool path and process helpers.
Use the configured dynamic/object suffixes and native toolchain; do not hard-code
`.so`, `.o`, or a Unix compiler command into a general build rule.

For Perl handles, use supported PerlIO APIs and preserve layers, buffering,
ownership, and close semantics. `PerlIO *` and `FILE *` are not interchangeable.
If a native API needs stdio or an fd, read `perlapio`'s conversion/release
contracts and determine whether a borrowed stream or duplicate is appropriate.
Direct fd operations can bypass PerlIO buffers and encoding layers. `perliol`
is chiefly relevant when implementing an actual PerlIO layer.

Choose tests for the changed axis: oldest supported Perl, current Perl,
threaded/non-threaded builds, integer width, native library versions, Windows
or other claimed platforms. Rebuild separately for each configuration. Do not
reuse a compiled extension based only on matching `$]` or `archname`.
