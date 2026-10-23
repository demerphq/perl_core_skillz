# Running tests and diagnosing XS failures

## Use the build under test

For a conventional MakeMaker project, configure and build first with the chosen
Perl and its compatible make, then run:

```sh
make test TEST_FILES=t/regression.t TEST_VERBOSE=1
make test
```

For Module::Build:

```sh
perl Build test --test_files t/regression.t --verbose 1
perl Build test
```

For direct investigation after building:

```sh
perl -Mblib t/regression.t
prove -bv t/regression.t
```

`prove` must use the selected interpreter too; its shebang can point to another
Perl. Use that environment's `prove` or its documented `--exec` override. `-b`
adds `blib/lib` and `blib/arch`; `-l` adds only `lib` and can pair edited Perl
code with an old installed extension. When loading is suspect, inspect `$^X`,
`@INC`, `%INC`, and the loader/native library paths. Build drivers may provide
extra test setup that a direct invocation lacks.

Check discovery: a focused invocation can run a file that the default suite
never finds, especially under nested directories. Run the ordinary full driver
after adding tests. Keep fixtures and subprocess modules in release contents.

## Choose tests for the failure mechanism

| Change | Useful observations |
| --- | --- |
| Scalar return ownership | Repeated calls, retain results after inputs leave scope, discard results, mutate a returned value if aliasing matters |
| Containers | Empty input, missing versus undef elements, sparse arrays, Unicode keys, tied behavior if supported |
| String conversion | Empty, embedded NUL, upgraded/downgraded equivalents, above-255 characters, malformed encoded bytes where relevant |
| Magic | Observable FETCH/STORE counts and values; check intended evaluation counts rather than simply “does not crash” |
| Native handles | Failed construction, explicit close then destruction, use after close, parent/child lifetimes |
| Callbacks | Requested context, empty results, exceptions including objects, reentry, temporary results, stack growth |
| Thread state | Create a thread after initialization, exercise clone policy, destroy parent and child independently |
| Build/metadata | Clean configured build plus fresh release-directory/archive build with declared prerequisites |

Tests should expose public behavior or meaningful lifecycle invariants. Avoid
exact refcount assertions when incidental temporaries legitimately vary; a
destruction counter, weak observer, or resource-release observation can test the
actual promise more reliably. Repeated calls alone are not proof of no leaks.

Use the existing subprocess helper for segfault, abort, interpreter-exit, or
global-destruction regressions. Check termination status, signal where the
platform exposes it, and expected output. Pass arguments without a shell when
possible; do not treat missing output or a truncated TAP stream as success.
Set justified timeouts for potential hangs. Isolate temp files and external
resources so tests can run concurrently; use the framework/build driver's
serialization controls when an inherently shared resource requires them.

Ordinary tests should be deterministic and offline unless the module's test
contract explicitly says otherwise. Preserve reproducible random seeds for
randomized tests. Avoid sleeps as synchronization and locale/clock-sensitive
expected values unless those are the behavior under test.

## Diagnose the right layer

For a loader failure, first check module/native version pairing, stale `blib`,
ABI/configuration mismatch, bootstrap name, and external shared-library paths.
Do not disable version checks or copy a random `.so` into place.

For conversion failures, inspect generated C, typemap precedence, and input/
output code before changing the native algorithm. For a crash, capture a small
reproducer and native backtrace using the actual Perl binary and extension.
For Perl-level flow, `perl -d -Mblib t/regression.t` is useful; it will not step
through C as a native debugger does. `Devel::Peek` can expose SV representations,
but dumping/coercion can change observable state, so do not use a diagnostic
print as proof of the undisturbed state.

Use debug symbols or available debug/sanitizer-enabled Perl environments when
native evidence requires them. Sanitizing only an extension loaded into an
uninstrumented host has limits and may need runtime setup; do not claim full
interpreter coverage. Valgrind or suitable leak tools can supplement ownership
analysis. Distinguish retained caches, allocator high-water behavior, and
interpreter shutdown effects from a per-call leak. `PERL_DESTRUCT_LEVEL=2` can
help some builds expose teardown issues, but does not prove absence of leaks.

Sources: target `prove`, Test::Harness/TAP::Harness, build-driver POD,
`perldebtut`/`perldebug`, `Devel::Peek`, and `perlguts` ownership/stack sections.
`perldebguts` describes debugger implementation hooks, not routine XS debugging.
