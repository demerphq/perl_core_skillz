# Interpreter context and state

Sources: `perlguts` How multiple interpreters and concurrency are supported,
`perlxs` Safely Storing Static Data in XS, `perlthrtut`, `perlmod`'s cloning
hooks, and target `perlapi` entries for the context macros.

## Pass context deliberately

For new helpers that use the Perl API, prefer explicit interpreter context:

```c
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static SV *
make_answer(pTHX_ IV value)
{
    return newSViv(value);
}
/* From an XSUB or helper with context: make_answer(aTHX_ 42); */
```

Place `PERL_NO_GET_CONTEXT` before the headers when adopting this pattern.
Use `pTHX_`/`aTHX_` when more arguments follow, and `pTHX`/`aTHX` alone for no
explicit arguments. Do not add your own comma. XSUB entry macros provide the
context; other C helpers must receive it or use a justified `dTHX` retrieval.
A library callback with a fixed signature may need an explicit owner/context
stored in its callback data, not the assumption that the current thread-local
context happens to be correct.

Preserve working legacy conventions during narrow fixes. Changing context
strategy requires updating all relevant helpers; adding the define alone can
break a previously compiling extension. Passing context is more efficient than
repeated retrieval, but it is not a reason for an unrelated rewrite.

## Keep state with its owner

Read-only tables may be process-global. Mutable SV caches, callbacks, and
interpreter-owned objects should not be plain process-global C statics. Use
the distribution's established per-object/per-interpreter storage. `MY_CXT`
provides a supported per-interpreter struct pattern when that is the right
scope: define `my_cxt_t`, `START_MY_CXT`, initialize in `BOOT:`, and obtain it
with `dMY_CXT` before use. It is not automatically shared across translation
units; follow the documented design if several C files need the same context.

`MY_CXT_INIT` initializes interpreter storage. When ithreads clone an
interpreter, `MY_CXT_CLONE` makes a byte copy of the struct, not a deep copy of
pointed-to native state or SVs. Define how each pointer field is duplicated,
mapped to the new interpreter, reset, shared safely, or rejected. Match teardown
to those ownership decisions. Do not add `MY_CXT_CLONE` and declare thread
safety without this analysis.

## Separate kinds of concurrency

Perl ithreads clone interpreter data; they do not make arbitrary C statics or
native libraries safe. MULTIPLICITY permits multiple interpreters, even without
concurrent threads. A native library's thread safety, process-global state,
and callback restrictions are separate from both.

Review locale, environment, cwd, signal handlers, libc static result buffers,
and native-library initialization. They may affect other interpreters or host
threads. A lock covering only this extension may not protect unrelated users
of a process-global facility.

When an object cannot safely clone, use the established documented cloning
policy rather than duplicating the pointer and risking double destruction.
If supporting cloning, test parent/child lifetime and independent teardown.
If supporting multiple embedded interpreters, test that state does not leak
between them. A threaded Perl running a single-threaded test is not a cloning
test.
