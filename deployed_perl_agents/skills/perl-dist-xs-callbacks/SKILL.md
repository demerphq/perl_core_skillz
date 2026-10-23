---
name: perl-dist-xs-callbacks
description: "Call Perl from XS or an embedding application: call_sv/call_method, stack synchronization, return context, temporary lifetimes, callback retention, and exception cleanup against an installed Perl."
---

# Calling Perl from native code

First decide the callback's context, argument ownership, result lifetime, and
exception policy. The call can reenter the extension, resize the Perl stack,
mutate inputs, and run destructors. Design native state for that behavior.

1. Prefer `call_sv` for a supplied callable or `call_method` for method
   dispatch. Do not generate Perl source by interpolating arguments into an
   `eval` string.
2. For the traditional callback sequence, establish a temporary scope, mark
   and push arguments, `PUTBACK` before the call, `SPAGAIN` after it, consume
   all results, `PUTBACK`, and then release temporaries and scope. Explain any
   departure using the target API's contract.
3. Request `G_SCALAR`, `G_LIST`/the supported equivalent, or `G_VOID`
   explicitly. Use `G_DISCARD` when results are unwanted. Scalar context is
   not a request to take the first item of a list-context call.
4. Decide whether errors propagate immediately or are trapped with `G_EVAL`
   so native cleanup can run. Preserve the exception before cleanup can run
   more Perl, balance returned stack entries on failure too, and rethrow or
   report according to the interface.
5. Retain callback results needed beyond `FREETMPS` with an owned reference or
   an appropriate copy. Retained callbacks themselves need ownership, release,
   interpreter affinity, and a cycle policy.

Read [callbacks.md](references/callbacks.md) for sequencing, reentry, and
exception pitfalls. Read [embedding.md](references/embedding.md) only for a
host application that owns interpreter creation and destruction; an ordinary
XS module must not create or tear down its host interpreter.

Use `perldoc perlcall` and exact `perlapi` entries from the target Perl.
Interpreter context, ithread cloning, and native thread safety are separate
questions; possessing a context pointer does not authorize arbitrary foreign
threads to enter Perl.
