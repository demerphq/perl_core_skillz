# Native resources and C++ wrappers

## Establish ownership before choosing a typemap

List each creation/acquisition function, its failure value, the matching release
function, and whether accessors return owned or borrowed handles. Check the
native library's contract rather than guessing from pointer types. A Perl
object wrapper does not automatically own every pointer reachable through it.

Keep each handle in one of explicit states such as open, closed, or failed
construction. Prevent double release after explicit `close` plus `DESTROY`,
and reject method calls on invalidated handles. Arrange state transitions
before operations that can reenter Perl. Define how children keep parents
alive, and release retained parents when children are destroyed.

`T_PTROBJ` and related mappings can encode pointers in blessed scalar refs.
Inspect their validation, class mapping, and special handling of `DESTROY`.
Blessing is not proof of pointer validity: a forged or already-closed wrapper
can satisfy a class check. Use established module validation and storage
patterns; do not treat an arbitrary integer or blessed scalar as a usable
pointer. `INT2PTR`/`PTR2IV` handle representation conversions, not authenticity
or lifetime.

For extension-owned private attachments, a supported magic-based wrapper can
associate native state with an SV. Use the extension's own vtable identity
when finding/removing `PERL_MAGIC_ext` so it cannot take another module's
attachment. Define free and clone behavior for the actual resource. Read
`perlapi` for `sv_magicext`, `mg_findext`, and `sv_unmagicext` before implementing
it, including preconditions and `mg_ptr`/length ownership rules.

## Failure and destruction

Validate inputs before acquiring native resources where possible. Cover partial
construction and native failure after earlier acquisitions. Pair Perl
allocators with `Safefree`, libc allocations with their matching allocator, and
library handles with their library destructor. Copy a foreign buffer into a
Perl-owned SV before freeing it when the API returns a snapshot; do not transfer
an incompatible allocation into an SV for convenience.

Destruction can occur during an exception or global teardown. Avoid relying on
other package globals still being available. A destructor should not replace
an active exception with a new cleanup error. Do not assume a Perl-level
`DESTROY` hook solves every C resource acquired before a wrapper was created.

Explicitly choose ithread clone behavior: independent clone, shared native
resource with native synchronization/refcounting, or unsupported cloning.
Copying a pointer creates neither a second resource nor a second valid owner.
Use `CLONE`/`CLONE_SKIP` only after reading their target-version contracts;
document and test the consequences.

## C++ boundary

Confirm both compiler and linker/runtime settings, generated C++ glue, typemaps,
and C linkage for bootstrap symbols. Do not assume a parser `-C++` flag selects
the compiler or provides exception translation.

Catch native C++ exceptions at the binding boundary and convert them according
to the Perl API. Perl `croak` is generally a nonlocal jump, not a C++ throw;
do not assume C++ destructors run when a Perl conversion, callback, or output
allocation croaks. Keep RAII-sensitive objects out of frames crossed by such
jumps or use an established, tested boundary mechanism that covers both kinds
of unwind. `CLEANUP:` and `catch (...)` alone do not establish that guarantee.

Test constructor failure, normal destruction, explicit close followed by
destruction, use after close, borrowed children, callback errors, and thread
cloning when those behaviors are part of the supported interface.
