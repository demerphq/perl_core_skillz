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
| Hash iteration or buckets | Enough keys that several share a bucket (a handful can pass by luck of the seed), runs under several `PERL_HASH_SEED` values, every loop bounded (`last if $n > 2 * keys %h`) so a hang regression fails |
| Callback reentry | Callbacks that delete or replace the called sub, assign to the input, empty an outer container, or die; check that later results still match the input |
| Decoders of untrusted input | Truncated and oversized declared lengths; mutation fuzzing outside the suite with each case in a child process, a journal of inputs, and delta-debugging minimisation; no corpus hooks that recurse into the decoder |
| Supported-Perl API use | A build with `-Werror=implicit-function-declaration` in `CCFLAGS`, and the CI matrix across supported Perls; read link or load errors there as portability failures |
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
interpreter coverage (see below). Valgrind or suitable leak tools can supplement
ownership analysis. Distinguish retained caches, allocator high-water behavior,
and interpreter shutdown effects from a per-call leak. `PERL_DESTRUCT_LEVEL=2`
can help some builds expose teardown issues, but does not prove absence of
leaks.

### Sanitizing an extension in an uninstrumented Perl

`perlhacktips` covers sanitizer builds of Perl itself. To instrument only an
extension, build it with sanitizer compile and link flags:

```sh
perl Makefile.PL \
  OPTIMIZE="-O1 -g -fsanitize=address,undefined -fsanitize-recover=all -fno-omit-frame-pointer" \
  LDDLFLAGS="$(perl -MConfig -e 'print $Config{lddlflags}') -fsanitize=address,undefined"
```

The uninstrumented `perl` binary does not load the sanitizer runtime, so insert
it into every process. On macOS that is
`DYLD_INSERT_LIBRARIES=$(cc -print-resource-dir)/lib/darwin/libclang_rt.asan_osx_dynamic.dylib`.
dyld removes the variable from the environment after honouring it, so every
child Perl a test spawns starts without it and the extension aborts with
"Interceptors are not working". Cover children explicitly:

- a launcher script that exports the variable and execs `perl`, used with
  `prove --exec <launcher>`;
- a small module on `PERL5LIB`, loaded through `PERL5OPT=-MThatModule`, that
  sets `$ENV{DYLD_INSERT_LIBRARIES}` again in a `BEGIN` block, so children
  started through `$^X` inherit it.

Set runtime options deliberately:

| Variable | Setting and reason |
| --- | --- |
| `ASAN_OPTIONS` | `detect_leaks=0`: Perl leaks deliberately at exit |
| `ASAN_OPTIONS` | `halt_on_error=0` with `log_path=...` for whole suites, so one report does not stop the run |
| `ASAN_OPTIONS` | `allocator_may_return_null=1` whenever a test expects a huge allocation to fail gracefully; without it the run aborts with "allocation-size-too-big", which looks like a regression |
| `UBSAN_OPTIONS` | `print_stacktrace=1` |

SV heads and bodies come from Perl's own arenas, so ASan cannot see a
use-after-free of an SV. It does see PV buffers, `AvARRAY`/`HvARRAY` storage
and `Newx` memory. A clean sanitizer run therefore does not establish SV
lifetime correctness; combine it with the ownership analysis and reentry tests
above.

Sources: target `prove`, Test::Harness/TAP::Harness, build-driver POD,
`perldebtut`/`perldebug`, `Devel::Peek`, `perlhacktips` on sanitizers and
compiler warnings, the compiler's AddressSanitizer and
UndefinedBehaviorSanitizer documentation, and `perlguts` ownership/stack
sections.
`perldebguts` describes debugger implementation hooks, not routine XS debugging.
